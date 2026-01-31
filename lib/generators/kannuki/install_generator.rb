# frozen_string_literal: true

require 'rails/generators'

module Kannuki
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc 'Creates a Kannuki initializer file.'

      def create_initializer_file
        template 'kannuki.rb', 'config/initializers/kannuki.rb'
      end
    end
  end
end
