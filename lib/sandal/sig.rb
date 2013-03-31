require 'singleton'

module Sandal
  # Contains signature (JWS) functionality.
  module Sig

    # The 'none' JWA signature method.
    class None
      include Singleton

      # @return [String] The JWA name of the algorithm.
      attr_reader :name

      # Creates a new instance.
      def initialize
        @name = 'none'
      end

      # Returns an empty signature.
      #
      # @param payload [String] This parameter is ignored.
      # @return [String] An empty string.
      def sign(payload)
        ''
      end

      # Validates that a signature is nil or empty.
      #
      # @param signature [String] The signature to verify.
      # @param payload [String] This parameter is ignored.
      # @return [Boolean] true if the signature is nil or empty; otherwise false.
      def valid?(signature, payload)
        signature.nil? || signature.empty?
      end

    end

  end
end

require 'sandal/sig/es'
require 'sandal/sig/hs'
require 'sandal/sig/rs'