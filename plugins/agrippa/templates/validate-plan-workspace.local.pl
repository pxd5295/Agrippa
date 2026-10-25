# Project-specific checks for the agrippa plugin's plan-workspace linter.
# Optional.
#
# Install as `tools/validate_plan_workspace.local.pl` only when this repository
# has command invariants worth enforcing in every plan's validation matrix; with
# no such invariant, do not install it. The linter, which runs from the plugin
# as `agrippa-lint`, loads this file from `<repository root>/tools/` when it
# exists. A plugin upgrade replaces the linter and never this file.
#
# The file is loaded with Perl's `do` and must return one hash reference. Every
# key is optional:
#
# - `command_path_extensions`: an array reference of lower-case extensions that
#   replaces the list check 13 verifies (which source or test paths inside a
#   validation command must exist).
# - `check_validation_row`: a sub called once per validation-matrix row with one
#   hash reference: `row` is the row keyed by the table's header text
#   (`$args->{row}{'Validation ID'}`, `$args->{row}{'Exact command or check'}`);
#   `command` and `sandbox` are that row's command and Sandbox (or older
#   Environment) cells; `check` is a code reference, `$args->{check}->($condition,
#   $message)`, that records one check and its failure message; `repo_root` and
#   `plan_root` are the resolved folders.
# - `check_validation_matrix`: a sub called once with `rows`, an array reference
#   of every row in matrix order, plus `check`, `repo_root`, and `plan_root`,
#   for ordering invariants.
#
# Typical invariants: one required launcher or wrapper binary instead of a bare
# name on PATH, an invocation shape per test kind, a required working directory
# for one runner, a required Sandbox value, and a prerequisite command that must
# come before the first test. Label failures "[Check 14]" to "[Check 17]" so
# they sort with the linter's own checks.
#
# Perl 5.30 or newer, core modules only, like the linter. The function bodies
# below are the worked example from the Godot repository the kit was extracted
# from. Replace them with this repository's rules; keep the key names and the
# argument shape.

use strict;
use warnings;

# A row is an engine row when it launches the console binary or runs a
# resource script or scene headless. Both subs use this one definition.
my $engine_row_pattern = qr/Godot_[^\s`]*_console\.exe|--headless\s+[^`]*res:\/\/[^\s`]+\.(?:gd|tscn)/ia;

sub command_of {
    my ($row) = @_;
    my $command = $row->{'Exact command or check'};
    return defined $command ? "$command" : '';
}

return {
    # Optional: narrow or extend the command-path extensions check 13 verifies.
    # command_path_extensions => [ 'gd', 'tscn', 'py', 'ps1', 'toml', 'md' ],

    check_validation_row => sub {
        my ($args) = @_;
        my $check = $args->{check};
        my $command = $args->{command};
        my $id = $args->{row}{'Validation ID'};

        # Every engine row uses one exact console binary and runs outside the
        # sandbox, because the engine writes caches outside the workspace.
        if ($command =~ $engine_row_pattern) {
            $check->(index($command, '[PROJECT: exact console binary path]') >= 0, "[Check 14] $id must use the real console binary.");
            $check->(scalar($command !~ /(?:^|[;&]\s*|`)\s*godot\s/ia), "[Check 14] $id uses a bare launcher name.");
            $check->(lc($args->{sandbox}) eq 'outside-sandbox', "[Check 14] $id must declare outside-sandbox.");
        }

        # A script target takes -s and no frame cap; a scene target takes a
        # numeric frame cap.
        if ($command =~ /res:\/\/[^\s`]+\.gd/ia) {
            $check->(scalar($command =~ /(?:^|\s)-s(?:\s|$)/a), "[Check 15] $id targets a script without -s.");
            $check->(scalar($command !~ /--quit-after/a), "[Check 15] $id script invocation must not use --quit-after.");
        }
        if ($command =~ /res:\/\/[^\s`]+\.tscn/ia) {
            $check->(scalar($command =~ /--quit-after\s+\d+/a), "[Check 15] $id scene invocation requires a numeric --quit-after.");
        }
    },

    check_validation_matrix => sub {
        my ($args) = @_;
        my $check = $args->{check};
        # The class-cache prelude must be the first engine row.
        my @engine_rows = grep { command_of($_) =~ $engine_row_pattern } @{ $args->{rows} };
        if (@engine_rows) {
            $check->(scalar(command_of($engine_rows[0]) =~ /--headless\s+--editor\s+--path\s+\.\s+--quit-after\s+\d+/a), '[Check 16] The class-cache prelude must precede the first engine test.');
        }
    },
};
