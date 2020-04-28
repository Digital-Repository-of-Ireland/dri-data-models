module DriDataModels

  def solr_config
    load_solr_config
    @solr_config
  end

  def load_solr_config
    return @solr_config unless @solr_config.blank?

    begin
      config_erb = ERB.new(IO.read(solr_config_path)).result(binding)
    rescue StandardError
      raise("solr.yml was found, but could not be parsed with ERB. \n#{$ERROR_INFO.inspect}")
    end

    begin
      solr_yml = YAML.safe_load(config_erb, [], [], true) # allow YAML aliases
    rescue StandardError
      raise("solr.yml was found, but could not be parsed.\n")
    end

    config = solr_yml.symbolize_keys
    config = config[Rails.env.to_sym].symbolize_keys
    @solr_config = { url: solr_url(config) }
  end

  # Given the solr_config that's been loaded for this environment,
  # determine which solr url to use
  def solr_url(solr_config)
    return solr_config[:url] if solr_config.key?(:url)
    return solr_config['url'] if solr_config.key?('url')
    if @index_full_text == true && solr_config.key?(:fulltext) && solr_config[:fulltext].key?('url')
      solr_config[:fulltext]['url']
    elsif solr_config.key?(:default) && solr_config[:default].key?('url')
      solr_config[:default]['url']
    else
      raise URI::InvalidURIError
    end
  end

  def solr_config_path
    Rails.root.join("config", "solr.yml")
  end

  module_function :solr_config, :load_solr_config, :solr_config_path, :solr_url
end
