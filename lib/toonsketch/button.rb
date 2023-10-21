using RubySketch

class Button < Sprite

  def initialize(w: 100, h: 44, label: nil, rgb: [200] * 3, &block)
    super 0, 0, w, h

    @label, @rgb, @block = label, rgb, block
    @selected, @pressing = false, false

    draw          { onDraw }
    mousePressed  { onMousePressed }
    mouseReleased { onMouseReleased }
    mouseDragged  { onMouseDragged }
  end

  attr_accessor :label, :rgb

  def selected?() = @selected

  def select(selected = true)
    @selected = selected
  end

  private

  def onDraw()
    round, offset = 12, 8
    w, h, y       = self.w, self.h - offset, @pressing ? 6 : 0

    if @rgb
      fill *@rgb.map { _1 - 20 }
      rect 0, offset, w, h, round

      fill *@rgb
      rect 0, y, w, h, round
    end

    if @selected
      strokeWeight 3
      stroke *(@rgb == [255, 255, 255] ? [0, 0, 0] : [255, 255, 255])
      noFill
      rect 0, y, w, h, round
    end

    if @label
      textAlign CENTER, CENTER
      fill 0
      text @label, 0, y, w, h
    end
  end

  def onMousePressed()
    @pressing = true
  end

  def onMouseReleased()
    @block.call self if @block && isMouseInside?
    @pressing = false
  end

  def onMouseDragged()
    @pressing = isMouseInside?
  end

  def isMouseInside?() =
    (0...w).include?(mouseX) && (0..h).include?(mouseY)

end # Button
