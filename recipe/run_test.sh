#!/bin/bash

set -e -u -x -o pipefail

git-annex version
git-annex test
