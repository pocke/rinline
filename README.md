# Rinline

Inline expansion for Ruby.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rinline'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install rinline

## Usage

Call `Rinline.optimize` after your program is loaded, but before your program is not ran yet.

```ruby
require 'your_program'
require 'rinline'

Rinline.optimize do |r|
  r.optimize_namespace(YourProgram)
end

YourProgram.start
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pocke/rinline.
