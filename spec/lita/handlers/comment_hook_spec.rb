describe Lita::Handlers::GithubPrList, lita_handler: true do
  let(:issue_comments_passed) { sawyer_resource_array("spec/fixtures/issue_comments_passed.json") }
  let(:issue_comments_passed_design) { sawyer_resource_array("spec/fixtures/issue_comments_passed_design.json") }
  let(:issue_comments_failed) { sawyer_resource_array("spec/fixtures/issue_comments_failed.json") }
  let(:issue_comments_in_review) { sawyer_resource_array("spec/fixtures/issue_comments_in_review_comment_hook.json") }
  let(:issue_comments_fixed) { sawyer_resource_array("spec/fixtures/issue_comments_fixed.json") }
  let(:issue_comments_trivial) { sawyer_resource_array("spec/fixtures/issue_comments_trivial.json") }
  let(:issue_comments_passed_both) { sawyer_resource_array("spec/fixtures/issue_comments_passed_both.json") }
  let(:issue_comments_passed_both_book_after) { sawyer_resource_array("spec/fixtures/issue_comments_passed_both_book_after.json") }

  before :each do
    Lita.config.handlers.github_pr_list.github_organization = 'aaaaaabbbbbbcccccc'
    Lita.config.handlers.github_pr_list.github_access_token = 'wafflesausages111111'
    allow_any_instance_of(Lita::Configuration).to receive(:hipchat).and_return(OpenStruct.new({ rooms: ["room"] }))
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

  let(:issue_comment_event_passed) { File.read("spec/fixtures/issue_comment_event_passed.json") }
  let(:issue_comment_event_passed_emoji) { File.read("spec/fixtures/issue_comment_event_passed_emoji.json") }
  let(:issue_comment_event_passed_design) { File.read("spec/fixtures/issue_comment_event_passed_design.json") }
  let(:issue_comment_event_failed) { File.read("spec/fixtures/issue_comment_event_failed.json") }
  let(:issue_comment_event_failed_hankey) { File.read("spec/fixtures/issue_comment_event_failed_hankey.json") }
  let(:issue_comment_event_in_review) { File.read("spec/fixtures/issue_comment_event_in_review.json") }
  let(:issue_comment_event_fixed) { File.read("spec/fixtures/issue_comment_event_fixed.json") }
  let(:issue_comment_event_no_event) { File.read("spec/fixtures/issue_comment_event_no_event.json") }

  let(:issue_comment_event_passed_dev_context) { File.read("spec/fixtures/dev/issue_comment_event_passed.json") }
  let(:issue_comment_event_failed_dev_context) { File.read("spec/fixtures/dev/issue_comment_event_failed.json") }
  let(:issue_comment_event_in_review_dev_context) { File.read("spec/fixtures/dev/issue_comment_event_in_review.json") }

  let(:issue_comment_event_passed_design_context) { File.read("spec/fixtures/design/issue_comment_event_passed.json") }
  let(:issue_comment_event_failed_design_context) { File.read("spec/fixtures/design/issue_comment_event_failed.json") }
  let(:issue_comment_event_in_review_design_context) { File.read("spec/fixtures/design/issue_comment_event_in_review.json") }

  it { is_expected.to route_http(:post, "/comment_hook").to(:comment_hook) }

  context "comment made with text" do
    it "mentions the github user in the room and tell them they passed , but they need design review" do
      expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(issue_comments_passed)

      request = Rack::Request.new("rack.input" => StringIO.new(issue_comment_event_passed))
      response = Rack::Response.new(['Hello'], 200, { 'Content-Type' => 'text/plain' })

      github_handler = Lita::Handlers::GithubPrList.new robot
      github_handler.comment_hook(request, response)

      expect(replies.last).to include("@mcwaffle1234 your pull request: Spelling error in the README file has passed DEV REVIEW."\
                                      " https://github.com/baxterthehacker/public-repo/issues/47"\
                                      " - You still require DESIGN REVIEW")
    end
  end

  context "comment made with emojis" do
    it "mentions the github user in the room and tell them they passed , but they need design review" do
      expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(issue_comments_passed)

      request = Rack::Request.new("rack.input" => StringIO.new(issue_comment_event_passed_emoji))
      response = Rack::Response.new(['Hello'], 200, { 'Content-Type' => 'text/plain' })

      github_handler = Lita::Handlers::GithubPrList.new robot
      github_handler.comment_hook(request, response)

      expect(replies.last).to include("@mcwaffle1234 your pull request: Spelling error in the README file has passed DEV REVIEW."\
                                      " https://github.com/baxterthehacker/public-repo/issues/47"\
                                      " - You still require DESIGN REVIEW")
    end
  end

  it "mentions the github user in the room and tell them they passed DESIGN" do
    expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(issue_comments_passed_design)

    request = Rack::Request.new("rack.input" => StringIO.new(issue_comment_event_passed_design))
    response = Rack::Response.new(['Hello'], 200, { 'Content-Type' => 'text/plain' })

    github_handler = Lita::Handlers::GithubPrList.new robot
    github_handler.comment_hook(request, response)

    expect(replies.last).to include("@mcwaffle1234 your pull request: Spelling error in the README file has passed DESIGN."\
                                    " https://github.com/baxterthehacker/public-repo/issues/47"\
                                    " - You still require DEV REVIEW")
  end

  it "mentions the github user in the room and tell them they passed DESIGN - DEV already passed" do
    expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(issue_comments_passed_both)

    request = Rack::Request.new("rack.input" => StringIO.new(issue_comment_event_passed_design))
    response = Rack::Response.new(['Hello'], 200, { 'Content-Type' => 'text/plain' })

    github_handler = Lita::Handlers::GithubPrList.new robot
    github_handler.comment_hook(request, response)

    expect(replies.last).to include("@mcwaffle1234 your pull request: Spelling error in the README file has passed."\
                                    " https://github.com/baxterthehacker/public-repo/issues/47")
    expect(replies.last).to_not include(" - You still require DEV REVIEW")
  end
  context "Design/Dev passed and book is used" do
    it "returns - currently reviewing" do
      expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(issue_comments_passed_both_book_after)

      request = Rack::Request.new("rack.input" => StringIO.new(issue_comment_event_passed_design))
      response = Rack::Response.new(['Hello'], 200, { 'Content-Type' => 'text/plain' })

      github_handler = Lita::Handlers::GithubPrList.new robot
      github_handler.comment_hook(request, response)

      expect(replies.last).to include("@baxterthehacker is currently reviewing: Spelling error in the README file."\
                                      " https://github.com/baxterthehacker/public-repo/issues/47")
      expect(replies.last).to_not include("@mcwaffle1234 your pull request: Spelling error in the README file has passed."\
                                      " https://github.com/baxterthehacker/public-repo/issues/47")
    end
  end


  it "mentions the github user in the room and tell them they failed" do
    expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(issue_comments_failed)

    request = Rack::Request.new("rack.input" => StringIO.new(issue_comment_event_failed))
    response = Rack::Response.new(['Hello'], 200, { 'Content-Type' => 'text/plain' })

    github_handler = Lita::Handlers::GithubPrList.new robot
    github_handler.comment_hook(request, response)

    expect(replies.last).to include("@mcwaffle1234 your pull request: Spelling error in the README file has failed."\
                                    " https://github.com/baxterthehacker/public-repo/issues/47")
  end

  it "mentions the github user in the room and tell them they failed for hankey too" do
    expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(issue_comments_failed)

    request = Rack::Request.new("rack.input" => StringIO.new(issue_comment_event_failed_hankey))
    response = Rack::Response.new(['Hello'], 200, { 'Content-Type' => 'text/plain' })

    github_handler = Lita::Handlers::GithubPrList.new robot
    github_handler.comment_hook(request, response)

    expect(replies.last).to include("@mcwaffle1234 your pull request: Spelling error in the README file has failed."\
                                    " https://github.com/baxterthehacker/public-repo/issues/47")
  end

  it "mentions the github user in the room and tell them they are reviewing and gives them karma" do
    expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(issue_comments_in_review)

    request = Rack::Request.new("rack.input" => StringIO.new(issue_comment_event_in_review))
    response = Rack::Response.new(['Hello'], 200, { 'Content-Type' => 'text/plain' })

    github_handler = Lita::Handlers::GithubPrList.new robot
    github_handler.comment_hook(request, response)

    expect(replies.last).to include("@baxterthehacker is currently reviewing: Spelling error in the README file."\
                                    " https://github.com/baxterthehacker/public-repo/issues/47,"\
                                    " @baxterthehacker++")
  end

  it "mentions the github user in the room and tell them it has been fixed" do
    expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(issue_comments_fixed)

    request = Rack::Request.new("rack.input" => StringIO.new(issue_comment_event_fixed))
    response = Rack::Response.new(['Hello'], 200, { 'Content-Type' => 'text/plain' })

    github_handler = Lita::Handlers::GithubPrList.new robot
    github_handler.comment_hook(request, response)

    expect(replies.last).to include("Spelling error in the README file has been fixed:"\
                                    " https://github.com/baxterthehacker/public-repo/issues/47")
  end

  it "it says nothing" do
    expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(issue_comments_trivial)

    request = Rack::Request.new("rack.input" => StringIO.new(issue_comment_event_passed_design_context))
    response = Rack::Response.new(['Hello'], 200, { 'Content-Type' => 'text/plain' })

    github_handler = Lita::Handlers::GithubPrList.new robot
    github_handler.comment_hook(request, response)

    expect(replies.last).to eq(nil)
  end

  context "starting out with an initial elephant" do
    it "mentions the github user in the room and tell them they passed" do

      expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(issue_comments_passed)

      request = Rack::Request.new("rack.input" => StringIO.new(issue_comment_event_passed_dev_context))
      response = Rack::Response.new(['Hello'], 200, { 'Content-Type' => 'text/plain' })

      github_handler = Lita::Handlers::GithubPrList.new robot
      github_handler.comment_hook(request, response)

      expect(replies.last).to include("@mcwaffle1234 your pull request: Spelling error in the README file has passed DEV REVIEW."\
                                      " https://github.com/baxterthehacker/public-repo/issues/47")
    end

    it "mentions the github user in the room and tell them they failed" do
      expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(issue_comments_failed)

      request = Rack::Request.new("rack.input" => StringIO.new(issue_comment_event_failed_dev_context))
      response = Rack::Response.new(['Hello'], 200, { 'Content-Type' => 'text/plain' })

      github_handler = Lita::Handlers::GithubPrList.new robot
      github_handler.comment_hook(request, response)

      expect(replies.last).to include("@mcwaffle1234 your pull request: Spelling error in the README file has failed."\
                                      " https://github.com/baxterthehacker/public-repo/issues/47")
    end

    it "mentions the github user in the room and tell them they are reviewing" do
      expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(issue_comments_in_review)

      request = Rack::Request.new("rack.input" => StringIO.new(issue_comment_event_in_review_dev_context))
      response = Rack::Response.new(['Hello'], 200, { 'Content-Type' => 'text/plain' })

      github_handler = Lita::Handlers::GithubPrList.new robot
      github_handler.comment_hook(request, response)

      expect(replies.last).to include("@baxterthehacker is currently reviewing: Spelling error in the README file."\
                                      " https://github.com/baxterthehacker/public-repo/issues/47")
    end
  end

  context "starting out with an initial art" do
    it "mentions the github user in the room and tell them they passed DESIGN" do
      expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(issue_comments_passed_design)

      request = Rack::Request.new("rack.input" => StringIO.new(issue_comment_event_passed_design_context))
      response = Rack::Response.new(['Hello'], 200, { 'Content-Type' => 'text/plain' })

      github_handler = Lita::Handlers::GithubPrList.new robot
      github_handler.comment_hook(request, response)

      expect(replies.last).to include("@mcwaffle1234 your pull request: Spelling error in the README file has passed DESIGN."\
                                      " https://github.com/baxterthehacker/public-repo/issues/47")
    end

    it "mentions the github user in the room and tell them they failed" do
      expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(issue_comments_failed)

      request = Rack::Request.new("rack.input" => StringIO.new(issue_comment_event_failed_design_context))
      response = Rack::Response.new(['Hello'], 200, { 'Content-Type' => 'text/plain' })

      github_handler = Lita::Handlers::GithubPrList.new robot
      github_handler.comment_hook(request, response)

      expect(replies.last).to include("@mcwaffle1234 your pull request: Spelling error in the README file has failed."\
                                      " https://github.com/baxterthehacker/public-repo/issues/47")
    end

    it "mentions the github user in the room and tell them they are reviewing" do
      expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(issue_comments_in_review)

      request = Rack::Request.new("rack.input" => StringIO.new(issue_comment_event_in_review_design_context))
      response = Rack::Response.new(['Hello'], 200, { 'Content-Type' => 'text/plain' })

      github_handler = Lita::Handlers::GithubPrList.new robot
      github_handler.comment_hook(request, response)

      expect(replies.last).to include("@baxterthehacker is currently reviewing: Spelling error in the README file."\
                                      " https://github.com/baxterthehacker/public-repo/issues/47")
    end
  end

end
