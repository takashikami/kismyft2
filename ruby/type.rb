#
require 'ft2'

#fontfile = '/usr/share/fonts/truetype/motoya-l-cedar/MTLc3m.ttf'
#fontfile = '../fonts/NotoSansJP-Thin.otf'
#fontfile = '../fonts/NotoSansJP-Black.otf'
fontfile = '../fonts/NotoSansJP-Regular.otf'

face=FT2::Face.new fontfile
face.set_pixel_sizes(0,15)

code = 'も'.encode('utf-16be').unpack('n*').first

=begin
face.load_char(code,FT2::Load::RENDER)
b = face.glyph.bitmap
data = b.buffer.unpack("a#{b.width}"*b.rows).map{|x|x.unpack('a1'*b.width).map{|y|y<"\x80"?' ':'*'}}
data.each{|z|puts z.join}
=end

index = face.char_index(code)
face.load_glyph(index, FT2::Load::DEFAULT)
face.glyph.render(FT2::RenderMode::MONO)
b = face.glyph.bitmap
p [b.buffer.size, b.width, b.rows, b.pitch]
data = b.buffer.unpack("a#{b.pitch}"*b.rows)
#data.each{|x|p x.unpack('B*')}

open("aaa.bmp","w") do |file|
  rowbytes = b.pitch
  height = b.rows
  buf = b.buffer

  rows = buf.unpack("a#{rowbytes}"*height)
  extbytes = rowbytes%4 == 0 ? 0 : 4-rowbytes%4
  extrows = rows.map{|r|r+("\0"*extbytes)}
  width = (rowbytes + extbytes)*8
  extbuf = extrows.reverse.join
  extrows.each{|x|p [x.unpack('B*')]}
  p extbytes

  file.write ['BM',extbuf.size+40+14+8,0,40+14+8].pack('Z2V3')
  file.write [40,width,height,1,1,0,extbuf.size,0,0,2,2,"ffffff0000000000"].pack('V3v2V6H*')
  file.write extbuf
end
