require 'nyaplot'
require 'nyaplot3d'
require 'rmagick'
require 'color'

include Magick

raise "1st argument must be a path to an image" if ARGV.count < 1

img = ImageList.new(ARGV[0])

resized_img = img.resize(100,100)

pixels = resized_img.export_pixels(0, 0, resized_img.columns, resized_img.rows,"ARGB")
  .each_slice(4)
  .to_a

pixels = pixels.reject { |p| p[0] < 65535 * 0.75 }
pixels = pixels.map { |p| [p[1], p[2], p[3]] }



pixels = pixels.map { |p| Color::RGB.from_fraction(p[0] / 65535.0, p[1] / 65535.0, p[2] / 65535.0) }

pixels = pixels.map { |p| p.to_hsl }

plot = Nyaplot::Plot3D.new

x = []
y = []
z = []
pixels.each do |pixel|
  x << pixel.hue
  y << pixel.saturation
  z << pixel.lightness
end

puts pixels.inspect

plot.add(:scatter, x, y, z)

plot.export_html('plot.html')




