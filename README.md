# ActiveStorage::SendZip

[![Gem Version](https://badge.fury.io/rb/active_storage-send_zip.svg)](https://badge.fury.io/rb/active_storage-send_zip)
[![MIT Licence](https://badges.frapsoft.com/os/mit/mit.png?v=103)](https://opensource.org/licenses/mit-license.php)

Add a `send_zip` method in your Rails controller to send a `.zip` file containing one or many [ActiveStorage](https://edgeguides.rubyonrails.org/active_storage_overview.html) objects.

## Usage

### With `Array`

Assuming you have an ActiveRecord model with ActiveStorage like this:

~~~ruby
# app/models/user.rb
class User < ApplicationRecord
  has_many_attached :pictures
end
~~~

You simply have to include `ActiveStorage::SendZip` in your controller & use  `ActiveStorage::SendZip#send_zip` method. Just pass some [`ActiveStorage::Attached`](https://edgeapi.rubyonrails.org/classes/ActiveStorage/Attached/) objects as parameters:

~~~ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  include ActiveStorage::SendZip

  # ...

  # GET /users/1
  # GET /users/1.zip
  def show
    respond_to do |format|
      format.html { render }
      format.zip { send_zip @user.pictures }
    end
  end
end
~~~

Will produce a `.zip` archive like this:

~~~
├── a.jpg
├── b.png
└── c.gif
~~~

Ii will also prevent duplicate filename and add an [`SecureRandom.uuid`](https://ruby-doc.org/stdlib-2.3.0/libdoc/securerandom/rdoc/SecureRandom.html) if two files as the same name.


### With `Hash`

You can also pass an `Hash` parameter at `send_zip` method to organize files in sublfolder:

~~~ruby
# app/controllers/holidays_controller.rb
class HolidaysController < ApplicationController
  include ActiveStorage::SendZip

  def zip
    send_zip {
      'Holidays in Lyon <3' => Holidays.where(place: 'lyon').first.pictures,
      'Holidays in Paris' => [
        Holidays.where(place: 'paris').first.pictures,
        'Eiffle Tower' => Holidays.where(place: 'eiffle_tower').first.pictures
      ]
    }
  end
end
~~~

Will produce a `.zip` archive like this:

~~~
├── Holidays in Lyon <3
│   ├── a.jpg
│   ├── b.png
│   └── c.gif
└── Holidays in Paris
    ├── Eiffle Tower
        ├── d.jpg
        ├── e.jpg
        ├── f.jpg
    ├── a.jpg
    ├── b.png
    └── c.gif
~~~

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_storage-send_zip'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_storage-send_zip

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/madeindjs/active_storage-send_zip. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the ActiveStorage::SendZip project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/madeindjs/active_storage-send_zip/blob/master/CODE_OF_CONDUCT.md).
