module DRI

  module Metadata

    # An ActiveFedora datastream that interacts with Qualified DC Metadata.

    class QualifiedDublinCore < DRI::Metadata::Base

      # Set OM (Opinionated Metadata) terminology
      def self.load_inherited_terminology
        set_terminology do |t|
          t.root(:path=>"/*") # Selects the root node of the XML document

          # Simple Dublin Core Fields
          t.title(:namespace_prefix=>"dc", :index_as=>[:stored_searchable, :displayable])

          t.rights(:namespace_prefix=>"dc", :index_as=>[:stored_searchable, :displayable])
          t.description(:namespace_prefix=>"dc", :index_as=>[:stored_searchable, :displayable])
          t.language(:namespace_prefix=>"dc", :index_as=>[:stored_searchable, Descriptors.language_facetable])
          t.subject(:namespace_prefix=>"dc", :index_as=>[:stored_searchable, :facetable, :displayable]) {
            t.subject_lang(:path=>{:attribute=> "xml:lang"})
          }
          t.subject_lang(:proxy=>[:subject, :subject_lang])
          t.date(:namespace_prefix=>"dc", :type=> :date, :index_as=>[:stored_searchable, :displayable, :dateable])
          t.contributor(:path=>"contributor", :namespace_prefix=>"dc", :index_as=>[:facetable, :stored_searchable])
          t.source(:path=>"source", :namespace_prefix=>"dc", :index_as=>[:displayable, :facetable])
          t.publisher(:path=>"publisher", :namespace_prefix=>"dc", :index_as=>[:facetable, :stored_searchable, :displayable])
          t.coverage(:namespace_prefix=>"dc", :index_as=>[:stored_searchable, :facetable]) {
            t.coverage_lang(:path=>{:attribute=> "xml:lang"})
          }
          t.relation(:namespace_prefix=>"dc", :index_as=>[:displayable, :facetable])
          t.creator(:namespace_prefix=>"dc", :index_as=>[:facetable, :stored_searchable, :displayable,  :sortable])
          t.format(:namespace_prefix=>"dc", :index_as=>[:facetable, :stored_searchable, :displayable])
          t.type(:namespace_prefix=>"dc", :index_as=>[:facetable, :stored_searchable, :displayable])

          # No need to index, but useful for editing
          t.identifier(:namespace_prefix=>"dc")

          # Qualified Dublin Core fields
          t.published_date(:path=>"issued", :namespace_prefix=>"dcterms", :index_as=>[:stored_searchable, :displayable, :dateable])
          t.creation_date(:path=>"created", :namespace_prefix=>"dcterms", :index_as=>[:stored_searchable, :displayable, :dateable])
          t.geographical_coverage(:path=>"spatial", :namespace_prefix=>"dcterms", :index_as=>[:stored_searchable, :facetable, :displayable])  {
            t.geographical_coverage_lang(:path=>{:attribute=> "xml:lang"})
          }
          t.temporal_coverage(:path=>"temporal", :namespace_prefix=>"dcterms", :index_as=>[:stored_searchable, :facetable, :displayable]) {
            t.temporal_coverage_lang(:path=>{:attribute=> "xml:lang"})
          }
          t.geocode_point(:ref=>:geographical_coverage, :attributes=> {"xsi:type"=>"dcterms:Point"}, :index_as=> [:stored_searchable, :displayable])
          t.geocode_box(:ref=>:geographical_coverage, :attributes=> {"xsi:type"=>"dcterms:Box"}, :index_as=> [:stored_searchable, :displayable])

          # Generate MARC Relators fields from the MARC Relators vocabulary
          DRI::Vocabulary::marcRelators.each do |role|
            t.send "role_"+role, :path=>role, :namespace_prefix=>"marcrel", :index_as=>[:facetable, :stored_searchable, :displayable]
          end

        end

      end

      def update_indexed_attributes(params={}, opts={})
        # if the params are just keys, not an array, make then into an array.
        new_params = {}
        params.each do |key, val|
          if key.is_a? Array
            new_params[key] = val
          else
            new_params[[key.to_sym]] = val
          end
        end
        super(new_params, opts)
      end


      def roles= roles
        if roles.is_a? Hash
          if roles.has_key?("type") && roles.has_key?("name") && (roles["type"].size == roles["name"].size )
            changed_roles = Hash.new
            roles["type"].uniq.each do |role|
              changed_roles[role] = []
            end

            roles["type"].each_with_index do |role, i|
              if (roles["name"][i] != "")
                changed_roles[role].push(roles["name"][i])
              end
            end

            changed_roles.keys.each do |role|
              send role+"=", changed_roles[role]
            end
          end
        end
      end

      # Build the xml doc
      def self.xml_template
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.qualifieddc(
               "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
               "xmlns:dcterms" => "http://purl.org/dc/terms/",
               "xmlns:marcrel" => "http://www.loc.gov/marc.relators/",
               "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
               "xsi:schemaLocation" => "http://www.loc.gov/marc.relators/ http://imlsdcc2.grainger.illinois.edu/registry/marcrel.xsd",
               "xsi:noNamespaceSchemaLocation"=>"http://dublincore.org/schemas/xmls/qdc/2008/02/11/qualifieddc.xsd") {
                 xml['dc'].title 
                 xml['dc'].description
            }
          end
          return builder.doc
      end

      # merge in special facets (e.g. person) into solr document
      def to_solr(solr_doc=Hash.new)
        super(solr_doc)

        # Retrieve list of all people and add them to facet and search indexes in solr document
        person_array = get_person_array()

        solr_doc.merge!(Solrizer.solr_name('person', :facetable) => person_array)
        solr_doc.merge!(Solrizer.solr_name('person', :stored_searchable, type: :text) => person_array | DRI::Metadata::Transformations.transform_name(person_array))
        
        # title_sorted - A SOLR index for sorting titles
        if (title.length > 0)
          sorted_title = DRI::Metadata::Transformations.transform_title_for_sort(title[0])
          if (sorted_title != "")
            solr_doc.merge!(Solrizer.solr_name('title_sorted', :stored_sortable, type: :string) => [sorted_title])
          end
        end

        # all_metadata - A SOLR index of all the text contained in the XML document
        all_metadata = ""
        ng_xml.xpath("//text()").each do |text_node|
          all_metadata += text_node.text
          all_metadata += " "
        end
        solr_doc.merge!(Solrizer.solr_name("all_metadata", :stored_searchable, type: :text) => [all_metadata])

        # Split facets into different languages based on xml:lang
        faceted_language_indexes = Hash.new
        faceted_language_indexes.merge! split_array_into_languages("subject")
        faceted_language_indexes.merge! split_array_into_languages("coverage")
        faceted_language_indexes.merge! split_array_into_languages("temporal_coverage")
        faceted_language_indexes.merge! split_array_into_languages("geographical_coverage") 

        faceted_language_indexes.each do | key, value |
          solr_doc.merge!(Solrizer.solr_name(key, :stored_searchable, type: :text) => value)
          solr_doc.merge!(Solrizer.solr_name(key, :facetable, type: :text) => value)
        end

        # Split date ranges into separate indexes
        #date_ranges = Transformations.transform_date_ranges({ "date" => date, "published_date" => published_date, "creation_date" => creation_date})
        #solr_doc.merge!(date_ranges)

        solr_doc
      end

      # Some indexes may need to be split up into different languages
      def split_array_into_languages(index_name="")
        results = Hash.new

        if index_name == ""
          return results
        end
        
        array_values = send index_name

        array_values.each_with_index do |value, i|
          value_lang = send(index_name, i).send(index_name+"_lang")

            foo = "eng"

            if (value_lang.length > 0) 
              foo = value_lang[0].strip
            end

            foo = DRI::Metadata::Descriptors.standardise_language_code foo

            if foo == nil
              foo = "eng"
            end

            if !results.has_key? index_name+"_"+foo
              results[index_name+"_"+foo] = [value]
            else
              results[index_name+"_"+foo] |= [value]
            end
        end

        return results
      end

      # Creates an array of all names stored in the metadata
      def get_person_array()
          people = contributor | creator | publisher

          DRI::Vocabulary::marcRelators.each do |role|
            people |= send("role_"+role)
          end

          return people
      end

      def set_delegates model
        model.class.delegate :title, :to=>"descMetadata"
        model.class.delegate :description, :to=>"descMetadata"
        model.class.delegate :language, :to=>"descMetadata"
        model.class.delegate :creator, :to=>"descMetadata"
        model.class.delegate :contributor, :to=>"descMetadata"
        model.class.delegate :publisher, :to=>"descMetadata"
        model.class.delegate :published_date, :to=>"descMetadata"
        model.class.delegate :creation_date, :to=>"descMetadata"
        model.class.delegate :relation, :to=>"descMetadata"
        model.class.delegate :subject, :to=>"descMetadata"
        model.class.delegate :source, :to=>"descMetadata"
        model.class.delegate :geographical_coverage, :to=>"descMetadata"
        model.class.delegate :temporal_coverage, :to=>"descMetadata"
        model.class.delegate :rights, :to=>"descMetadata"
        model.class.delegate :type, :to=>"descMetadata"
        model.class.delegate :format, :to=>"descMetadata"
        model.class.delegate :coverage, :to=>"descMetadata"
        model.class.delegate :identifier, :to=>"descMetadata"
        model.class.delegate :geocode_point, :to=>"descMetadata"
        model.class.delegate :geocode_box, :to=>"descMetadata"
        model.class.delegate_to :descMetadata, DRI::Vocabulary::marcRelators.map { |s| s.prepend("role_").to_sym}
      end

      def unset_delegates
        delegates = [ "title", "description", "language", "creator", "contributor", "publisher", "published_date",
          "creation_date", "relation", "subject", "source", "geographical_coverage", "temporal_coverage", "rights",
          "type", "format", "coverage", "identifier", "geocode_point", "geocode_box"]
        DRI::Vocabulary::marcRelators.each { |s| delegates.push(s.prepend("role_"))}

        return delegates
      end

      def collection?
        type.include? "Collection"
      end

      # Load Dublin Core terminology
      load_inherited_terminology      
    end # class
    
  end # module

end # module
