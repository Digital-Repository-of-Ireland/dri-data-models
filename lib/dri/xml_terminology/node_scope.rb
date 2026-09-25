# frozen_string_literal: true

module DRI
  module XmlTerminology
    class NodeScope
      def initialize(evaluator, parent_term, node)
        @evaluator = evaluator
        @parent_term = parent_term
        @node = node
      end

      # The node's own text/attribute value, e.g. `subject(0).value`.
      def value
        @node ? @evaluator.node_text(@node) : nil
      end

      def present? = !@node.nil?

      def method_missing(name, *_args)
        return [] unless @node
        return super unless @parent_term

        child_term = @evaluator.children_of(@parent_term)[name.to_sym]
        return super unless child_term

        @evaluator.nodes_for(child_term, [@node]).map { |n| @evaluator.node_text(n) }
      end

      def respond_to_missing?(name, include_private = false)
        (@parent_term && @evaluator.children_of(@parent_term).key?(name.to_sym)) || super
      end
    end
  end
end