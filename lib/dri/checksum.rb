require 'digest'
# DRI namespace
module DRI
  # Generate various checksums
  module Checksum
    # Generate checksum for a file using the algorithm as input
    # @param algorithm [String] the name of the checksum algorithm to use
    # @param filename [String] the filename of the file for which to generate the checksum
    # using the MD5 algorithm
    def self.checksum(algorithm, filename)
      case algorithm
      when 'md5'
        md5(filename)
      when 'sha256'
        sha256(filename)
      when 'rmd160'
        rmd160(filename)
      else
        sha256(filename) # default to sha256 if unknown
      end
    end

    # Generate MD5 checksum from a given string
    # @param string [String] the string for which to generate checksum
    # using the MD5 algorithm
    def self.md5_string(string)
      Digest::MD5.hexdigest(string)
    end

    # Generate MD5 checksum for a file
    # @param filename [String] the filename of the file for which to generate the checksum
    # using the MD5 algorithm
    def self.md5(filename)
      Digest::MD5.file(filename).hexdigest
    end

    # Generate sha256 checksum for a file
    # @param filename [String] the filename of the file for which to generate the checksum
    # using the sha256 algorithm
    def self.sha256(filename)
      Digest::SHA256.file(filename).hexdigest
    end

    # Generate rmd160 checksum for a file
    # @param filename [String] the filename of the file for which to generate the checksum
    # using the rmd160 algorithm
    def self.rmd160(filename)
      Digest::RMD160.file(filename).hexdigest
    end
  end
end