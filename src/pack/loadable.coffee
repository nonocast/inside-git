fs = require 'fs'
zlib = require 'zlib'
pack = require './coffee-pack'

exports.load = (callback) ->
    chunks = []
    fs.createReadStream(@file).pipe(zlib.createInflate())
      .on 'data', (chunk) -> chunks.push chunk
      .on 'end', =>
        buffer = Buffer.concat chunks
        buffer = new pack.BufferStack buffer
        header = buffer.pop 'string'
        @body = buffer.buffer

        if typeof @['parse_body'] is 'function'
          @['parse_body'] callback
        else
          callback null, this
