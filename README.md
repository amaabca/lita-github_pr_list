# lita-github_pr_list

`lita-github_pr_list` is a handler for Lita that connects up with GitHub and lists an organization's pull requests

## Installation

Add this line to your application's Gemfile:

    gem 'lita-github_pr_list'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lita-github_pr_list

## Configuration

```ruby
Lita.configure do |config|
...
  config.handlers.github_pr_list.github_organization = ENV['GITHUB_ORG']
  config.handlers.github_pr_list.github_access_token = ENV['GITHUB_TOKEN']
...
end
```

## Usage

```Lita: pr list```

All of the open pull requests for an organization will get listed out from lita. If it has one of the emoji statuses below it
will display it, otherwise it will display :new:.

## Emoji status

New - :new: - This is the default state, shown (new) if none of the other states are set.
Pass - :elephant: :elephant: :elephant: = (elephant)(elephant)(elephant)
Pass DESIGN - :art: :art: :art: = (art)(art)(art)
In Review - :book: = (book)
Fail - :poop: OR :hankey: = (poop)
Fixed - :wave:  = (wave)

Placing an :art: or :elephant: in the initial pull request will designate the request to be for design or developers respectively
Placing neither :art: nor :elephant:, or placing both of them will assume both design and developer review is requested

## Contributing

1. Fork it ( https://github.com/amaabca/lita-github_pr_list/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
