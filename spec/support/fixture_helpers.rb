module FixtureHelpers
  def fixture(file)
    File.new(File.join(File.dirname(__FILE__), '../fixtures', file))
  end
end
