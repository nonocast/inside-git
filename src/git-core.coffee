_ = require 'lodash'
fs = require 'fs'
path = require 'path'
zlib = require 'zlib'
strftime = require 'strftime'
sprintf = require("sprintf-js").sprintf
pack = require './pack/coffee-pack'

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

class Tree

class Commit

class Tag

class Branch

class Builder
  @Types = blob: Blob, tree: Tree, tag: Tag, commit: Commit
  constructor: (@file) ->
  build: (done) ->
    obj = {}
    [obj.file, obj.sha1, obj.stat, obj.dir, obj.name] =
      [@file, new Buffer(path.basename(@file), 'hex'), fs.statSync(@file), @file.split(path.sep)[-2..]...]

    (source = fs.createReadStream(@file)).pipe(zlib.createInflate()).on 'readable', ->
      return if obj.type? # return表示跳过这次readable，不应该调用done err
      source.unpipe()
      chunk = new pack.BufferStack @read()
      [obj.type, obj.size] = chunk.pop('string').split ' '
      obj.size = parseInt obj.size
      obj.sample = chunk.pop '55 byte' # 55 - 只为一行显示，没有特殊含义

      result = new Builder.Types[obj.type]()
      result[k] = v for k, v of obj
      done null, result

exports.Index = Index
exports.Builder = Builder
