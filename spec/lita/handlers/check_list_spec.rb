describe Lita::Handlers::GithubPrList, lita_handler: true do
  before :each do
    Lita.config.handlers.github_pr_list.github_organization = 'aaaaaabbbbbbcccccc'
    Lita.config.handlers.github_pr_list.github_access_token = 'wafflesausages111111'
  end

  let(:update_pull_request_response) { File.read("spec/fixtures/update_pull_request_response.json") }
  let(:open_pull_request_response) { [File.read("spec/fixtures/open_pull_request_response.json")] }
  #let(:open_pull_request_rack_response) { Rack::Response.new(open_pull_request_response, 200, { 'Content-Type' => 'json' }) }
  let(:check_list) do
    "- [ ] Change log - [ ] Demo page - [ ] Product owner signoff - [ ] Merge into master - [ ] Deploy to production"
  end

  it { routes_http(:post, "/check_list").to(:check_list) }

  it "adds the check list to the body of the pull request" do
    allow_any_instance_of(Octokit::Client).to receive(:update_pull_request).and_return(update_pull_request_response)
    request = Rack::Request.new("rack.input" => StringIO.new(open_pull_request_response.first))
    response = Rack::Response.new(['Hello'], 200, {'Content-Type' => 'text/plain'})
    github_handler = Lita::Handlers::GithubPrList.new
    github_handler.check_list(request, response)
    expect(update_pull_request_response).to include(check_list)
  end
end
