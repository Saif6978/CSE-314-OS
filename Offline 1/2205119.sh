#!/usr/bin/bash
REPO=".bvcs" 
OBJECTS="$REPO/objects"
STAGING="$REPO/staging"
LOG="$REPO/log"
HEAD="$REPO/HEAD"

usage(){
    echo "BVCS - A simple Bash Version Control System"
    echo ""
    echo "Usage:"
    echo "  bvcs init                    Initialize a new repository"
    echo "  bvcs add <file>...           Stage one or more files"
    echo "  bvcs status                  Show staged/modified/untracked files"
    echo "  bvcs commit -m \"message\"     Commit staged files"
    echo "  bvcs log                     Show commit history"
    echo "  bvcs diff [file]             Show differences against HEAD"
    echo "  bvcs restore <file>          Restore a file from HEAD"
    echo "  bvcs help                    Show this help message"

}

check_repo(){
    if [[ ! -d $REPO ]]; then #-d checks if .bvcs exists returns 0 or 1 
        echo "Error: Not a BVCS repository. Run 'init' first." >&2
        exit 1
    fi
}

contains_item(){
    it="$1"
    shift
    for element in "$@"; do
        if [[ "$element" == "$it" ]]; then
            return 0
        fi
    done
    return 1
}

init_repo(){
    if [[ -d "$REPO" ]]; then
        echo "Error: BVCS repository already exists." >&2
        exit 1
    fi

    mkdir -p "$OBJECTS"
    touch "$STAGING"
    touch "$LOG"
    touch "$HEAD"

    echo "Initialized empty BVCS repository."
}

add_files(){
    if [[ "$#" -eq 0 ]]; then #
        echo "Error: No files specified." >&2
        exit 1
    fi

    for file in "$@"; do
        if [[ ! -f "$file" ]]; then
            echo "Error: '$file' not found." >&2
            continue
        fi

        already_staged="no"
        while IFS= read -r staged_line; do
            if [[ "$staged_line" = "$file" ]]; then
                already_staged="yes"
            fi
        done < "$STAGING"

        if [[ "$already_staged" = "yes" ]]; then
            echo "Already staged: $file"
            continue
        fi
        
        echo "$file" >> "$STAGING"
        echo "Staged: $file"
    done
}

do_commit(){
    message=""

    if [[ "$1" = "-m" ]]; then
    message="$2"
    fi

    if [[ -z "$message" ]]; then
        echo "Error: Commit message required. Use -m \"message\"." >&2
        exit 1
    fi

    if [[ ! -s "$STAGING" ]]; then
        echo "Error: Nothing to commit."
        exit 1
    fi

    prev_count=$(wc -l < "$LOG")
    next_num=$((prev_count + 1))
    new_id=$(printf "%04d" "$next_num");

    new_dir="$OBJECTS/$new_id/files"
    mkdir -p "$new_dir"

    head_id=""

    if [[ -s "$HEAD" ]]; then
        head_id=$(cat "$HEAD")
    fi

    if [[ -n "$head_id" ]]; then
        prev_dir="$OBJECTS/$head_id/files"
        cp -r "$prev_dir/." "$new_dir/"
    fi

    file_count=0
    while IFS= read -r staged_file; do
        if [[ -n "$staged_file" ]]; then
            dest="$new_dir/$staged_file"
            dest_parent=$(dirname "$dest")
            mkdir -p "$dest_parent"
            cp "$staged_file" "$dest"
            file_count=$((file_count + 1))
        fi
    done < "$STAGING"

    echo "$message" > "$OBJECTS/$new_id/message"
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "$timestamp" > "$OBJECTS/$new_id/timestamp"

    echo "$new_id|$timestamp|$message" >> "$LOG"
    echo "$new_id" > "$HEAD"
    > "$STAGING"

    echo "[$new_id] $message"
    echo "$file_count file(s) committed."

}

show_status(){
    staged_files=()
    if [[ -s "$STAGING" ]]; then
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                staged_files+=("$line")
            fi
        done < "$STAGING"
    fi

    head_id=""
    if [[ -s "$HEAD" ]]; then
        head_id=$(cat "$HEAD")
    fi

    head_files=()
    modified_files=()
    if [[ -n "$head_id" ]]; then
        head_dir="$OBJECTS/$head_id/files"
        find "$head_dir" -type f > /tmp/bvcs_head_files.$$
        while IFS= read -r fullpath; do
            relpath="${fullpath#$head_dir/}"
            head_files+=("$relpath")
            if contains_item "$relpath" "${staged_files[@]}"; then
                continue
            fi
            if [[ -f "$relpath" ]]; then
                if ! diff -q "$fullpath" "$relpath" > /dev/null 2>&1; then
                    modified_files+=("$relpath")
                fi
            fi
        done < /tmp/bvcs_head_files.$$
        rm -f /tmp/bvcs_head_files.$$
    fi

    sorted_modified=()
    if [[ "${#modified_files[@]}" -gt 0 ]]; then
        printf '%s\n' "${modified_files[@]}" > /tmp/bvcs_modified.$$
        sort /tmp/bvcs_modified.$$ -o /tmp/bvcs_modified.$$
        while IFS= read -r line; do
            sorted_modified+=("$line")
        done < /tmp/bvcs_modified.$$
        rm -f /tmp/bvcs_modified.$$
    fi

    untracked_files=()
    find . -type f ! -path "./$REPO/*" > /tmp/bvcs_all_files.$$
    while IFS= read -r fullpath; do
        relpath="${fullpath#./}"
        if contains_item "$relpath" "${staged_files[@]}"; then
            continue
        fi
        if contains_item "$relpath" "${head_files[@]}"; then
            continue
        fi
        untracked_files+=("$relpath")
    done </tmp/bvcs_all_files.$$
    rm -f /tmp/bvcs_all_files.$$

    sorted_untracked=()
    if [[ "${#untracked_files[@]}" -gt 0 ]]; then
        printf '%s\n' "${untracked_files[@]}" > /tmp/bvcs_untracked.$$
        sort /tmp/bvcs_untracked.$$ -o /tmp/bvcs_untracked.$$
        while IFS= read -r line; do
            sorted_untracked+=("$line")
        done < /tmp/bvcs_untracked.$$
        rm -f /tmp/bvcs_untracked.$$
    fi

    printed_something="no"
    if [[ "${#staged_files[@]}" -gt 0 ]]; then
        printed_something="yes"
        echo "Staged for commit:"
        for f in "${staged_files[@]}"; do
            echo "$f"
        done
        echo ""
    fi
    if [[ "${#sorted_modified[@]}" -gt 0 ]]; then
        printed_something="yes"
        echo "Modified (not staged):"
        for f in "${sorted_modified[@]}"; do
            echo "$f"
        done
        echo ""
    fi
    if [[ "${#sorted_untracked[@]}" -gt 0 ]]; then
        printed_something="yes"
        echo "Untracked files:"
        for f in "${sorted_untracked[@]}"; do
            echo "$f"
        done
        echo ""
    fi
    if [[ "$printed_something" = "no" ]]; then
        echo "Nothing to commit, working tree clean."
    fi


}

show_log(){
    if [[ ! -s "$LOG" ]]; then
        echo "No commits yet."
        return
    fi

    tac "$LOG" > /tmp/bvcs_log_reversed.$$

    while IFS='|' read -r id ts msg; do
        echo "commit $id"
        echo "Date: $ts"
        echo "Message: $msg"
        echo ""
    done < /tmp/bvcs_log_reversed.$$

    rm -f /tmp/bvcs_log_reversed.$$

}

diff_one_file(){
    file="$1"
    snapshot="$2"
    if diff -q "$snapshot" "$file" > /dev/null 2>&1; then
        echo "$file: no changes."
    else 
        diff -u --label "$snapshot" --label "$file" "$snapshot" "$file"
    fi
}

show_diff(){
    if [[ ! -s "$HEAD" ]]; then
        echo "Error: No commits yet." >&2
        exit 1
    fi
    head_id=$(cat "$HEAD")
    head_dir="$OBJECTS/$head_id/files"
    if [[ -n "$1" ]]; then
        file="$1"
        snapshot="$head_dir/$file"
        if [[ ! -f "$snapshot" ]]; then
            echo "Error: '$file' is not tracked." >&2
            exit 1
        fi
        diff_one_file "$file" "$snapshot"
    else
        find "$head_dir" -type f > /tmp/bvcs_difflist.$$
        sort /tmp/bvcs_difflist.$$ -o /tmp/bvcs_difflist.$$
        while IFS= read -r fullpath; do
            relpath="${fullpath#$head_dir/}"
            diff_one_file "$relpath" "$fullpath"
        done < /tmp/bvcs_difflist.$$
        rm -f /tmp/bvcs_difflist.$$
    fi
}

restore_file(){
    if [[ -z "$1" ]]; then
        echo "Error: No file specified." >&2
        exit 1
    fi

    if [[ ! -s "$HEAD" ]]; then
        echo "Error: No commits yet." >&2
        exit 1
    fi
    file="$1"
    head_id=$(cat "$HEAD")
    snapshot="$OBJECTS/$head_id/files/$file"
    if [[ ! -f "$snapshot" ]]; then
        echo "Error: '$file' not found in commit $head_id." >&2
        exit 1
    fi
    printf "Restore '%s' from commit %s? [y/N]: " "$file" "$head_id"
    read -r answer
    if [[ "$answer" = "y" || "$answer" = "Y" ]]; then
        dest_parent=$(dirname "$file")
        mkdir -p "$dest_parent"
        cp "$snapshot" "$file"
        echo "Restored: $file"
    else
        echo "Aborted."
        exit 0
    fi
}
subcommand="$1"
if [[ "$#" -gt 0 ]]; then
    shift
fi
case "$subcommand" in
    init)
        init_repo
        ;;
    status)
        check_repo
        show_status
        ;;
    help|"")
        usage
        ;;
    add)
        check_repo
        add_files "$@"
        ;;
    commit)
        check_repo
        do_commit "$@"
        ;;
    log)
        check_repo
        show_log
        ;;
    diff)
        check_repo
        show_diff "$@"
        ;;
    restore)
        check_repo
        restore_file "$@"
        ;;
    *)
        echo "Error: Unknown subcommand '$subcommand'." >&2
        exit 1
        ;;

esac