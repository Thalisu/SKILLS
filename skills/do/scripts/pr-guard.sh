#!/usr/bin/env bash
# pr-guard.sh: reads each fixer branch of a pr round against the commit the checks ran on and names
# every CI workflow, secret or migration file the branch changes, so the round stops before it
# pushes one, and fails a branch whose shape the round's pick would refuse.
#
#   pr-guard.sh <tree> <base> <k>=<branch> [<k>=<branch>...]
#
# <tree> is a git work tree, <base> the commit the run tree was cut at (the verdict's sha=), <k> the
# check's number, <branch> the fixer's branch. The paths examined are the diff of <base> against the
# branch tip, over all its commits. The tree's moving HEAD is never the base: a commit planted in the
# run tree is a part of every branch cut over it, and a diff against that HEAD would not show it.
# Matching is case-sensitive on repo-relative paths and errs toward a stop. Writes nothing and
# moves no ref.
#
# Prints, per <k> in argument order, one or more of:
#   clean <k>                                     the branch changes no protected path
#   touches <k> <workflow|secret|migration> <path>  one per protected path, path last
#   failed <k>: <reason>                          the branch cannot be read, or its shape over the
#                                                 tree's HEAD is one fix-integrate.sh --compose
#                                                 refuses: not one or two commits ahead, a first of
#                                                 two that is no chore(e2e) commit of regular compose
#                                                 files alone, a first commit whose parent is not HEAD
#
# Exit codes: 0 every <k> clean · 1 at least one touches or failed line · 2 usage, nothing on stdout.
set -uo pipefail

# path_class <path>: prints workflow, secret or migration for a protected path, nothing otherwise.
path_class() {
  local p="$1" base seg
  base="${p##*/}"
  case "$p" in
    .github/workflows/* | .github/actions/* | .circleci/* | .buildkite/* | .woodpecker/*)
      echo workflow
      return
      ;;
    .gitlab-ci.yml | azure-pipelines.yml | bitbucket-pipelines.yml | Jenkinsfile | .travis.yml | .woodpecker.yml)
      echo workflow
      return
      ;;
  esac
  case "$base" in
    .env | .env.* | *.pem | *.key | *.p12 | *.pfx | *.jks | *.keystore | id_rsa* | id_ed25519* | secrets.* | .npmrc | .pypirc | credentials*)
      echo secret
      return
      ;;
  esac
  local IFS=/
  # shellcheck disable=SC2086 # split on / on purpose.
  set -- $p
  for seg in "${@:1:$#-1}"; do
    case "$seg" in
      secrets)
        echo secret
        return
        ;;
    esac
  done
  for seg in "${@:1:$#-1}"; do
    case "$seg" in
      migrations | migration | migrate)
        echo migration
        return
        ;;
    esac
  done
  case "$p" in
    alembic/versions/* | db/schema.rb | db/structure.sql)
      echo migration
      return
      ;;
  esac
  case "$base" in
    secrets)
      echo secret
      return
      ;;
  esac
}

# shape_refusal <tree> <branch>: prints why fix-integrate.sh --compose would refuse the branch over
# the tree's HEAD, nothing when it would pick it. That script refuses its whole call over one such
# branch, so the rule is read here first, per check; keep it in step with fix-integrate.sh's.
shape_refusal() {
  local tree="$1" branch="$2" ahead first path
  ahead="$(git -C "$tree" rev-list --count "HEAD..$branch" 2>/dev/null)"
  case "$ahead" in
    1) first="$branch" ;;
    2)
      first="$(git -C "$tree" rev-parse "$branch^")"
      case "$(git -C "$tree" log -1 --format=%s "$first")" in
        "chore(e2e)"*) ;;
        *)
          echo "$branch's first of two commits is not a chore(e2e) commit"
          return
          ;;
      esac
      local meta mode
      while IFS=$'\t' read -r meta path; do
        case "${path##*/}" in
          compose*.yml | compose*.yaml | docker-compose*.yml | docker-compose*.yaml | *.compose.yml | *.compose.yaml) ;;
          *)
            echo "$branch's chore(e2e) commit changes $path, which is not a compose file"
            return
            ;;
        esac
        # A symlink or a submodule named like a compose points anywhere; 000000 is a deleted compose.
        mode="$(cut -d' ' -f2 <<<"$meta")"
        case "$mode" in
          100644 | 100755 | 000000) ;;
          *)
            echo "$branch's chore(e2e) commit makes $path mode $mode, not a regular file"
            return
            ;;
        esac
      done < <(git -C "$tree" diff-tree --no-commit-id --raw --no-renames -r "$first")
      ;;
    *)
      echo "$branch is $ahead commits ahead of the run tree's HEAD, not one or two"
      return
      ;;
  esac
  # HEAD..branch counts one for a branch cut on an earlier HEAD too, once HEAD moved past its cut.
  [ "$(git -C "$tree" rev-parse "$first^" 2>/dev/null)" = "$(git -C "$tree" rev-parse HEAD)" ] ||
    echo "$branch's first commit's parent is not the run tree's HEAD"
}

pr_guard() {
  local tree base k branch pair rc=0 usage="usage: pr-guard.sh <tree> <base> <k>=<branch> [<k>=<branch>...]"
  [ "$#" -ge 3 ] || {
    echo "$usage" >&2
    return 2
  }
  tree="$1"
  base="$2"
  shift 2
  for pair in "$@"; do
    case "$pair" in
      ?*=?*) ;;
      *)
        echo "$usage" >&2
        return 2
        ;;
    esac
  done
  [ "$(git -C "$tree" rev-parse --is-inside-work-tree 2>/dev/null)" = true ] || {
    echo "$usage" >&2
    return 2
  }

  git -C "$tree" rev-parse --verify --quiet "$base^{commit}" >/dev/null 2>&1 || {
    echo "$usage" >&2
    return 2
  }

  local path class hit reason
  for pair in "$@"; do
    k="${pair%%=*}"
    branch="${pair#*=}"
    if ! git -C "$tree" rev-parse --verify --quiet "$branch^{commit}" >/dev/null 2>&1; then
      echo "failed $k: cannot read branch $branch"
      rc=1
      continue
    fi
    reason="$(shape_refusal "$tree" "$branch")"
    if [ -n "$reason" ]; then
      echo "failed $k: $reason"
      rc=1
      continue
    fi
    hit=0
    while IFS= read -r -d '' path; do
      class="$(path_class "$path")"
      [ -n "$class" ] || continue
      echo "touches $k $class $path"
      hit=1
    done < <(git -C "$tree" diff --name-only --no-renames -z "$base" "$branch" --)
    if [ "$hit" = 0 ]; then
      echo "clean $k"
    else
      rc=1
    fi
  done
  return "$rc"
}

pr_guard "$@"
exit $?
