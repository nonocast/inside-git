_ = require 'lodash'
async = require 'async'
path = require 'path'
fs = require 'fs'
filesize = require 'filesize'
path = require 'path'
chalk = require 'chalk'
program = require 'commander'
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
    Git.config @root, =>
      if program.inspect? then @inspect(program.inspect) else @inspect_all()

  inspect: (sha1) ->
    new Git.Builder(sha1).build (err, result) =>
      result.load (err, result) =>
        @['inspect_'+result.type](result)

  inspect_tree: (result) ->
    p = _.map result.items, (p) -> "#{sprintf '%06s', p.mode} #{sprintf '%4s', p.type} \
      #{chalk.green p.sha1.toShortSha1()} #{p.name}"
    console.log p.join '\n'

  inspect_blob: (result) ->
    console.log if result.body.isText() then result.body.toString().trim() else result.body.toHexString()

  inspect_commit: (result) ->
    console.log result.body

  inspect_all: ->
    async.map Git.context.objects, (each, done) ->
      new Git.Builder(each.sha1).build(done)
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
      @root = path.join @root, '.git/'
    else
      throw new Error 'not found .git/'

  opts: ->
    program.version('0.0.1')
      .option('-p, --inspect <short sha1>', 'inspect object')
      .parse(process.argv)

module.exports = exports = App

new App().run() if require.main is module
