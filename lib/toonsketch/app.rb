using RubySketch

class App

  MARGIN = 8

  SAVE_PATH = 'ToonData'

  def initialize()
    setTitle 'ToonSketch'
    windowResize 800, 600
    noStroke

    @canvas  = Canvas.new 160, 120, zoom: 3
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
    @tools = [1, 2, 3, 5, 10].map { |n|
      Button.new(label: "#{n}px", w: 44) {
        @canvas.brushSize = n
        updateSelections
      }
    }
    @colors = [0, 127, 191, 223, 255].map { |n|
      Button.new(w: 44, rgb: [n, n, n]) {
        @canvas.brushColor = [n, n, n]
        updateSelections
      }
    }
    @status  = createStatus
    @sprites = [@canvas, *@actions, *@tools, *@colors, @status]
    @sprites.each { addSprite _1 }

    updateSelections
  end

  attr_reader :canvas

  def playOrStop(button)
    @canvas.playing? ? @canvas.stop : @canvas.play
    button.label = @canvas.playing? ? 'Stop' : 'Play'
  end

  def updateSelections()
    @tools.each  { _1.select = _1.label == "#{@canvas.brushSize}px" }
    @colors.each { _1.select = _1.rgb   == @canvas.brushColor }
  end

  def draw()
    background 100
    sprite *@sprites
  end

  def resized()
    @actions.first.pos = [MARGIN, MARGIN]
    @actions.each_cons(2) { _2.pos = [MARGIN, _1.bottom + MARGIN] }

    @tools.first.pos = [@actions.first.right + MARGIN, MARGIN]
    @tools.each_cons(2) { _2.pos = [_1.right + MARGIN, _1.y] }

    @colors.first.pos = [@actions.first.right + MARGIN, @tools.first.bottom + MARGIN]
    @colors.each_cons(2) { _2.pos = [_1.right + MARGIN, _1.y] }

    @status.pos    = [0, height - 22]
    @status.right  = width
    @status.bottom = height

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
    Sprite.new.tap do |sp|
      sp.draw do
        fill 200
        rect 0, 0, sp.w, sp.y

        fill 0
        textAlign LEFT, CENTER
        text "[ #{canvas.frame + 1} / #{canvas.size} ]", MARGIN, 0, sp.w, sp.h
      end
    end
  end

end # App
