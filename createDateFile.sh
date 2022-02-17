#!/bin/bash

date=$(date --rfc-3339=date)
touch ./_posts/$date-$1.md
