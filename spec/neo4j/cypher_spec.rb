require 'spec_helper'

class FooIndex
  extend Neo4j::Core::Index::ClassMethods
  include Neo4j::Core::Index

  self.node_indexer do
    index_names :exact => 'fooindex_exact', :fulltext => 'fooindex_fulltext'
    trigger_on :myindex => true
  end

  index :name
  index :desc, :type => :fulltext
end


describe "Neo4j::Cypher" do
  describe "DSL   { start n = node(3); match n <=> :x; ret :x }" do
    it { Proc.new { start n = node(3); match n <=> :x; ret :x }.should be_cypher("START n0=node(3) MATCH (n0)--(x) RETURN x") }
  end


  describe "DSL   { x = node; n = node(3); match n <=> x; ret x }" do
    it { Proc.new { x = node; n = node(3); match n <=> x; ret x }.should be_cypher("START n0=node(3) MATCH (n0)--(v0) RETURN v0") }
  end

  describe "DSL   { x = node; n = node(3); match n <=> x; ret x[:name] }" do
    it { Proc.new { x = node; n = node(3); match n <=> x; ret x[:name] }.should be_cypher("START n0=node(3) MATCH (n0)--(v0) RETURN v0.name") }
  end


  describe "DSL   { n = node(3).as(:n); n <=> node.as(:x); :x }" do
    it { Proc.new { n = node(3).as(:n); n <=> node.as(:x); :x }.should be_cypher("START n=node(3) MATCH (n)--(x) RETURN x") }
  end


  describe "DSL   { node(3) <=> node(:x); :x }" do
    it { Proc.new { node(3) <=> node(:x); :x }.should be_cypher("START n0=node(3) MATCH (n0)--(x) RETURN x") }
  end

  describe "DSL   { node(3) <=> 'foo'; :foo }" do
    it { Proc.new { node(3) <=> 'foo'; :foo }.should be_cypher("START n0=node(3) MATCH (n0)--(foo) RETURN foo") }
  end

  describe "DSL   { r = rel(0); ret r }" do
    it { Proc.new { r = rel(0); ret r }.should be_cypher("START r0=relationship(0) RETURN r0") }
  end

  describe "DSL   { n = node(1, 2, 3); ret n }" do
    it { Proc.new { n = node(1, 2, 3); ret n }.should be_cypher("START n0=node(1,2,3) RETURN n0") }
  end

  describe %q[DSL   query(FooIndex, "name:A")] do
    it { Proc.new { query(FooIndex, "name:A") }.should be_cypher(%q[START n0=node:fooindex_exact(name:A) RETURN n0]) }
  end

  describe %q[DSL   query(FooIndex, "name:A", :fulltext)] do
    it { Proc.new { query(FooIndex, "name:A", :fulltext) }.should be_cypher(%q[START n0=node:fooindex_fulltext(name:A) RETURN n0]) }
  end

  describe %q[DSL   lookup(FooIndex, "name", "A")] do
    it { Proc.new { lookup(FooIndex, "name", "A") }.should be_cypher(%q[START n0=node:fooindex_exact(name="A") RETURN n0]) }
  end

  describe %q[DSL   lookup(FooIndex, "desc", "A")] do
    it { Proc.new { lookup(FooIndex, "desc", "A") }.should be_cypher(%q[START n0=node:fooindex_fulltext(desc="A") RETURN n0]) }
  end

  describe "DSL   { a = node(1); b=node(2); ret(a, b) }" do
    it { Proc.new { a = node(1); b=node(2); ret(a, b) }.should be_cypher(%q[START n0=node(1),n1=node(2) RETURN n0,n1]) }
  end

  describe "DSL   { [node(1), node(2)] }" do
    it { Proc.new { [node(1), node(2)] }.should be_cypher(%q[START n0=node(1),n1=node(2) RETURN n0,n1]) }
  end

  describe "DSL   { node(3) >> :x; :x }" do
    it { Proc.new { node(3) >> :x; :x }.should be_cypher("START n0=node(3) MATCH (n0)-->(x) RETURN x") }
  end

  describe "DSL   { node(3) > :r > :x; :r }" do
    it { Proc.new { node(3) > :r > :x; :r }.should be_cypher("START n0=node(3) MATCH (n0)-[r]->(x) RETURN r") }
  end

  describe "DSL   { node(3) > 'r:friends' > :x; :r }" do
    it { Proc.new { node(3) > 'r:friends' > :x; :r }.should be_cypher("START n0=node(3) MATCH (n0)-[r:friends]->(x) RETURN r") }
  end

  describe "DSL   { r = rel('r:friends').as(:r); node(3) > r > :x; r }" do
    it { Proc.new { r = rel('r:friends').as(:r); node(3) > r > :x; r }.should be_cypher("START n0=node(3) MATCH (n0)-[r:friends]->(x) RETURN r") }
  end

  describe "DSL   { r = rel('r:friends'); node(3) > r > :x; r }" do
    it { Proc.new { r = rel('r:friends'); node(3) > r > :x; r }.should be_cypher("START n0=node(3) MATCH (n0)-[r:friends]->(x) RETURN r") }
  end

  describe "DSL   { r = rel('r?:friends'); node(3) > r > :x; r }" do
    it { Proc.new { r = rel('r?:friends'); node(3) > r > :x; r }.should be_cypher("START n0=node(3) MATCH (n0)-[r?:friends]->(x) RETURN r") }
  end

  describe "DSL   { node(3) > rel('?') > :x; :x }" do
    it { Proc.new { node(3) > rel('?') > :x; :x }.should be_cypher("START n0=node(3) MATCH (n0)-[?]->(x) RETURN x") }
  end

  describe "DSL   { node(3) > rel('r?') > :x; :x }" do
    it { Proc.new { node(3) > rel('r?') > :x; :x }.should be_cypher("START n0=node(3) MATCH (n0)-[r?]->(x) RETURN x") }
  end

  describe "DSL   { node(3) > rel('r?') > 'bla'; :x }" do
    it { Proc.new { node(3) > rel('r?') > 'bla'; :x }.should be_cypher("START n0=node(3) MATCH (n0)-[r?]->(bla) RETURN x") }
  end

  describe "DSL   { r=rel('?'); node(3) > r > :x; r }" do
    it do
      pending "this should raise an error since it's an illegal cypher query"
      Proc.new { r=rel('?'); node(3) > r > :x; r }.should be_cypher("START n0=node(3) MATCH (n0)-[r?]->(x) RETURN x")
    end
  end

  describe %{n=node(3,1).as(:n); where(%q[n.age < 30 and n.name = "Tobias") or not(n.name = "Tobias"')]} do
    it { Proc.new { n=node(3, 1).as(:n); where(%q[(n.age < 30 and n.name = "Tobias") or not(n.name = "Tobias")]); ret n }.should be_cypher(%q[START n=node(3,1) WHERE (n.age < 30 and n.name = "Tobias") or not(n.name = "Tobias") RETURN n]) }
  end

  describe %{n=node(3,1); where n[:age] < 30; ret n} do
    it { Proc.new { n=node(3, 1); where n[:age] < 30; ret n }.should be_cypher(%q[START n0=node(3,1) WHERE (n0.age < 30) RETURN n0]) }
  end

  describe %{n=node(3, 1); where((n[:age] < 30) & ((n[:name] == 'foo') | (n[:size] > n[:age]))); ret n} do
    it { Proc.new { n=node(3, 1); where((n[:age] < 30) & ((n[:name] == 'foo') | (n[:size] > n[:age]))); ret n }.should be_cypher(%q[START n0=node(3,1) WHERE ((n0.age < 30) and ((n0.name = "foo") or (n0.size > n0.age))) RETURN n0]) }
  end

  describe %{ n=node(3).as(:n); where((n[:desc] =~ /.\d+/) ); ret n} do
    it { Proc.new { n=node(3).as(:n); where(n[:desc] =~ /.\d+/); ret n }.should be_cypher(%q[START n=node(3) WHERE (n.desc =~ /.\d+/) RETURN n]) }
  end

  describe %{ n=node(3).as(:n); where((n[:desc] =~ ".d+") ); ret n} do
    it { Proc.new { n=node(3).as(:n); where(n[:desc] =~ ".d+"); ret n }.should be_cypher(%q[START n=node(3) WHERE (n.desc =~ /.d+/) RETURN n]) }
  end

  describe %{ n=node(3).as(:n); where((n[:desc] == /.\d+/) ); ret n} do
    it { Proc.new { n=node(3).as(:n); where(n[:desc] == /.\d+/); ret n }.should be_cypher(%q[START n=node(3) WHERE (n.desc =~ /.\d+/) RETURN n]) }
  end

  describe %{n=node(3,4); n[:desc] == "hej"; n} do
    it { Proc.new { n=node(3, 4); n[:desc] == "hej"; n }.should be_cypher(%q[START n0=node(3,4) WHERE (n0.desc = "hej") RETURN n0]) }
  end

  describe %{node(3,4) <=> :x; node(:x)[:desc] =~ /hej/; :x} do
    it { Proc.new { node(3, 4) <=> :x; node(:x)[:desc] =~ /hej/; :x }.should be_cypher(%q[START n0=node(3,4) MATCH (n0)--(x) WHERE (x.desc =~ /hej/) RETURN x]) }
  end

  describe       %{ a, x=node(1), node(2); p = shortest_path { a > '?*' > x }; p } do
    it { Proc.new { a, x=node(1), node(2); p = shortest_path { a > '?*' > x }; p }.should be_cypher(%{START n0=node(1),n1=node(2) MATCH m3 = shortestPath((n0)-[?*]->(n1)) RETURN m3}) }
  end

  describe %{shortest_path{node(1) > '?*' > node(2)}} do
    it { Proc.new { shortest_path{node(1) > '?*' > node(2)} }.should be_cypher(%{START n0=node(1),n2=node(2) MATCH m2 = shortestPath((n0)-[?*]->(n2)) RETURN m2}) }
  end

  #
  ##                          (a)-[:KNOWS]->(b)-[:KNOWS]->(c), (a)-[:BLOCKS]-(d)-[:KNOWS]-(c)
  #it { Proc.new{ a = node(1); a > :knows > :c > :knows > :c; a > :blocks > :d > :knows > :c } }
  if RUBY_VERSION > "1.9.0"
    # the ! operator is only available in Ruby 1.9.x
    describe %{n=node(3).as(:n); where(!(n[:desc] =~ ".\d+")); ret n} do
      it { Proc.new { n=node(3).as(:n); where(!(n[:desc] =~ ".\d+")); ret n }.should be_cypher(%q[START n=node(3) WHERE not(n.desc =~ /.d+/) RETURN n]) }
    end
  end

end