#!/bin/bash -e

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
