Git = require './git-core'
index = new Git.Index '/Users/nonocast/Code/learngit/my-git-tools/.git/index'
for each in index.entries
  console.log each.toString()
