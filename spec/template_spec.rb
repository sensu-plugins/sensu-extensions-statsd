require File.join(File.dirname(__FILE__), "helpers")
require "sensu/extensions/template"

describe "Sensu::Extension::Template" do
  include Helpers

  before do
    @extension = Sensu::Extension::Template.new
  end

  it "can run" do
    @extension.safe_run(event_template) do |output, status|
      expect(output).to eq("template")
      expect(status).to eq(0)
    end
  end
end
