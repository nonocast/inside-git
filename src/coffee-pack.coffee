_ = require 'lodash'
Function::property = (prop, descriptor) -> Object.defineProperty @::, prop, descriptor
Function::extend = (obj) -> @[k] = v for k,v of obj
Function::include = (obj) -> @::[k] = v for k,v of obj

Buffer.prototype.toHexString = -> '< ' + this.toString('hex').replace(/.{2}/g, (match) -> match + ' ') + '>'
Buffer.prototype.toShortSha1 = -> this.toString('hex')[0...6]

###
http://blog.csdn.net/cherylnatsu/article/details/6412898
int isPlainText2(const char *filename)
{
  FILE *fp = fopen(filename, "rb");
  long white_list_char_count = 0;
  int read_len;
  unsigned char byte;
  while ((read_len = fread(&byte, 1, 1, fp)) > 0)
  {
    if (byte == 9 || byte == 10 || byte == 13 || (byte >= 32 && byte <= 255))
      white_list_char_count++;
    else if ((byte <= 6) || (byte >= 14 && byte <= 31))
      return 0;
  }
  fclose(fp);
  return (white_list_char_count >= 1) ? 1 : 0;
}
###
Buffer.prototype.isText = ->
  white = 0
  whitelist = [9, 10, 13]
  for each in this
    if each in whitelist or (each >= 32 and each <= 255)
      ++white
    else if each <= 6 or (each >= 14 and each <= 31)
      return false
  return white > 0

exports.BufferStack = class BufferStack
  @property 'length', get: -> @buffer.length
  constructor: (@buffer) -> @total = @buffer.length
  toString: -> @buffer

  pop: (args...) ->
    if args.length is 1
      @parse args[0]
    else
      @parse(each) for each in args

  parse: (arg) ->
    return @parse_byte arg.split(/\s/)... if arg.match /^\d+\sbyte$/i
    return @parse_int32() if arg.match /^int32$/i
    return @parse_uint32() if arg.match /^uint32$/i
    return @parse_uint16() if arg.match /^uint16$/i
    return @parse_char arg.split(/\s/)... if arg.match /^\d+\schar$/i
    return @parse_string() if arg.match /^string$/i

  parse_byte: (count) ->
    p = @buffer[0..count-1]
    @buffer = @buffer[count..]
    return p

  parse_char: (count) -> @parse_byte(count).toString()
  parse_string: -> @parse_byte(1+_.findIndex @buffer, (x) -> x is 0x00).toString()
  parse_int32: -> @parse_byte(4).readInt32BE()
  parse_uint32: -> @parse_byte(4).readUInt32BE()
  parse_uint16: -> @parse_byte(2).readUInt16BE()
