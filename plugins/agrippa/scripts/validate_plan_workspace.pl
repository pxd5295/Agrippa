#!/usr/bin/perl
# Validates a planning workspace's dispatch shape.
#
# This linter checks shape, never truth. A wrong constant, incomplete design
# choice, or incorrect contract can satisfy every static check. Human planning
# and review remain responsible for semantic correctness.
#
# This is the portable version. It recognizes any dotted file extension and any
# URI-style scheme prefix, and it encodes no project's toolchain. Do not edit
# this file per project. Project-specific command invariants (one required test
# binary, an invocation shape per test kind, a prelude that must come first, a
# narrower command-path extension list) go in the optional
# `tools/validate_plan_workspace.local.pl` in the project, which this script
# loads at the "Project-specific extension point". A plugin upgrade replaces
# this file and never touches the local one.
#
# It ships in the agrippa plugin and runs from there, never from a copy in the
# project. Inside Claude Code, the plugin's `bin/agrippa-lint` wrapper runs it
# from the Bash tool:
#
#     agrippa-lint -PlanPath plans/YYYY-MM-DD-name
#
# Elsewhere, run it from a checkout of Agrippa at the project's pinned tag:
#
#     perl plugins/agrippa/scripts/validate_plan_workspace.pl -PlanPath <plan> -RepoRoot <repository>
#
# Arguments: -PlanPath <folder> (the plan workspace, absolute or relative to
# the repository root; a bare path argument means the same), -RepoRoot <folder>
# (the repository the plan belongs to; when omitted, the git top-level folder
# of the current directory), and -SkipLocalChecks (ignore the project's local
# checks; the kit smoke test uses this because its generic fixture cannot
# satisfy a project's own invariants). The `--plan-path` spellings work too.
#
# Errors go to stderr one per line, warnings to stderr prefixed `WARNING:`,
# and one PASS or FAIL summary line to stdout. Exit 0 on PASS, 1 on FAIL, 2 on
# a usage error.
#
# Perl 5.30 or newer with core modules only, so it runs on the Perl that Git
# for Windows bundles and on the Perl macOS and Linux ship. Files are read as
# bytes and decoded as UTF-8, with a bad byte replaced rather than reported, so
# every string inside the program is a character string; the fs_* helpers
# encode a path back to bytes at each file-system call. Repository paths are
# built with `/` on every OS. Every pattern carries /a so \d, \w, \b, and \s
# stay ASCII, and a `.` outside /s is written [^\r\n] so a CRLF workspace
# lints like an LF one.
#
# It is coupled to the plan templates in `skills/plan/templates/`: a change to
# the template shape must be reflected here, and the reverse. Keep it
# read-only.

use v5.30;
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Spec;
use POSIX qw(strftime);
use Encode qw(decode encode);
use IO::Handle;

# The encoding layer buffers STDERR, so without autoflush the summary line on
# STDOUT could reach a shared pipe before the errors it counts.
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
STDOUT->autoflush(1);
STDERR->autoflush(1);

# Extensions that count as repository source or test paths when they appear
# inside a validation command (check 13). Other paths, such as an output file a
# command writes or a path a command proves is absent, are not checked for
# existence. Ownership, census, and contract-source fields use any dotted
# extension regardless of this list. The local extension file may replace it.
my @default_command_path_extensions = (
    'py', 'ps1', 'psm1', 'sh', 'bash', 'js', 'mjs', 'cjs', 'ts', 'tsx', 'jsx',
    'go', 'rs', 'java', 'kt', 'cs', 'c', 'cc', 'cpp', 'h', 'hpp', 'rb', 'php',
    'swift', 'lua', 'sql', 'gd', 'tscn', 'toml', 'yaml', 'yml', 'md',
);

# Every dispatch packet carries these labels. dev/validate-kit.mjs reads this
# list from the source and requires each label in the PACKETS.md template.
my @required_packet_labels = (
    'Plan', 'Stage', 'Goal', 'Dependencies', 'Owner / assigned tier',
    'Design state', 'Contract IDs', 'Owned files', 'Forbidden scope',
    'Allowed interfaces', 'Pre-authorized ownership expansion',
    'Acceptance', 'Validation', 'Validation output',
    'Relevant references', 'Dirty/user-owned warnings',
    'Stop/escalate when', 'Return only',
);

# A stage's Assigned tier is a model tier (lead/haiku/sonnet/opus, optionally
# with an effort suffix) or a named role from the plugin's agents
# (repo-scout/plan-reviewer/validator).
my $tier_pattern = qr/^(lead|haiku|sonnet|opus|repo-scout|plan-reviewer|validator)\b/ia;

my @allowed_determinism = ('deterministic', 'noisy-retry', 'skips-headless', 'manual');

my $local_checks_name = 'tools/validate_plan_workspace.local.pl';
my @legacy_local_checks = (
    [ 'tools/validate_plan_workspace.local.mjs', 'JavaScript' ],
    [ 'tools/validate_plan_workspace.local.ps1', 'PowerShell' ],
);

# Paths compare case-insensitively where the default file system does. Under
# Git Bash, Perl reports msys rather than MSWin32.
my $case_insensitive_paths = $^O =~ /^(?:MSWin32|msys|cygwin|darwin)$/ ? 1 : 0;

sub usage {
    return 'usage: agrippa-lint -PlanPath <plan folder> [-RepoRoot <repository>] [-SkipLocalChecks]';
}

# --- Character strings in, bytes at the file system boundary ----------------

sub fs {
    my ($path) = @_;
    return encode('UTF-8', $path);
}

sub fs_is_file {
    my ($path) = @_;
    return -f fs($path) ? 1 : 0;
}

sub fs_is_directory {
    my ($path) = @_;
    return -d fs($path) ? 1 : 0;
}

sub fs_mtime {
    my ($path) = @_;
    return (stat fs($path))[9];
}

# Resolves a path that exists to its absolute form; under Git Bash this turns
# C:/... into /c/..., so two spellings of one folder compare equal.
sub fs_resolve {
    my ($path) = @_;
    my $resolved = abs_path(fs($path));
    return defined $resolved ? decode('UTF-8', $resolved) : $path;
}

# Reads a text file as UTF-8, replacing a bad byte with U+FFFD rather than
# warning, and drops a byte-order mark.
sub read_text {
    my ($path) = @_;
    open(my $fh, '<:raw', fs($path)) or die "cannot read $path: $!\n";
    local $/;
    my $bytes = <$fh>;
    close $fh;
    my $text = decode('UTF-8', $bytes // '');
    $text =~ s/^\x{FEFF}//;
    return $text;
}

# Splits text into lines the way a line-by-line reader counts them: a
# trailing newline does not add an empty last line, and an empty file has no
# lines. The -1 keeps trailing empty fields that Perl's split would drop.
sub split_lines {
    my ($text) = @_;
    my @lines = split /\r?\n/, $text, -1;
    pop @lines if @lines && $lines[-1] eq '';
    return @lines;
}

sub read_lines {
    my ($path) = @_;
    return split_lines(read_text($path));
}

sub is_absolute {
    my ($path) = @_;
    return 1 if File::Spec->file_name_is_absolute($path);
    return $path =~ /^[A-Za-z]:[\\\/]/a ? 1 : 0;
}

# --- Small helpers ----------------------------------------------------------

# Accepts the PowerShell spellings every plan's matrix row uses (-PlanPath,
# -RepoRoot, -SkipLocalChecks), their --long-option forms, and a bare path.
sub parse_arguments {
    my @argv = @_;
    my %names = (
        planpath          => 'plan_path',
        'plan-path'       => 'plan_path',
        reporoot          => 'repo_root',
        'repo-root'       => 'repo_root',
        skiplocalchecks   => 'skip_local_checks',
        'skip-local-checks' => 'skip_local_checks',
    );
    my %options = ( plan_path => '', repo_root => '', skip_local_checks => 0 );
    for (my $i = 0; $i < @argv; $i++) {
        my $argument = $argv[$i];
        if ($argument !~ /^--?([A-Za-z][\w-]*)(?:[=:](.*))?$/sa) {
            if ($options{plan_path} eq '') {
                $options{plan_path} = $argument;
                next;
            }
            return { error => "unexpected argument '$argument'" };
        }
        my ($flag, $inline) = ($1, $2);
        my $key = $names{ lc $flag };
        if (!defined $key) {
            return { error => "unknown option '$argument'" };
        }
        if ($key eq 'skip_local_checks') {
            $options{skip_local_checks} = 1;
            next;
        }
        my $value = $inline;
        if (!defined $value) {
            $i++;
            $value = $argv[$i];
            if (!defined $value) {
                return { error => "$argument needs a value" };
            }
        }
        $options{$key} = $value;
    }
    if ($options{plan_path} eq '') {
        return { error => '-PlanPath is required' };
    }
    return { options => \%options };
}

sub normalize_text {
    my ($text) = @_;
    $text = '' if !defined $text;
    $text =~ s/\s+/ /ga;
    $text =~ s/^ //;
    $text =~ s/ $//;
    return $text;
}

sub trim {
    my ($text) = @_;
    $text =~ s/^\s+//a;
    $text =~ s/\s+$//a;
    return $text;
}

# Every match of a /g pattern in order, each as [whole match, group 1, ...],
# like the arrays JavaScript's matchAll yields.
sub matches {
    my ($text, $pattern) = @_;
    my @found;
    while ($text =~ /$pattern/g) {
        push @found, [ $&, @{^CAPTURE} ];
    }
    return @found;
}

# Distinct values in first-seen order.
sub unique {
    my %seen;
    return grep { !$seen{$_}++ } @_;
}

sub same_set {
    my ($left, $right) = @_;
    my @a = sort(unique(@$left));
    my @b = sort(unique(@$right));
    return 0 if @a != @b;
    for my $i (0 .. $#a) {
        return 0 if $a[$i] ne $b[$i];
    }
    return 1;
}

sub same_path {
    my ($left, $right) = @_;
    return $case_insensitive_paths ? lc($left) eq lc($right) : $left eq $right;
}

# Local calendar date of a file's last write, as yyyy-mm-dd.
sub local_date {
    my ($epoch) = @_;
    return strftime('%Y-%m-%d', localtime($epoch));
}

# Returns a table cell by header name, ignoring the header's case, or ''.
sub cell {
    my ($row, $name) = @_;
    if (exists $row->{$name}) {
        return defined $row->{$name} ? "$row->{$name}" : '';
    }
    my $wanted = lc $name;
    for my $key (keys %$row) {
        if (lc($key) eq $wanted) {
            return defined $row->{$key} ? "$row->{$key}" : '';
        }
    }
    return '';
}

# Splits one Markdown table row into cells: a pipe splits cells unless it is
# escaped or inside backticks.
sub split_markdown_row {
    my ($line) = @_;
    my $body = trim($line);
    $body =~ s/^\|+//;
    $body =~ s/\|+$//;
    my @cells;
    my $current = '';
    my $in_code = 0;
    my $escaped = 0;
    for my $char (split //, $body) {
        if ($escaped) {
            $current .= $char;
            $escaped = 0;
            next;
        }
        if ($char eq '\\') {
            $current .= $char;
            $escaped = 1;
            next;
        }
        if ($char eq '`') {
            $in_code = !$in_code;
            $current .= $char;
            next;
        }
        if ($char eq '|' && !$in_code) {
            push @cells, trim($current);
            $current = '';
            next;
        }
        $current .= $char;
    }
    push @cells, trim($current);
    return @cells;
}

# Returns the rows of the first table whose header line matches, as hashes
# keyed by header text. A row with the wrong cell count is reported and skipped.
sub get_table {
    my ($text, $header_pattern, $errors) = @_;
    my @lines = split /\r?\n/, $text, -1;
    my $header_index = -1;
    for my $i (0 .. $#lines) {
        if ($lines[$i] =~ $header_pattern) {
            $header_index = $i;
            last;
        }
    }
    return () if $header_index < 0;
    my @headers = split_markdown_row($lines[$header_index]);
    my @rows;
    for (my $i = $header_index + 2; $i < @lines; $i++) {
        last if $lines[$i] !~ /^\s*\|/a;
        my @cells = split_markdown_row($lines[$i]);
        if (@cells != @headers) {
            push @$errors, sprintf('[Table] Row has %d cells; expected %d: %s', scalar @cells, scalar @headers, $lines[$i]);
            next;
        }
        my %row;
        for my $index (0 .. $#headers) {
            $row{ $headers[$index] } = $cells[$index];
        }
        push @rows, \%row;
    }
    return @rows;
}

# Milestone and Integration sections of PLAN.md with their two-column field
# tables. Field names are matched without regard to case.
sub get_stage_sections {
    my ($text) = @_;
    my $pattern = qr/^#{2,3}\s+((?:M\d+\s*:|Milestone\s+\d+|Integration)[^\r\n]*)\r?\n(.*?)(?=^#{2,3}\s+(?:M\d+\s*:|Milestone\s+\d+|Integration)|\z)/msa;
    my @stages;
    for my $match (matches($text, $pattern)) {
        my $heading = trim($match->[1]);
        my $id = 'Integration';
        if ($heading =~ /^M(\d+)/ia || $heading =~ /^Milestone\s+(\d+)/ia) {
            $id = "M$1";
        }
        my %fields;
        for my $field (matches($match->[2], qr/^\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*$/ma)) {
            my $key = trim($field->[1]);
            if (lc($key) ne 'field' && lc($key) ne '---') {
                $fields{ lc $key } = trim($field->[2]);
            }
        }
        push @stages, { id => $id, heading => $heading, text => $match->[2], fields => \%fields };
    }
    return @stages;
}

sub get_packet_sections {
    my ($text) = @_;
    my $pattern = qr/^###\s+Packet\s+(M\d+|Integration)\s*\r?\n(.*?)(?=^###\s+|\z)/msa;
    return map { { id => $_->[1], text => $_->[2] } } matches($text, $pattern);
}

sub field {
    my ($stage, $name) = @_;
    my $value = $stage->{fields}{ lc $name };
    return defined $value ? $value : '';
}

# Generic path detector: any backtick-quoted token ending in a dotted extension,
# optionally followed by :line, :line-line, or :symbol. There is no
# project-specific extension allow-list, so this works for any language.
sub get_code_paths {
    my ($text) = @_;
    my @paths;
    for my $match (matches($text, qr/`([^`]+)`/a)) {
        my $candidate = trim($match->[1]);
        if ($candidate =~ /\.[A-Za-z0-9]{1,10}(?::[^\/\s]+|:\d+(?:-\d+)?)?$/ia) {
            push @paths, $candidate;
        }
    }
    return @paths;
}

sub get_owned_path_tokens {
    my ($text) = @_;
    my @tokens = get_code_paths($text);
    my %seen = map { lc($_) => 1 } @tokens;
    my $pattern = qr/(?:^|[\s,`])((?:\.?[\w.-]+\/)*[\w.*-]+\.[A-Za-z0-9]{1,10}(?::[^,\s`]+)?)(?=$|[\s,`])/ia;
    for my $match (matches($text, $pattern)) {
        if (!$seen{ lc $match->[1] }) {
            $seen{ lc $match->[1] } = 1;
            push @tokens, $match->[1];
        }
    }
    return @tokens;
}

# Strips a URI-style scheme prefix (for example an engine's virtual resource
# root), a :line or :line-line suffix, and a :symbol suffix, and returns the
# repository-relative file path with `/` separators.
sub get_repo_relative_file {
    my ($owned_path) = @_;
    my $path = $owned_path;
    $path =~ s/^[A-Za-z][A-Za-z0-9+.-]*:\/\///a;
    $path =~ s/:\d+(?:-\d+)?$//a;
    if ($path =~ /^([^\r\n]+\.[A-Za-z0-9]{1,10}):[^\/\\]+$/ia) {
        $path = $1;
    }
    return $path;
}

# Resolves the repository root from -RepoRoot or from git. Returns a hash
# with the root or a message explaining why none was found.
sub find_repo_root {
    my ($requested) = @_;
    my $root = $requested;
    if ($root eq '') {
        my $output = `git rev-parse --show-toplevel 2>/dev/null`;
        if (defined $output && $? == 0) {
            $root = decode('UTF-8', (split /\r?\n/, $output)[0] // '');
            $root = trim($root);
        }
    }
    if ($root eq '' || !fs_is_directory($root)) {
        my $cwd = decode('UTF-8', Cwd::getcwd() // '');
        my $shown = $root ne '' ? $root : "the current directory ($cwd) is not inside a git repository";
        return { error => "[Files] Could not find the repository root: $shown. Run from inside the repository or pass -RepoRoot." };
    }
    return { root => fs_resolve($root) };
}

# Loads the project's optional local checks. Returns the hash the file
# returns, undef when there is no local file, or undef after reporting a
# problem. The file is loaded by its resolved path, because `do` with a
# C:/... path would search @INC under Git Bash.
sub load_local_checks {
    my ($repo_root, $check) = @_;
    my $local_path = "$repo_root/$local_checks_name";
    if (fs_is_file($local_path)) {
        local $@;
        local $!;
        my $resolved = fs(fs_resolve($local_path));
        my $result = do $resolved;
        if ($@) {
            my $error = $@;
            $error =~ s/\s+$//a;
            $check->(0, "[Local] $local_checks_name failed to load: $error");
            return undef;
        }
        if (!defined $result && $!) {
            $check->(0, "[Local] $local_checks_name failed to load: $!");
            return undef;
        }
        if (ref($result) ne 'HASH') {
            $check->(0, "[Local] $local_checks_name must return a hash reference of checks; see templates/validate-plan-workspace.local.pl.");
            return undef;
        }
        return $result;
    }
    for my $legacy (@legacy_local_checks) {
        my ($name, $language) = @$legacy;
        if (fs_is_file("$repo_root/$name")) {
            $check->(0, "[Local] $name is $language; this linter loads $local_checks_name. Run the agrippa upgrade skill to port it.");
        }
    }
    return undef;
}

sub main {
    my @argv = @_;
    my $parsed = parse_arguments(@argv);
    if ($parsed->{error}) {
        print STDERR "agrippa-lint: $parsed->{error}\n", usage(), "\n";
        return 2;
    }
    my $options = $parsed->{options};

    my @errors;
    my @warnings;
    my $checks = 0;
    # A regex match passed straight as the first argument is evaluated in list
    # context and yields an empty list when it fails, which would shift the
    # message into the condition slot and pass the check. Every caller here
    # wraps such a match in scalar(); a project's local file might not, so a
    # one-argument call is treated as the failure it can only be.
    my $check = sub {
        my ($condition, $message) = @_;
        if (@_ == 1) {
            ($condition, $message) = (0, $_[0]);
        }
        $checks++;
        push @errors, $message if !$condition;
        return;
    };
    my $finish = sub {
        my ($summary) = @_;
        print STDERR "WARNING: $_\n" for @warnings;
        print STDERR "$_\n" for @errors;
        print STDOUT "$summary\n";
        return @errors ? 1 : 0;
    };

    my $found = find_repo_root($options->{repo_root});
    if ($found->{error}) {
        push @errors, $found->{error};
        return $finish->('FAIL: 1 shape error(s), 0 checks. Shape validation never proves contract truth.');
    }
    my $repo_root = $found->{root};

    my $requested_path = $options->{plan_path};
    if (!is_absolute($requested_path)) {
        $requested_path = "$repo_root/$requested_path";
    }
    $check->(fs_is_directory($requested_path), "[Files] PlanPath is not a directory: $options->{plan_path}");
    if (!fs_is_directory($requested_path)) {
        return $finish->(sprintf('FAIL: %d error(s), %d checks.', scalar @errors, $checks));
    }
    my $plan_root = fs_resolve($requested_path);
    my $root_prefix = $case_insensitive_paths ? lc $repo_root : $repo_root;
    my $plan_prefix = $case_insensitive_paths ? lc $plan_root : $plan_root;
    $check->(index($plan_prefix, $root_prefix) == 0, '[Files] PlanPath must be inside the repository.');

    my $read_required_file = sub {
        my ($name) = @_;
        my $path = "$plan_root/$name";
        $check->(fs_is_file($path), "[Files] Missing $name.");
        return fs_is_file($path) ? read_text($path) : '';
    };
    my $spec = $read_required_file->('SPEC.md');
    my $plan = $read_required_file->('PLAN.md');
    my $packets = $read_required_file->('PACKETS.md');
    my $status = $read_required_file->('STATUS.md');
    my $workspace_text = join("\n", $spec, $plan, $packets, $status);

    # 1-4: ID traceability and exact acceptance quoting.
    my @acceptance_ids = map { $_->[1] } matches($spec, qr/^\s*-\s*\[[ xX]\]\s*\*\*(A\d+):\*\*/ma);
    my @validation_rows = get_table($plan, qr/^\s*\|\s*Validation ID\s*\|/ia, \@errors);
    my @validation_ids = grep { /^V\d+$/ia } map { cell($_, 'Validation ID') } @validation_rows;
    my @contract_ids = map { $_->[1] } matches($packets, qr/^###\s+(C\d+):/ma);

    $check->(scalar(unique(@acceptance_ids)) == @acceptance_ids, '[Check 2] Duplicate Acceptance ID definition.');
    $check->(scalar(unique(@validation_ids)) == @validation_ids, '[Check 2] Duplicate Validation ID definition.');
    $check->(scalar(unique(@contract_ids)) == @contract_ids, '[Check 3] Duplicate Contract ID definition.');

    for my $acceptance_id (unique(@acceptance_ids)) {
        my $id_pattern = qr/\b\Q$acceptance_id\E\b/ia;
        my $mapped = grep { cell($_, 'Acceptance IDs') =~ $id_pattern } @validation_rows;
        $check->($mapped, "[Check 1] $acceptance_id is not mapped by any validation row.");
    }

    for my $group ([ 'A', \@acceptance_ids, 2 ], [ 'V', \@validation_ids, 2 ], [ 'C', \@contract_ids, 3 ]) {
        my ($prefix, $ids, $check_number) = @$group;
        my @defined = unique(@$ids);
        my %defined_lower = map { lc($_) => 1 } @defined;
        my @referenced = unique(map { $_->[0] } matches($workspace_text, qr/\b$prefix\d+\b/a));
        for my $id (@referenced) {
            $check->($defined_lower{ lc $id }, "[Check $check_number] Referenced $id is undefined.");
        }
        for my $id (@defined) {
            my $occurrences = scalar matches($workspace_text, qr/\b\Q$id\E\b/a);
            $check->($occurrences > 1, "[Check $check_number] Defined $id is orphaned.");
        }
    }

    my $normalized_spec = normalize_text($spec);
    for my $quote (matches($packets, qr/^\s*-\s*(A\d+):\s*([^\r\n]+)\r?$/ma)) {
        my $text = normalize_text($quote->[2]);
        if ($text !~ /^\[/) {
            $check->(index($normalized_spec, $text) >= 0, "[Check 4] Packet text for $quote->[1] is not a whitespace-normalized SPEC.md substring.");
        }
    }

    # 5-12 and 19-23: stage design, routing, ownership, and validation assignment.
    my @stages = get_stage_sections($plan);
    $check->(scalar @stages > 0, '[Stages] No milestone or integration records found.');
    my @packet_sections = get_packet_sections($packets);
    my @packet_ids = map { $_->{id} } @packet_sections;
    $check->(scalar(unique(@packet_ids)) == @packet_ids, '[Packets] Duplicate stage packet.');
    my $plan_relative_path = substr($plan_root, length $repo_root);
    $plan_relative_path =~ s/^[\\\/]+//;

    my %wave_stages;
    my @wave_order;
    for my $stage (@stages) {
        my $design_state = field($stage, 'Design state');
        my $design_state_lower = lc $design_state;
        $check->($design_state_lower eq 'frozen' || $design_state_lower eq 'bounded-choice', "[Check 5] $stage->{id} Design state must be Frozen or Bounded-choice; Open/missing cannot hand off.");
        my $contracts = field($stage, 'Contract IDs');
        if ($design_state_lower eq 'frozen') {
            $check->(scalar($contracts =~ /\bC\d+\b/ia), "[Check 6] Frozen stage $stage->{id} must name at least one Contract ID.");
        }
        if ($design_state_lower eq 'bounded-choice') {
            my $choice = field($stage, 'Bounded choice');
            $choice = $stage->{text} if $choice eq '';
            $check->(scalar($choice =~ /Options\s*:/ia), "[Check 7] $stage->{id} bounded choice must enumerate Options.");
            $check->(scalar($choice =~ /Default\s*:/ia), "[Check 7] $stage->{id} bounded choice must name a Default.");
            $check->(scalar($choice =~ /Change observation\s*:/ia), "[Check 7] $stage->{id} bounded choice must name the exact Change observation.");
            if ($stage->{text} =~ /Bounded choice\s*\|(.+?)(?:\r?\n\||\z)/isa && defined $1 && $1 ne '') {
                my $choice_block = $1;
                $check->(scalar($choice_block !~ /\bC\d+\b|(?:^|\s)(?:[A-Za-z][A-Za-z0-9+.-]*:\/\/|[\w.-]+\/)[^\s,;]+/ia), "[Check 7] $stage->{id} bounded-choice block contains a Contract ID or bare path.");
            }
        }

        my $profile = field($stage, 'Assigned tier');
        my $profile_base = $profile =~ $tier_pattern ? lc $1 : '';
        $check->($profile_base ne '', "[Check 19] $stage->{id} Assigned tier '$profile' is not a known tier (lead/haiku/sonnet/opus) or role (repo-scout/plan-reviewer/validator).");
        if ($profile_base eq 'opus') {
            my $split_text = '';
            if ($stage->{text} =~ /^####\s+Split attempt\s*\r?\n(.+?)(?=^####|^#{2,3}\s|\z)/imsa) {
                $split_text = normalize_text($1);
            }
            $check->(scalar($split_text ne '' && $split_text !~ /^not attempted|not required/ia), "[Check 8] $stage->{id} high-tier stage requires a substantive Split attempt.");
        }

        $check->(field($stage, 'Forbidden scope') ne '', "[Check 12] $stage->{id} must name Forbidden scope.");
        $check->(field($stage, 'Pre-authorized ownership expansion') ne '', "[Check 12] $stage->{id} must name a pre-authorized ownership-expansion bound.");

        my $validation_refs = field($stage, 'Validation IDs');
        $check->(scalar($validation_refs =~ /\bV\d+\b/ia), "[Check 22] $stage->{id} must name at least one Validation ID.");

        my $risk_flags = field($stage, 'Risk flags');
        if ($profile_base eq 'haiku' && $risk_flags =~ /native|persist|security|concurr|perf|layout|gpu/ia) {
            $check->(0, "[Check 20] $stage->{id} risk flags require sonnet or stronger, not haiku.");
        }

        my $owned = field($stage, 'Owned files/modules');
        my $owns_nothing = $owned =~ /^None$/ia ? 1 : 0;
        if ($profile_base eq 'validator') {
            $check->($owns_nothing, "[Check 23] validator stage $stage->{id} must declare Owned files/modules: None.");
        }
        if ($profile_base eq 'haiku') {
            my $anchor_text = field($stage, 'Line-anchored edit sites');
            for my $owned_path (get_code_paths($owned)) {
                my $file_only = get_repo_relative_file($owned_path);
                my $has_anchor = $anchor_text =~ /\Q$file_only\E:\d+/ia ? 1 : 0;
                $check->($has_anchor, "[Check 21] Haiku stage $stage->{id} lacks a line anchor for $file_only.");
                my $absolute_owned = "$repo_root/$file_only";
                if (fs_is_file($absolute_owned)) {
                    my $line_count = scalar read_lines($absolute_owned);
                    if ($line_count > 800) {
                        $check->($has_anchor, "[Check 21] Haiku stage $stage->{id} owns $line_count-line $file_only without an anchor.");
                    }
                }
            }
            $check->(scalar(field($stage, 'Validation output') =~ /^Bounded$/ia), "[Check 21] Haiku stage $stage->{id} must declare bounded validation output.");
        }

        my $wave = field($stage, 'Wave');
        if ($wave ne '' && $stage->{id} ne 'Integration') {
            my $wave_key = lc $wave;
            if (!exists $wave_stages{$wave_key}) {
                $wave_stages{$wave_key} = { name => $wave, stages => [] };
                push @wave_order, $wave_key;
            }
            push @{ $wave_stages{$wave_key}{stages} }, $stage;
        }

        my @stage_packets = grep { $_->{id} eq $stage->{id} } @packet_sections;
        $check->(scalar @stage_packets == 1, "[Packets] $stage->{id} must have exactly one dispatch packet.");
        if (@stage_packets == 1) {
            my $packet_text = $stage_packets[0]{text};
            for my $label (@required_packet_labels) {
                $check->(scalar($packet_text =~ /^\Q$label\E\s*:/ima), "[Packets] $stage->{id} packet is missing '$label'.");
            }
            $check->(scalar($packet_text =~ /^Plan:\s*\Q$plan_relative_path\E\s*$/ima), "[Packets] $stage->{id} packet Plan path does not match $plan_relative_path.");
            $check->(scalar($packet_text =~ /^Stage:\s*\Q$stage->{id}\E\b/ima), "[Packets] $stage->{id} packet Stage field does not match.");
            $check->(scalar($packet_text =~ /^Owner \/ assigned tier:\s*\Q$profile\E\s*$/ima), "[Packets] $stage->{id} packet assigned tier does not match PLAN.md.");
            $check->(scalar($packet_text =~ /^Design state:\s*\Q$design_state\E\s*$/ima), "[Packets] $stage->{id} packet design state does not match PLAN.md.");

            my @plan_contract_ids = unique(map { $_->[0] } matches($contracts, qr/\bC\d+\b/a));
            my @packet_contract_ids;
            if ($packet_text =~ /^Contract IDs:\s*([^\r\n]+)\r?$/ima) {
                @packet_contract_ids = unique(map { $_->[0] } matches($1, qr/\bC\d+\b/a));
            }
            $check->(same_set(\@plan_contract_ids, \@packet_contract_ids), "[Packets] $stage->{id} Contract IDs differ between PLAN.md and PACKETS.md.");

            my @stage_acceptance_ids = unique(map { $_->[0] } matches(field($stage, 'Acceptance IDs'), qr/\bA\d+\b/a));
            for my $acceptance_id (@stage_acceptance_ids) {
                $check->(scalar($packet_text =~ /^\s*-\s*\Q$acceptance_id\E:\s*\S/ima), "[Packets] $stage->{id} omits acceptance text for $acceptance_id.");
            }
            my @stage_validation_ids = unique(map { $_->[0] } matches($validation_refs, qr/\bV\d+\b/a));
            for my $validation_id (@stage_validation_ids) {
                $check->(scalar($packet_text =~ /^\s*-\s*\Q$validation_id\E:\s*\S/ima), "[Packets] $stage->{id} omits validation text for $validation_id.");
            }

            my @plan_owned_paths = unique(map { lc get_repo_relative_file($_) } get_owned_path_tokens($owned));
            my @packet_owned_paths;
            if ($packet_text =~ /^Owned files:\s*([^\r\n]+)\r?$/ima) {
                @packet_owned_paths = unique(map { lc get_repo_relative_file($_) } get_owned_path_tokens($1));
            }
            if ($owns_nothing) {
                $check->(scalar($packet_text =~ /^Owned files:\s*None\s*$/ima), "[Packets] $stage->{id} no-file ownership must match in its packet.");
            } else {
                $check->(same_set(\@plan_owned_paths, \@packet_owned_paths), "[Packets] $stage->{id} owned files differ between PLAN.md and PACKETS.md.");
            }
        }
    }

    my @stage_ids = map { $_->{id} } @stages;
    for my $packet_id (unique(@packet_ids)) {
        $check->((grep { $_ eq $packet_id } @stage_ids) ? 1 : 0, "[Packets] Packet $packet_id has no matching PLAN.md stage.");
    }

    for my $wave_key (@wave_order) {
        my $wave = $wave_stages{$wave_key}{name};
        my @members = @{ $wave_stages{$wave_key}{stages} };
        my @writers = grep { field($_, 'Owned files/modules') !~ /^None$/ia } @members;
        $check->(scalar @writers <= 3, sprintf('[Check 10] Wave %s declares %d writers; maximum is 3.', $wave, scalar @writers));
        if (@writers > 2) {
            for my $writer (@writers) {
                $check->(lc(field($writer, 'Design state')) eq 'frozen', "[Check 10] Every stage in three-writer Wave $wave must be Frozen.");
            }
        }

        my %owners_by_path;
        my @owner_order;
        for my $writer (@writers) {
            for my $owned_path (get_code_paths(field($writer, 'Owned files/modules'))) {
                my $file_only = lc get_repo_relative_file($owned_path);
                if (!exists $owners_by_path{$file_only}) {
                    $owners_by_path{$file_only} = [];
                    push @owner_order, $file_only;
                }
                push @{ $owners_by_path{$file_only} }, { stage => $writer, raw => $owned_path };
            }
        }
        for my $path (@owner_order) {
            my @owners = @{ $owners_by_path{$path} };
            $check->(scalar @owners <= 1, "[Check 9] Wave $wave has overlapping ownership of $path.");
            if (@owners > 1 && grep { $_->{raw} =~ /\.[A-Za-z0-9]+:[^\d][^\/\\]*$/ia } @owners) {
                for my $owner (@owners) {
                    $check->(scalar(field($owner->{stage}, 'Worktree') !~ /^No$|^None$|^$/ia), "[Check 11] Concurrent file:symbol ownership of $path requires a declared worktree.");
                }
            }
        }
    }

    # The ownership matrix is authoritative and must exactly mirror stage ownership.
    my @ownership_rows = get_table($plan, qr/^\s*\|\s*Path\s*\|\s*Wave\s*\|\s*Owning stage\s*\|/ia, \@errors);
    $check->(scalar @ownership_rows > 0, '[Ownership matrix] Missing or empty Ownership matrix.');
    my @expected_ownership;
    for my $stage (@stages) {
        my $wave = field($stage, 'Wave');
        for my $owned_path (get_code_paths(field($stage, 'Owned files/modules'))) {
            push @expected_ownership, { path => lc get_repo_relative_file($owned_path), wave => $wave, stage => $stage->{id} };
        }
    }
    my @actual_ownership;
    for my $row (@ownership_rows) {
        my @matrix_paths = map { lc get_repo_relative_file($_) } get_code_paths(cell($row, 'Path'));
        $check->(scalar @matrix_paths == 1, '[Ownership matrix] Each row must name exactly one code path: ' . cell($row, 'Path'));
        if (@matrix_paths == 1) {
            push @actual_ownership, { path => $matrix_paths[0], wave => cell($row, 'Wave'), stage => cell($row, 'Owning stage') };
        }
    }
    my $same_mapping = sub {
        my ($left, $right) = @_;
        return $left->{path} eq $right->{path}
            && lc($left->{wave}) eq lc($right->{wave})
            && lc($left->{stage}) eq lc($right->{stage});
    };
    for my $expected (@expected_ownership) {
        my @found_rows = grep { $same_mapping->($_, $expected) } @actual_ownership;
        $check->(scalar @found_rows == 1, "[Ownership matrix] Missing or duplicate mapping for $expected->{path}, Wave $expected->{wave}, $expected->{stage}.");
    }
    for my $actual (@actual_ownership) {
        my @found_rows = grep { $same_mapping->($_, $actual) } @expected_ownership;
        $check->(scalar @found_rows == 1, "[Ownership matrix] Extraneous or mismatched mapping for $actual->{path}, Wave $actual->{wave}, $actual->{stage}.");
    }

    my ($integration) = grep { $_->{id} eq 'Integration' } @stages;
    $check->(defined $integration, '[Check 22] Exactly one Integration stage is required.');
    if (defined $integration) {
        $check->(scalar($integration->{text} =~ /full applicable suite/ia), '[Check 22] Integration must run the full applicable suite.');
        my $integration_ids = field($integration, 'Validation IDs');
        my $has_integration_row = grep {
            cell($_, 'When') =~ /Integration/ia
                && $integration_ids =~ /\b\Q${\ cell($_, 'Validation ID') }\E\b/ia
        } @validation_rows;
        $check->($has_integration_row, '[Check 22] Integration Validation IDs must include a matrix row scheduled for Integration.');
    }

    # Project-specific extension point: load the optional local checks. The
    # file returns a hash that may hold command_path_extensions (replacing the
    # default list), check_validation_row (called once per matrix row), and
    # check_validation_matrix (called once with every row); both subs get
    # check to report with. A missing file changes nothing. The file belongs
    # to the project, so it is read from the repository root, never from this
    # script's folder.
    my @command_path_extensions = @default_command_path_extensions;
    my $local;
    if (!$options->{skip_local_checks}) {
        $local = load_local_checks($repo_root, $check);
    }
    if ($local && ref($local->{command_path_extensions}) eq 'ARRAY') {
        @command_path_extensions = map { lc "$_" } @{ $local->{command_path_extensions} };
    }
    my $local_row_check = $local && ref($local->{check_validation_row}) eq 'CODE' ? $local->{check_validation_row} : undef;
    my $local_matrix_check = $local && ref($local->{check_validation_matrix}) eq 'CODE' ? $local->{check_validation_matrix} : undef;
    my %local_context = ( check => $check, repo_root => $repo_root, plan_root => $plan_root );

    # 13-18: validation commands are runnable and honestly classified.
    $check->(scalar @validation_rows > 0, '[Validation] Validation matrix is missing or empty.');
    for my $row (@validation_rows) {
        my $validation_id = cell($row, 'Validation ID');
        my $command = cell($row, 'Exact command or check');
        my $style = cell($row, 'Style');
        # Current templates name this column Sandbox. Workspaces written from an
        # earlier kit named it Environment; accept either so older plans still lint.
        my $sandbox = cell($row, 'Sandbox');
        $sandbox = cell($row, 'Environment') if $sandbox eq '';
        my $determinism = cell($row, 'Determinism');
        $check->($style ne '', "[Check 18] $validation_id is missing Style.");
        $check->($sandbox ne '', "[Check 18] $validation_id is missing Sandbox.");
        $check->((grep { $_ eq lc $determinism } @allowed_determinism) ? 1 : 0, "[Check 18] $validation_id has invalid Determinism '$determinism'.");

        # Check 13: every source or test path a command names must exist, relative
        # to the repository root or to the plan folder (for a file under design/
        # or another plan-local folder). A URL is not a repository path.
        my $path_pattern = qr/(?<![\w.-])([A-Za-z][A-Za-z0-9+.-]*:\/\/)?((?:[\w.-]+\/)+[\w.-]+\.([A-Za-z0-9]{1,10}))(?![\w\/-])/ia;
        for my $target (matches($command, $path_pattern)) {
            my $scheme = $target->[1] // '';
            next if $scheme =~ /^https?:\/\/$/ia;
            next if !grep { $_ eq lc $target->[3] } @command_path_extensions;
            my $relative = $target->[2];
            my $exists = fs_is_file("$repo_root/$relative") || fs_is_file("$plan_root/$relative");
            $check->($exists, "[Check 13] $validation_id names missing path $relative.");
        }

        # Project-specific extension point, per row (checks 14-17).
        if ($local_row_check) {
            local $@;
            eval {
                $local_row_check->({ row => $row, command => $command, sandbox => $sandbox, %local_context });
                1;
            } or do {
                my $error = $@ // 'unknown error';
                $error =~ s/\s+$//a;
                $check->(0, "[Local] check_validation_row failed on $validation_id: $error");
            };
        }
    }
    # Project-specific extension point, across rows (ordering invariants).
    if ($local_matrix_check) {
        local $@;
        eval {
            $local_matrix_check->({ rows => \@validation_rows, %local_context });
            1;
        } or do {
            my $error = $@ // 'unknown error';
            $error =~ s/\s+$//a;
            $check->(0, "[Local] check_validation_matrix failed: $error");
        };
    }

    # 24-26: contract source freshness, consumer census, and covering-test resolution.
    for my $contract (matches($packets, qr/^###\s+(C\d+):[^\r\n]*\r?\n(.*?)(?=^###\s+|^##\s|\z)/msa)) {
        my $contract_id = $contract->[1];
        my $body = $contract->[2];
        if ($body =~ /Contract source:\s*`?([^`\r\n:]+\.[A-Za-z0-9]+):(\d+)`?\s*\(read\s+(\d{4}-\d{2}-\d{2})\)/ia) {
            my ($source_relative, $source_line, $read_date) = ($1, $2 + 0, $3);
            my $source_path = "$repo_root/$source_relative";
            $check->(fs_is_file($source_path), "[Check 24] $contract_id source file does not exist: $source_relative.");
            if (fs_is_file($source_path)) {
                my @source_lines = read_lines($source_path);
                $check->($source_line >= 1 && $source_line <= @source_lines, "[Check 24] $contract_id source line $source_line is outside $source_relative.");
                my $modified_date = local_date(fs_mtime($source_path));
                $check->($modified_date le $read_date, "[Check 24] $contract_id is stale: $source_relative changed after $read_date.");
            }
        } else {
            $check->(0, "[Check 24] $contract_id lacks Contract source: file:line (read YYYY-MM-DD).");
        }

        if ($body =~ /Consumer census:\s*(.+?)(?=Pre-authorized ownership expansion:|Covering tests:|\z)/isa) {
            my $census = $1;
            for my $entry (matches($census, qr/`([^`:\r\n]+\.[A-Za-z0-9]+):(\d+)`(?:\s*:\s*`([^`\r\n]+)`)?/ma)) {
                my $relative = $entry->[1];
                my $line_number = $entry->[2] + 0;
                my $snippet = normalize_text($entry->[3]);
                my $consumer_path = "$repo_root/$relative";
                $check->(fs_is_file($consumer_path), "[Check 25] $contract_id consumer file does not exist: $relative.");
                if (fs_is_file($consumer_path)) {
                    my @consumer_lines = read_lines($consumer_path);
                    $check->($line_number >= 1 && $line_number <= @consumer_lines, "[Check 25] $contract_id consumer line $line_number is outside $relative.");
                    if ($snippet ne '' && $line_number >= 1 && $line_number <= @consumer_lines) {
                        $check->(index(normalize_text($consumer_lines[$line_number - 1]), $snippet) >= 0, "[Check 25] $contract_id consumer snippet no longer matches $relative:$line_number.");
                    }
                }
            }
        } else {
            $check->(0, "[Check 25] $contract_id lacks a Consumer census.");
        }

        if ($body =~ /Covering tests:\s*(.+?)(?=^-\s|\z)/imsa) {
            my $covering = $1;
            for my $entry (matches($covering, qr/`([^`\r\n]+\.[A-Za-z0-9]+)(?::\d+)?`/a)) {
                my $relative = $entry->[1];
                $check->(fs_is_file("$repo_root/$relative"), "[Check 26] $contract_id covering test does not exist: $relative.");
            }
        } else {
            push @warnings, "[Check 26] $contract_id lacks Covering tests; list the test scripts and scenes that reference the owned files, or None.";
        }
    }

    if (@errors) {
        return $finish->(sprintf('FAIL: %d shape error(s), %d checks. Shape validation never proves contract truth.', scalar @errors, $checks));
    }
    return $finish->("PASS: $checks workspace-shape checks. This result does not validate contract truth.");
}

# An uncaught error exits 1 with the wrapper's prefix, as the Node version
# did, rather than Perl's default status.
my $code = eval { main(map { decode('UTF-8', $_) } @ARGV) };
if (!defined $code) {
    my $error = $@ // 'unknown error';
    $error =~ s/\s+$//a;
    print STDERR "agrippa-lint: $error\n";
    $code = 1;
}
exit $code;
