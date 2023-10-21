using RubySketch

class Canvas < Sprite

  include Enumerable

  def initialize(width, height)
    super 0, 0, width, height

    @anim, @frame, @layer  = Animation.new(width, height), 0, 0
    @scroll, @zoom, @angle = createVector(0, 0), 1, 0

    self.brushSize  = 1
    self.brushColor = [0, 0, 0]

    draw          { _draw }
    mousePressed  { brushStarted *_mousePos }
    mouseReleased { brushEnded   *_mousePos }
    mouseDragged  { brushMoved   *_mousePos }
  end

  attr_accessor :scroll, :angle, :brushSize, :brushColor

  attr_reader :frame, :layer, :zoom

  def size() = @anim.size

  def frame=(frame)
    @frame = frame.clamp(0..)
  end

  def layer=(layer)
    @layer = layer.clamp(0..)
  end

  def zoom=(zoom)
    @zoom = zoom.clamp(1..)
  end

  def insert(offset = 0)
    @anim.insert @frame + offset
  end

  def delete()
    @anim.delete @frame
  end

  def clear(anim = Animation.new(@anim.width, @anim.height))
    @anim, @frame, @layer = anim, 0, 0
  end

  def each(&block)
    @anim.each &block
  end

  def play()
    return if playing?
    setInterval 0.2, id: :play do
      @frame = (@frame + 1) % size
    end
    @playing = true
  end

  def stop()
    clearInterval :play
    @playing = false
  end

  def playing?() = @playing

  def drawPoint(x, y)
    _beginDraw do |g|
      g.noFill
      g.strokeWeight @brushSize
      g.stroke *@brushColor
      g.point x, y
    end
  end

  def drawLine(x1, y1, x2, y2)
    _beginDraw do |g|
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
    @anim.save dir
  end

  def load(dir)
    @anim = Animation.load dir
  end

  private

  CHECKER = createShader nil, <<~END
    varying vec4 vertPosition;
    void main() {
      float x = mod(vertPosition.x, 32.) / 16. - 1.;
      float y = mod(vertPosition.y, 32.) / 16. - 1.;
      float c = x * y >= 0. ? 0.8 : 0.7;
      gl_FragColor = vec4(c, c, c, 1.);
    }
  END

  def _getFrame(offset: 0, create: true)
    frame = @frame + offset
    return nil if frame < 0 || (!create && size <= frame)
    @anim[frame]
  end

  def _beginDraw(&block)
    _getFrame[@layer].beginDraw do |graphics|
      block.call graphics
    end
  end

  def _draw()
    aw, ah = @anim.width, @anim.height

    push do
      shader CHECKER
      rect 0, 0, w, h
    end

    translate w / 2 + @scroll.x, h / 2 + @scroll.y
    rotate radians @angle
    scale @zoom, @zoom
    translate -aw / 2, -ah / 2

    clip x, y, w, h
    _getFrame.tap { drawImage _1.image, 0, 0, aw, ah }

    tint 255, 20
    _getFrame(offset: -1, create: false)&.tap { drawImage _1.image, 0, 0, aw, ah }
    _getFrame(offset: +1, create: false)&.tap { drawImage _1.image, 0, 0, aw, ah }
  end

  def _mousePos()
    Rays::Matrix.new(1)
      .translate(@anim.width / 2, @anim.height / 2)
      .scale(1.0 / @zoom, 1.0 / @zoom)
      .rotate(-@angle)
      .translate(-w / 2 - @scroll.x, -h / 2 - @scroll.y)
      .then {_1 * Rays::Point.new(mouseX, mouseY)}
      .to_a(2)
  end

end # Canvas
