$:.unshift File.join(File.dirname(__FILE__), 'src')

require 'resheet/app'

run Resheet::App.new
