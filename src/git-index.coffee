path = require 'path'
fs = require 'fs'
chalk = require 'chalk'
Git = require './git-core'
pack = require './coffee-pack'
style = sha1: chalk.green, stage: chalk.red

class App
  run: ->
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
      current = path.resolve current, '..'
      if fs.existsSync path.join current, '.git/index'
        @root = current
        break

    if @root?
      @root = path.join @root, '.git/index'
    else
      throw new Error 'not found .git/index'

module.exports = exports = App

new App().run() if require.main is module
