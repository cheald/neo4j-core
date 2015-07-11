module Neo4j
  module Server
    class CypherNode < Neo4j::Node
      include Neo4j::Server::NodeModule
      include Neo4j::Core::ActiveEntity

      alias_method :delete, :del
      alias_method :destroy, :del

      def initialize(session, value)
        @session = session

        @neo_id = if value.is_a?(Hash)
                    @props = value[:data]
                    @labels = value[:metadata][:labels].map!(&:to_sym) if value[:metadata]
                    value[:id]
                  else
                    value
                  end
      end

      attr_reader :neo_id

      def inspect
        "CypherNode #{neo_id} (#{object_id})"
      end

      # TODO, needed by neo4j-cypher
      def _java_node
        self
      end

      # (see Neo4j::Node#remove_property)
      def remove_property(key)
        refresh
        @session._query_or_fail(match_start_query.remove(n: key), false)
      end

      # (see Neo4j::Node#set_property)
      def set_property(key, value)
        refresh
        @session._query_or_fail(match_start_query.set(n: {key => value}), false)
      end

      # (see Neo4j::Node#props=)
      def props=(properties)
        refresh
        @session._query_or_fail(match_start_query.set_props(n: properties), false)
        properties
      end

      def remove_properties(properties)
        return if properties.empty?

        refresh
        @session._query_or_fail(match_start_query.remove(n: properties), false, neo_id: neo_id)
      end


      # (see Neo4j::Node#get_property)
      def get_property(key)
        @props ? @props[key.to_sym] : @session._query_or_fail(match_start_query.return(n: key), true)
      end

      def _cypher_label_list(labels_list)
        ':' + labels_list.map { |label| "`#{label}`" }.join(':')
      end
    end
  end
end
