require "fiddle"

begin
  Fiddle::Function.new(Fiddle.dlopen("#{__dir__}/#{RbConfig::CONFIG["ruby_version"]}/libore_rs.#{RbConfig::CONFIG["SOEXT"]}")["Init_libore_rs"], [], Fiddle::TYPE_VOIDP).call
rescue Fiddle::DLError
  begin
    Fiddle::Function.new(Fiddle.dlopen("#{__dir__}/libore_rs.#{RbConfig::CONFIG["SOEXT"]}")["Init_libore_rs"], [], Fiddle::TYPE_VOIDP).call
  rescue Fiddle::DLError
    raise LoadError, "Failed to initialize libore_rs.#{RbConfig::CONFIG["SOEXT"]}; either it hasn't been built, or was built incorrectly for your system"
  end
end

require_relative "./ore/aes128"
