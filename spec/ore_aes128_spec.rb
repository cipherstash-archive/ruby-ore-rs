require_relative './spec_helper'
require 'ore-rs'

describe ORE::AES128 do
  describe ".new" do
    it "succeeds when given the right arguments" do
      expect { ORE::AES128.new("abcd1234abcd1234".force_encoding("BINARY"), "abcd1234abcd1234".force_encoding("BINARY"), 64, 8) }.to_not raise_error
    end

    it "returns an AES128 cipher" do
      expect(ORE::AES128.new("abcd1234abcd1234".force_encoding("BINARY"), "abcd1234abcd1234".force_encoding("BINARY"), 64, 8)).to be_a(ORE::AES128)
    end

    it "needs a string as the first arg" do
      expect { ORE::AES128.new(42, "abcd1234abcd1234".force_encoding("BINARY"), 64, 8) }.to raise_error(ArgumentError)
    end

    it "needs a *binary* string as the first arg" do
      expect { ORE::AES128.new("abcd1234abcd1234", "abcd1234abcd1234".force_encoding("BINARY"), 64, 8) }.to raise_error(ArgumentError)
    end

    it "needs a 16 byte binary string as the first arg" do
      expect { ORE::AES128.new("abcd1234".force_encoding("BINARY"), "abcd1234abcd1234".force_encoding("BINARY"), 64, 8) }.to raise_error(ArgumentError)
    end

    it "needs a string as the second arg" do
      expect { ORE::AES128.new("abcd1234abcd1234".force_encoding("BINARY"), 42, 64, 8) }.to raise_error(ArgumentError)
    end

    it "needs a *binary* string as the second arg" do
      expect { ORE::AES128.new("abcd1234abcd1234".force_encoding("BINARY"), "abcd1234abcd1234", 64, 8) }.to raise_error(ArgumentError)
    end

    it "needs a 16 byte binary string as the second arg" do
      expect { ORE::AES128.new("abcd1234abcd1234".force_encoding("BINARY"), "abcd1234".force_encoding("BINARY"), 64, 8) }.to raise_error(ArgumentError)
    end

    it "needs 64 as the third arg" do
      expect { ORE::AES128.new("abcd1234abcd1234".force_encoding("BINARY"), "abcd1234abcd1234".force_encoding("BINARY"), 42, 8) }.to raise_error(ArgumentError)
    end

    it "needs 8 as the fourth arg" do
      expect { ORE::AES128.new("abcd1234abcd1234".force_encoding("BINARY"), "abcd1234abcd1234".force_encoding("BINARY"), 64, 42) }.to raise_error(ArgumentError)
    end
  end

  describe "#encrypt" do
    let(:ore) { ORE::AES128.new("abcd1234abcd1234".force_encoding("BINARY"), "abcd1234abcd1234".force_encoding("BINARY"), 64, 8) }

    # Valid scalar inputs
    {
      "a legal integer" => 42,
      "zero" => 0,
      "U64_MAX" => 2**64-1,
      "a legal finite float" => 4.2,
      "infinity" => Float::INFINITY,
      "a UTF-8 string" => "Hello world!",
      "boolean true" => true,
      "boolean false" => false,
    }.each do |desc, value|
      it "encrypts #{desc}" do
        expect { ore.encrypt(value) }.to_not raise_error
      end

      it "produces a ciphertext from #{desc}" do
        expect(ore.encrypt(value)).to be_a(ORE::AES128::Ciphertext)
      end
    end

    # Valid ranges
    {
      "a bounded integer range" => 42..100,
      "an integer range to infinity" => 42..,
      "an integer range from -infinity" => ..100,
      "a bounded float range" => 42.5..100.2,
      "a float range to infinity" => 42.5..,
      "a float range from -infinity" => ..100.2,
    }.each do |desc, value|
      it "encrypts #{desc}" do
        expect { ore.encrypt(value) }.to_not raise_error
      end

      it "produces a range of ciphertexts from #{desc}" do
        ct = ore.encrypt(value)
        expect(ct).to be_a(Range)
        expect(ct.min).to be_a(ORE::AES128::Ciphertext)
        expect(ct.max).to be_a(ORE::AES128::Ciphertext)
      end

      it "correctly orders the ciphertexts for #{desc}" do
        ct = ore.encrypt(value)
        min, max = ct.min, ct.max

        expect(min < max).to be(true)
      end
    end

    # Invalid inputs
    {
      "a random object" => Object.new,
      "a negative integer" => -42,
      "an excessively large integer" => 2**64,
      "a stupidly large integer" => 2**420,
      "NaN" => Float::NAN,
      "a binary string" => "\x42\x69".force_encoding("BINARY"),
      "a non-UTF-8 string" => "womp womp".force_encoding("ISO-8859-15"),
      "an invalid UTF-8 string" => "\xe0Happy Birthday".force_encoding(Encoding.find("UTF-8")),
      "a range of strings" => "a".."z",
      "an int/float mixed range" => 42..420.0,
      "a float/int mixed range" => 4.2..42,
      "a backwards int range" => 42..0,
      "a backwards float range" => 42.2..0.5,
    }.each do |desc, value|
      it "refuses to encrypt #{desc}" do
        expect { ore.encrypt(value) }.to raise_error(ArgumentError)
      end
    end
  end
end
