require 'spec_helper'
require 'rails/generators'
# require 'rails/generators/scripts/generate'

describe 'ActsAsGeocodableGenerator' do

  before do
    FileUtils.mkdir_p(fake_rails_root)
    @original_files = file_list
  end

  after do
    FileUtils.rm_r(fake_rails_root)
  end

  # it "should generate the correct file" do
  #   pending    
  #   Rails::Generators.invoke "acts_as_geocodable", :destination => fake_rails_root
  #   new_file = (file_list - @original_files).first
  #   File.basename(new_file).should =~ /add_geocodable_tables/
  # end

  private
    def fake_rails_root
      File.join(File.dirname(__FILE__), 'rails_root')
    end

    def file_list
      Dir.glob(File.join(fake_rails_root, "*"))
    end
end