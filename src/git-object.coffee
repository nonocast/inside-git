_ = require 'lodash'
async = require 'async'
path = require 'path'
fs = require 'fs'
filesize = require 'filesize'
path = require 'path'
chalk = require 'chalk'
program = require 'commander'
exec = require('child_process').exec
sprintf = require('sprintf-js').sprintf
Git = require './git-core'
pack = require './pack/coffee-pack'
style = sha1: chalk.green, stage: chalk.red, span: chalk.gray

class App
  run: ->
    @opts()
    @get_root()
    @parse()

  parse: ->
    if program.inspect? then @inspect(program.inspect) else @inspect_all()

  inspect: (sha1) ->

  inspect_all: ->
    exec "find #{@root} -type f", (err, stdout, stderr) =>
      files = stdout.trim().split('\n')
      files = _.filter files, (p) -> path.basename(p).length is 38

      async.map files, (each, done) ->
        new Git.Builder(each).build(done)
      , (err, results) =>
        throw err if err?
        results = _.sortBy results, (x) -> x.stat.ctime
        for each in results
          console.log "#{style.sha1 each.sha1.toShortSha1()} #{sprintf '%-6s', each.type} \
            #{style.span sprintf '%7s', filesize each.size, spacer:''}  #{style.span each.sample.toSampleString()}"

  get_root: ->
    current = '.'
    while true
      break if current is path.resolve current, '..'
      current = path.resolve current, '..'
      if fs.existsSync path.join current, '.git/'
        @root = current
        break

    if @root?
      @root = path.join @root, '.git/objects'
    else
      throw new Error 'not found .git/'

  opts: ->
    program.version('0.0.1')
      .option('-p, --inspect <short sha1>', 'inspect object')
      .parse(process.argv)

module.exports = exports = App

new App().run() if require.main is module
