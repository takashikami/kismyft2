#
require 'ft2'

fontfile = '/usr/share/fonts/truetype/motoya-l-cedar/MTLc3m.ttf'
#fontfile = '../fonts/NotoSansJP-Thin.otf'
#fontfile = '../fonts/NotoSansJP-Regular.otf'
face=FT2::Face.new fontfile

size = ARGV[0]
size ||= 32
str = ARGV[1]
str ||= 'かみKAMI'

face.set_pixel_sizes(size.to_i,size.to_i)

str.each_char do |c|
code = c.encode('utf-16be').unpack('n*').first

index = face.char_index(code)
face.load_glyph(index, FT2::Load::DEFAULT)
face.glyph.render(FT2::RenderMode::MONO)
b = face.glyph.bitmap
m = face.glyph.metrics
#b.buffer.unpack("a#{b.pitch}"*b.rows).each{|x|p x.unpack('B*')}
p [c, [m.w, m.h, m.hbx, m.hby, m.ha, m.vbx, m.vby, m.va].map{|x|x/64}]
end
