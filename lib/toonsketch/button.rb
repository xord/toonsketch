using RubySketch

class Button < Sprite

  def initialize(w: 100, h: 44, label: nil, rgb: [200] * 3, &block)
    super 0, 0, w, h

    @label, @rgb, @block = label, rgb, block
    @enabled, @selected, @pressing = true, false, false

    draw          { _draw }
    mousePressed  { _mousePressed }
    mouseReleased { _mouseReleased }
    mouseDragged  { _mouseDragged }
  end

  attr_accessor :label, :rgb

  def enable(enabled = true)
    @enabled = enabled
  end

  def disable()
    enable false
  end

  def enabled?()  =  @enabled

  def disabled?() = !@enabled

  def selected?() = @selected

  def select(selected = true)
    @selected = selected
  end

  private

  def _draw()
    round, offset = 12, 8

    w, h = self.w, self.h - offset
    y    = enabled? && @pressing ? 6 : 0

    if @rgb
      fill *@rgb.map { _1 - 20 }
      rect 0, offset, w, h, round

      fill *@rgb
      rect 0, y, w, h, round
    end

    if selected? && enabled?
      strokeWeight 3
      stroke *(@rgb == [255, 255, 255] ? [0, 0, 0] : [255, 255, 255])
      noFill
      rect 0, y, w, h, round
    end

    if @label
      textAlign CENTER, CENTER
      fill enabled? ? 0 : 127
      text @label, 0, y, w, h
    end
  end

  def _mousePressed()
    return if disabled?
    @pressing = true
  end

  def _mouseReleased()
    @block.call self if @block && enabled? && _isMouseInside?
    @pressing = false
  end

  def _mouseDragged()
    @pressing = _isMouseInside?
  end

  def _isMouseInside?() =
    (0...w).include?(mouseX) && (0..h).include?(mouseY)

end # Button
