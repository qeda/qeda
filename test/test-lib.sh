#!/bin/bash -e

rm -rf library
git clone https://github.com/qeda/library.git --depth 1

../bin/qeda reset

for d in library/*/ ; do
  for f in $d* ; do
    filename="${f#*/}"
    element="${filename%.*}"
    type="${f##*.}"

    if [ $type == "yaml" ]; then
      ../bin/qeda add $element
    fi
  done
done

../bin/qeda generate test
