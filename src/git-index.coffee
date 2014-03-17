Git = require './git-core'

class App
  run: ->
    @get_root()
    @parse()

  parse: ->
    index = new Git.Index @root
    console.log entry.toString() for each in index.entries

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
