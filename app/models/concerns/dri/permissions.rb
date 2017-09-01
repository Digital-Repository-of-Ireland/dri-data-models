module DRI::Permissions

  def solrize_permissions(solr_doc = {})
    %w(read edit manager).each do |permission|
      solr_doc.merge!(ActiveFedora::index_field_mapper.solr_name("#{permission}_access_group", :symbol) => permission_array("#{permission}_groups"))
      solr_doc.merge!(ActiveFedora::index_field_mapper.solr_name("#{permission}_access_person", :symbol) => permission_array("#{permission}_users"))
    end

    solr_doc
  end

  def permission_array(permission)
    value = read_attribute("#{permission}_string")
    return [] unless value
    value.split(',').map(&:strip)
  end
  
end