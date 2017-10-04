require 'active_fedora/noid'

module DRI
  module Noid
    extend ActiveSupport::Concern

    ## This overrides the default behavior, which is to ask Fedora for an id
    # @see ActiveFedora::Persistence.assign_id
    def assign_id
      Mutex.new.synchronize do
        loop do
          pid = service.respond_to?(:minter) ? service.minter.send(:next_id) : service.next_id
                    
          return pid unless DRI::Identifier.exists?(alternate_id: pid)
        end
      end
    end

    def to_param
      noid
    end

    private

      def service
        @service ||= ActiveFedora::Noid::Service.new
      end
  end
end
