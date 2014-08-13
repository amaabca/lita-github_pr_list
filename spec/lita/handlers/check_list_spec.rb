describe Lita::Handlers::GithubPrList, lita_handler: true do
  before :each do
    Lita.config.handlers.github_pr_list.github_organization = 'aaaaaabbbbbbcccccc'
    Lita.config.handlers.github_pr_list.github_access_token = 'wafflesausages111111'
  end

  let(:pull_request_review_comment) { File.read("spec/fixtures/pull_request_review_comment.json") }
  let(:edit_comment_response_content) { [File.read("spec/fixtures/edit_comment.json")] }
  let(:edit_comment_response) { Rack::Response.new(edit_comment_response_content, 200, { 'Content-Type' => 'json' }) }
  let(:check_list) { "- [ ] Change log
    - [ ] Demo page
    - [ ] Product owner signoff
    - [ ] Merge into master
    - [ ] Deploy to production"
  }

  it { routes_http(:post, "/check_list").to(:check_list) }

  it "mentions the github user in the room and tell them the check list was added to the pull request" do
    allow_any_instance_of(Octokit::Client).to receive(:update_comment).and_return(edit_comment_response)
    request = Rack::Request.new("rack.input" => StringIO.new(pull_request_review_comment))
    response = Rack::Response.new(['Hello'], 200, {'Content-Type' => 'text/plain'})

    github_handler = Lita::Handlers::GithubPrList.new
    github_handler.check_list(request, response)
    expect(edit_comment_response.body.first).to include(check_list)
  end
end
