# frozen_string_literal: true

module DRI
  module XmlTerminology
    # The `t` object terminology files call `t.foo(...)` on. Mimics
    # OM's DSL.
    class TermBuilder
      def initialize(terminology)
        @terminology = terminology
        @parent_stack = []
      end

      def root(opts = {})
        path = opts[:path] || '*'

        # Register namespaces FIRST, so path/term construction below can
        # already see whether a default (bare `xmlns:`) namespace applies.
        # `oxns` is om's own synthetic alias for "the root's default
        # namespace" (confirmed from om's Terminology::Builder#root source)
        # -- used below so any term that doesn't specify its own
        # `namespace_prefix` still resolves against the right namespace,
        # rather than being treated as unprefixed/no-namespace.
        opts.each do |k, v|
          if k == :xmlns
            @terminology.namespaces['oxns'] = v
          elsif k.to_s.start_with?('xmlns:')
            @terminology.namespaces[k.to_s.sub('xmlns:', '')] = v
          end
        end

        effective_prefix = opts[:namespace_prefix] || (@terminology.namespaces['oxns'] && 'oxns')

        full_path = if path == '*'
                      '/*'
                    elsif effective_prefix
                      "/#{effective_prefix}:#{path}"
                    else
                      "/#{path}"
                    end
        @terminology.instance_variable_set(:@root_path, full_path)

        unless path == '*'
          implicit = Term.new(path.to_sym, path: path, namespace_prefix: effective_prefix)
          @terminology.terms[path.to_sym] ||= implicit
        end
      end

      # Registers a namespace prefix -> URI, needed so we can declare it on
      # the document root the first time we create an element/attribute that
      # uses it. Reading doesn't need this (Nokogiri gives us the document's
      # already-declared namespaces); writing into a brand-new document does.
      def namespace(prefix, uri)
        @terminology.namespaces[prefix.to_s] = uri
      end

      def method_missing(name, opts = {}, &block)
        opts = opts.dup
        # if the terminology has a default
        # (bare `xmlns:`) namespace and this term doesn't specify its own
        # prefix, it means "the default namespace", not "no namespace".
        # Harmless no-op for attribute terms (`relative_xpath` never
        # consults namespace_prefix for those).
        if opts[:namespace_prefix].nil? && @terminology.namespaces['oxns']
          opts[:namespace_prefix] = 'oxns'
        end

        term = Term.new(name, opts)

        if (parent = @parent_stack.last)
          parent.children[term.name] = term
        else
          @terminology.terms[term.name] = term
        end

        if block_given?
          @parent_stack.push(term)
          instance_eval(&block)
          @parent_stack.pop
        end

        term
      end

      def respond_to_missing?(*) = true
    end
  end
end