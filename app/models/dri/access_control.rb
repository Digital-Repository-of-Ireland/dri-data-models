# frozen_string_literal: true
module DRI
  class AccessControl < ApplicationRecord
    belongs_to :digital_object, class_name: 'DRI::DigitalObject', polymorphic: true, autosave: true

    serialize :manager_groups, type: Array, coder: YAML
    serialize :manager_users, type: Array, coder: YAML
    serialize :edit_groups, type: Array, coder: YAML
    serialize :edit_users, type: Array, coder: YAML
    serialize :read_groups, type: Array, coder: YAML
    serialize :read_users, type: Array, coder: YAML
    serialize :discover_groups, type: Array, coder: YAML
    serialize :discover_users, type: Array, coder: YAML

    def permissions
      graph = RDF::Graph.new
      %w[manager edit read].each do |permission|
        permission_array("#{permission}_users").each do |entry|
          graph << [RDF::URI.new("http://projecthydra.org/ns/auth/person##{entry}"), mode(permission), digital_object.alternate_id]
        end

        permission_array("#{permission}_groups").each do |entry|
          graph << [RDF::URI.new("http://projecthydra.org/ns/auth/group##{entry}"), mode(permission), digital_object.alternate_id]
        end
      end

      if master_file_access
        graph << [
          RDF::URI.new("http://projecthydra.org/ns/auth/group##{master_file_access}"),
          RDF::URI.new("https://dri.ie/ns/auth/acl#ReadMaster"),
          digital_object.alternate_id
        ]
      end

      graph.dump(:ntriples)
    end

    def permission_array(permission)
      self[permission.to_sym] || []
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
