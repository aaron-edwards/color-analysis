require 'nyaplot'
require 'nyaplot3d'
require 'rmagick'
require 'color'
require 'kmeans-clusterer'

include Magick

raise "1st argument must be a path to an image" if ARGV.count < 1

img = ImageList.new(ARGV[0])

resized_img = img.resize(100,100)

pixels = resized_img.export_pixels(0, 0, resized_img.columns, resized_img.rows,"ARGB")
  .each_slice(4)
  .to_a
  .reject { |p| p[0] < 65535 * 0.9 }
  .map { |p| Color::RGB.from_fraction(p[1] / 65535.0, p[2] / 65535.0, p[3] / 65535.0) }
  .map { |p| p.to_hsl }

def hsl_to_cart(pixel)
  h = pixel.h
  s = pixel.s
  l = pixel.l
  [
    s * Math.cos(h*2*Math::PI),
    s * Math.sin(h*2*Math::PI),
    l
  ]
end

def cart_to_hsl(pixel)
  x = pixel[0]
  y = pixel[1]

  h = Math::atan(y.to_f / x.to_f)
  s = Math::sqrt(x * x + y * y)


  h = h + Math::PI if x < 0 && y > 0
  h = h + Math::PI if x < 0 && y < 0
  h = h + Math::PI * 2 if x > 0 && y < 0

  h = h / (Math::PI * 2)

  puts "h #{h}"
  puts "p #{pixel.inspect}"

  Color::HSL.from_fraction(h,s,pixel[2])
end


data = pixels.map { |p| hsl_to_cart(p) }



kmeans = (3..8).reduce(nil) do |best, k|
  puts "Clustering #{k}"
  n = KMeansClusterer.run k, data
  best.nil? || n.silhouette > best.silhouette ? n : best
end

puts "\nSilhouette score: #{kmeans.silhouette.round(2)}"


plot = Nyaplot::Plot3D.new

clusters = kmeans.clusters

clusters.each do |cluster|
  x = []
  y = []
  z = []
  cluster.points.map(&:data).each do |pixel|
    x << pixel[0]
    y << pixel[1]
    z << pixel[2]
  end

  centroid = cluster.centroid.data
  color = cart_to_hsl(centroid)

  puts color.to_rgb.hex
  puts color.inspect

  plot.add(:particles, x, y, z)
    .color("##{color.to_rgb.hex}")

  plot.add(:scatter, [centroid[0]], [centroid[1]], [centroid[2]])
    .fill_color("##{color.to_rgb.hex}")
    .shape('circle')
end

plot.export_html('plot.html')

