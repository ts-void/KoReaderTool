#!/bin/sh
printf '\033c\033]0;%s\a' KoReader Tool
base_path="$(dirname "$(realpath "$0")")"
"$base_path/KoReader Tool.x86_64" "$@"
