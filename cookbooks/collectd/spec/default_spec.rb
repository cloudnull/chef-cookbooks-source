require "spec_helper"

describe "collectd::default" do
  let(:chef_run) { runner.converge "collectd::default" }
  let(:node) { runner.node }
  let(:platform) { { :platform => "ubuntu", :version => "12.04" } }
  let(:results) { [] }
  let(:runner) { ChefSpec::ChefRunner.new(runner_options) }
  let(:runner_options) do
    {
      :cookbook_path => [COOKBOOK_PATH],
      :evaluate_guards => true,
      :step_into => step_into
    }.merge(platform)
  end
  let(:step_into) { [] }

  before do
    node.set["monitoring"]["configs"] = []
  end

  describe "collectd_test::collectd_plugin_definition" do
    let(:chef_run) do
      runner.converge "collectd_test::collectd_plugin_definition"
    end
    let(:step_into) { ["collectd_plugin"] }
    let(:plugin) { "/etc/collectd/plugins/myserver.conf" }
    let(:script) { "/etc/collectd/plugins/python.conf" }


    it "creates a plugin file in collectd plugins directory" do
      chef_run.should create_file(plugin)
      chef_run.should create_file_with_content plugin, 'Plugin "myserver"'
      chef_run.should create_file_with_content plugin, "Foo 1"
    end

    it "creates a plugin file in collectd script plugins directory" do
      chef_run.should create_file(script)
      chef_run.should create_file_with_content script, 'Module "myscript"'
      chef_run.should create_file_with_content script, 'Paths "farp"'
    end
  end

  describe "collectd_test::collectd_threshold_definition" do
    let(:chef_run) do
      runner.converge "collectd_test::collectd_threshold_definition"
    end
    let(:step_into) { ["collectd_threshold"] }
    let(:threshold) { "/etc/collectd/thresholds/myserver.conf" }

    it "creates a plugin file in collectd thresholds directory" do
      chef_run.should create_file(threshold)
      chef_run.should create_file_with_content threshold, "Foo 1"
    end
  end
end
