#!/usr/bin/env bash
##
## Copyright (c) dushin.net
## All rights reserved.
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##

THIS_DIR="$(cd $(dirname $0) && pwd)"
ROOT_DIR="$(cd "${THIS_DIR}/../../.." && pwd)"

python "${THIS_DIR}/mkimage.py" \
    --root_dir "${ROOT_DIR}" \
    --config "${ROOT_DIR}/src/platforms/esp32/mkimage.json" \
    --out "${ROOT_DIR}/src/platforms/esp32/build/atomvm-$(git rev-parse --short HEAD).img" \
    "$@"
