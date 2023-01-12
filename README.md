## 👢👢 Bootboot   - [![Build Status](https://github.com/Shopify/bootboot/actions/workflows/ci.yml/badge.svg)](https://github.com/Shopify/bootboot/actions/workflows/ci.yml)

Introduction
------------
Bootboot is a [Bundler plugin](https://bundler.io/v1.17/guides/bundler_plugins.html#what-is-a-plugin) meant to help dual boot your ruby application.

#### What is "Dual booting"?
In this context, dual boot is the process of booting your application with a different set of dependencies. This technique has become very popular in the Ruby community to help applications safely upgrade dependencies. If you want to learn more about it, have a look at this [conference talk](https://www.youtube.com/watch?v=I-2Xy3RS1ns&t=368s) by @rafaelfranca.

There are two schools on how to dual boot your app, each having advantages and disadvantages.
1) Use three Gemfiles. One with current production dependencies, a second with an alternate "next" set of dependencies, and a third containing the dependencies that both Gemfiles have in common.
```ruby
# Gemfile.common
gem "some_gem"

# Gemfile
gem "rails", "~> 5.1.0"
eval_gemfile "Gemfile.common"

# Gemfile.next
gem "rails", "~> 5.2.0"
eval_gemfile "Gemfile.common"
```

2) Have a single Gemfile containing dependencies separated by environment sensitive `if` statements.
```ruby
# Gemfile

if ENV['DEPENDENCIES_NEXT']
  gem "rails", "~> 5.2.0"
else
  gem "rails", "~> 5.1.0"
end
```
-----------------------------
The former doesn't require any Bundler workaround but you need to deal with three Gemfiles and the [confusion](https://github.com/bundler/bundler/issues/6777#issuecomment-436771340) that comes with it.
The latter is the approach we decided to take at Shopify and it worked very well for us for multiple years.

No matter what approach you decide to take, you'll need to create tooling to ensure that all the lockfiles are in sync whenever a developer updates a dependency.

Bootboot is only useful if you decide to follow the second approach. It creates the required tooling as well as the Bundler workaround needed to enable dual booting.

Installation
------------
1) In your Gemfile, add this
```ruby
plugin 'bootboot', '~> 0.2.1'
```
2) Run `bundle install && bundle bootboot`
3) You're done. Commit the Gemfile and the Gemfile_next.lock

Note: You should only run `bundle bootboot` once to install the plugin, otherwise your Gemfile will get updated each time you run it.

Dual boot it!
------------
If you want to boot using the dependencies from the `Gemfile_next.lock`, run any bundler command prefixed with the `DEPENDENCIES_NEXT=1` ENV variable. I.e. `DEPENDENCIES_NEXT=1 bundle exec irb`.

**Note:** `bootboot` will use the gems and Ruby version specified per environment in your `Gemfile` to resolve dependencies and keep `Gemfile.lock` and `Gemfile_next.lock` in sync, but it does not do any magic to actually change the running Ruby version or install the gems in the environment you are not currently running, it simply tells Bundler which Ruby and gem versions to use in its resolution algorithm and keeps the lock files in sync. If you are a developer who is not involved in updating the dependency set, this should not affect you, simply use bundler normally. _However_, if you are involved in the dependency changes directly, you will often have to run `DEPENDENCIES_NEXT=1 bundle install` after making changes to the dependencies.

```sh
# This will update Gemfile.lock and Gemfile_next.lock and install the gems
# specified in Gemfile.lock:
$ bundle update some_gem
# This will actually install the gems specified in Gemfile_next.lock
$ DEPENDENCIES_NEXT=1 bundle install
```

Dual boot different Ruby versions
---------------------------------

While dual booting is often used for framework upgrades, it is also possible to use `bootboot` to dual boot two Ruby versions, each with its own set of gems.

```ruby
# Gemfile

if ENV['DEPENDENCIES_NEXT']
  ruby '2.6.5'
else
  ruby '2.5.7'
end
```

Dual booting Ruby versions does incur some additional complications however, see the examples following for more detail.

Example: updating a gem while dual booting Ruby versions
--------------------------------------------------------

To dual boot an app while upgrading from Ruby 2.5.7 to Ruby 2.6.5, your Gemfile would look like this:

```ruby
# Gemfile

if ENV['DEPENDENCIES_NEXT']
  ruby '2.6.5'
else
  ruby '2.5.7'
end
```

After running `bundle install`, `Gemfile.lock` will have:

```
RUBY VERSION
   ruby 2.5.7p206
```

and `Gemfile_next.lock` will have:

```
RUBY VERSION
   ruby 2.6.5p114
```
Assuming there's a gem `some_gem` with the following constraints in its gemspecs:

```ruby
# some_gem-1.0.gemspec
spec.version = "1.0"
spec.required_ruby_version = '>= 2.5.7'
```

```ruby
# some_gem-2.0.gemspec
spec.version = "2.0"
spec.required_ruby_version = '>= 2.6.5'
```

Running `bundle update some_gem` will use Ruby 2.5.7 to resolve `some_gem` for `Gemfile.lock` and Ruby 2.6.5 to resolve `some_gem` for `Gemfile_next.lock` with the following results:

Gemfile.lock:
```
specs:
  some_gem (1.0)
```

Gemfile_next.lock:
```
specs:
  some_gem (2.0)
```

**Note:** It is important to note that at this point, `some_gem 2.0` **will not** be installed on your system, it will simply be specified in `Gemfile_next.lock`, since installing it on the system would require changing the running Ruby version. This is sufficient to keep `Gemfile_next.lock` in sync, but is a potential source of confusion. To install gems under both versions of Ruby, see the next section.

Vendoring both sets of gems
---------------------------
To vendor both sets of gems, make sure caching is enabled by checking `bundle config` or bundle gems using `bundle pack`.

```bash
bundle pack
DEPENDENCIES_NEXT=1 bundle pack
```

### Example: running Ruby scripts while dual booting Ruby versions

When running Ruby scripts while dual booting two different Ruby versions, you have to remember to do two things simultaneously for every command:
- Run the command with the correct version of Ruby
- Add the DEPENDENCIES_NEXT environment variable to tell bundler to use `Gemfile_next.lock`

So to run a spec in both versions, the workflow would look like this (assuming chruby for version management):

```sh
$ chruby 2.5.7
$ bundle exec rspec spec/some_spec.rb
$ chruby 2.6.5
$ DEPENDENCIES_NEXT=1 bundle exec rspec spec/some_spec.rb
```

Perhaps more importantly, to update or install a gem, the workflow would look like this:

```sh
# This will update Gemfile.lock and Gemfile_next.lock and install the gems
# specified in Gemfile.lock:
$ chruby 2.5.7
$ bundle update some_gem
# This will actually install the gems specified in Gemfile_next.lock under the
# correct Ruby installation:
$ chruby 2.6.5
$ DEPENDENCIES_NEXT=1 bundle install
```

Configuration (Optional)
------------------------
By default Bootboot will use the `DEPENDENCIES_NEXT` environment variable to update your Gemfile_next.lock. You can however configure it. For example, if you want the dualboot to happen when the `SHOPIFY_NEXT` env variable is present, you simply have to add this in your Gemfile:

```ruby
# Gemfile
Bundler.settings.set_local('bootboot_env_prefix', 'SHOPIFY')
```

Keep the `Gemfile_next.lock` in sync
------------
When a developer bumps or adds a dependency, Bootboot will ensure that the `Gemfile_next.lock` snapshot gets updated.

**However, this feature is only available if you are on Bundler `>= 1.17`**
Other versions will trigger a warning message telling them that Bootboot can't automatically keep the `Gemfile_next.lock` in sync.

If you use the deployment flag (`bundle --deployment`) this plugin won't work on Bundler `<= 2.0.1`. Consider using this workaround in your Gemfile for these versions of Bundler:

```ruby
plugin 'bootboot', '~> 0.1.2' unless Bundler.settings[:frozen]
```
