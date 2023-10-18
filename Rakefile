task :default

task :run do
  libs = %w[xot rucy beeps rays reflex processing rubysketch]
    .map {|lib| "-I#{ENV['ALL'] || '..'}/#{lib}/lib"}
  sh %( ruby #{libs.join ' '} -Ilib -rtoonsketch -e '' )
end
