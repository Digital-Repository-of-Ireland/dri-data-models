# frozen_string_literal: true
require 'noid-rails'

module DRI
  module Noid
    extend ActiveSupport::Concern

    def assign_id
      service.mint
    end

    def to_param
      alternate_id
    end

    private

    def service
      @service ||= ::Noid::Rails::Service.new
    end
  end
end
