#! /bin/bash

dir="./source/_posts"
output="_sidebar.md"

true >"$output" # 置空文件
list=$(find "$dir" -name "*.md" | rev | cut -d"/" -f1 | rev|sort)
for l in $list; do
    name="$(basename "$l" ".md")"
    echo "- [$name]($dir/$l)" >>"$output"
done

echo "- [关于](./source/about/index.md)" >>"$output"
