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

class Slip
  attr_accessor :w,:h,:rows,:pitch,:size,:pen

  def initialize(w, h, base)
    @w = w
    @h = h
    @pitch = w/8 + (w%8 == 0 ? 0 : 1)
    @rows = ["\0"*@pitch]*h
    @size = @pitch * h
    @pen = 0
    @base = base
  end

  def cr(delta)
    @base+=delta
    @pen=0
  end

  def draw(slot)
    x = @pen+slot.bitmap_left
    y = @base-slot.bitmap_top
    y = 0 if y < 0
    p ["x,y =",x,y]
    xa = x/8
    shift = x%8
    b = slot.bitmap
    p ["xa,shift =",xa,shift]

    rows = b.buffer.unpack("a#{b.pitch}"*b.rows)
    rows = rows.map{|r|r+"\0"}

    mask = (1<<shift)-1
    carry = 0
    rows = rows.map do |r|
      r.bytes.map do |b|
        cc=b&mask
        x=b>>shift|carry<<(8-shift)
        carry=cc
        x
      end.pack('C*')
    end

    @rows[y..y+rows.size-1] = @rows[y..y+rows.size-1].zip(rows).map do |r|
      ra = r[0].bytes
      ra[xa..(xa+b.pitch)] = ra[xa..(xa+b.pitch)].zip(r[1].bytes).map{|e|e.inject(&:|)}
      ra.pack('C*')
    end

    p ["advance=",slot.advance.map{|x|x>>6}]
    @pen += slot.advance[0]>>6
  end
end

fontfile = '/usr/share/fonts/truetype/motoya-l-cedar/MTLc3m.ttf'
#fontfile = '/usr/share/fonts/truetype/fonts-japanese-mincho.ttf'
#fontfile = '../fonts/NotoSansJP-Thin.otf'
#fontfile = '../fonts/NotoSansJP-Black.otf'
#fontfile = '../fonts/NotoSansJP-Regular.otf'

face=FT2::Face.new fontfile

size = ARGV[0]
size ||= 32
size = size.to_i
str = ARGV[1]
str ||= 'Takashi KAMI　かみたかし'
#str ||= (' '..'~').to_a.join
slip = Slip.new(1024,768,size)

face.set_pixel_sizes(0,size.to_i)
asc = face.ascender*size/face.units_per_em
des = size - asc
p [face.ascender, face.descender, face.units_per_em, asc, des, size]

str.each_char do |c|
  code = c.encode('utf-16be').unpack('n*').first

  index = face.char_index(code)
  face.load_glyph(index, FT2::Load::DEFAULT)
  face.glyph.render(FT2::RenderMode::MONO)

  slip.draw(face.glyph)
end
bmp("slip.bmp", slip.rows.join, slip.pitch)
