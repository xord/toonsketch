require 'json'
require 'rubysketch'
require 'toonsketch/all'

using RubySketch

setup         { $app = App.new }
draw          { $app.draw }
windowResized { $app.resized if $app }
keyPressed    { $app.keyPressed key, keyCode }
