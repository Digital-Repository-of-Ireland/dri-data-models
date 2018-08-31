module DRI::Permissions

  def solrize_permissions(solr_doc = {})
    %w(discover read edit manager).each do |permission|
      solr_doc.merge!(Solrizer.solr_name("#{permission}_access_group", :symbol) => permission_array("#{permission}_groups"))
      solr_doc.merge!(Solrizer.solr_name("#{permission}_access_person", :symbol) => permission_array("#{permission}_users"))
    end

    solr_doc
  end

  def permission_array(permission)
    value = read_attribute("#{permission}")
    return [] unless value
    value
  end

  def permissions
    graph = RDF::Graph.new
    %w(manager edit read discover).each do |permission|
      permission_array("#{permission}_users").each do |entry|
        graph << [ RDF::URI.new("http://projecthydra.org/ns/auth/person##{entry}"), mode(permission), "#{noid}" ]
      end

      permission_array("#{permission}_groups").each do |entry|
        graph << [ RDF::URI.new("http://projecthydra.org/ns/auth/group##{entry}"), mode(permission), "#{noid}" ]
      end
    end

    graph.dump(:ntriples)
  end

  def mode(permission)
    case permission
    when 'manager'
      ::ACL.Control
    when 'edit'
      ::ACL.Write
    when 'read'
      ::ACL.Read
    when 'discover'
      Hydra::ACL.Discover
    end
  end
end
