#!/bin/bash
##===----------------------------------------------------------------------===##
##
## This source file is part of the Swift OpenTelemetry open source project
##
## Copyright (c) 2020 Moritz Lang and the Swift OpenTelemetry project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
##
## SPDX-License-Identifier: Apache-2.0
##
##===----------------------------------------------------------------------===##

##===----------------------------------------------------------------------===##
##
## This source file is part of the SwiftNIO open source project
##
## Copyright (c) 2017-2019 Apple Inc. and the SwiftNIO project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See CONTRIBUTORS.txt for the list of SwiftNIO project authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===----------------------------------------------------------------------===##

set -u

printf "=> Checking format\n"
FIRST_OUT="$(git status --porcelain)"
# swiftformat does not scale so we loop ourselves
shopt -u dotglob
find . -type d \( -name .build \) -prune -false -o -name "*.swift" | while IFS= read -r d; do
  printf "   * checking $d... "
  out=$(mint run swiftformat $d 2>&1)
  SECOND_OUT="$(git status --porcelain)"
  if [[ "$out" == *"error"*] && ["$out" != "*No eligible files" ]]; then
    printf "\033[0;31merror!\033[0m\n"
    echo $out
    exit 1
  fi
  if [[ "$FIRST_OUT" != "$SECOND_OUT" ]]; then
    printf "\033[0;31mformatting issues!\033[0m\n"
    git --no-pager diff
    exit 1
  fi
  printf "\033[0;32mokay.\033[0m\n"
done
