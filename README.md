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

Set ```ENV['GITHUB_TOKEN']``` and ```ENV['GITHUB_ORG']```

Such as: ```ENV['GITHUB_TOKEN'] = 'oauthtoken'``` and ```ENV['GITHUB_ORG'] = amaabca``` - Or just put it in your .env if you're using foreman.

## Usage

```Lita: pr list```

All of the open pull requests for an organization will get listed out from lita. If it has one of the emoji statuses below it
will display it, otherwise it will display :new:.

## Emoji status

New - :new: - This is the default state, shown (new) if none of the other states are set.  
Pass - :elephant: :elephant: :elephant: = (elephant)(elephant)(elephant)  
In Review - :book: = (book)  
Fail - :poop: = (poop)  
Fixed - :wave:  = (wave)  

## Contributing

1. Fork it ( https://github.com/amaabca/lita-github_pr_list/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
