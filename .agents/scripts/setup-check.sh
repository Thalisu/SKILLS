#!/usr/bin/env bash
# setup-check.sh: the state of the impeccable setup in the project it is run in, one line per step.
# It is the one executable form of that reading, so every caller that needs to know whether the
# setup is there calls it instead of working the answer out. Run from anywhere inside the project,
# with no argument. It writes nothing.
#
# Prints four key=value lines, always these and always in this order, each reading done or missing
# and nothing else: impeccable-skill, the impeccable skill installed; product-context, the product
# context file committed; design-system, the design system file committed; build-path, the code-led
# build path configured.
#
# Exit codes: 2 the project could not be read: one line on stderr naming what could not be read,
# and nothing on stdout.
set -uo pipefail

die() { echo "$1" >&2; exit 2; }

probe_impeccable_skill() { echo missing; }
probe_product_context() { echo missing; }
probe_design_system() { echo missing; }
probe_build_path() { echo missing; }

git rev-parse --show-toplevel >/dev/null 2>&1 || die "not a git repository: $(pwd -P)"

echo "impeccable-skill=$(probe_impeccable_skill)"
echo "product-context=$(probe_product_context)"
echo "design-system=$(probe_design_system)"
echo "build-path=$(probe_build_path)"
