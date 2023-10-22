using RubySketch

class App

  MARGIN = 8

  SAVE_PATH = 'ToonData'

  def initialize()
    setTitle 'ToonSketch'
    windowResize 800, 600
    noStroke

    @history = History.new

    _setup
  end

  attr_reader :history

  def draw()
    @undo.enable @history.canUndo?
    @redo.enable @history.canRedo?

    background 100
    sprite *@sprites
  end

  def resized()
    @actions.first.pos = [MARGIN, MARGIN]
    @actions.each_cons(2) { _2.pos = [MARGIN, _1.bottom + MARGIN] }

    @brushes.first.pos = [@actions.first.right + MARGIN, MARGIN]
    @brushes.each_cons(2) { _2.pos = [_1.right + MARGIN, _1.y] }

    @colors.first.pos = [@brushes.first.left, @brushes.first.bottom + MARGIN]
    @colors.each_cons(2) { _2.pos = [_1.right + MARGIN, _1.y] }

    @tools.first.pos = [@brushes.last.right + MARGIN * 2, @brushes.last.top]
    @tools.each_cons(2) { _2.pos = [_1.right + MARGIN, _1.y] }

    @layers.first.pos = [@tools.first.left, @colors.last.top]
    @layers.each_cons(2) { _2.pos = [_1.right + MARGIN, _1.y] }

    @status.pos   = [0, height - @status.h]
    @status.width = width

    @canvas.pos    = [@actions.first.right + MARGIN, @colors.first.bottom + MARGIN]
    @canvas.right  = width - MARGIN
    @canvas.bottom = @status.top - MARGIN
  end

  def keyPressed(key, keyCode)
    case key
    when 'z' then _clickInsert
    when 'x' then _clickPrevious
    when 'c' then _clickNext
    when 'v' then _clickInsertNext
    when 'D' then _clickDelete
    when 'q' then _clickBrushSize BRUSH_SIZES[0]
    when 'w' then _clickBrushSize BRUSH_SIZES[1]
    when 'e' then _clickBrushSize BRUSH_SIZES[2]
    when 'r' then _clickBrushSize BRUSH_SIZES[3]
    when 't' then _clickBrushSize BRUSH_SIZES[4]
    when 'a' then _clickBrushColor *BRUSH_COLORS[0]
    when 's' then _clickBrushColor *BRUSH_COLORS[1]
    when 'd' then _clickBrushColor *BRUSH_COLORS[2]
    when 'f' then _clickBrushColor *BRUSH_COLORS[3]
    when 'g' then _clickBrushColor *BRUSH_COLORS[4]
    when '1' then _clickLayer 0
    when '2' then _clickLayer 1
    when '3' then _clickLayer 2
    when '4' then _clickLayer 3
    when '5' then _clickLayer 4
    end
    case keyCode
    when :space then _clickPlayOrStop
    when :left  then _clickPrevious
    when :right then _clickNext
    end
  end

  private

  BRUSH_SIZES  = [1, 2, 3, 5, 10]

  BRUSH_COLORS = [0, 127, 191, 223, 255].map { [_1] * 3 }

  def _setup()
    @canvas = Canvas.new(self, 160, 120).tap {_1.zoom = 3}

    @playOrStop =
      Button.new(label: 'Play', h: 66, rgb: [240, 180, 180]) { _clickPlayOrStop }

    @undo = Button.new(label: 'Undo') { _clickUndo }
    @redo = Button.new(label: 'Redo') { _clickRedo }

    @actions = [
      @playOrStop,
      Space.new(h: MARGIN * 2),
      Button.new(label: 'Previous',    h: 66, rgb: [180, 240, 180]) { _clickPrevious },
      Button.new(label: 'Next',        h: 66, rgb: [180, 240, 180]) { _clickNext },
      Button.new(label: 'Insert Next', h: 66, rgb: [180, 240, 180]) { _clickInsertNext },
      Button.new(label: 'Insert',             rgb: [180, 240, 180]) { _clickInsert },
      Button.new(label: 'Delete',             rgb: [180, 240, 180]) { _clickDelete },
      Space.new(h: MARGIN * 2),
      @undo,
      @redo,
      Space.new(h: MARGIN * 2),
      Button.new(label: 'New',  rgb: [240, 240, 180]) { _clickNew },
      Button.new(label: 'Load', rgb: [240, 240, 180]) { _clickLoad },
      Button.new(label: 'Save', rgb: [240, 240, 180]) { _clickSave },
    ]
    @brushes = BRUSH_SIZES.map { |n|
      Button.new(label: "#{n}px", w: 44) { _clickBrushSize n }
    }
    @colors = BRUSH_COLORS.map { |r, g, b|
      Button.new(w: 44, rgb: [r, g, b]) { _clickBrushColor r, g, b }
    }
    @tools = [
      Button.new(label: 'Move',   w: 66).tap { |b|
        b.mouseDragged { _dragMove b.mouseX - b.pmouseX, b.mouseY - b.pmouseY }
      },
      Button.new(label: 'Rotate', w: 66).tap { |b|
        b.mouseDragged { _dragRotate b.mouseX - b.pmouseX }
      },
      Button.new(label: 'Zoom',   w: 66).tap { |b|
        b.mouseDragged { _dragZoom b.mouseX - b.pmouseX }
      },
    ]
    @layers = 5.times.map { |n|
      Button.new(label: (n + 1).to_s, w: 44) { _clickLayer n }
    }
    @status  = _createStatus
    @sprites = [@canvas, *@actions, *@brushes, *@colors, *@tools, *@layers, @status]
    @sprites.each { addSprite _1 }

    _updateSelections
  end

  def _createStatus()
    Sprite.new(0, 0, 1, 28).tap do |sp|
      left = -> {
        "[ #{@canvas.frame + 1} / #{@canvas.size} ]"
      }
      right = -> {
        "( #{(@canvas.zoom * 100).to_i}% )"
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

  def _clickPlayOrStop()
    @canvas.playing? ? @canvas.stop : @canvas.play
    @playOrStop.label = @canvas.playing? ? 'Stop' : 'Play'
  end

  def _clickPrevious()
    @canvas.stop
    @canvas.frame -= 1
  end

  def _clickNext()
    @canvas.stop
    @canvas.frame += 1 if @canvas.frame + 1 < @canvas.size
  end

  def _clickInsertNext()
    @canvas.stop
    @canvas.insert 1
    @canvas.frame += 1
  end

  def _clickInsert()
    @canvas.stop
    @canvas.insert
  end

  def _clickDelete()
    @canvas.stop
    @canvas.delete
    @canvas.frame = @canvas.frame - 1 if @canvas.frame == @canvas.size
  end

  def _clickUndo()
    @history.undo
  end

  def _clickRedo()
    @history.redo
  end

  def _clickNew()
    @canvas.clear
  end

  def _clickLoad()
    @canvas.load SAVE_PATH
  end

  def _clickSave()
    @canvas.save SAVE_PATH
  end

  def _clickBrushSize(size)
    @canvas.brushSize = size
    _updateSelections
  end

  def _clickBrushColor(r, g, b)
    @canvas.brushColor = [r, g, b]
    _updateSelections
  end

  def _dragMove(dx, dy)
    @canvas.scroll += createVector dx, dy
  end

  def _dragRotate(dangle)
    @canvas.angle += dangle
  end

  def _dragZoom(dzoom)
    @canvas.zoom += dzoom / 32.0
  end

  def _clickLayer(layer)
    button = @layers[layer]
    if button.selected?
      visible = !@canvas.first[layer].visible?
      @canvas.each { _1[layer].visible = visible }
      button.label = (layer + 1).to_s + (visible ? '' : 'x')
    else
      @canvas.layer = layer
      _updateSelections
    end
  end

  def _updateSelections()
    @brushes.each { _1.select _1.label == "#{@canvas.brushSize}px" }
    @colors.each  { _1.select _1.rgb   == @canvas.brushColor }
    @layers.each  { _1.select _1.label[/\d+/].to_i == @canvas.layer + 1 }
  end

end # App
