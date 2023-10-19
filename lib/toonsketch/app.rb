using RubySketch

class App

  MARGIN = 8

  SAVE_PATH = 'ToonData'

  def initialize()
    setTitle 'ToonSketch'
    windowResize 800, 600
    noStroke

    @canvas  = Canvas.new(160, 120).tap {_1.zoom = 3}
    @actions = [
      Button.new(label: 'Play', rgb: [240, 180, 180]) { playOrStop _1 },
      Space.new(h: MARGIN * 2),
      Button.new(label: 'Append',          rgb: [180, 240, 180]) { @canvas.nextFrame },
      Button.new(label: 'Next',     h: 66, rgb: [180, 240, 180]) { @canvas.nextFrame append: false },
      Button.new(label: 'Previous', h: 66, rgb: [180, 240, 180]) { @canvas.prevFrame },
      Space.new(h: MARGIN * 2),
      Button.new(label: 'New',  rgb: [240, 240, 180]) { @canvas.clear },
      Button.new(label: 'Load', rgb: [240, 240, 180]) { @canvas.load SAVE_PATH },
      Button.new(label: 'Save', rgb: [240, 240, 180]) { @canvas.save SAVE_PATH },
    ]
    @brushes = [1, 2, 3, 5, 10].map { |n|
      Button.new(label: "#{n}px", w: 44) {
        @canvas.brushSize = n
        updateSelections
      }
    }
    @tools = [
      Button.new(label: 'Move',   w: 66).tap { |sprite|
        sprite.mouseDragged do
          canvas.translation += createVector(_1.mouseX - _1.pmouseX, _1.mouseY - _1.pmouseY)
        end
      },
      Button.new(label: 'Rotate', w: 66).tap { |sprite|
        sprite.mouseDragged do
          canvas.rotation += _1.mouseX - _1.pmouseX
        end
      },
      Button.new(label: 'Zoom',  w: 66).tap { |sprite|
        sprite.mouseDragged do
          @canvas.zoom += (_1.mouseX - _1.pmouseX) / 32.0
        end
      },
    ]
    @colors = [0, 127, 191, 223, 255].map { |n|
      Button.new(w: 44, rgb: [n, n, n]) {
        @canvas.brushColor = [n, n, n]
        updateSelections
      }
    }
    @status  = createStatus
    @sprites = [@canvas, *@actions, *@brushes, *@tools, *@colors, @status]
    @sprites.each { addSprite _1 }

    updateSelections
  end

  attr_reader :canvas

  def playOrStop(button)
    @canvas.playing? ? @canvas.stop : @canvas.play
    button.label = @canvas.playing? ? 'Stop' : 'Play'
  end

  def updateSelections()
    @brushes.each { _1.select = _1.label == "#{@canvas.brushSize}px" }
    @colors.each  { _1.select = _1.rgb   == @canvas.brushColor }
  end

  def draw()
    background 100
    sprite *@sprites
  end

  def resized()
    @actions.first.pos = [MARGIN, MARGIN]
    @actions.each_cons(2) { _2.pos = [MARGIN, _1.bottom + MARGIN] }

    @brushes.first.pos = [@actions.first.right + MARGIN, MARGIN]
    @brushes.each_cons(2) { _2.pos = [_1.right + MARGIN, _1.y] }

    @tools.first.pos = [@brushes.last.right + MARGIN * 2, @brushes.last.top]
    @tools.each_cons(2) { _2.pos = [_1.right + MARGIN, _1.y] }

    @colors.first.pos = [@actions.first.right + MARGIN, @brushes.first.bottom + MARGIN]
    @colors.each_cons(2) { _2.pos = [_1.right + MARGIN, _1.y] }

    @status.pos   = [0, height - @status.h]
    @status.width = width

    @canvas.pos    = [@actions.first.right + MARGIN, @colors.first.bottom + MARGIN]
    @canvas.right  = width - MARGIN
    @canvas.bottom = @status.top - MARGIN
  end

  def keyPressed(key)
    case key
    when :right then @canvas.nextFrame
    when :left  then @canvas.prevFrame
    when :space then @canvas.playing? ? @canvas.stop : @canvas.play
    end
  end

  private

  def createStatus()
    Sprite.new(0, 0, 1, 28).tap do |sp|
      left = -> {
        "[ #{canvas.frame + 1} / #{canvas.size} ]"
      }
      right = -> {
        "( #{(canvas.zoom * 100).to_i}% )"
      }
      sp.draw do
        fill 200
        rect 0, 0, sp.w, sp.y

        fill 0
        textSize 16
        textAlign LEFT, CENTER
        text left.call,  MARGIN * 2, 0, sp.w - MARGIN, sp.h
        textAlign RIGHT, CENTER
        text right.call, MARGIN, 0, sp.w - MARGIN * 2, sp.h
      end
    end
  end

end # App
