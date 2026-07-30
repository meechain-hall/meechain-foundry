#!/bin/bash
set -e
git init
git config user.name "MEECHAIN 1"
git config user.email "pt.tp.00@my.com"
git add .
git commit -m "Initial commit: MeeChain contracts deployed"
chmod +x fix-git-repo.sh
