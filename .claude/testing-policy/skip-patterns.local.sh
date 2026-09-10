# The bash test scripts have no framework skip: the repo's idiom for one is an `echo "skip ..."` line
# (skills/do/tests/context-usage.sh). Fixture corpora under tests/fixture/ are inputs, not tests.
skip_pattern_local() {
  case "$1" in
    */tests/fixture/*) ;;
    */tests/*.sh) SKIP_PAT="echo[[:space:]]+[\"']?skip[[:space:]:]" SKIP_KIND='echo "skip"' ;;
  esac
}
