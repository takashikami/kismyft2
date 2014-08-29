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

fontfile = '/usr/share/fonts/truetype/motoya-l-cedar/MTLc3m.ttf'
#fontfile = '/usr/share/fonts/truetype/fonts-japanese-mincho.ttf'
fontfile = '../fonts/NotoSansJP-Thin.otf'
#fontfile = '../fonts/NotoSansJP-Black.otf'
#fontfile = '../fonts/NotoSansJP-Regular.otf'

face=FT2::Face.new fontfile

size = ARGV[0]
size ||= 32
str = ARGV[1]
str ||= 'kami'
#str ||= ('!'..'~').to_a.join

face.set_pixel_sizes(0,size.to_i)
asc = face.ascender*size/face.units_per_em
des = size - asc
p [face.ascender, face.descender, face.units_per_em, asc, des, size]

str.each_char do |c|
  code = c.encode('utf-16be').unpack('n*').first

  index = face.char_index(code)
  face.load_glyph(index, FT2::Load::DEFAULT)
  face.glyph.render(FT2::RenderMode::MONO)
  slot = face.glyph
  b = face.glyph.bitmap
  m = face.glyph.metrics

  left = slot.bitmap_left
  top = slot.bitmap_top
  p [c, [left, top, slot.advance.map{|x|x>>6}],
     [b.width, b.rows, b.pitch, b.buffer.size],
    ]
  rows = b.buffer.unpack("a#{b.pitch}"*b.rows)
  wline = ["\0"*b.pitch]

  # add white lines above of glyph
  topspace = asc - top
  bottomspace = size - (topspace + b.rows)
  p ["[topspace,bottomspace]=",[topspace,bottomspace]]
  bottomspace=0 if bottomspace<0
  rows.unshift(wline*topspace)
  # add white lines below the glyph
  #p [asc, top, size ,topspace, b.rows]
  #rows.push(wline*bottomspace)
  rows.flatten!

  buf = rows.join
  pitch = b.pitch

=begin
  # add white padding left of the glyph
  lbytes = m.hbx/64/8
  lbytes = -lbytes if lbytes<0
  wpad = ["\0"*lbytes].pack('a*')
  rows = rows.map{|r|wpad+r}

  # add white padding right of the glyph
  wpixels = m.ha/64
  wpixels = b.pitch*8 if wpixels < b.pitch*8
  pitch = wpixels/8 + ((wpixels%8 == 0) ? 0 : 1)
  #p [pitch,b.pitch,lbytes,(pitch-b.pitch-lbytes)]
  wpad = ["\0"*(pitch-b.pitch-lbytes)].pack('a*') if pitch-b.pitch-lbytes > 0
  rows = rows.map{|r|r+wpad}

  # shift right
  shift = m.hbx/64%8
  shift = 8-shift if shift<0
  mask = (1<<shift)-1
  carry = 0
  buf = rows.join.bytes.map{|b|cc=b&mask;x=b>>shift|carry<<(8-shift);carry=cc;x}.pack('C*')
=end

  #rows.each{|x|p x.unpack('B*')}
  bmp("0x"+c.bytes.first.to_s(16)+".bmp", buf, pitch)
end
