# frozen_string_literal: true
class SystemIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    {
      id: resource.alternate_id,
      resource_id_isi: resource.wrapped_object.id,
      alternate_id: resource.alternate_id,
      'active_fedora_model_ssi' => resource.wrapped_object.class.to_s,
      'has_model_ssim' => resource.wrapped_object.has_model,
      'system_create_dtsi' => c_time,
      'system_modified_dtsi' => m_time
    }
  end

  private
    def c_time
      c_time = resource.create_date.present? ? resource.create_date : DateTime.now
      c_time = DateTime.parse(c_time) unless c_time.is_a?(DateTime)
      c_time
    end

    def m_time
      m_time = resource.modified_date.present? ? resource.modified_date : DateTime.now
      m_time = DateTime.parse(m_time) unless m_time.is_a?(DateTime)
      m_time
    end
end
