# frozen_string_literal: true

module DRI::Metadata::Transformations
  # Shared parsing/detection helpers for DCMI Point, DCMI Box, and DCMI
  # Period encoded strings (semicolon-separated key=value pairs, e.g.
  # "east=-6.26; north=53.35").
  module DcmiParser
    # Keys required to fully parse a DCMI Point / DCMI Box (see .complete?).
    POINT_KEYS = %w[east north].freeze
    BOX_KEYS = %w[eastlimit northlimit westlimit southlimit].freeze

    POINT_DETECTION_KEYS = %w[east north elevation projection].freeze
    BOX_DETECTION_KEYS = %w[eastlimit northlimit southlimit westlimit uplimit downlimit].freeze
    PERIOD_DETECTION_KEYS = %w[start end scheme].freeze

    module_function

    # Parses a DCMI-encoded string ("key=value; key=value; ...") into a
    # Hash keyed by downcased key.
    # @param [String, nil] value
    # @return [Hash]
    def components(value = nil)
      return {} if value.nil?

      value.split(/\s*;\s*/).each_with_object({}) do |component, hash|
        k, v = component.split(/\s*=\s*/)
        next if k.nil? || v.nil?

        hash[k.downcase] = v.strip
      end
    end

    # @param [Array<String>] required_keys
    # @param [Hash] parsed_components result of #components
    # @return [Boolean] true if every required key is present
    def complete?(required_keys, parsed_components)
      required_keys.all? { |key| parsed_components.key?(key) }
    end

    # @return [Boolean] true if value looks like a DCMI Point
    def point?(value)
      raw_keys(value).intersect?(POINT_DETECTION_KEYS)
    end

    # @return [Boolean] true if value looks like a DCMI Box
    def box?(value)
      raw_keys(value).intersect?(BOX_DETECTION_KEYS)
    end

    # @return [Boolean] true if value looks like a DCMI Period
    def period?(value)
      raw_keys(value).intersect?(PERIOD_DETECTION_KEYS)
    end

    # @return [Boolean] true if value is DCMI Box, Point, or Period encoded
    def encoded?(value)
      box?(value) || period?(value) || point?(value)
    end

    def raw_keys(value)
      value.split(/\s*;\s*/).filter_map { |component| component.split(/\s*=\s*/).first }
    end
  end
end
