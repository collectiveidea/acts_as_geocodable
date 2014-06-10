require "spec_helper"
require "rails/generators"

describe "ActsAsGeocodableGenerator" do
  before do
    FileUtils.mkdir_p(fake_rails_root)
    @original_files = file_list
  end

  after do
    FileUtils.rm_r(fake_rails_root)
  end

  private

  def fake_rails_root
    File.join(File.dirname(__FILE__), "rails_root")
  end

  def file_list
    Dir.glob(File.join(fake_rails_root, "*"))
  end
end
