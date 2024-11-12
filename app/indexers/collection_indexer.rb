# frozen_string_literal: true
class CollectionIndexer
  IS_PRECEDED_BY = "#{DRI::RdfVocabularies::DRIRelsVocabulary.isPrecededBy.fragment}_ssim"

  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.wrapped_object.respond_to?(:governing_collection)

    ancestor_ids_and_titles = ancestor_collections
    solr_doc = ancestor_ids_and_titles.empty? ? root_collection_fields : sub_collection_fields(ancestor_ids_and_titles)
    solr_doc['isGovernedBy_ssim'] = [governing_collection_id] unless resource.wrapped_object.governing_collection.nil?
    solr_doc['isMemberOf_ssim'] = collection_relatives_ids if resource.wrapped_object.collection_relatives.present?

    siblings = sibling_fields
    solr_doc.merge! sibling_fields if siblings

    solr_doc.merge({ 'is_collection_ssi' => resource.wrapped_object.collection? })
  end

  private

  def ancestor_collections
    ancestor_collections = []
    curr_gov_collection = resource.wrapped_object.governing_collection

    until curr_gov_collection.nil?
      ancestor_collections << {
        id: curr_gov_collection.alternate_id,
        title: curr_gov_collection.title[0]
      }
      curr_gov_collection = curr_gov_collection.governing_collection
    end

    ancestor_collections
  end

  def collection_relatives_ids
    resource.wrapped_object.collection_relatives.map(&:alternate_id)
  end

  def governing_collection_id
    resource.wrapped_object.governing_collection.alternate_id
  end

  def root_collection_fields
    {
      'root_collection_sim' => [resource.wrapped_object.title.first],
      'root_collection_tesim' => [resource.wrapped_object.title.first],
      'root_collection_id_ssi' => resource.wrapped_object.alternate_id
    }
  end

  def sibling_fields
    return { IS_PRECEDED_BY => [resource.wrapped_object.previous_sibling.alternate_id] } if resource.wrapped_object.previous_sibling.present?

    return { 'is_first_sibling_isi' => 1 } if resource.wrapped_object.is_a?(DRI::EadComponent)
  end

  def sub_collection_fields(ancestor_ids_and_titles)
    ancestor_titles = ancestor_ids_and_titles.map { |collection| collection[:title] }
    ancestor_ids = ancestor_ids_and_titles.map { |collection| collection[:id] }
    {
      'ancestor_title_sim' => ancestor_titles,
      'ancestor_title_tesim' => ancestor_titles,
      'ancestor_id_ssim' => ancestor_ids,
      # governing_id needed for user_group gem!!!
      'governing_id_sim' => [ancestor_ids.first],
      'collection_id_sim' => [ancestor_ids.first],
      'collection_sim' => [ancestor_titles.first],
      'collection_tesim' => [ancestor_titles.first],
      'root_collection_id_ssi' => ancestor_ids.last,
      'root_collection_sim' => [ancestor_titles.last],
      'root_collection_tesim' => [ancestor_titles.last]
    }
  end
end
