require_relative './spec_helper'
require 'ore-rs'

describe ORE::AES128::Ciphertext do
  let(:dummy_key) { "abcd1234abcd1234".force_encoding("BINARY") }
  let(:cipher) { ORE::AES128.new(dummy_key, dummy_key, 64, 8) }

  describe ".new" do
    it "works if passed valid input" do
      expect { described_class.new(cipher.encrypt(42).to_s, 8) }.to_not raise_error
    end

    it "returns a Ciphertext object" do
      expect(described_class.new(cipher.encrypt(42).to_s, 8)).to be_a(ORE::AES128::Ciphertext)
    end

    it "refuses to accept a non-string" do
      expect { described_class.new(42, 8) }.to raise_error(ArgumentError)
    end

    it "refuses to accept a non-binary string" do
      expect { described_class.new("ohai!", 8) }.to raise_error(ArgumentError)
    end

    it "refuses to accept a different n" do
      expect { described_class.new(cipher.encrypt(42).to_s, 42) }.to raise_error(ArgumentError)
    end
  end

  describe "#to_s" do
    let(:ct) { cipher.encrypt(42) }

    it "works" do
      expect { ct.to_s }.to_not raise_error
    end

    it "returns a string" do
      expect(ct.to_s).to be_a(String)
    end

    it "returns a *binary* string" do
      expect(ct.to_s.encoding).to eq(Encoding::BINARY)
    end

    it "returns a string of the right length" do
      expect(ct.to_s.length).to eq(408)
    end
  end

  describe "<=>" do
    it "compares encrypted floats correctly" do
      expect(cipher.encrypt(42.5) <=> cipher.encrypt(42.6)).to eq(-1)
      expect(cipher.encrypt(100.9) <=> cipher.encrypt(100.9)).to eq(0)
      expect(cipher.encrypt(1_000_000.1) <=> cipher.encrypt(1_000_000.05)).to eq(1)
    end

    it "compares encrypted integers correctly" do
      expect(cipher.encrypt(42) <=> cipher.encrypt(43)).to eq(-1)
      expect(cipher.encrypt(100) <=> cipher.encrypt(100)).to eq(0)
      expect(cipher.encrypt(1_000_000) <=> cipher.encrypt(999_999)).to eq(1)
    end

    it "refuses to compare a ciphertext with something else" do
      expect { cipher.encrypt(42) <=> 43 }.to raise_error(ArgumentError)
      expect { cipher.encrypt(100) <=> 10.5 }.to raise_error(ArgumentError)
      expect { cipher.encrypt(1_000_000) <=> Object.new }.to raise_error(ArgumentError)
    end
  end
end
