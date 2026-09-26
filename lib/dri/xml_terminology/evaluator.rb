# frozen_string_literal: true

module DRI
  module XmlTerminology
    # Walks a Nokogiri document against a Terminology: term name -> XPath ->
    # matched nodes/values, in both directions (read and write).
    class Evaluator
      def initialize(terminology, nokogiri_doc)
        @terminology = terminology
        @doc = nokogiri_doc
      end

      # Namespaces recomputed each call (not memoized) because writes can add
      # new xmlns declarations to the root mid-session.
      def ns
        @doc.collect_namespaces.transform_keys { |k| k.sub('xmlns:', '') }
                                .merge(@terminology.namespaces) { |_k, doc_uri, _term_uri| doc_uri }
      end

      def values_for(term_name)
        term, ancestors = public_resolve(term_name.to_sym)
        return [] unless term

        top_level_nodes(term, ancestors).map { |n| node_text(n) }
      end

      # Raw matched Nokogiri nodes for a term name, for callers that need
      # the nodes themselves rather than their text values (e.g. `om`'s
      # `find_by_terms`, or SolrIndexer).
      def raw_nodes_for(term_name)
        term, ancestors = public_resolve(term_name.to_sym)
        return [] unless term

        top_level_nodes(term, ancestors)
      end

      def nodes_for(term, context_nodes)
        return proxy_nodes(term, context_nodes) if term.proxy

        xpath = effective_xpath(term)
        context_nodes.flat_map { |ctx| safe_xpath(ctx, xpath) }
      end

      def safe_xpath(node, xpath)
        node.xpath(xpath, ns)
      rescue Nokogiri::XML::XPath::SyntaxError => e
        raise unless e.message.include?('Undefined namespace prefix')

        Nokogiri::XML::NodeSet.new(@doc)
      end

      def effective_xpath(term)
        return term.relative_xpath unless term.ref

        base, attrs = resolve_ref_chain(term)
        Term.new(base.name, path: base.path, namespace_prefix: base.namespace_prefix,
                             attributes: attrs).relative_xpath
      end

      def resolve_ref_chain(term)
        chain = [term]
        chain << resolve(chain.last.ref) while chain.last.ref && chain.last.path.nil?
        merged_attrs = chain.reverse.each_with_object({}) { |t, acc| acc.merge!(t.attributes) }
        [chain.last, merged_attrs]
      end

      def children_of(term)
        return children_of(resolve(term.proxy.last)) if term.proxy
        return term.children unless term.children.empty? && term.ref

        children_of(resolve(term.ref))
      end

      def node_at(term_name, index)
        term, ancestors = public_resolve(term_name.to_sym)
        return NodeScope.new(self, term, nil) unless term

        matched = top_level_nodes(term, ancestors)
        NodeScope.new(self, term, matched[index])
      end

      def node_text(node)
        node.is_a?(Nokogiri::XML::Attr) ? node.value : node.text
      end

      def set_values(term_name, values)
        values = Array(values).map(&:to_s)
        name = term_name.to_sym
        top_level_term = @terminology.terms[name]

        if top_level_term&.proxy
          write_via_proxy(top_level_term, values)
          return values
        end

        term, ancestors = resolve_with_ancestors(name)
        raise ArgumentError, "Unknown term #{term_name}" unless term
        if term.proxy
          raise NotImplementedError, "Writing through nested proxy term '#{term.name}' isn't supported yet"
        end

        if term.path.is_a?(String) && term.path.match?(/\[\d+\]/)
          raise NotImplementedError, "Writing positional-path term '#{term.name}' (path: #{term.path.inspect}) isn't supported yet"
        end
        if ancestors.size > 1
          raise NotImplementedError, "Writing nested term '#{term.name}' more than one level deep isn't supported yet"
        end

        parent_context = walk_term_chain_for_write(ancestors)
        sync_values(term, parent_context, values)
        values
      end

      private

      # Read-preference name resolution: top-level definition wins over a
      # same-named nested one (see the comment above `values_for`).
      def public_resolve(name)
        @terminology.terms[name] ? [@terminology.terms[name], []] : resolve_with_ancestors(name)
      end

      def write_via_proxy(proxy_term, values)
        *ancestor_steps, last_step = proxy_term.proxy
        resolved_ancestors = resolve_proxy_steps(ancestor_steps)
        parent_context = walk_term_chain_for_write(resolved_ancestors)

        final_term = resolve_step(last_step, resolved_ancestors.last)
        raise ArgumentError, "Unknown proxy target '#{last_step}'" unless final_term

        sync_values(final_term, parent_context, values)
      end

      # Resolves a proxy chain's step names into Terms, each in the CONTEXT
      # of the previous step rather than by global name lookup.
      #
      # This matters because the same name legitimately exists at multiple
      # places in a terminology with DIFFERENT definitions.
      def resolve_proxy_steps(steps)
        context_term = nil
        steps.map do |step|
          term = resolve_step(step, context_term)
          raise ArgumentError, "Unknown proxy step '#{step}'" unless term

          context_term = term
        end
      end

      # One step: prefer a child of the previous step (walking through its
      # ref/proxy indirection via children_of), else fall back to a global
      # lookup (correct for the first step, and for chains that jump).
      def resolve_step(step, context_term)
        name = step.to_sym
        if context_term
          child = children_of(context_term)[name]
          return child if child
        end
        resolve(name)
      end

      # Walks a chain of already-resolved terms the same way a `proxy` read
      # does: the first term is unanchored ("//"), every term after is a
      # plain relative descent from what the previous one matched. This is
      # confirmed real om behavior, not just a read-side convenience -- real
      # om's write path (`term_values_append`'s `find_by_terms(*parent_select)`)
      # uses the exact same absolute-xpath resolution for parent lookups as
      # reads do, so writes need the same unanchored-first-hop rule too. An
      # empty chain means "the document root" itself.
      #
      # READ-ONLY version -- never creates anything. See
      # `walk_term_chain_for_write` for the write-path variant that can
      # auto-create a missing SIMPLE intermediate ancestor (confirmed real
      # need: e.g. `desc_physdesc_note`'s proxy chain includes
      # `physical_description`, which may not exist yet on a record that's
      # never had physical-description metadata set).
      def walk_term_chain(terms)
        return [@doc.root] if terms.empty?

        first, *rest = terms
        context = unanchored_nodes_for(first, @doc)
        rest.each { |t| context = nodes_for(t, context) }
        context
      end

      # Same traversal as `walk_term_chain`, but for writes: if a step's
      # search comes up empty, create it -- PROVIDED it's a "simple" term
      # (see `simple_term?`). A term with a compound/predicate-heavy path
      # (like `role_cre`'s multi-attribute name/role/roleTerm structure)
      # describes a whole structural pattern, not one element, and can't be
      # synthesized generically -- that raises instead of guessing, with a
      # message pointing at what to do instead (a dedicated builder method,
      # e.g. real mods.rb's own `add_role`, not the generic writer).
      def walk_term_chain_for_write(terms)
        return [@doc.root] if terms.empty?

        first, *rest = terms
        context = unanchored_nodes_for(first, @doc)
        context = auto_create_ancestor(first, [@doc.root]) if context.empty?
        rest.each do |t|
          next_context = nodes_for(t, context)
          next_context = auto_create_ancestor(t, context) if next_context.empty?
          context = next_context
        end
        context
      end

      def auto_create_ancestor(term, parent_context)
        if parent_context.empty?
          raise "Cannot create missing ancestor '#{term.name}' -- no parent node to attach it to"
        end

        # Resolve through any ref indirection to find the concrete element
        # this term actually describes, then check THAT for simplicity --
        # a term like `control_access/subject` is `ref:`-based with a nil
        # path of its own, but resolves to a perfectly simple element.
        creation_term, attrs = term.ref ? resolve_ref_chain(term) : [term, term.attributes]
        unless simple_term?(creation_term)
          raise "Cannot write '#{term.name}' -- an intermediate step in its path/proxy chain " \
                "(path: #{creation_term.path.inspect}) doesn't exist yet, and its path is too " \
                "complex (compound XPath or proxy) to synthesize automatically. Set it explicitly " \
                "first, or use a dedicated builder method instead of the generic writer."
        end

        node = node_builder.create_element(creation_term, '', attrs)
        parent_context.first.add_child(node)
        [node]
      end

      # A term whose shape is simple enough to safely auto-create: a bare or
      # single-segment element path, no compound/unioned/positional XPath,
      # not an attribute. NOTE this is called on an already-resolved
      # *creation term* (post-`resolve_ref_chain`) at the sync_values call
      # site, so `ref` itself isn't disqualifying there -- what matters is
      # whether the thing we'd actually build is one plain element. A
      # `proxy` term never describes a single element of its own, so it is.
      def simple_term?(term)
        return false if term.proxy || term.attribute_term?

        term.path.nil? || (term.path.is_a?(String) && !term.path.match?(%r{[/|\[]}))
      end

      # The shared core: `existing` is the term's matched nodes across ALL
      # of `parent_context` combined into one flat, positionally-ordered
      # list (matching real om's model) -- update in place / remove excess.
      # A genuinely new value goes only into `parent_context.first`.
      # Works for both element and attribute terms unmodified: Nokogiri's
      # Attr nodes support `.content=` and `.remove` exactly like elements
      # (confirmed empirically), so no separate attribute-handling branch
      # is needed here, matching how real om's DynamicNode doesn't need one
      # either.
      def sync_values(term, parent_context, values)
        # For a compound-path term, existing_nodes_for searches the whole
        # document (see its comment), so asking each parent separately
        # would return the same nodes repeatedly -- ask once in that case.
        creation_term_probe = term.ref ? resolve_ref_chain(term).first : term
        existing = if simple_term?(creation_term_probe)
                     parent_context.flat_map { |parent| existing_nodes_for(term, parent) }
                   else
                     existing_nodes_for(term, parent_context.first)
                   end
        creation_term, attrs_for_create = term.ref ? resolve_ref_chain(term) : [term, term.attributes]

        # Updating an EXISTING match (`existing[i].content = val`) is always
        # well-defined, regardless of how complex the term's path is -- it's
        # just "find this node, change its text". CREATING a brand-new node
        # is only well-defined when the term's own shape is simple; a
        # compound path (like `role_cre`'s multi-attribute name/role/
        # roleTerm structure) describes a whole structural pattern, and
        # naively building "one element" from it produces invalid XML
        # (confirmed: build_element_name on such a path yields a slash-
        # containing tag name like "mods/mods:name"). Raise clearly instead
        # of silently corrupting the document -- confirmed real case:
        # mods.rb's `creator=` writes `role_cre` directly rather than going
        # through a dedicated builder like `add_role` the way `contributor=`
        # does; that inconsistency belongs in app-level code, not something
        # this engine should paper over by guessing at a shape.
        if values.size > existing.size && !term.attribute_term? && !simple_term?(creation_term)
          raise "Cannot create a new '#{term.name}' node -- its path (#{creation_term.path.inspect}) " \
                "is too complex (compound XPath) to synthesize automatically. This term can only be " \
                "UPDATED if a matching node already exists, not created from scratch this way -- use " \
                "a dedicated builder method (e.g. a real add_role/add_* style method) instead."
        end

        values.each_with_index do |val, i|
          if existing[i]
            existing[i].content = val
          elsif term.attribute_term?
            parent_context.first[term.local_name] = val
          else
            parent_context.first.add_child(node_builder.create_element(creation_term, val, attrs_for_create))
          end
        end

        existing[values.length..].to_a.each(&:remove)
      end

      # Confirmed against the real om source: only the FIRST term in any
      # chain is ever unanchored ("//"), because every entry directly in
      # `@terminology.terms` is structurally top-level (parent=nil) in the
      # real OM sense -- including ones that happen to be someone else's
      # ancestor for a deeper nested term (e.g. `:role` is top-level, but
      # `role_code` is nested under it). Every hop AFTER the first is a
      # plain relative descent from whatever the previous hop matched.
      # `proxy` terms are the one exception: they anchor at the real root
      # element instead (see NamedTermProxy#proxied_term in real om).
      def top_level_nodes(term, ancestors)
        return nodes_for(term, safe_xpath(@doc, @terminology.root_path)) if term.proxy && ancestors.empty?

        walk_term_chain(ancestors + [term])
      end

      # Same as `nodes_for`, but prefixes the xpath with `//` so the search
      # is unanchored (document-wide) rather than relative to a context node.
      def unanchored_nodes_for(term, doc)
        doc.xpath("//#{effective_xpath(term)}", ns)
      rescue Nokogiri::XML::XPath::SyntaxError => e
        raise unless e.message.include?('Undefined namespace prefix')

        Nokogiri::XML::NodeSet.new(@doc)
      end

      # Finds a term's already-existing nodes beneath a given parent.
      #
      # A term with a COMPOUND path (e.g. role_cre's
      # 'mods/mods:name[...]/mods:namePart[...]') is written to be matched
      # unanchored, exactly as reads do it (see `unanchored_nodes_for` and
      # the big READING comment above) -- evaluating it as a plain relative
      # descent from the parent finds nothing, which would then wrongly
      # send the caller down the "create a new node" branch and raise.
      # Match the read path's anchoring rule here so an UPDATE of such a
      # term works even though creating one from scratch legitimately
      # can't. Confirmed real case: mods.rb's `creator=` -> `role_cre=`.
      def existing_nodes_for(term, parent)
        creation_term = term.ref ? resolve_ref_chain(term).first : term
        return unanchored_nodes_for(term, @doc) unless simple_term?(creation_term)

        safe_xpath(parent, effective_xpath(term))
      end

      def node_builder
        @node_builder ||= NodeBuilder.new(@terminology, @doc)
      end

      # ----- shared helpers -------------------------------------------------

      def resolve(name) = resolve_with_ancestors(name.to_sym).first

      def resolve_with_ancestors(name, terms = @terminology.terms, ancestors = [])
        terms.each_value do |t|
          return [t, ancestors] if t.name == name

          found, found_ancestors = resolve_with_ancestors(name, t.children, ancestors + [t])
          return [found, found_ancestors] if found
        end
        [nil, []]
      end

      def proxy_nodes(term, context_nodes)
        # Each step is resolved in the CONTEXT of the previous one, not by
        # global name lookup -- see resolve_proxy_steps for why (the same
        # name can exist at multiple places in a terminology with different
        # attribute filters, e.g. top-level `:name` vs `control_access/name`
        # with `role="subject"`).
        resolved = resolve_proxy_steps(term.proxy)
        first, *rest = resolved
        # The first step resolves exactly like an ordinary top-level term
        # (unanchored `//` search) -- see the comment in TermBuilder#root
        # for why this is correct rather than a special case.
        nodes = unanchored_nodes_for(first, @doc)
        rest.each { |step_term| nodes = nodes_for(step_term, nodes) }
        nodes
      end
    end
  end
end