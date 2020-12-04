# frozen_string_literal: true
class PermissionsIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
	  solr_doc = {}
    %w(discover read edit manager).each do |permission|
      solr_doc.merge!(
        {
          "#{permission}_access_group_ssim" => resource.permission_array("#{permission}_groups"),
          "#{permission}_access_person_ssim" => resource.permission_array("#{permission}_users")
        }
      )
    end

    solr_doc
  end
end
