# frozen_string_literal: true

require 'pp'

run do |env|
  [200, {}, [env.pretty_inspect]]
end
