require "faraday/encoding"

Faraday::Encoding.class_eval do  
  def call(environment)
    @app.call(environment).on_complete do |env|
      @env = env
      if encoding = content_charset
        env[:body] = env[:body].dup if env[:body].frozen?
        env[:body].force_encoding(encoding)
      end
    end
  end
end
