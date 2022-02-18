#!/bin/bash

date=$(date --rfc-3339=date)
file="./_posts/$date-$1.md"
touch $file
echo "---" >> $file
echo "layout: post" >> $file
echo "title: " >> $file
echo "date: $date" >> $file
echo "categories: " >> $file
echo "tags: " >> $file
echo "---" >> $file