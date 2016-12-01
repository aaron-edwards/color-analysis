require 'nyaplot'
require 'nyaplot3d'
require 'rmagick'
require 'color'
require 'kmeans-clusterer'

include Magick

raise "1st argument must be a path to an image" if ARGV.count < 1

def rgb_to_xyz(pixel)
  pixel = pixel.map do |v|
    if v > 0.04045
      (((v + 0.055) / 1.055) ** 2.4) * 100
    else
      (v / 12.92) * 100
    end
  end
  r = pixel[0]
  g = pixel[1]
  b = pixel[2]
  [
    r * 0.4124 + g * 0.3576 + b * 0.1805,
    r * 0.2126 + g * 0.7152 + b * 0.0722,
    r * 0.0193 + g * 0.1192 + b * 0.1192,
  ]
end

def xyz_to_rgb(pixel)
  pixel = pixel.map {|p| p.to_f / 100}
  x = pixel[0]
  y = pixel[1]
  z = pixel[2]

  r = x * 3.2406 + y * -1.5372 + z * -0.4986
  g = x * -0.9689 + y * 1.8758 + z * 0.0415
  b = x * 0.0557 + y * -0.2040 + z * 1.0570

  [r,g,b].map do |p|
    if p > 0.0031308
      (1.055 * (p ** (1.to_f / 2.4)) - 0.055)
    else
      12.92 * p
    end
  end

end

img = ImageList.new(ARGV[0])

resized_img = img.resize(100,100)

pixels = resized_img.export_pixels(0, 0, resized_img.columns, resized_img.rows,"ARGB")
  .each_slice(4)
  .to_a
  .reject { |p| p[0] < 65535 * 0.9 }

data = pixels.map {|p| [p[1].to_f / 65535, p[2].to_f / 65535, p[3].to_f / 65535]}
  .map {|p| rgb_to_xyz(p)}

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
    pixel = xyz_to_rgb(pixel)
    x << pixel[0]
    y << pixel[1]
    z << pixel[2]
  end

  centroid = xyz_to_rgb(cluster.centroid.data)
  color = Color::RGB.from_fraction(centroid[0], centroid[1], centroid[2])

  plot.add(:particles, x, y, z)
    .color("##{color.hex}")

  plot.add(:scatter, [centroid[0]], [centroid[1]], [centroid[2]])
    .fill_color("##{color.hex}")
    .shape('circle')
end

plot.export_html('plot-xyz.html')

