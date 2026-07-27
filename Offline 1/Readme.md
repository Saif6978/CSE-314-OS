# BVCS — Bash Version Control System

A lightweight, fully functional version control system written entirely in Bash. BVCS mirrors core Git workflows—staging, committing, logging, diffing, and restoring—using only standard POSIX/GNU utilities.

---

## Table of Contents

- [About the Project](#about-the-project)
  - [What is a Version Control System?](#what-is-a-version-control-system)
  - [What is BVCS?](#what-is-bvcs)
  - [Why Build BVCS?](#why-build-bvcs)
- [Theory & How It Works](#theory--how-it-works)
  - [Snapshot-Based Storage](#snapshot-based-storage)
  - [Repository Layout](#repository-layout)
  - [Commit IDs](#commit-ids)
  - [Staging Area](#staging-area)
  - [Status Classification](#status-classification)
- [Project Structure](#project-structure)
- [Features](#features)
- [Installation & Setup](#installation--setup)
- [Usage](#usage)
- [Command Reference](#command-reference)
- [Example Workflow](#example-workflow)
- [Constraints](#constraints)

---

## About the Project

### What is a Version Control System?

A **Version Control System (VCS)** is a tool that records changes to files over time, allowing you to:
- Track the history of every modification
- Compare different versions of a file
- Revert to previous states when something breaks
- Collaborate with others without overwriting each other's work

Tools like **Git**, **SVN**, and **Mercurial** are industrial-strength VCS solutions used by millions of developers. They solve complex problems like branching, merging, distributed collaboration, and efficient storage.

### What is BVCS?

**BVCS (Bash Version Control System)** is a **minimalist, educational VCS** written as a single Bash script. It implements the **core mental model** of version control—without the complexity of a full production system.

Think of BVCS as a "Git-lite" that you can read, understand, and modify in an afternoon. It proves that the fundamental ideas behind version control (snapshots, staging, diffs, restoration) can be expressed with nothing more than shell commands and file system operations.

### What Does BVCS Actually Do?

BVCS provides a complete, end-to-end version control workflow:

1. **Initialize** a hidden `.bvcs/` repository in any directory.
2. **Stage** files you want to save—this is your "proposed changes" list.
3. **Commit** those staged files, creating a permanent snapshot with a message and timestamp.
4. **Inspect** the history of all commits, most recent first.
5. **Compare** any working file against the last committed version.
6. **Restore** a file to its last committed state if you make a mistake.

Every commit stores a **complete snapshot** of every tracked file. This means you can always see exactly what your project looked like at any point in time, and you can recover any file instantly.

### Why Build BVCS?

This project was built as a programming assignment to demonstrate mastery of:

- **Bash scripting** — functions, loops, conditionals, arrays, I/O redirection
- **File system manipulation** — creating directories, copying files, reading/writing text files
- **Process control** — exit codes, error handling, piping, temporary files
- **VCS internals** — understanding how Git actually stores data under the hood
- **POSIX utilities** — `find`, `diff`, `grep`, `wc`, `date`, `tac`, `sort`, `mkdir`, `cp`

By building BVCS from scratch, you gain an intuitive understanding of concepts that are often hidden behind Git's user-friendly interface.

---

## Theory & How It Works

### Snapshot-Based Storage

Most modern VCS tools (including Git) use **delta compression**—they store only the *differences* between commits to save space. BVCS takes the opposite approach: **complete snapshots**.

Here's what happens on every commit:

1. **Copy forward**: The entire `files/` directory from the previous commit is copied into the new commit directory.
2. **Overwrite**: Each file currently in the staging area is copied on top of the carried-forward snapshot.
3. **Save metadata**: A `message` file and a `timestamp` file are written.
4. **Update pointers**: The `HEAD` file is updated to point to the new commit, and the commit is appended to `log`.
5. **Clear staging**: The staging area is emptied.

**Why snapshots?** Because they make every operation simple:
- `status` just compares working files against `HEAD/files/`.
- `diff` runs `diff -u` between a working file and `HEAD/files/<file>`.
- `restore` copies `HEAD/files/<file>` back to the working directory.
- `log` reads `.bvcs/log` in reverse order.

No graph traversal. No parent pointers. No object hashing. Just files and directories.

### Repository Layout

```
.bvcs/
├── objects/                # One subdirectory per commit
│   ├── 0001/
│   │   ├── files/          # Complete snapshot of every tracked file at this commit
│   │   │   ├── main.c
│   │   │   └── util.h
│   │   ├── message         # Commit message (one plain-text line)
│   │   └── timestamp       # Commit time (one plain-text line, YYYY-MM-DD HH:MM:SS)
│   ├── 0002/
│   │   ├── files/          # Carries forward 0001's files, plus any staged changes
│   │   ├── message
│   │   └── timestamp
│   └── ...
├── staging                 # Staged file paths, one per line, no duplicates
├── log                     # Pipe-delimited history: id|timestamp|message
└── HEAD                    # Commit ID of the most recent commit (empty if none)
```

### Commit IDs

Commit IDs are **sequential 4-digit zero-padded integers**: `0001`, `0002`, `0003`, ...

The ID of the next commit is calculated as:
```
next_id = (number of lines in .bvcs/log) + 1
```

This guarantees monotonic, human-readable identifiers with no gaps.

### Staging Area

The `.bvcs/staging` file is a simple text list. Each line is a relative file path that has been marked for the next commit.

- Adding a file appends its path to this file.
- Duplicate entries are prevented.
- Committing reads this file line-by-line, copies each file into the snapshot, then truncates the file to empty.

This is exactly analogous to Git's "index" or "staging area," but implemented as a plain text file instead of a binary blob.

### Status Classification

When you run `bvcs status`, the working directory is analyzed into three mutually exclusive categories:

| Category | Definition | Example |
|----------|------------|---------|
| **Staged** | Files explicitly added via `bvcs add` and waiting to be committed | `main.c` (just added) |
| **Modified** | Files already tracked in `HEAD` whose working copy differs from the snapshot, **and** they are not currently staged | `readme.txt` (edited after last commit) |
| **Untracked** | Files in the working directory that are neither staged nor present in `HEAD` | `build/output.o`, `notes.md` |

If all three categories are empty, BVCS reports:
```
Nothing to commit, working tree clean.
```

**Ordering rules:**
- Staged files appear in the order they were staged.
- Modified and untracked files appear in alphabetical (sorted) order.
- Each non-empty category is followed by exactly one blank line.
- The `.bvcs/` directory is always excluded from scanning.

---

## Project Structure

```
.
├── 2205119.sh              # Main BVCS executable (single-file Bash script)
├── README.md               # Project documentation
└── .bvcs/                  # Created automatically by 'bvcs init'
    ├── objects/            # Commit objects directory
    │   └── <commit_id>/
    │       ├── files/      # Snapshot of tracked files
    │       ├── message     # Commit message
    │       └── timestamp   # Commit timestamp
    ├── staging             # Staging area (list of paths)
    ├── log                 # Commit history
    └── HEAD                # Pointer to latest commit
```

---

## Features

- ✅ **Repository Initialization** — Create a new `.bvcs/` repository with one command
- ✅ **File Staging** — Stage one or more files for the next commit
- ✅ **Status Inspection** — View staged, modified, and untracked files with clear categorization
- ✅ **Committing** — Save complete snapshots with custom messages and timestamps
- ✅ **History Log** — View all commits in reverse chronological order
- ✅ **Diffing** — Compare working copy against HEAD using unified diff format (`diff -u`)
- ✅ **File Restoration** — Restore any tracked file from HEAD with interactive confirmation
- ✅ **Help System** — Built-in usage instructions for all subcommands
- ✅ **Error Handling** — Graceful errors for missing repos, missing files, empty staging, etc.

---

## Installation & Setup

### Prerequisites

- A Unix-like environment (Linux, macOS, WSL)
- Bash shell
- Standard POSIX/GNU utilities: `find`, `diff`, `grep`, `wc`, `date`, `mkdir`, `cp`, `tac`, `sort`, `dirname`

### Setup

1. Clone or download the repository containing `2205119.sh`.
2. Make the script executable:

```bash
chmod +x 2205119.sh
```

3. (Optional but recommended) Create an alias for convenience:

```bash
alias bvcs="/path/to/2205119.sh"
```

To make the alias permanent, add it to your shell configuration:

```bash
echo 'alias bvcs="/path/to/2205119.sh"' >> ~/.bashrc
source ~/.bashrc
```

---

## Usage

### Initialize a Repository

```bash
bvcs init
```

Creates the `.bvcs/` directory structure. Fails if `.bvcs/` already exists.

Output:
```
Initialized empty BVCS repository.
```

### Stage Files

```bash
bvcs add <file>...
```

Stages one or more files. Files must exist. Already-staged files are skipped. Missing files produce an error but do not stop processing of remaining files.

Example:
```bash
bvcs add main.c util.h
```

Output:
```
Staged: main.c
Staged: util.h
```

### Check Status

```bash
bvcs status
```

Displays the current state of the working directory in three categories: Staged, Modified, and Untracked.

Example output:
```
Staged for commit:
  main.c
  util.h

Modified (not staged):
  readme.txt

Untracked files:
  build/output.o
  notes.md

```

### Commit Changes

```bash
bvcs commit -m "Your commit message"
```

Creates a new commit from the staging area. Requires a non-empty message and a non-empty staging area.

Output:
```
[0001] Initial commit
2 file(s) committed.
```

### View History

```bash
bvcs log
```

Displays all commits in reverse chronological order (most recent first).

Example output:
```
commit 0002
Date:    2026-06-26 11:30:00
Message: Add utility functions

commit 0001
Date:    2026-06-26 10:00:00
Message: Initial commit

```

### View Differences

```bash
bvcs diff [file]
```

- **With a file argument**: Shows the unified diff for that specific file against HEAD.
- **Without a file argument**: Shows the diff for every tracked file.

If a file has no changes, it prints:
```
main.c: no changes.
```

If there are differences, it prints a standard `diff -u` output with custom labels to suppress timestamps:
```
--- .bvcs/objects/0002/files/main.c
+++ main.c
@@ -1,4 +1,6 @@
 #include <stdio.h>
+#include <stdlib.h>
...
```

### Restore a File

```bash
bvcs restore <file>
```

Restores a file from the HEAD snapshot, overwriting the working copy. Prompts for confirmation.

Example interaction:
```
Restore 'main.c' from commit 0002? [y/N]: y
Restored: main.c
```

Any answer other than `y` or `Y` aborts:
```
Restore 'main.c' from commit 0002? [y/N]: n
Aborted.
```

### Show Help

```bash
bvcs help
```

Prints a concise usage message listing all subcommands and their syntax.

---

## Command Reference

| Command | Syntax | Description |
|---------|--------|-------------|
| `init` | `bvcs init` | Initialize a new BVCS repository |
| `add` | `bvcs add <file>...` | Stage one or more files |
| `status` | `bvcs status` | Show staged, modified, and untracked files |
| `commit` | `bvcs commit -m "message"` | Commit staged files |
| `log` | `bvcs log` | Display commit history (most recent first) |
| `diff` | `bvcs diff [file]` | Compare working copy to HEAD |
| `restore` | `bvcs restore <file>` | Restore a file from HEAD |
| `help` | `bvcs help` | Print usage information |

---

## Example Workflow

Here is a complete end-to-end session demonstrating all BVCS features:

```bash
# 1. Set up a project
mkdir myproject && cd myproject
alias bvcs="/path/to/2205119.sh"

# 2. Initialize the repository
bvcs init
# Output: Initialized empty BVCS repository.

# 3. Create some source files
echo '#include <stdio.h>' > main.c
echo 'int helper() {}' > util.c
echo '# Notes' > notes.md

# 4. Stage files for the first commit
bvcs add main.c util.c
# Output:
# Staged: main.c
# Staged: util.c

# 5. Check the status
bvcs status
# Output:
# Staged for commit:
#   main.c
#   util.c
#
# Untracked files:
#   notes.md
#

# 6. Commit the staged files
bvcs commit -m "Initial commit"
# Output:
# [0001] Initial commit
# 2 file(s) committed.

# 7. Make a change to a tracked file
echo 'int main() {}' >> main.c

# 8. Check status again
bvcs status
# Output:
# Modified (not staged):
#   main.c
#
# Untracked files:
#   notes.md
#

# 9. View the diff
bvcs diff main.c
# Output:
# --- .bvcs/objects/0001/files/main.c
# +++ main.c
# @@ -1 +1,2 @@
#  #include <stdio.h>
# +int main() {}

# 10. Oops—let's restore the original
bvcs restore main.c
# Output:
# Restore 'main.c' from commit 0001? [y/N]: y
# Restored: main.c

# 11. Verify it's back to original
cat main.c
# Output: #include <stdio.h>

# 12. View the commit log
bvcs log
# Output:
# commit 0001
# Date:    2026-06-26 10:00:00
# Message: Initial commit
#
```

---

## Constraints

- Uses **only** standard POSIX/GNU utilities available on a typical Linux system (`bash`, `find`, `diff`, `grep`, `wc`, `date`, `mkdir`, `cp`, `tac`, `sort`, etc.)
- **Does not** invoke `git` or any other external VCS tool anywhere in the script
- Implemented as a **single file** (`2205119.sh`) for simplicity and portability
- All output must match the specification exactly for automated grading

---

## Author

- **Student ID:** 2205119
- **Course:** Bash Scripting (Offline 1)
- **Assignment:** BVCS — A Bash Version Control System
- **Deadline:** 10 July 2026

---

## License

This project is an academic assignment. Use it for educational and reference purposes.
