_ = require 'lodash'
async = require 'async'
fs = require 'fs'
path = require 'path'
zlib = require 'zlib'
strftime = require 'strftime'
sprintf = require("sprintf-js").sprintf
exec = require('child_process').exec
chalk = require 'chalk'
pack = require './pack/coffee-pack'
loadable = require './pack/loadable'

class Index
  constructor: (@index) ->
    @entries = []
    data = new pack.BufferStack fs.readFileSync @index
    [@header, @version, count] = data.pop '4 char', 'int32', 'int32'
    throw new Error 'version 2 only..' unless @version is 2
    _.times count, =>
      @entries.push entry = new Entry data.pop(_.times(10, -> 'uint32')..., '20 byte', 'uint16', 'string')...
      data.pop "#{8 - s % 8} byte" if (s = data.total - data.length - 12) % 8 isnt 0 # for padding

class Entry
  constructor: (ctime_s, ctime_ns, mtime_s, mtime_ns,
    @dev, @ino, @mode, @uid, @gid, @file_size, @sha1, flags, @name) ->
    [@stage, @name_len, @ctime, @mtime] = [flags << 2 >> 14, flags & 0xFFF,
      strftime('%Y-%m-%d %H:%M:%S', new Date(ctime_s*10**3)) + sprintf('.%09d', ctime_ns),
      strftime('%Y-%m-%d %H:%M:%S', new Date(mtime_s*10**3)) + sprintf('.%09d', mtime_ns)]

class Blob
  @include loadable

class Tree
  @include loadable
  constructor: (@items = []) ->
  parse_body: (callback) ->
    buffer = new pack.BufferStack @body
    while buffer.length > 0
      [mode, name] = buffer.pop('string').split /\s/
      sha1 = buffer.pop '20 byte'
      @items.push mode: mode, name: name, sha1: sha1

    async.map @items, (item, done) =>
      new Builder(item.sha1.toString('hex')).build (err, result) ->
        result[k] = v for k,v of item
        done null, result
    , (err, results) =>
      @items = results
      callback null, this

class Commit
  @include loadable
  parse_body: (callback) ->
    @body = @body.toString().trim()
    callback null, this

class Tag
  @include loadable
  parse_body: (callback) ->
    @body = @body.toString().trim()
    callback null, this

class Branch

class Builder
  @Types = blob: Blob, tree: Tree, tag: Tag, commit: Commit
  constructor: (sha1) ->
    item = Context.instance().find(sha1)
    [@sha1, @file] = [item.sha1, item.file]

  build: (done) ->
    obj = {}
    [obj.file, obj.sha1, obj.stat, obj.dir, obj.name] =
      [@file, new Buffer(@sha1, 'hex'), fs.statSync(@file), @file.split(path.sep)[-2..]...]

    (source = fs.createReadStream(@file)).pipe(zlib.createInflate()).on 'readable', ->
      return if obj.type? # return表示跳过这次readable event，不应该调用done err
      source.unpipe()
      chunk = new pack.BufferStack @read()
      [obj.type, obj.size] = chunk.pop('string').split ' '
      obj.size = parseInt obj.size
      obj.sample = chunk.pop '55 byte' # 55 - 只为一行显示，没有特殊含义

      result = new Builder.Types[obj.type]()
      result[k] = v for k, v of obj
      done null, result

class Context
  _instance = null
  @instance: -> _instance = _instance or new this
  initialize: (root, callback) ->
    @root = root
    @objects = path.join @root, 'objects'
    @index = path.join @root, 'index'

    exec "find #{@objects} -type f", (err, stdout, stderr) =>
      files = stdout.trim().split('\n')
      files = _.filter files, (p) -> path.basename(p).length is 38
      @objects = _.map files, (x) -> file: x, sha1: x.split(path.sep)[-2..].join ''
      callback null, this

  find: (sha1) -> _.find @objects, (p) -> p.sha1.match sha1

exports.Index = Index
exports.Builder = Builder
exports.Context = null
exports.config = (root, callback) ->
  (exports.context = Context.instance()).initialize root, callback
