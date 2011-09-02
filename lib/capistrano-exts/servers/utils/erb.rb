# encoding: utf-8

require 'erb'

module Capistrano
  module Extensions
    module Erb
      def render
        sanity_check

        erb_template = ::ERB.new(File.read(@template))
        erb_template.result(binding).strip_empty_lines
      end
    end
  end
end