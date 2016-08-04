# RecurrenceDetector

[![Build Status](https://travis-ci.org/17hats/recurrence_detector.svg?branch=master)](https://travis-ci.org/17hats/recurrence_detector)

Given an array of dates, this gem detectes the recurrence pattern.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'recurrence_detector'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install recurrence_detector

## Usage

```ruby
dates = [
  Date.new(2001, 1, 8),
  Date.new(2001, 1, 15),
  Date.new(2001, 1, 22),
  Date.new(2001, 1, 29),
  Date.new(2001, 2, 5)
]

RecurrenceDetector.new(dates).detect
# => { recurrence: :every_week, on: :monday }

```

```ruby
dates = [
  Date.new(2001, 1, 29), # Monday
  Date.new(2001, 1, 31), # Wednesday
  Date.new(2001, 2, 2),  # Friday
  Date.new(2001, 2, 5),  # Monday
  Date.new(2001, 2, 7),  # Wednesday
  Date.new(2001, 2, 9),  # Friday
  Date.new(2001, 2, 12)  # Monday
]

RecurrenceDetector.new(dates).detect
# => { recurrence: :custom_weeks, every: 1, on: [:monday, :wednesday, :friday] }

```

```ruby
dates = [
  Date.new(2001, 1, 29), # Monday
  Date.new(2001, 1, 31), # Wednesday
  Date.new(2001, 2, 2),  # Friday
  Date.new(2001, 2, 12), # Monday (Skips a week)
  Date.new(2001, 2, 14), # Wednesday
  Date.new(2001, 2, 16), # Friday
  Date.new(2001, 2, 26), # Monday (Skips a week)
  Date.new(2001, 2, 28), # Wednesday
  Date.new(2001, 3, 2)   # Friday
]

RecurrenceDetector.new(dates).detect
# => { recurrence: :custom_weeks, every: 2, on: [:monday, :wednesday, :friday] }

```

```ruby
dates = [
  Date.new(2001, 1, 10),
  Date.new(2001, 1, 12),
  Date.new(2001, 3, 10),
  Date.new(2001, 3, 12),
  Date.new(2001, 5, 10),
  Date.new(2001, 5, 12)
]

RecurrenceDetector.new(dates).detect
# => { recurrence: :custom_months, every: 2, each: [10, 12] }
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/17hats/recurrence_detector.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
