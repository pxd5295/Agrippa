// Finds the sh and perl executables the plugin's scripts run on, for the
// development tools, which are Node scripts.
//
// On macOS and Linux both are on PATH. On Windows they come from Git for
// Windows, whose usr/bin folder is on PATH inside Git Bash (where Claude Code
// runs the hooks and the Bash tool) but not in PowerShell or cmd, where a
// developer typically runs `node dev/validate-kit.mjs`. So on Windows the
// lookup asks git for its exec path, <Git>/mingw64/libexec/git-core, and
// derives the Git root from it before trying PATH, which also keeps a native
// Perl on PATH (Strawberry, ActiveState) from standing in for the MSYS one the
// hooks actually use. For sh it takes <Git>/bin/sh.exe, the launcher that
// puts /usr/bin on the shell's PATH the way Claude Code's own Git Bash does;
// <Git>/usr/bin/sh.exe started from a Windows process finds no sed or tr.
// Perl has no launcher and runs fine from <Git>/usr/bin. Uses only Node's
// built-in modules.

import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { join, resolve } from 'node:path';

// Each tool is probed with a command it must accept on every implementation:
// dash rejects `sh --version`, so sh runs an empty command instead.
const probes = {
    sh: ['-c', 'exit 0'],
    perl: ['-e', '1'],
};

function works(command, name) {
    const args = probes[name];
    if (args === undefined) {
        throw new Error(`no probe for tool '${name}'`);
    }
    const result = spawnSync(command, args, { encoding: 'utf8', windowsHide: true });
    return !result.error && result.status === 0;
}

function gitRoot() {
    const git = spawnSync('git', ['--exec-path'], { encoding: 'utf8', windowsHide: true });
    if (git.error || git.status !== 0 || !git.stdout) {
        return null;
    }
    const execPath = git.stdout.split(/\r?\n/)[0].trim();
    if (execPath === '') {
        return null;
    }
    return resolve(execPath, '..', '..', '..');
}

// Returns the command or full path to run the named tool with, or null when
// none works. The result is suitable for spawnSync.
export function findTool(name) {
    if (process.platform === 'win32') {
        const root = gitRoot();
        if (root !== null) {
            const folder = name === 'sh' ? 'bin' : join('usr', 'bin');
            const candidate = join(root, folder, `${name}.exe`);
            if (existsSync(candidate) && works(candidate, name)) {
                return candidate;
            }
        }
    }
    return works(name, name) ? name : null;
}
