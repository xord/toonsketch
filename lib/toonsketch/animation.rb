using RubySketch


class Animation

  def initialize(width, height)
    @width, @height = width, height
    @frames         = []
  end

  attr_reader :width, :height

  def size() = @frames.size

  def [](index)
    return nil if index < 0
    @frames[index] ||= Frame.new self, width, height
  end

  def []=(index, frame)
    @frames[index] = frame
  end

  def insert(index)
    @frames.insert index, nil
  end

  def delete(index)
    @frames.delete_at index
  end

  def each(&block)
    @frames.each { block.call _1 }
  end

  def save(dir)
    dir = File.expand_path dir

    File.write self.class._metaPath(dir), {
      animation: {width: width, height: height}
    }.to_json

    Dir.glob("#{dir}/image_*.png").each do |path|
      File.delete path
    end

    FileUtils.mkdir_p dir
    @frames.each.with_index do |frame, index|
      frame.save dir, index
    end
  end

  def self.load(dir)
    dir    = File.expand_path dir
    meta   = JSON.parse File.read(_metaPath dir), symbolize_names: true
    width  = meta.dig(:animation, :width)  or raise "missing animation width"
    height = meta.dig(:animation, :height) or raise "missing animation height"

    self.new(width, height).tap do |anim|
      Dir.glob("#{dir}/image_*.png")
        .group_by { |path| path[/_(\d+)_\d+\.png$/, 1]&.to_i }
        .each { |frame, paths| anim[frame] = Frame.load anim, width, height, paths }
    end
  end

  private

  def self._metaPath(dir)
    "#{dir}/toon.json"
  end

end # Animation


class Frame

  def initialize(owner, width, height)
    @owner, @width, @height = owner, width, height
    @layers, @redrawCache   = [], true
  end

  attr_reader :width, :height

  def size() = @layers.size

  def [](index)
    return nil if index < 0
    @layers[index] ||= Layer.new self, width, height
  end

  def []=(index, layer)
    @layers[index] = layer
  end

  def image()
    _drawCache
    _cache
  end

  def invalidateCache()
    @redrawCache = true
  end

  def save(dir, frameIndex)
    @layers.each.with_index do |layer, layerIndex|
      layer&.image(create: false)&.save _imagePath(dir, frameIndex, layerIndex)
    end
  end

  def self.load(owner, width, height, paths)
    self.new(owner, width, height).tap do |frame|
      paths.each do |path|
        index = _layerIndex(path) or next
        frame[index] = Layer.load frame, path
      end
    end
  end

  private

  def _cache()
    @cache ||= createGraphics width, height
  end

  def _drawCache()
    return unless @redrawCache
    _cache.beginDraw do |g|
      g.background 255
      @layers.each do |layer|
        next unless layer && layer.visible?
        g.image layer.image, 0, 0
      end
    end
    @redrawCache = false
  end

  def _imagePath(dir, frame, layer)
    "#{dir}/image_#{frame}_#{layer}.png"
  end

  def self._layerIndex(path)
    path[/image_\d+_(\d+)\.png$/, 1]&.to_i
  end

end# Frame


class Layer

  def initialize(owner, width, height)
    @owner, @width, @height, @visible = owner, width, height, true
  end

  attr_reader :width, :height, :visible

  alias visible? visible

  def visible=(visible)
    return if visible == @visible
    @visible = visible
    invalidateCache
  end

  def image(create: true)
    @image ||= createGraphics @width, @height
  end

  def clear()
    @image = nil
    self
  end

  def beginDraw(&block)
    image.beginDraw do |graphics|
      block.call graphics
    end
    invalidateCache
  end

  def save(path)
    @image.save path if @image
  end

  def self.load(owner, path)
    img = loadImage(path) or return nil
    self.new(owner, img.w, img.h).tap do |layer|
      layer.beginDraw { _1.image img, 0, 0 }
    end
  end

  private

  def invalidateCache()
    @owner&.invalidateCache
  end

end# Layer
