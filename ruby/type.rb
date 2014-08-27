#
require 'ft2'

def bmp(filename, buf, pitch)
  open(filename,"w") do |file|
    height = buf.size / pitch #b.rows
    rows = buf.unpack("a#{pitch}"*height)
    extbytes = pitch%4 == 0 ? 0 : 4-pitch%4
    extrows = rows.map{|r|r+("\0"*extbytes)}
    width = (pitch + extbytes)*8
    extbuf = extrows.reverse.join
    #extrows.each{|x|p [x.unpack('B*')]}

    file.write ['BM',extbuf.size+40+14+8,0,40+14+8].pack('Z2V3')
    file.write [40,width,height,1,1,0,extbuf.size,0,0,2,2,"ffffff0000000000"].pack('V3v2V6H*')
    file.write extbuf
  end
end

fontfile = '/usr/share/fonts/truetype/motoya-l-cedar/MTLc3m.ttf'
#fontfile = '../fonts/NotoSansJP-Thin.otf'
#fontfile = '../fonts/NotoSansJP-Black.otf'
#fontfile = '../fonts/NotoSansJP-Regular.otf'

face=FT2::Face.new fontfile

size = ARGV[0]
size ||= 32
str = ARGV[1]
str ||= 'fghj'

face.set_pixel_sizes(0,size.to_i)

str.each_char do |c|
  code = c.encode('utf-16be').unpack('n*').first

  index = face.char_index(code)
  face.load_glyph(index, FT2::Load::DEFAULT)
  face.glyph.render(FT2::RenderMode::MONO)
  b = face.glyph.bitmap
  m = face.glyph.metrics

  p [c, [b.buffer.size, b.width, b.rows, b.pitch],
     [m.ha, m.va, m.w, m.h, m.hbx, m.vby, -m.vbx, m.hby].map{|x|x/64}]
  rows = b.buffer.unpack("a#{b.pitch}"*b.rows)
  wline = ["\0"*b.pitch]
  wlines = m.vby/64
  rows.unshift(wline*wlines) if wlines > 0
  wlines = (m.va-m.vby)/64-b.rows
  rows.push(wline*wlines) if wlines > 0
  rows.flatten
  #buf.each{|x|p x.unpack('B*')}
  bmp(c+".bmp", rows.join, b.pitch)
end
