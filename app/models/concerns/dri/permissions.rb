module DRI::Permissions

  def permission_array(permission)
    value = read_attribute("#{permission}")
    return [] unless value
    value
  end

  def permissions
    graph = RDF::Graph.new
    %w(manager edit read).each do |permission|
      permission_array("#{permission}_users").each do |entry|
        graph << [ RDF::URI.new("http://projecthydra.org/ns/auth/person##{entry}"), mode(permission), "#{noid}" ]
      end

      permission_array("#{permission}_groups").each do |entry|
        graph << [ RDF::URI.new("http://projecthydra.org/ns/auth/group##{entry}"), mode(permission), "#{noid}" ]
      end
    end

    if master_file_access
      graph << [
                 RDF::URI.new("http://projecthydra.org/ns/auth/group##{master_file_access}"),
                 RDF::URI.new("https://dri.ie/ns/auth/acl#ReadMaster"),
                 "#{noid}"
               ]
    end

    graph.dump(:ntriples)
  end

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
