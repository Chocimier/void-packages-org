#!/bin/sh
#
# changed_templates.sh

tip="$(git rev-list -1 --parents HEAD)"
origin_HEAD="$(git rev-list -1 --parents origin/HEAD)"
case "$tip" in
	# This is a merge commit, pick last parent
	*" "*" "*) tip="${tip##* }" ;;
	# This is a non-merge commit, pick itself
	*)         tip="${tip%% *}" ;;
esac

base="$(git merge-base origin/HEAD "$tip")"

echo origin/HEAD=$origin_HEAD base=$base tip=$tip HEAD=$(git rev-parse HEAD) FETCH_HEAD=$(git rev-parse FETCH_HEAD)
git branch -av
[ $(git rev-list --count "$tip" "^$base") -lt 200 ] || {
	echo "::error title=Branch out of date::Your branch is too out of date. Please rebase on upstream and force-push."
	exit 1
}

echo "$base $tip" >/tmp/revisions

/bin/echo -e '\x1b[32mChanged packages:\x1b[0m'
git diff-tree -r --no-renames --name-only --diff-filter=AM \
	"$base" "$tip" \
	-- 'srcpkgs/*/template' |
	cut -d/ -f 2 |
	tee /tmp/templates |
	sed "s/^/  /" >&2
