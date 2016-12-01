require 'nyaplot'
require 'nyaplot3d'
require 'rmagick'
require 'color-rgb'
require 'kmeans-clusterer'

include Magick

raise "1st argument must be a path to an image" if ARGV.count < 1

img = ImageList.new(ARGV[0])

resized_img = img.resize(100,100)

pixels = resized_img.export_pixels(0, 0, resized_img.columns, resized_img.rows,"ARGB")
  .each_slice(4)
  .to_a
  .reject { |p| p[0] < 65535 * 0.9 }

data = pixels.map {|p| [p[1].to_f / 65535, p[2].to_f / 65535, p[3].to_f / 65535]}
  .map{ |p| p.map {|v| v * 255} }
  .map { |p| Color::RGB.from_array(p).to_lab.to_a }

kmeans = (5..5).reduce(nil) do |best, k|
  puts "Clustering #{k}"
  n = KMeansClusterer.run k, data
  best.nil? || n.silhouette > best.silhouette ? n : best
end

puts "\nSilhouette score: #{kmeans.silhouette.round(2)}"


plot = Nyaplot::Plot3D.new

clusters = kmeans.clusters

colors = ['#ff0000', '#FFFF00', '#00FF00', '#00FFFF', '#0000FF', '#FF00FF']

clusters.each_with_index do |cluster, index|
  x = []
  y = []
  z = []
  cluster.points.map(&:data).each do |pixel|
    #pixel = xyz_to_rgb(pixel)
    x << pixel[0]
    y << pixel[1]
    z << pixel[2]
  end

  centroid = (cluster.centroid.data)
  puts centroid.inspect
  #color = Color::RGB.from_fraction(centroid[0], centroid[1], centroid[2])

  plot.add(:particles, x, y, z)
    .color("#{colors[index]}")
    #.color("##{color.hex}")

  plot.add(:scatter, [centroid[0]], [centroid[1]], [centroid[2]])
    .fill_color("#{colors[index]}")
    .shape('circle')
    #.fill_color("##{color.hex}")
end

plot.export_html('plot-lab.html')

