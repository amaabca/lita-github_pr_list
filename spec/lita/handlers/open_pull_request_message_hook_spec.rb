describe Lita::Handlers::GithubPrList, lita_handler: true do
  before :each do
    Lita.config.handlers.github_pr_list.github_organization = 'aaaaaabbbbbbcccccc'
    Lita.config.handlers.github_pr_list.github_access_token = 'wafflesausages111111'
    allow_any_instance_of(Lita::Configuration).to receive(:hipchat).and_return(OpenStruct.new({ rooms: ["room"] }))
  end

  let(:open_pull_request_response) { [File.read("spec/fixtures/open_pull_request_response.json")] }

  it { is_expected.to route_http(:post, "/pull_request_open_message_hook").to(:pull_request_open_message_hook) }

  it "sends a message to hipchat - pull request opened" do
    request = Rack::Request.new("rack.input" => StringIO.new(open_pull_request_response.first))
    response = Rack::Response.new(['Hello'], 200, {'Content-Type' => 'text/plain'})
    github_handler = Lita::Handlers::GithubPrList.new robot
    github_handler.pull_request_open_message_hook(request, response)

    expect(replies.last).to include("@baxterthehacker opened pull request: 'Update the README with new information' in 'baxterthehacker/public-repo'. https://github.com/baxterthehacker/public-repo/pull/48")
  end
end
