require "date"

require_relative "./aes128/ciphertext"

module ORE
  class AES128
    VALID_STRING_ENCODINGS = [Encoding.find("UTF-8"), Encoding.find("US-ASCII")]
    private_constant :VALID_STRING_ENCODINGS

    # Create a new ORE::AES128 "cipher" -- an object capable of encrypting plaintexts into ORE ciphertexts.
    #
    # @param k1 [String] also known as the "PRF key", this is one of the two keys required
    #   to encrypt with ORE.  This key must be a 16 octet string in the `BINARY` encoding.
    #
    # @param k2 [String] also known as the "PRP key", this is the other of the two keys
    #   required to encrypt with ORE.  This key must also be a 16 octet string in the `BINARY`
    #   encoding.
    #
    # @param b [Integer] the number of bits in each plaintext.  At present, the only supported
    #   value for this parameter is `64`.
    #
    # @param n [Integer] the number of blocks to generate in the ORE ciphertext.  Each block
    #   is derived from 8 bits of plaintext, and thus at present the only supported value
    #   for this parameter is `8`.
    #
    # @raises [ArgumentError] if any of the parameters do not meet the requirements.
    #
    def self.new(k1, k2, b, n)
      validate_key(k1, "k1")
      validate_key(k2, "k2")

      unless b == 64
        raise ArgumentError, "Only 64 bit ORE plaintexts are supported at present"
      end

      unless n == 8
        raise ArgumentError, "Only 8 bit ORE blocks are supported at present"
      end

      _new(k1, k2, b, n)
    end

    # Encrypt a plaintext into an ORE::AES128::Ciphertext.
    #
    # @note the type of the object you pass in as the plaintext is crucially important.
    #   Different types of object are encoded incompatibly, and comparisons between
    #   ciphertexts generated from objects of different types is not guaranteed.
    #   For example, `#encrypt(-3.0) < #encrypt(1)` will not necessarily be true,
    #   even though `#encrypt(-3.0) < #encrypt(1.0)` is guaranteed.
    #
    # The currently supported types are:
    #
    # * `Integer` -- must be in the range 0..2**64-1 (inclusive).  Will be encoded as
    #   an ORE `uint64`.
    #
    # * `Float` -- can be any double precision floating-point number, except for a NaN.
    #
    # * `String` -- any valid UTF-8 string.  Will be hashed into a 64-bit value for storage.
    #
    # * `Range` -- a range of Integers, Floats, Dates, or Times; both ends must be of the
    #     same type.  Indefinite beginnings *or* ends are supported, but not both.
    #
    # * `Date`, `Time` -- will be converted into milliseconds relative to the UTC epoch.
    #
    # @param plaintext [Integer, Float] the plaintext to encrypt.
    #
    # @raises [ArgumentError] if the type of the plaintext is not one currently supported,
    #   or the value of the plaintext is not one which is valid.
    #
    # @raises [RuntimeError] if a float is encrypted on a platform that doesn't use
    #   IEEE754 double-precision floating-point numbers as its representation of a
    #   `Float`, or if something spectacularly wrong happens in the ORE encryption process.
    #
    def encrypt(plaintext)
      case plaintext
      when Integer
        encrypt_u64(plaintext)
      when Float
        encrypt_f64(plaintext)
      when String
        encrypt_string(plaintext)
      when TrueClass, FalseClass
        encrypt_bool(plaintext)
      when Range
        encrypt_range(plaintext)
      when Date
        encrypt(plaintext.to_time)
      when Time
        encrypt_time(plaintext)
      else
        raise ArgumentError, "Do not know how to ORE encrypt a #{plaintext.class}"
      end
    end

    class << self
      private

      def validate_key(k, name)
        unless k.is_a?(String) && k.encoding == Encoding::BINARY && k.bytesize == 16
          raise ArgumentError, "#{name} must be a 16 octet binary string"
        end
      end
    end

    private

    def encrypt_u64(plaintext)
      if plaintext < 0
        raise ArgumentError, "Cannot encrypt integers less than zero"
      end

      if plaintext >= 2**64
        raise ArgumentError, "Cannot encrypt integers greater than 2^64 - 1"
      end

      _encrypt_u64(plaintext)
    end

    def encrypt_f64(plaintext)
      if Float::MAX_EXP != 1024 || Float::MIN_EXP != -1021
        # This is a pure sanity check, so...
        #:nocov:
        raise RuntimeError, "This platform does not conform to our expectations for floating-point representations.  Out of an abundance of caution, we will not encrypt floats on this platform."
        #:nocov:
      end

      if plaintext.nan?
        raise ArgumentError, "Cannot ORE encrypt NaN"
      end

      _encrypt_f64(plaintext)
    end

    def encrypt_string(plaintext)
      unless VALID_STRING_ENCODINGS.include?(plaintext.encoding)
        raise ArgumentError, "Cannot encrypt non-UTF-8 string"
      end

      if !plaintext.valid_encoding?
        raise ArgumentError, "Cannot encrypt invalid UTF-8 string"
      end

      _encrypt_string(plaintext)
    end

    def encrypt_bool(plaintext)
      _encrypt_bool(plaintext)
    end

    def encrypt_range(plaintext)
      min, max = plaintext.begin, plaintext.end

      case [min.class, max.class]
      # Integer ranges
      when [Integer, Integer]
        if max < min
          raise ArgumentError, "Cannot encrypt a non-ascending range"
        end
        (encrypt_u64(min)..encrypt_u64(max))
      when [Integer, NilClass]
        (encrypt_u64(min)..encrypt_u64(2**64-1))
      when [NilClass, Integer]
        (encrypt_u64(0)..encrypt_u64(max))

      # Float ranges
      when [Float, Float]
        if max < min
          raise ArgumentError, "Cannot encrypt a non-ascending range"
        end
        (encrypt_f64(min)..encrypt_f64(max))
      when [Float, NilClass]
        (encrypt_f64(min)..encrypt_f64(Float::INFINITY))
      when [NilClass, Float]
        (encrypt_f64(-Float::INFINITY)..encrypt_f64(max))

      # Date ranges
      when [Date, Date]
        encrypt_range(min.to_time..max.to_time)
      when [Date, NilClass]
        encrypt_range(min.to_time..)
      when [NilClass, Date]
        encrypt_range(..max.to_time)

      # Time ranges
      when [Time, Time]
        (encrypt_time(min)..encrypt_time(max))
      when [Time, NilClass]
        (encrypt_time(min)..encrypt_u64(2**64-1))
      when [NilClass, Time]
        (encrypt_u64(0)..encrypt_time(max))

      else
        raise ArgumentError, "Cannot encrypt a range over #{min.class}..#{max.class}"
      end
    end

    def encrypt_time(plaintext)
      # Get the time in integer milliseconds, and then "shift" it so
      # that times before the epoch are still positive numbers, just
      # smaller than times after the epoch
      encrypt_u64((plaintext.to_r * 1000).to_i + 2**63)
    end
  end
end
