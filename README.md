# lita-github_pr_list

lita-google-images is a handler for Lita that connects up with Github and lists an organizations pull requests

## Installation

Add this line to your application's Gemfile:

    gem 'lita-github_pr_list'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lita-github_pr_list

## Configuration

```
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
In Review - :book: = (book)
Fail - :poop: = (poop)  OR :hankey: = (hankey)
Fixed - :wave:  = (wave)

## Contributing

1. Fork it ( https://github.com/amaabca/lita-github_pr_list/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
