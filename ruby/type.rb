#
require 'ft2'

def bmp(filename, buf, pitch)
  open(filename,"w") do |file|
    height = buf.size / pitch #b.rows
    rows = buf.unpack("a#{pitch}"*height)
    extbytes = pitch%4 == 0 ? 0 : 4-pitch%4
    extrows = rows.map{|r|r+(["\xff"*extbytes].pack('a*'))}
    width = (pitch + extbytes)*8
    extbuf = extrows.reverse.join
    #extrows.each{|x|p [x.unpack('B*')]}

    file.write ['BM',extbuf.size+40+14+8,0,40+14+8].pack('Z2V3')
    file.write [40,width,height,1,1,0,extbuf.size,0,0,2,2,"ffffff0000000000"].pack('V3v2V6H*')
    file.write extbuf
  end
end

#fontfile = '/usr/share/fonts/truetype/motoya-l-cedar/MTLc3m.ttf'
fontfile = '../fonts/NotoSansJP-Thin.otf'
#fontfile = '../fonts/NotoSansJP-Black.otf'
#fontfile = '../fonts/NotoSansJP-Regular.otf'

face=FT2::Face.new fontfile

size = ARGV[0]
size ||= 6
str = ARGV[1]
str ||= 'kami'

face.set_pixel_sizes(0,size.to_i)

str.each_char do |c|
  code = c.encode('utf-16be').unpack('n*').first

  index = face.char_index(code)
  face.load_glyph(index, FT2::Load::DEFAULT)
  face.glyph.render(FT2::RenderMode::MONO)
  b = face.glyph.bitmap
  m = face.glyph.metrics

  p [c, [b.width, b.rows, b.pitch, b.buffer.size],
     [m.ha, m.va, m.w, m.h, m.hbx, m.vby, -m.vbx, m.hby].map{|x|x/64}]
  rows = b.buffer.unpack("a#{b.pitch}"*b.rows)
  wline = ["\0"*b.pitch]
  # add white lines above of glyph
  wlines = m.vby/64
  rows.unshift(wline*wlines) if wlines > 0
  # add white lines below the glyph
  wlines = (m.va-m.vby)/64-b.rows
  rows.push(wline*wlines) if wlines > 0
  rows.flatten!
  buf = rows.join
  pitch = b.pitch

  #=begin
  # add white padding left of the glyph
  lbytes = m.hbx/64/8
  wpad = ["\0"*lbytes].pack('a*')
  rows = rows.map{|r|wpad+r}

  # add white padding right of the glyph
  wpixels = m.ha/64
  wpixels = 16 if wpixels < 16
  pitch = wpixels/8 + ((wpixels%8 == 0) ? 0 : 1)
  p [wpixels, pitch, b.pitch, lbytes]
  wpad = "\0"*(pitch-b.pitch-lbytes)
  rows = rows.map{|r|r+wpad}

  # shift right
  shift = m.hbx/64%8
  mask = (1<<shift)-1
  carry = 0
  buf = rows.join.bytes.map{|b|cc=b&mask;x=b>>shift|carry<<(8-shift);carry=cc;x}.pack('C*')
  #=end

  rows.each{|x|p x.unpack('B*')}
  bmp(c+".bmp", buf, pitch)
end
