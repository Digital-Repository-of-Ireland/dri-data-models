module DRI
  module Metadata
  	module Descriptors
  	  require 'iso-639'

  	  # Creates a facet index in SOLR for ISO 639.2 language codes 
  	  def self.language_facetable
      	@language ||= Solrizer::Descriptor.new(:string, :indexed, :multivalued, converter: language_converter)
      end

      # Converts an RFC 5646 or ISO 639.1 language code into an ISO 639.2 code
      def self.language_converter
      	lambda do |type|
      		lambda do |val|
      			begin
      				# If using RFC 5646, then val will be of the
      				# format language-script-region-variant
      				#
      				# NOTE: RFC 5646 can be divided by either hyphens or
      				# underscores.
      				#
      				# We really only care about the first element in this
      				# format.
      				clean_val = val.strip.split(/-|_/)[0].strip.downcase

      				# Now we have either a ISO 639.1 code or ISO 639.2 code.
      				result = ISO_639.find(clean_val)

      				# If result is nil, as a last resort check if they wrote
      				# the language name in english.
      				if result == nil
      					result = ISO_639.find_by_english_name(clean_val.capitalize)
      				end
		
      				if result == nil
      					nil
      				else
      					# Return the 3-letter ISO 639.2 code
      					result.alpha3_bibliographic
      				end
      			rescue
      				nil
      			end
      		end
      	end
      end

  	end
  end
end