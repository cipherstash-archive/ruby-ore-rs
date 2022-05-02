module ORE
end

begin
  RUBY_VERSION =~ /(\d+\.\d+)/
  require_relative "./#{$1}/ore_rs"
rescue LoadError
  begin
    require_relative "./ore_rs"
  rescue LoadError
    raise LoadError, "Could not load ore_rs binary library"
  end
end

require_relative "./ore/aes128"
