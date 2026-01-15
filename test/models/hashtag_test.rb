require 'test_helper'

class HashtagTest < ActiveSupport::TestCase
  def setup
    @hashtag = Hashtag.new(name: 'python')
  end

  test 'should be valid' do
    assert @hashtag.valid?, "Hashtag should be valid but has errors: #{@hashtag.errors.full_messages}"
  end

  test 'name should be present' do
    @hashtag.name = '   '
    assert_not @hashtag.valid?
  end

  test 'name should be unique' do
    duplicate_hashtag = @hashtag.dup
    @hashtag.save
    assert_not duplicate_hashtag.valid?
  end

  test 'name should be case insensitive unique' do
    duplicate_hashtag = @hashtag.dup
    duplicate_hashtag.name = @hashtag.name.upcase
    @hashtag.save
    assert_not duplicate_hashtag.valid?
  end

  test 'name should be normalized to lowercase' do
    @hashtag.name = 'RUBY'
    @hashtag.save
    assert_equal 'ruby', @hashtag.name
  end
end
