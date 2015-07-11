module Neo4j
  module Server
    module CypherRels
      # (see Neo4j::Node#create_rel)
      def create_rel(type, other_node, props = nil)
        q = Neo4j::Session.current.query.match(:a, :b).where(a: {neo_id: neo_id}, b: {neo_id: other_node.neo_id})
            .create("(a)-[r:`#{type}`]->(b)").break.set(r: props).return(r: :neo_id)

        id = Neo4j::Session.current._query_or_fail(q, true)

        CypherRelationship.new(Neo4j::Session.current, type: type, data: props, start: neo_id, end: other_node.neo_id, id: id)
      end

      def set_label(*label_names)
        labels_to_add = label_names.map(&:to_sym).uniq
        labels_to_remove = labels - label_names

        common_labels = labels & labels_to_add
        labels_to_add -= common_labels
        labels_to_remove -= common_labels

        mod_labels(labels_to_add, labels_to_remove)
      end

      # (see Neo4j::Node#node)
      def node(match = {})
        ensure_single_relationship { match(CypherNode, 'p as result LIMIT 2', match) }
      end

      # (see Neo4j::Node#rel)
      def rel(match = {})
        ensure_single_relationship { match(CypherRelationship, 'r as result LIMIT 2', match) }
      end

      # (see Neo4j::Node#rel?)
      def rel?(match = {})
        result = match(CypherRelationship, 'r as result', match)
        !!result.first
      end

      # (see Neo4j::Node#nodes)
      def nodes(match = {})
        match(CypherNode, 'p as result', match)
      end

      # (see Neo4j::Node#rels)
      def rels(match = {dir: :both})
        match(CypherRelationship, 'r as result', match)
      end

      # @private
      def match(clazz, returns, match = {})
        ::Neo4j::Node.validate_match!(match)

        query = self.query
        query = query.match(:p).where(p: {neo_id: match[:between].neo_id}) if match[:between]
        r = query.match("(n)#{relationship_arrow(match)}(p)").return(returns).response
        r.raise_error if r.error?
        r.to_node_enumeration.map(&:result)
      end

      def query(identifier = :n)
        Neo4j::Session.current.query.match(identifier).where(identifier => {neo_id: neo_id})
      end

      private

      def mod_labels(labels_to_add, labels_to_remove)
        q = match_start_query
        q = q.remove(n: labels_to_remove) unless labels_to_remove.empty?
        q = q.set(n: labels_to_add) unless labels_to_add.empty?

        Neo4j::Session.current._query_or_fail(q, false) unless (labels_to_add + labels_to_remove).empty?
      end

      def relationship_arrow(match)
        rel_spec = match[:type] ? "[r:`#{match[:type]}`]" : '[r]'

        case match[:dir] || :both
        when :outgoing then "-#{rel_spec}->"
        when :incoming then "<-#{rel_spec}-"
        when :both then "-#{rel_spec}-"
        else
          fail "Invalid value for relationship_arrow direction: #{match[:dir].inspect}"
        end
      end

      def ensure_single_relationship
        fail 'Expected a block' unless block_given?
        result = yield
        fail "Expected to only find one relationship from node #{neo_id} matching #{match.inspect} but found #{result.count}" if result.count > 1
        result.first
      end
    end
  end
end
