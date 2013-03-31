require 'openssl'

module Sandal
  module Sig

    # Base implementation of the ECDSA-SHA family of signature algorithms.
    class ES

      # @return [String] The JWA name of the algorithm.
      attr_reader :name

      # Creates a new instance; it's probably easier to use one of the subclass constructors.
      #
      # @param sha_size [Integer] The size of the SHA algorithm.
      # @param prime_size [Integer] The size of the ECDSA primes.
      # @param key [OpenSSL::PKey::EC] The key to use for signing (private) or validation (public).
      def initialize(sha_size, prime_size, key)
        @name = "ES#{sha_size}"
        @digest = OpenSSL::Digest.new("sha#{sha_size}")
        @prime_size = prime_size
        @key = key
      end

      # Signs a payload and returns the signature.
      #
      # @param payload [String] The payload of the token to sign.
      # @return [String] The signature.
      def sign(payload)
        hash = @digest.digest(payload)
        asn1_sig = @key.dsa_sign_asn1(hash)
        r, s = self.class.decode_asn1_signature(asn1_sig)
        self.class.encode_jws_signature(r, s, @prime_size)
      end

      # Validates a payload signature and returns whether the signature matches.
      #
      # @param signature [String] The signature to verify.
      # @param payload [String] The payload of the token.
      # @return [Boolean] true if the signature is correct; otherwise false.
      def valid?(signature, payload)
        hash = @digest.digest(payload)
        r, s = self.class.decode_jws_signature(signature)
        asn1_sig = self.class.encode_asn1_signature(r, s)
        @key.dsa_verify_asn1(hash, asn1_sig)
      end

      # Decodes an ASN.1 signature into a pair of BNs.
      #
      # @param signature [String] The ASN.1 signature.
      # @return [OpenSSL::BN, OpenSSL::BN] A pair of BNs.
      def self.decode_asn1_signature(signature)
        asn_seq = OpenSSL::ASN1.decode(signature)
        return asn_seq.value[0].value, asn_seq.value[1].value
      end

      # Encodes a pair of BNs into an ASN.1 signature.
      #
      # @param r [OpenSSL::BN] The 'r' value.
      # @param s [OpenSSL::BN] The 's' value.
      # @return [String] The ASN.1 signature.
      def self.encode_asn1_signature(r, s)
        items = [OpenSSL::ASN1::Integer.new(r), OpenSSL::ASN1::Integer.new(s)]
        OpenSSL::ASN1::Sequence.new(items).to_der
      end

      # Decodes a JWS signature into a pair of BNs.
      #
      # @param signature [String] The ASN.1 signature.
      # @return [OpenSSL::BN, OpenSSL::BN] A pair of BNs.
      def self.decode_jws_signature(signature)
        n_length = signature.length / 2
        s_to_n = lambda { |s| OpenSSL::BN.new(s.unpack('H*')[0], 16) }
        r = s_to_n.call(signature[0..(n_length - 1)])
        s = s_to_n.call(signature[n_length..-1])
        return r, s
      end

      # Encodes a pair of BNs into a JWS signature.
      #
      # @param r [OpenSSL::BN] The 'r' value.
      # @param s [OpenSSL::BN] The 's' value.
      # @param prime_size [Integer] The size of the ECDSA primes.
      # @return [String] The ASN.1 signature.
      def self.encode_jws_signature(r, s, prime_size)
        byte_count = (prime_size / 8.0).ceil
        n_to_s = lambda { |n| [n.to_s(16)].pack('H*').rjust(byte_count, "\0") }
        n_to_s.call(r) + n_to_s.call(s)
      end

    end

    # The ECDSA-SHA256 signing algorithm.
    class ES256 < Sandal::Sig::ES
      # Creates a new instance.
      #
      # @param key [OpenSSL::PKey::EC] The key to use for signing (private) or validation (public). 
      # @raise [ArgumentError] The key is not in the "prime256v1" group.
      def initialize(key)
        raise ArgumentError, 'The key must be in the prime256v1 group.' unless key.group.curve_name == 'prime256v1'
        super(256, 256, key)
      end
    end

    # The ECDSA-SHA384 signing algorithm.
    class ES384 < Sandal::Sig::ES
      # Creates a new instance.
      #
      # @param key [OpenSSL::PKey::EC] The key to use for signing (private) or validation (public). 
      # @raise [ArgumentError] The key is not in the "secp384r1" group.
      def initialize(key)
        raise ArgumentError, 'The key must be in the secp384r1 group.' unless key.group.curve_name == 'secp384r1'
        super(384, 384, key)
      end
    end

    # The ECDSA-SHA512 signing algorithm.
    class ES512 < Sandal::Sig::ES
      # Creates a new instance.
      #
      # @param key [OpenSSL::PKey::EC] The key to use for signing (private) or validation (public). 
      # @raise [ArgumentError] The key is not in the "secp521r1" group.
      def initialize(key)
        raise ArgumentError, 'The key must be in the secp521r1 group.' unless key.group.curve_name == 'secp521r1'
        super(512, 521, key)
      end
    end

  end
end