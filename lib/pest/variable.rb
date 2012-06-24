class Pest::Variable
  def self.deserialize(string)
    if string.chomp =~ /^([^\:]+)\:(\w{8}-\w{4}-\w{4}-\w{4}-\w{12})$/
      new :name => $1, :uuid => $2
    end
  end

  attr_reader :name, :uuid

  def initialize(args={})
    @name = args[:name]
    @uuid = args[:uuid] || UUIDTools::UUID.random_create
  end

  def identifier
    "#{name}:#{uuid}"
  end
  alias :serialize :identifier

  def hash
    identifier.hash
  end

  def ==(other)
    other.kind_of?(self.class) and identifier == other.identifier
  end
  alias :eql? :==

  def <=>(other)
    identifier <=> other.identifier
  end
end
