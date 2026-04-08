#!/usr/bin/env bash

set -euo pipefail

usage() {
	cat <<'EOF'
Usage: copilot-worktree.sh [options] <branch> [-- <copilot args...>]

Create a temporary git worktree for a branch, run Copilot inside it, commit any
changes, and remove the worktree when finished.

Options:
  -b, --base <ref>       Base ref for a new branch (default: current HEAD)
  -m, --message <msg>    Commit message (default: "Apply Copilot changes to <branch>")
  -w, --worktree-dir <path>
                         Use a specific worktree directory instead of a temp dir
  -k, --keep-worktree    Keep the worktree after Copilot exits
  -h, --help             Show this help message

Examples:
  copilot-worktree.sh feat/copilot-cleanup
  copilot-worktree.sh -b main -m "Add cleanup helper" feat/cleanup -- --prompt "implement cleanup"
EOF
}

branch_name=""
base_ref="HEAD"
commit_message=""
worktree_dir=""
keep_worktree=0
copilot_args=()

while (($# > 0)); do
	case "$1" in
		-b|--base)
			base_ref="${2:?missing value for $1}"
			shift 2
			;;
		-m|--message)
			commit_message="${2:?missing value for $1}"
			shift 2
			;;
		-w|--worktree-dir)
			worktree_dir="${2:?missing value for $1}"
			shift 2
			;;
		-k|--keep-worktree)
			keep_worktree=1
			shift
			;;
		-h|--help)
			usage
			exit 0
			;;
		--)
			shift
			copilot_args=("$@")
			break
			;;
		-*)
			echo "Unknown option: $1" >&2
			usage >&2
			exit 1
			;;
		*)
			if [[ -n "${branch_name}" ]]; then
				echo "Only one branch name may be provided." >&2
				usage >&2
				exit 1
			fi
			branch_name="$1"
			shift
			;;
	esac
done

if [[ -z "${branch_name}" ]]; then
	echo "A branch name is required." >&2
	usage >&2
	exit 1
fi

if ! command -v copilot >/dev/null 2>&1; then
	echo "copilot command not found in PATH." >&2
	exit 1
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
	echo "This script must be run from inside a git repository." >&2
	exit 1
}

repo_name="$(basename "${repo_root}")"
root_env_file="${repo_root}/.env"

if [[ -z "${worktree_dir}" ]]; then
	safe_branch_name="${branch_name//\//-}"
	parent_dir="${TMPDIR:-/tmp}/copilot-worktrees"
	mkdir -p "${parent_dir}"
	worktree_dir="$(mktemp -d "${parent_dir}/${repo_name}-${safe_branch_name}-XXXXXX")"
fi

cleanup_worktree() {
	if ((keep_worktree)); then
		echo "Kept worktree at ${worktree_dir}"
		return
	fi

	git -C "${repo_root}" worktree remove "${worktree_dir}"
	echo "Removed worktree ${worktree_dir}"
}

if git -C "${repo_root}" show-ref --verify --quiet "refs/heads/${branch_name}"; then
	git -C "${repo_root}" worktree add "${worktree_dir}" "${branch_name}"
else
	git -C "${repo_root}" worktree add -b "${branch_name}" "${worktree_dir}" "${base_ref}"
fi

if [[ -f "${root_env_file}" && ! -e "${worktree_dir}/.env" ]]; then
	cp -p "${root_env_file}" "${worktree_dir}/.env"
fi

echo "Starting Copilot in ${worktree_dir}"
set +e
(
	cd "${worktree_dir}"
	copilot "${copilot_args[@]}"
)
copilot_exit=$?
set -e

status_output="$(git -C "${worktree_dir}" status --short)"

if [[ -n "${status_output}" ]]; then
	git -C "${worktree_dir}" add -A

	if git -C "${worktree_dir}" diff --cached --quiet; then
		echo "Worktree has changes, but nothing is staged for commit." >&2
	else
		if [[ -z "${commit_message}" ]]; then
			commit_message="Apply Copilot changes to ${branch_name}"
		fi

		git -C "${worktree_dir}" commit -m "${commit_message}"
		echo "Committed changes to ${branch_name}"
	fi
fi

post_commit_status="$(git -C "${worktree_dir}" status --short)"
if [[ -n "${post_commit_status}" && ${keep_worktree} -eq 0 ]]; then
	echo "Worktree still has uncommitted changes; leaving it at ${worktree_dir}" >&2
	exit "${copilot_exit}"
fi

cleanup_worktree
exit "${copilot_exit}"
