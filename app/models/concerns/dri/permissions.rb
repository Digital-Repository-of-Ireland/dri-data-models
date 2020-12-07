module DRI::Permissions

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
