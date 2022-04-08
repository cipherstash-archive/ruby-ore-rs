module ORE
  class AES128
    # An ORE ciphertext produced by an AES128 cipher.
    class Ciphertext
      include Comparable

      # Create a ciphertext object from a serialized form.
      #
      # ORE ciphertexts can be serialized (using #to_s), and then deserialized by
      # passing them into this constructor.
      #
      # @param ct [String] the serialized ciphertext.  This must be a `BINARY` encoded
      #   string.
      #
      # @param n [Integer] the number of ORE blocks contained in the ciphertext.  Each
      #   ORE block represents one octet of the plaintext.  At present, only 64-bit
      #   plaintexts are supported, so this must always be `8`.
      #
      # @raises [ArgumentError] if the string passed as the ciphertext is not valid,
      #   or `n` is not a supported value.
      #
      def self.new(ct, n)
        unless ct.is_a?(String)
          raise ArgumentError, "Ciphertext must be a string"
        end

        unless n == 8
          raise ArgumentError, "Only a block count of 8 is currently supported"
        end

        _new(ct, n)
      end

      def to_s
        _serialize
      end

      def <=>(other)
        unless other.is_a?(ORE::AES128::Ciphertext)
          raise ArgumentError, "Cannot compare an ORE ciphertext to anything other than another ciphertext"
        end

        _cmp(other)
      end
    end
  end
end
