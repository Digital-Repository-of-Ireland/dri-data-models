module DRI
  class AccessControl < ApplicationRecord
    belongs_to :digital_object, class_name: 'DRI::DigitalObject', polymorphic: true, autosave: true

    serialize :manager_groups, Array
    serialize :manager_users, Array
    serialize :edit_groups, Array
    serialize :edit_users, Array
    serialize :read_groups, Array
    serialize :read_users, Array
    serialize :discover_groups, Array
    serialize :discover_users, Array

    def permissions
      graph = RDF::Graph.new
      %w(manager edit read).each do |permission|
        permission_array("#{permission}_users").each do |entry|
          graph << [ RDF::URI.new("http://projecthydra.org/ns/auth/person##{entry}"), mode(permission), "#{digital_object.noid}" ]
        end

        permission_array("#{permission}_groups").each do |entry|
          graph << [ RDF::URI.new("http://projecthydra.org/ns/auth/group##{entry}"), mode(permission), "#{digital_object.noid}" ]
        end
      end

      if master_file_access
        graph << [
                   RDF::URI.new("http://projecthydra.org/ns/auth/group##{master_file_access}"),
                   RDF::URI.new("https://dri.ie/ns/auth/acl#ReadMaster"),
                   "#{digital_object.noid}"
                 ]
      end

      graph.dump(:ntriples)
    end

    def permission_array(permission)
      value = read_attribute("#{permission}")
      return [] unless value
      value
    end

    private

    def mode(permission)
      case permission
      when 'manager'
        ::RDF::Vocab::ACL.Control
      when 'edit'
        ::RDF::Vocab::ACL.Write
      when 'read'
        ::RDF::Vocab::ACL.Read
      end
    end
  end
end
