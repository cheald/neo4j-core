module Neo4j
  module Server
    module NodeModule
      include Neo4j::Server::Resource
      include Neo4j::Core::CypherTranslator
      include Neo4j::Server::CypherRels

      LABEL_MAP = {}

      attr_reader :neo_id

      def self.included(other)
        return unless other.respond_to?(:mapped_label_names)
        LABEL_MAP[other.mapped_label_names.map(&:to_s)] = other
      end

      # (see Neo4j::Node#props)
      def props
        if @props
          @props
        else
          hash = current_session._query_entity_data(match_start_query.return(:n), nil)
          @props = Hash[hash[:data].to_a]
        end
      end

      # (see Neo4j::Node#update_props)
      def update_props(properties)
        refresh
        return if properties.empty?

        current_session._query_or_fail(match_start_query.set(n: properties), false)

        properties
      end

      def refresh
        @props = nil
      end

      # (see Neo4j::Node#del)
      def del
        query = match_start_query.optional_match('n-[r]-()').delete(:n, :r)
        current_session._query_or_fail(query, false)
      end

      # (see Neo4j::Node#exist?)
      def exist?
        !current_session._query(match_start_query.return(n: :neo_id)).data.empty?
      end

      # (see Neo4j::Node#labels)
      def labels
        @labels ||= current_session._query_or_fail(match_start_query.return('labels(n) AS labels'), true).map(&:to_sym)
      end

      def add_label(*new_labels)
        current_session._query_or_fail(match_start_query.set(n: new_labels), false)
        new_labels.each { |label| labels << label }
      end

      def remove_label(*target_labels)
        current_session._query_or_fail(match_start_query.remove(n: target_labels), false)
        target_labels.each { |label| labels.delete(label) } unless labels.nil?
      end

      private

      def match_start_query(identifier = :n)
        current_session.query.match(identifier).where(identifier => {neo_id: neo_id}).with(identifier)
      end

      def current_session
        @session || Neo4j::Session.current
      end
    end
  end
end
