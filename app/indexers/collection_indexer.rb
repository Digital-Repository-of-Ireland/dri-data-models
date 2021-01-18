# frozen_string_literal: true
class CollectionIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    solr_doc = {}

    # Add title metadata from parent collections
    ancestor_titles = []
    ancestor_ids = []

    return solr_doc unless resource.respond_to?(:governing_collection)
    curr_gov_collection = resource.governing_collection

    until curr_gov_collection.nil?
      ancestor_titles << curr_gov_collection.title[0]
      ancestor_ids << curr_gov_collection.alternate_id
      curr_gov_collection = curr_gov_collection.governing_collection
    end

    if ancestor_ids.empty?
      # This must be a root collection
      solr_doc.merge!(
        {
          'root_collection_sim' => [resource.title.first],
          'root_collection_tesim' => [resource.title.first],
          'root_collection_id_ssi' => resource.alternate_id,
        }
      )
    else
      solr_doc.merge!(
        {
          'ancestor_title_sim' => ancestor_titles,
          'ancestor_title_tesim' => ancestor_titles,
          #solr_doc.merge!(Solrizer.solr_name('ancestor_id', :stored_searchable) => ancestor_ids)
          'ancestor_id_ssim' => ancestor_ids,
          # governing_id needed for user_group gem!!!
          'governing_id_sim' => [ancestor_ids.first],
          'collection_id_sim' => [ancestor_ids.first],
          #solr_doc.merge!('collection_id_tesim' => [ancestor_ids.first])
          'collection_sim' => [ancestor_titles.first],
          'collection_tesim' => [ancestor_titles.first],
          'root_collection_id_ssi' => ancestor_ids.last,
          #solr_doc.merge!('root_collection_id_tesim' => [ancestor_ids.last])
          'root_collection_sim' => [ancestor_titles.last],
          'root_collection_tesim' => [ancestor_titles.last]
        }
      )
    end

    unless resource.governing_collection.nil?
      solr_doc['isGovernedBy_ssim'] = [resource.governing_collection.alternate_id]
    end

    unless resource.collection_relatives.blank?
      solr_doc['isMemberOf_ssim'] = resource.collection_relatives.map(&:alternate_id)
    end

    if !resource.previous_sibling.blank?
      solr_doc["#{DRI::RDFVocabularies::DriRelsVocabulary.isPrecededBy.fragment}_ssim"] = [resource.previous_sibling.alternate_id]
    elsif resource.is_a?(DRI::EadComponent)
      solr_doc['is_first_sibling_isi'] = 1
    end

    solr_doc['is_collection_ssi'] = resource.collection?

    solr_doc
  end
end
