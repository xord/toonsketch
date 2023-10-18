using RubySketch

class Button < Sprite

  def initialize(w: 100, h: 44, label: nil, rgb: [200] * 3, &block)
    super 0, 0, w, h

    @label, @rgb, @select = label, rgb, false

    pressing     = false
    includeMouse = ->x, y { (0...self.w).include?(x) && (0..self.h).include?(y) }

    self.draw do
      round, offset = 12, 8
      ww, hh        = self.w, self.h - offset
      yy            = pressing ? 6 : 0

      if @rgb
        fill *@rgb.map { _1 - 20 }
        rect 0, offset, ww, hh, round

        fill *@rgb
        rect 0, yy, ww, hh, round
      end

      if select
        strokeWeight 3
        stroke *(@rgb == [255, 255, 255] ? [0, 0, 0] : [255, 255, 255])
        noFill
        rect 0, yy, ww, hh, round
      end

      if label
        textAlign CENTER, CENTER
        fill 0
        text @label, 0, yy, ww, hh
      end
    end

    self.mousePressed do
      pressing = true
    end

    self.mouseReleased do
      block.call self if block && includeMouse[self.mouseX, self.mouseY]
      pressing = false
    end

    self.mouseDragged do
      pressing = includeMouse[self.mouseX, self.mouseY]
    end
  end

  attr_accessor :label, :rgb, :select

end # Button
