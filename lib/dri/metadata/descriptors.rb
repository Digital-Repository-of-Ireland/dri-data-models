module DRI
  module Metadata
  	module Descriptors
  	  require 'iso-639'

  	  def self.language_facetable
      	@language ||= Solrizer::Descriptor.new(:string, :indexed, :multivalued, converter: language_converter)
      end

      def self.language_converter
      	lambda do |type|
      		lambda do |val|
      			begin
      				ISO_639.find(val.strip).alpha3_bibliographic
      			rescue
      				nil
      			end
      		end
      	end
      end

  	end
  end
end