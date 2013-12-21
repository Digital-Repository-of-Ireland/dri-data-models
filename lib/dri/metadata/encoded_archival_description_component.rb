module DRI

  module Metadata

    class EncodedArchivalDescriptionComponent < DRI::Metadata::Base

      # OM (Opinionated Metadata) terminology mapping to an EAD Component tag
      set_terminology do |t|
        t.root(:path=>"*", :namespace_prefix => nil)

        t.c(:path=>"*", :namespace_prefix => nil) {
          t.ead_level(:path => {:attribute=>"level"}, :namespace_prefix => nil)
          t.did(:path => "did", :namespace_prefix => nil) {
            t.title(:path=>"unittitle", :index_as=>[:stored_searchable, :displayable, :sortable])
            t.abstract(:path=>"abstract", :index_as=>[:displayable])
            t.language(:path=>"langmaterial", :index_as=>[:stored_searchable, :facetable])
            t.creator(:path=>"origination", :index_as=>[:stored_searchable, :facetable])
            t.subject(:path=>"subject", :index_as=>[:stored_searchable, :facetable])
            t.name_coverage(:path=>"name", :index_as=>[:stored_searchable, :facetable])
            t.persname_coverage(:path=>"persname", :index_as=>[:stored_searchable, :facetable])
            t.geographical_coverage(:path=>"geogname", :index_as=>[:stored_searchable, :facetable])
            t.creation_date(:path=>"unitdate", :index_as=>[:stored_searchable, :displayable, :facetable], :type=>:date)
            t.type(:path=>"physdesc/genreform", :index_as=>[:stored_searchable, :displayable, :facetable])

            # We need to keep track of the unitid in order to sync this XML snippet to the correct
            # component tag in the complete EAD XML datastream in the collection object!
            t.unitid(:path=>"unitid", :index_as=>[:stored_searchable], :namespace_prefix => nil) {
              t.repository_code(:path => {:attribute=>"repositorycode"}, :index_as=>[:stored_searchable], :namespace_prefix => nil)
              t.country_code(:path => {:attribute=>"countrycode"}, :index_as=>[:stored_searchable], :namespace_prefix => nil)
            }
          }
          t.bioghist {

          }
          t.scopecontent {

          }
        }
      end # set_terminology

      synchronize_metadata_on_save = true

      # Build the xml doc
      def self.xml_template
          builder = Nokogiri::XML::Builder.new do |xml|
              xml.c(:level => '') {
                xml.did {
                  xml.unittitle
                  xml.unitid(:repositorycode => '', :countrycode => 'IE')
                }
              }
          end

          return builder.doc
      end

      def to_solr(solr_doc=Hash.new)
        super(solr_doc)

        # EAD has several "name" tags, so we merge them together into the SOLR document
        person_array = get_person_array()
        description_array = description
        solr_doc.merge!(ActiveFedora::SolrService.solr_name('person', :stored_searchable) => person_array)
        solr_doc.merge!(ActiveFedora::SolrService.solr_name('person', :facetable) => person_array)
        solr_doc.merge!(ActiveFedora::SolrService.solr_name('description', :stored_searchable) => description_array)
        solr_doc.merge!(ActiveFedora::SolrService.solr_name('description', :facetable) => description_array)

        solr_doc
      end

      def get_person_array()
         return c.did.name_coverage | c.did.persname_coverage | c.did.corpname_coverage | c.did.creator
      end

      def description
        return c.did.abstract | c.scopecontent | c.bioghist
      end

      def set_attributes model
        model.class.has_attributes :title, datastream: :descMetadata, at: [:c, :did, :title], multiple: false
        model.class.has_attributes :abstract, datastream: :descMetadata, at: [:c, :did, :abstract], multiple: false
        model.class.has_attributes :bioghist, datastream: :descMetadata, at: [:c, :bioghist], multiple: false
        model.class.has_attributes :scope_content, datastream: :descMetadata, at: [:c, :scopecontent], multiple: false
        model.class.has_attributes :ead_level, datastream: :descMetadata, at: [:c, :ead_level], multiple: false
        model.class.has_attributes :language, datastream: :descMetadata, at: [:c, :did, :language], multiple: true
        model.class.has_attributes :creator, datastream: :descMetadata,  at: [:c, :did, :creator], multiple: true
        model.class.has_attributes :creation_date, datastream: :descMetadata, at: [:c, :did, :creation_date], multiple: true
        model.class.has_attributes :name_coverage, datastream: :descMetadata, at: [:c, :did, :name_coverage], multiple: true
        model.class.has_attributes :geographical_coverage, datastream: :descMetadata, at: [:c, :did, :geographical_coverage], multiple: true
        model.class.has_attributes :type, datastream: :descMetadata, multiple: true,  at: [:c, :did, :type]
        model.class.has_attributes :unitid, datastream: :descMetadata, at: [:c, :did, :unitid], multiple: false
        model.class.has_attributes :repository_code, datastream: :descMetadata, at: [:c, :did, :unitid, :repository_code], multiple: false
        model.class.has_attributes :country_code, datastream: :descMetadata, at: [:c, :did, :unitid, :country_code], multiple: false
      end

      def unset_attributes
        delegates = [ "title", "abstract", "bioghist", "scope_content", "ead_level", "language", "creator",
          "creation_date", "name_coverage", "geographical_coverage", "type", "unitid", "repository_code", "country_code"]

        return delegates
      end

      def interchangeable?
        false
      end

      def collection?
        if c.ead_level == ["file"]
          false
        else
          true
        end
      end

      def synchronize_metadata parent
        # Exit if we have no parent to sync with
        if parent == nil
          return
        end

        # Prevent parent from automatically syncing
        parent.synchronize_if_changed = false

        # Check if the component node in parent XML is different
        parentMetadataXML = parent.descMetadata.to_ng
        childMetadataXML = descMetadata.to_ng

        matchingNodes = parentMetadataXML.xpath(".//parent::unitid[@repository_code='#{repository_code}' and @countrycode='#{country_code}' and "+
                                            " text()=#{unitid}]")
        # Queue synchronization between parent and grandparent
        if parent.descMetadata.class == DRI::Metadata::EncodedArchivalDescriptionComponent 
          Sufia.queue.push(SynchronizeMetadata.new(parent.pid))
        end
      end

      def custom_validations
        errors = Hash.new
        
        errors[:abstract] = "can not be blank" if description.blank?
        errors[:ead_level] = "can not be blank" if c.ead_level.blank? #hmm, this check is not working
        errors[:unitid] = "can not be blank" if c.did.unitid.blank?
        errors[:country_code] = "can not be blank" if c.did.unitid.country_code.blank?
        errors[:repository_code] = "can not be blank" if c.did.unitid.repository_code.blank?

        errors
      end

    end

  end

end
