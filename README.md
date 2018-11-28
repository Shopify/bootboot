## 👢👢 Bootboot   - [![Build Status](https://travis-ci.com/Shopify/bootboot.svg?branch=master)](https://travis-ci.com/Shopify/bootboot)

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
plugin 'bootboot', '~> 0.1.1`
```
2) Run `bundle install && bundle bootboot`
3) You're done. Commit the Gemfile and the Gemfile_next.lock

Dual boot it!
------------
If you want to boot using the dependencies from the `Gemfile_next.lock`, run any bundler command prefixed with the `DEPENDENCIES_NEXT=1` ENV variable. I.e. `DEPENDENCIES_NEXT=1 bundle exec irb`.

Configuration (Optional)
------------------------
By default Bootboot will use the `DEPENDENCIES_NEXT` environment variable to update your Gemfile_next.lock. You can however configure it. For example, if you want the dualboot to happen when the `SHOPIFY_NEXT` env variable is present, you simply have to add this in your Gemfile:

```ruby
# Gemfile
Bundler.settings.set_local('booboot_env_previx', 'SHOPIFY')
```

Keep the `Gemfile_next.lock` in sync
------------
When a developer bumps or adds a dependency, Bootboot will ensure that the `Gemfile_next.lock` snapshot gets updated.

**However, this feature is only available if you are on Bundler `>= 1.17`**
Other versions will trigger a warning message telling them that Bootboot can't automatically keep the `Gemfile_next.lock` in sync.
