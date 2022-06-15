# frozen_string_literal: true
module DRI
  module Datastreams
    module NokogiriDatastream
      extend ActiveSupport::Concern

      included do
        attribute :ng_xml, :binary
      end

      module ClassMethods
        def xml_template
          Nokogiri::XML::Document.parse("<xml/>")
        end

        def decorate_ng_xml(xml)
          xml
        end
      end

      def ng_xml
        @ng_xml ||= begin
          xml = if new_record?
                  ## Load up the template
                  self.class.xml_template
                else
                  Nokogiri::XML::Document.parse(remote_content)
                end
          self.class.decorate_ng_xml xml
        end
      end

      def ng_xml=(new_xml)
        # before we set ng_xml, we load the datastream so we know if the new value differs.
        # TODO reinstate this
        # local_or_remote_content(true)
        case new_xml
        when Nokogiri::XML::Document
          self.content = new_xml.to_xml
        when Nokogiri::XML::Node
          ## Cast a fragment to a document
          self.content = new_xml.to_s
        when String
          self.content = new_xml
        else
          raise TypeError, "You passed a #{new_xml.class} into the ng_xml of the datastream. OmDatastream.ng_xml= only accepts Nokogiri::XML::Document, Nokogiri::XML::Element, Nokogiri::XML::Node, or raw XML (String) as inputs."
        end
      end

      def refresh_attributes
        clear_changes_information
        @ng_xml = nil
      end

      # don't want content eagerly loaded by proxy, so implementing methods that would be implemented by define_attribute_methods
      def ng_xml_will_change!
        attribute_will_change!('ng_xml')
      end

      def ng_xml_doesnt_change!
        clear_attribute_changes('ng_xml')
      end

      # don't want content eagerly loaded by proxy, so implementing methods that would be implemented by define_attribute_methods
      def ng_xml_changed?
        changed.include?('ng_xml')
      end

      def remote_content
        @ds_content ||= Nokogiri::XML(persisted_remote_content).to_xml(&:no_declaration).strip
      end

      def content=(new_content)
        if remote_content != new_content.to_s
          attribute_will_change!('ng_xml')
          @ng_xml = Nokogiri::XML::Document.parse(new_content)

          attribute_will_change!('content') unless @content == new_content.to_s
          @content = new_content.to_s
        end
        self.class.decorate_ng_xml @ng_xml
      end

      def content_changed?
        return true if new_record?
        return false unless xml_loaded
        ng_xml_changed?
      end

      def to_xml(xml = nil)
        xml = ng_xml if xml.nil?
        ng_xml = self.ng_xml
        if ng_xml.respond_to?(:root) && ng_xml.root.nil? && self.class.respond_to?(:root_property_ref) && !self.class.root_property_ref.nil?
          ng_xml = self.class.generate(self.class.root_property_ref, "")
          xml = ng_xml if xml.root.nil?
        end

        unless xml == ng_xml || ng_xml.root.nil?
          if xml.is_a?(Nokogiri::XML::Document)
            xml.root.add_child(ng_xml.root)
          elsif xml.is_a?(Nokogiri::XML::Node)
            xml.add_child(ng_xml.root)
          else
            raise "You can only pass instances of Nokogiri::XML::Node into this method.  You passed in #{xml}"
          end
        end

        xml.to_xml.strip
      end

      def content
        @content = to_xml if ng_xml_changed? || (new_record? && @content.nil?)
        persisted_content
      end

      def xml_loaded
        instance_variable_defined? :@ng_xml
      end
    end
  end
end
