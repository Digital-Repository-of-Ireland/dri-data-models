module DRI
  module Metadata
    # Shared by the two EAD-family datastream classes
    # (EncodedArchivalDescription and EncodedArchivalDescriptionComponent),
    # which both use OM terminology accessors exposing a #normal_at
    # sub-value (field_name(idx).normal_at) alongside a free-text display
    # value, for creation_date, published_date, temporal_coverage, and a
    # date/date_cvg field.
    module EadDateIndexing
      # @param [String] display the free-text display value for a date
      # @param [String] iso_date the ISO8601-encoded value, possibly a
      #   '/'-separated range (EAD date format: YYYYmmdd/YYYYmmdd or YYYY/YYYY)
      # @return [String] the DCMI Period formatted string
      def iso_to_dcmi_period(display, iso_date)
        if iso_date.include?('/')
          start_date, end_date = iso_date.split('/')
          DRI::Metadata::Transformations.create_dcmi_period(display, start_date, end_date)
        else
          DRI::Metadata::Transformations.create_dcmi_period(display, iso_date)
        end
      end

      # Builds a DCMI-Period-formatted array for an OM terminology field
      # that exposes both a plain value array (field_name) and, per index,
      # a sub-accessor with #normal_at (field_name(idx).normal_at) holding
      # the ISO8601-encoded equivalent.
      # @param [Symbol] field_name the metadata accessor to read
      # @return [Array<String>] the DCMI Period formatted values
      def dcmi_period_array_for(field_name)
        send(field_name).collect.with_index do |value, idx|
          normal_at = send(field_name, idx).normal_at

          if normal_at.empty?
            DRI::Metadata::Transformations.create_dcmi_period(value)
          else
            iso_to_dcmi_period(value, normal_at[0])
          end
        end
      end

      # Builds a name/place array with role suffixes (e.g. "Jane Doe
      # (photographer)") for an OM terminology field exposing a per-index
      # #role sub-accessor. Shared by subject_name_for_index and
      # subject_place_for_index in both EAD-family classes.
      # @param [Symbol] field_name the metadata accessor to read
      # @return [Array<String>]
      def named_with_roles(field_name)
        send(field_name).map.with_index do |n, idx|
          role = send(field_name, idx).role
          role.empty? ? n : "#{n} (#{role[0]})"
        end
      end
    end
  end
end
