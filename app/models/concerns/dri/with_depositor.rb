# frozen_string_literal: true
module DRI
  module WithDepositor
    # Adds metadata about the depositor to the asset and
    # grants edit permissions to the +depositor+
    # @param [String, #user_key] depositor
    def apply_depositor_metadata(depositor)
      depositor_id = depositor.respond_to?(:user_key) ? depositor.user_key : depositor

      self.depositor = depositor_id if respond_to? :depositor
      self.edit_users += [depositor_id] if respond_to? :edit_users

      true
    end
  end
end
