_ = require 'lodash'
fs = require 'fs'
strftime = require 'strftime'
sprintf = require("sprintf-js").sprintf
pack = require './coffee-pack'

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

exports.Index = Index
