# frozen_string_literal: true
class AccessControlIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.respond_to?(:access_control)

	  solr_doc = {}

    solr_doc['master_file_access_ssi'] = resource.master_file_access if resource.respond_to?(:master_file_access)
    %w(discover read edit manager).each do |permission|
      solr_doc.merge!(
        {
          "#{permission}_access_group_ssim" => resource.access_control.permission_array("#{permission}_groups"),
          "#{permission}_access_person_ssim" => resource.access_control.permission_array("#{permission}_users")
        }
      )
    end

    solr_doc
  end
end
