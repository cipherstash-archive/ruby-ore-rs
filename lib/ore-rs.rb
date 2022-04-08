require "rutie"

module ORE
  Rutie.new(:ruby_ore_rs).init 'Init_ruby_ore_rs', __dir__
end

require_relative "./ore/aes128"
