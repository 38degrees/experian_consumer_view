# frozen_string_literal: true

Dir[File.join(File.dirname(__FILE__), 'experian_consumer_view', '**', '*.rb')].sort.each { |file| require file }
