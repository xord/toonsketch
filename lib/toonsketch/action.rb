using RubySketch


class Action

  def do()
    raise NotImplementedError
  end

  def undo()
    raise NotImplementedError
  end

end# Action


class DrawAction < Action

  def initialize(layer)
    super()
    @layer = layer
    backupLayerImage
  end

  def undo()
    @layer.clear
    @layer.beginDraw { _1.image @backupImage, 0, 0 } if @backupImage
  end

  def backupLayerImage()
    @backupImage = @layer.image(create: false)&.then do |img|
      createGraphics(img.width, img.height).tap do |g|
        g.beginDraw { g.image img, 0, 0 }
      end
    end
  end

end# DrawAction


class Brush < DrawAction

  def initialize(layer, size, color)
    super layer
    @size, @color = size, color
    @points       = []
  end

  def do()
    @points.each do |points|
      case points.size
      when 2 then _drawPoint *points
      when 4 then _drawLine *points
      end
    end
  end

  def brushStarted(x, y)
    _drawPoint x, y
    @points << [x, y]
    @prevPoint = [x, y]
  end

  def brushEnded(x, y)
    @prevPoint = nil
  end

  def brushMoved(x, y)
    return unless @prevPoint
    _drawLine *@prevPoint, x, y
    @points << [*@prevPoint, x, y]
    @prevPoint = [x, y]
  end

  private

  def _drawPoint(x, y)
    @layer.beginDraw do |g|
      g.noFill
      g.strokeWeight @size
      g.stroke *@color
      g.point x, y
    end
  end

  def _drawLine(x1, y1, x2, y2)
    @layer.beginDraw do |g|
      g.noFill
      g.strokeWeight @size
      g.stroke *@color
      g.line x1, y1, x2, y2
    end
  end

end# Brush
