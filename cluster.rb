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


data = pixels.map { |p| [p.red, p.green, p.blue] }


kmeans = (5..5).reduce(nil) do |best, k|
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
  color = Color::RGB.from_fraction(centroid[0] / 255.0, centroid[1] / 255.0, centroid[2] / 255.0)

 puts color.hex 

  plot.add(:particles, x, y, z)
    .color("##{color.hex}")
end

plot.export_html('plot.html')
