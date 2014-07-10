describe Lita::Handlers::GithubPrList, lita_handler: true do
  before :each do
    Lita.config.handlers.github_pr_list.github_organization = 'aaaaaabbbbbbcccccc'
    Lita.config.handlers.github_pr_list.github_access_token = 'wafflesausages111111'
  end

  it "should map the github name to the hipchat username (mention)" do
    send_command("pr alias user mcwaffle mcrib")

    expect(replies.last).to include("Mapped mcwaffle to mcrib")
    expect(subject.redis.get("alias:mcwaffle")).to include("mcrib")
  end
end
