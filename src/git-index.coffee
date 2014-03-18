path = require 'path'
fs = require 'fs'
chalk = require 'chalk'
program = require 'commander'
Git = require './git-core'
pack = require './pack/coffee-pack'
style = sha1: chalk.green, stage: chalk.red

module.exports = exports = \
class GitIndexApp
  run: ->
    @opts()
    @get_root()
    @parse()

  parse: ->
    index = new Git.Index @root
    for each in index.entries
      console.log "#{style.stage each.stage} #{style.sha1 each.sha1.toShortSha1()} #{each.name}"

  get_root: ->
    current = '.'
    while true
      break if current is path.resolve current, '..'
      if fs.existsSync path.join current, '.git/index'
        @root = current
        break

      current = path.resolve current, '..'

    if @root?
      @root = path.join @root, '.git/index'
    else
      throw new Error 'not found .git/index'

  opts: -> program.version('0.0.1').parse(process.argv)


new GitIndexApp().run() if require.main is module
