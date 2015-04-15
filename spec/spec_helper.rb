require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/vendor/"
end

require "lita/github_pr_list"
require "lita/rspec"