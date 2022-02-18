#!/bin/bash

date=$(date --rfc-3339=date)
file="./_posts/$date-$1.md"

cat > $file << EOF
---
layout: post
title: 
date: $date
categories:
tags:
---
EOF