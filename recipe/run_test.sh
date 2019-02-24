#!/bin/sh

set -eu -o pipefail -x

git annex --verbose --debug version
git annex test
