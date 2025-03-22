# [*MOSTLY* DEAD AND UNMAINTAINED](https://www.youtube.com/shorts/nkpAUKqfel4)

## Joint

MongoMapper and GridFS joined in file upload love.

## Usage

Declare the plugin and use the attachment method to make attachments.
```ruby
class Foo
  include MongoMapper::Document
  plugin Joint

  attachment :file
  attachment :image
  attachment :pdf
end
```

This gives you `#file`, `#file=`, `#image`, `#image=`, `#pdf`, and `#pdf=`. The `=` methods take any IO that responds to `read()` (`File`, `Tempfile`, etc).

The `file()`, `image()` and `pdf()` methods return a `Mongo::Grid::FSBucket::Stream::Read` instance (can be found in the ruby driver).

Also, `#file`, `#image` and `#pdf` are instances of `Joint::AttachmentProxy` so you can do stuff like:

```ruby
doc.image.id, doc.image.size, doc.image.type, doc.image.name
```
~~If you call a method other than those in the proxy it calls it on the GridIO
instance so you can still get at all the GridIO instance methods.~~

`AttachmentProxy#method_missing(..)` has been removed as the Mongo Ruby driver
has changed dramatically. Instead, methods are include to get the info from the
driver.

```ruby
content_type(), file_id(), filename(), file_length(), upload_date()
```
For consistency with the `Joint` API, `file_size()` aliased to `file_length()`.
These are methods on instances of `Grid::File::Info`

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2010 John Nunemaker. See LICENSE for details.
