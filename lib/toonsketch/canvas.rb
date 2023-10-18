using RubySketch

class Canvas < Sprite

  CHECKER = createShader nil, <<~END
    varying vec4 vertPosition;
    void main() {
      float x = mod(vertPosition.x, 32.) / 16. - 1.;
      float y = mod(vertPosition.y, 32.) / 16. - 1.;
      float c = x * y >= 0. ? 0.8 : 0.7;
      gl_FragColor = vec4(c, c, c, 1.);
    }
  END

  def initialize(width, height, zoom: 1)
    super 0, 0, width, height

    @width, @height, @zoom = width, height, zoom

    clear
    self.brushSize  = 1
    self.brushColor = [0, 0, 0]

    self.draw do
      push do
        shader CHECKER
        rect 0, 0, self.w, self.h
      end

      scale @zoom, @zoom
      drawImage self.image, 0, 0, @width, @height
      tint 255, 10
      self.image(offset: -1)&.tap { drawImage _1, 0, 0, @width, @height }
      self.image(offset: +1)&.tap { drawImage _1, 0, 0, @width, @height }
    end

    self.mousePressed  { brushStarted self.mouseX / @zoom, self.mouseY / @zoom }
    self.mouseReleased { brushEnded   self.mouseX / @zoom, self.mouseY / @zoom }
    self.mouseDragged  { brushMoved   self.mouseX / @zoom, self.mouseY / @zoom }
  end

  attr_accessor :brushSize, :brushColor

  attr_reader :zoom, :frame, :playing, :brushSize, :brushColor

  alias playing? playing

  def image(offset: 0)
    frame = @frame + offset
    return nil if frame < 0
    @images.insert frame, createFrameImage(@width, @height) if offset == 0 && @images[frame] == nil
    @images[frame]
  end

  def size()
    @images.size
  end

  def clear()
    stop
    @images, @frame = [], 0
  end

  def play()
    return if playing?
    setInterval 0.2, id: :play do
      @frame += 1
      @frame = 0 if @frame >= size
    end
    @playing = true
  end

  def stop()
    clearInterval :play
    @playing = false
  end

  def nextFrame(append: true)
    @frame += 1 if append || @frame + 1 < @images.size
  end

  def prevFrame()
    @frame -= 1
    @frame = 0 if @frame < 0
  end

  def drawPoint(x, y)
    image.beginDraw do |g|
      g.noFill
      g.strokeWeight @brushSize
      g.stroke *@brushColor
      g.point x, y
    end
  end

  def drawLine(x1, y1, x2, y2)
    image.beginDraw do |g|
      g.noFill
      g.strokeWeight @brushSize
      g.stroke *@brushColor
      g.line x1, y1, x2, y2
    end
  end

  def brushStarted(x, y)
    drawPoint x, y
    @prevPoint = [x, y]
  end

  def brushEnded(x, y)
    @prevPoint = nil
  end

  def brushMoved(x, y)
    return unless @prevPoint
    drawLine *@prevPoint, x, y
    @prevPoint = [x, y]
  end

  def save(dir)
    dir = File.expand_path dir

    Dir.glob("#{dir}/image_*.png").each do |path|
      File.delete path
    end

    FileUtils.mkdir_p dir
    @images.each.with_index do |img, i|
      img.save "#{dir}/image_#{i}.png"
    end
  end

  def load(dir)
    dir = File.expand_path dir

    images = Dir.glob("#{dir}/image_*.png")
      .sort { _1[/(\d+)\.png$/, 1].to_i <=> _2[/(\d+)\.png$/, 1].to_i }
      .map { loadFrameImage _1 }
    raise "Invalid images" if images.any? { _1.width != @width || _1.height != @height }

    clear
    @images = images
  end

  private

  def createFrameImage(w, h)
    createGraphics(w, h).tap do |g|
      g.beginDraw do
        g.background 255
      end
    end
  end

  def loadFrameImage(path)
    img = loadImage path
    createFrameImage(img.width, img.height).tap do |g|
      g.beginDraw do
        g.image img, 0, 0
      end
    end
  end

end # Canvas
