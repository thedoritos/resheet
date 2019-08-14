$:.unshift File.join(File.dirname(__FILE__), 'src')

require 'resheet/app'
require 'resheet/authenticator'

use Resheet::Authenticator
run Resheet::App.new
