require 'zlib'

class PNG
  def self.chunk(type, data)
    length = [data.size].pack('N')
    body = [type,data].pack('a4a*')
    crc = [Zlib::crc32(body)].pack('N')
    length+body+crc
  end

  def self.write(filename,img,w,h)
    pitch = w/8 + (w%8 == 0 ? 0 : 1)
    data = (["\0"]*h).zip(img.unpack("a#{pitch}"*h)).map(&:join).join

    png = [['89 50 4E 47 0D 0A 1A 0A'.delete(' ')].pack('H*'),
           chunk('IHDR',[w, h, 1, 3, 0 ,0, 0].pack('N2C5')),
           chunk('PLTE', ['ffffff'].pack('H*')),
           chunk('IDAT', Zlib::deflate(data,9)),
           chunk('IEND','')
    ].join

    open(filename, "w") do |f|
      f.write(png)
    end
  end

  def self.read(filename)
    idat = nil
    w,h = 0,0
    open(filename) do |f|
      data = f.read
      a = []
      head, rest = data.unpack('a8a*')
      a << head

      while rest.size > 0
        len, typ, rst = rest.unpack('Na4a*')
        dat, crc, rest = rst.unpack("a#{len}Na*")

        idat=Zlib::inflate dat if typ == 'IDAT'
        w,h = dat.unpack('NN') if typ == 'IHDR'

        a << [len, typ, dat.unpack('H*').first, crc]
      end
      a.each{|aa|p aa}
    end
    p = w/8 + (w%8 == 0 ? 0 : 1)
    idat.unpack("a#{p+1}"*h).map{|a|a.unpack("aa#{p}")}.transpose[1].map{|a|a.each_byte{|aa|printf "%08b",aa};puts}
    idat
  end
end

#PNG.read ARGV[0]