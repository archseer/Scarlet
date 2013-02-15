require "openssl"
require "base64"

module Scarlet
  module SASL

    class Mechanism; end

    class Plain < Mechanism
      def self.mechanism_name
        "PLAIN"
      end

      def self.generate user, password, payload
        Base64.strict_encode64([user, user, password].join("\0"))
      end
    end

    class DH_Blowfish
      def self.mechanism_name
        "DH-BLOWFISH"
      end

      # @return [Array(Numeric, Numeric, Numeric)] p, g and y for DH
      def self.unpack_payload(payload)
        pgy     = []
        payload = payload.dup

        3.times do
          size = payload.unpack("n").first
          payload.slice!(0, 2)
          pgy << payload.unpack("a#{size}").first
          payload.slice!(0, size)
        end

        pgy.map {|i| OpenSSL::BN.new(i, 2)}
      end

      def self.generate user, password, payload
        user     = user.dup
        password = password.dup

        p, g, y = unpack_payload(Base64.decode64(payload).force_encoding("ASCII-8BIT"))

        dh = OpenSSL::PKey::DH.new
        dh.p = p
        dh.g = g
        dh.generate_key!

        secret_key = dh.compute_key(y)
        public_key = dh.public_key.to_der

        # Pad the password to the nearest multiple of cipher block size
        password << "\0"
        password << "." * (8 - (password.size % 8))

        cipher = OpenSSL::Cipher.new("BF-ECB")
        cipher.key_len = 32 # OpenSSL's default of 16 doesn't work
        cipher.encrypt
        cipher.key = secret_key

        crypted = cipher.update(password) # we do not want the content of cipher.final

        answer = [public_key.bytesize, public_key, user, crypted].pack("na*Z*a*")
        Base64.strict_encode64(answer)
      end
    end

  end
end