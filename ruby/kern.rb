#
require 'ft2'

p FT2::version

fontfile = '../fonts/NotoSansJP-Regular.otf'
face=FT2::Face.new fontfile
face.set_pixel_sizes(0,64)
pre = nil

begin
  c = 'W'
  code = c.encode('utf-16be').unpack('n*').first
  index = face.char_index(code)
  kern = 0
  kern = face.kerning(pre,index,FT2::KerningMode::DEFAULT).first if pre
  face.load_glyph(index, FT2::Load::DEFAULT)
  glyph = face.glyph.glyph
  pre = index

  b = glyph.to_bmap(FT2::RenderMode::MONO,[glyph.advance[0],0],0)
end
