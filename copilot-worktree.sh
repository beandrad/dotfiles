#!/usr/bin/env bash

set -euo pipefail

usage() {
	cat <<'EOF'
Usage: copilot-worktree.sh [options] <branch> [-- <copilot args...>]

Create a git worktree for a branch as a sibling of the repo, run Copilot inside
it, commit any changes, and remove the worktree when finished. Git linkage files
are converted to relative paths so the worktree works inside devcontainers.

Options:
  -b, --base <ref>       Base ref for a new branch (default: current HEAD)
  -m, --message <msg>    Commit message (default: "Apply Copilot changes to <branch>")
  -w, --worktree-dir <path>
                         Use a specific worktree directory instead of the default
                         sibling location (<repo-parent>/<repo>-<branch>)
  -k, --keep-worktree    Keep the worktree after Copilot exits
  -d, --delete <path>    Delete a kept worktree (handles relative git paths)
  -h, --help             Show this help message

Examples:
  copilot-worktree.sh feat/copilot-cleanup
  copilot-worktree.sh -b main -m "Add cleanup helper" feat/cleanup -- --prompt "implement cleanup"
  copilot-worktree.sh -d /path/to/kept/worktree
EOF
}

branch_name=""
base_ref="HEAD"
commit_message=""
worktree_dir=""
keep_worktree=0
delete_dir=""
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
		-d|--delete)
			delete_dir="${2:?missing value for $1}"
			shift 2
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

if [[ -z "${branch_name}" && -z "${delete_dir}" ]]; then
	echo "A branch name is required." >&2
	usage >&2
	exit 1
fi

if [[ -z "${delete_dir}" ]] && ! command -v copilot >/dev/null 2>&1; then
	echo "copilot command not found in PATH." >&2
	exit 1
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
	echo "This script must be run from inside a git repository." >&2
	exit 1
}

repo_name="$(basename "${repo_root}")"
root_env_file="${repo_root}/.env"

# Compute a relative path from $2 to $1 (portable, no GNU coreutils needed)
relpath() {
	python3 -c "import os.path, sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$1" "$2"
}

# Rewrite absolute paths in worktree linkage files to relative paths.
# Makes the worktree portable across different mount points (e.g. devcontainers).
fixup_worktree_paths() {
	local wt_dir="$1"
	local dot_git_file="${wt_dir}/.git"

	local abs_gitdir
	abs_gitdir="$(sed -n 's/^gitdir: //p' "${dot_git_file}")"

	local gitdir_file="${abs_gitdir}/gitdir"

	# Resolve symlinks so relative paths are correct (e.g. /tmp → /private/tmp on macOS)
	local real_wt_dir real_abs_gitdir
	real_wt_dir="$(cd "${wt_dir}" && pwd -P)"
	real_abs_gitdir="$(cd "${abs_gitdir}" && pwd -P)"

	printf 'gitdir: %s\n' "$(relpath "${real_abs_gitdir}" "${real_wt_dir}")" > "${dot_git_file}"
	printf '%s\n' "$(relpath "${real_wt_dir}/.git" "${real_abs_gitdir}")" > "${gitdir_file}"
}

# Restore relative paths back to absolute so git worktree remove can work.
restore_worktree_paths() {
	local wt_dir="$1"
	local dot_git_file="${wt_dir}/.git"

	local rel_gitdir
	rel_gitdir="$(sed -n 's/^gitdir: //p' "${dot_git_file}")"

	# Already absolute — nothing to do
	if [[ "${rel_gitdir}" == /* ]]; then
		return
	fi

	local real_wt_dir abs_gitdir
	real_wt_dir="$(cd "${wt_dir}" && pwd -P)"
	abs_gitdir="$(cd "${real_wt_dir}/${rel_gitdir}" && pwd -P)"

	local gitdir_file="${abs_gitdir}/gitdir"

	printf 'gitdir: %s\n' "${abs_gitdir}" > "${dot_git_file}"
	printf '%s\n' "${real_wt_dir}/.git" > "${gitdir_file}"
}

# Handle --delete mode: restore absolute paths and remove the worktree
if [[ -n "${delete_dir}" ]]; then
	if [[ ! -d "${delete_dir}" ]]; then
		echo "Worktree directory not found: ${delete_dir}" >&2
		exit 1
	fi
	if [[ ! -f "${delete_dir}/.git" ]]; then
		echo "Not a git worktree (no .git file): ${delete_dir}" >&2
		exit 1
	fi
	restore_worktree_paths "${delete_dir}"
	git -C "${repo_root}" worktree remove "${delete_dir}"
	echo "Removed worktree ${delete_dir}"
	exit 0
fi

if [[ -z "${worktree_dir}" ]]; then
	safe_branch_name="${branch_name//\//-}"
	worktree_dir="$(dirname "${repo_root}")/${repo_name}-${safe_branch_name}"
fi

if git -C "${repo_root}" show-ref --verify --quiet "refs/heads/${branch_name}"; then
	git -C "${repo_root}" worktree add "${worktree_dir}" "${branch_name}"
else
	git -C "${repo_root}" worktree add -b "${branch_name}" "${worktree_dir}" "${base_ref}"
fi

# Convert to relative paths immediately so the worktree is usable from
# devcontainers while Copilot is still running interactively.
fixup_worktree_paths "${worktree_dir}"

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

# Restore absolute paths so git operations (status, add, commit, remove) work.
restore_worktree_paths "${worktree_dir}"

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

if ((keep_worktree)); then
	# Re-convert to relative paths for devcontainer portability.
	fixup_worktree_paths "${worktree_dir}"
	echo "Kept worktree at ${worktree_dir} (paths converted to relative)"
else
	git -C "${repo_root}" worktree remove "${worktree_dir}"
	echo "Removed worktree ${worktree_dir}"
fi

exit "${copilot_exit}"
