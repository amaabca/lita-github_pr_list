require 'json'

describe Lita::Handlers::GithubPrList, lita_handler: true do
  before :each do
    Lita.config.handlers.github_pr_list.github_organization = 'aaaaaabbbbbbcccccc'
    Lita.config.handlers.github_pr_list.github_access_token = 'wafflesausages111111'
  end

  let(:agent) do
    Sawyer::Agent.new "http://example.com/a/" do |conn|
      conn.builder.handlers.delete(Faraday::Adapter::NetHttp)
      conn.adapter :test, Faraday::Adapter::Test::Stubs.new
    end
  end

  def sawyer_resource_array(file_path)
    resources = []
    JSON.parse(File.read(file_path)).each do |i|
      resources << Sawyer::Resource.new(agent, i)
    end

    resources
  end

  let(:one_issue) { sawyer_resource_array("spec/fixtures/one_org_issue_list.json") }
  let(:two_issues) { sawyer_resource_array("spec/fixtures/two_org_issue_list.json") }
  let(:issue_comments_passed) { sawyer_resource_array("spec/fixtures/issue_comments_passed.json") }
  let(:issue_comments_passed_design) { sawyer_resource_array("spec/fixtures/issue_comments_passed_design.json") }
  let(:issue_comments_failed) { sawyer_resource_array("spec/fixtures/issue_comments_failed.json") }
  let(:issue_comments_in_review) { sawyer_resource_array("spec/fixtures/issue_comments_in_review.json") }
  let(:issue_comments_fixed) { sawyer_resource_array("spec/fixtures/issue_comments_fixed.json") }
  let(:issue_comments_new) { sawyer_resource_array("spec/fixtures/issue_comments_new.json") }
  let(:gitlab_merge_request) { OpenStruct.new(body: OpenStruct.new(read: File.read("spec/fixtures/gitlab_merge_request.json"))) }
  let(:gitlab_request_closed) { OpenStruct.new(body: OpenStruct.new(read: File.read("spec/fixtures/gitlab_request_closed.json"))) }

  it { is_expected.to route_command("pr list").to(:list_org_pr) }
  it { is_expected.to route_http(:post, "/merge_request_action").to(:merge_request_action) }

  it "displays a list of pull requests" do
    expect_any_instance_of(Octokit::Client).to receive(:org_issues).and_return(two_issues)
    expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(issue_comments_passed, issue_comments_failed, issue_comments_passed_design)

    send_command("pr list")

    expect(replies.last).to include("Found a bug")
  end

  it "displays the status of the PR (pass/fail)" do
    expect_any_instance_of(Octokit::Client).to receive(:org_issues).and_return(two_issues)
    expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(issue_comments_passed, issue_comments_failed, issue_comments_passed_design)

    send_command("pr list")

    expect(replies.last).to include("waffles (art)(art)(art) Found a bug https://github.com/octocat/Hello-World/pull/1347")
    expect(replies.last).to include("waffles (elephant)(elephant)(elephant) Found a bug https://github.com/octocat/Hello-World/pull/1347")
    expect(replies.last).to include("waffles (poop) Found a waffle https://github.com/octocat/Hello-World/pull/1347")
  end

  it "displays the status of the PR (in review/fixed)" do
    expect_any_instance_of(Octokit::Client).to receive(:org_issues).and_return(two_issues)
    expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(issue_comments_in_review, issue_comments_fixed)

    send_command("pr list")

    expect(replies.last).to include("waffles (book) Found a bug https://github.com/octocat/Hello-World/pull/1347")
    expect(replies.last).to include("waffles (wave) Found a waffle https://github.com/octocat/Hello-World/pull/1347")
  end

  it "displays the status of the PR (new)" do
    expect_any_instance_of(Octokit::Client).to receive(:org_issues).and_return(one_issue)
    expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(issue_comments_new)

    send_command("pr list")

    expect(replies.last).to include("waffles (new) Found a bug https://github.com/octocat/Hello-World/pull/1347")
  end

  it "lists gitlab merge requests" do
    expect_any_instance_of(Octokit::Client).to receive(:org_issues).and_return(one_issue)
    expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(issue_comments_new)

    subject.merge_request_action(gitlab_merge_request, nil)

    send_command("pr list")

    expect(replies.last).to include("rails_envs (new) Fixed the things https://gitlab.corp.ads/ama/rails_envs/merge_requests/99")
  end

  it "removes gitlab merge requests" do
    expect_any_instance_of(Octokit::Client).to receive(:org_issues).and_return(one_issue)
    expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(issue_comments_new)

    subject.merge_request_action(gitlab_request_closed, nil)

    send_command("pr list")

    expect(replies.last).to_not include("rails_envs (new) Fixed the things https://gitlab.corp.ads/ama/rails_envs/merge_requests/99")
  end

end
