describe Lita::Handlers::GithubPrList, lita_handler: true do
  before :each do
    Lita.config.handlers.github_pr_list.github_organization = 'aaaaaabbbbbbcccccc'
    Lita.config.handlers.github_pr_list.github_access_token = 'wafflesausages111111'
    allow_any_instance_of(Lita::Configuration).to receive(:hipchat).and_return(OpenStruct.new({ rooms: ["room"] }))
  end

  let(:issue_comment_event_passed) { File.read("spec/fixtures/issue_comment_event_passed.json") }
  let(:issue_comment_event_failed) { File.read("spec/fixtures/issue_comment_event_failed.json") }
  let(:issue_comment_event_failed_hankey) { File.read("spec/fixtures/issue_comment_event_failed_hankey.json") }
  let(:issue_comment_event_in_review) { File.read("spec/fixtures/issue_comment_event_in_review.json") }
  let(:issue_comment_event_fixed) { File.read("spec/fixtures/issue_comment_event_fixed.json") }

  it { routes_http(:post, "/comment_hook").to(:comment_hook) }

  it "mentions the github user in the room and tell them they passed" do
    request = Rack::Request.new("rack.input" => StringIO.new(issue_comment_event_passed))
    response = Rack::Response.new(['Hello'], 200, { 'Content-Type' => 'text/plain' })

    github_handler = Lita::Handlers::GithubPrList.new
    github_handler.comment_hook(request, response)

    expect(replies.last).to include("@mcwaffle1234 your pull request: Spelling error in the README file has passed."\
                                    " https://github.com/baxterthehacker/public-repo/issues/47")
  end

  it "mentions the github user in the room and tell them they failed" do
    request = Rack::Request.new("rack.input" => StringIO.new(issue_comment_event_failed))
    response = Rack::Response.new(['Hello'], 200, { 'Content-Type' => 'text/plain' })

    github_handler = Lita::Handlers::GithubPrList.new
    github_handler.comment_hook(request, response)

    expect(replies.last).to include("@mcwaffle1234 your pull request: Spelling error in the README file has failed."\
                                    " https://github.com/baxterthehacker/public-repo/issues/47")
  end

  it "mentions the github user in the room and tell them they failed for hankey too" do
    request = Rack::Request.new("rack.input" => StringIO.new(issue_comment_event_failed_hankey))
    response = Rack::Response.new(['Hello'], 200, { 'Content-Type' => 'text/plain' })

    github_handler = Lita::Handlers::GithubPrList.new
    github_handler.comment_hook(request, response)

    expect(replies.last).to include("@mcwaffle1234 your pull request: Spelling error in the README file has failed."\
                                    " https://github.com/baxterthehacker/public-repo/issues/47")
  end

  it "mentions the github user in the room and tell them they are reviewing" do
    request = Rack::Request.new("rack.input" => StringIO.new(issue_comment_event_in_review))
    response = Rack::Response.new(['Hello'], 200, { 'Content-Type' => 'text/plain' })

    github_handler = Lita::Handlers::GithubPrList.new
    github_handler.comment_hook(request, response)

    expect(replies.last).to include("@baxterthehacker is currently reviewing: Spelling error in the README file."\
                                    " https://github.com/baxterthehacker/public-repo/issues/47")
  end

  it "mentions the github user in the room and tell them it has been fixed" do
    request = Rack::Request.new("rack.input" => StringIO.new(issue_comment_event_fixed))
    response = Rack::Response.new(['Hello'], 200, { 'Content-Type' => 'text/plain' })

    github_handler = Lita::Handlers::GithubPrList.new
    github_handler.comment_hook(request, response)

    expect(replies.last).to include("Spelling error in the README file has been fixed:"\
                                    " https://github.com/baxterthehacker/public-repo/issues/47")
  end
end
