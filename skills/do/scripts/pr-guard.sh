#!/usr/bin/env bash
# pr-guard.sh: reads each fixer branch of a pr round against the tree's HEAD and names every CI
# workflow, secret or migration file the branch changes, so the round stops before it pushes one.
#
#   pr-guard.sh <tree> <k>=<branch> [<k>=<branch>...]
#
# <tree> is a git work tree whose HEAD is the base, <k> the check's number, <branch> the fixer's
# branch. The paths examined are the diff of HEAD against the branch tip, over all its commits.
# Matching is case-sensitive on repo-relative paths and errs toward a stop. Writes nothing and
# moves no ref.
#
# Prints, per <k> in argument order, one or more of:
#   clean <k>                                     the branch changes no protected path
#   touches <k> <workflow|secret|migration> <path>  one per protected path, path last
#   failed <k>: <reason>                          the branch cannot be read
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

pr_guard() {
  local tree k branch pair rc=0 usage="usage: pr-guard.sh <tree> <k>=<branch> [<k>=<branch>...]"
  [ "$#" -ge 2 ] || {
    echo "$usage" >&2
    return 2
  }
  tree="$1"
  shift
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

  local path class hit
  for pair in "$@"; do
    k="${pair%%=*}"
    branch="${pair#*=}"
    if ! git -C "$tree" rev-parse --verify --quiet "$branch^{commit}" >/dev/null 2>&1; then
      echo "failed $k: cannot read branch $branch"
      rc=1
      continue
    fi
    hit=0
    while IFS= read -r -d '' path; do
      class="$(path_class "$path")"
      [ -n "$class" ] || continue
      echo "touches $k $class $path"
      hit=1
    done < <(git -C "$tree" diff --name-only --no-renames -z HEAD "$branch" --)
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
