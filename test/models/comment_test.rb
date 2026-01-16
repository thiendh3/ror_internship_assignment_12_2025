require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  def setup
    @user = users(:michael)
    @micropost = microposts(:orange)
    @comment = Comment.new(user: @user, micropost: @micropost, content: 'Great post!')
  end

  test 'should be valid' do
    assert @comment.valid?
  end

  test 'user should be present' do
    @comment.user = nil
    assert_not @comment.valid?
  end

  test 'micropost should be present' do
    @comment.micropost = nil
    assert_not @comment.valid?
  end

  test 'content should be present' do
    @comment.content = '   '
    assert_not @comment.valid?
  end

  test 'content should not be too long' do
    @comment.content = 'a' * 501
    assert_not @comment.valid?
  end

  test 'should increment micropost comments_count' do
    assert_difference '@micropost.reload.comments_count', 1 do
      @comment.save
    end
  end

  test 'should decrement micropost comments_count on destroy' do
    @comment.save
    assert_difference '@micropost.reload.comments_count', -1 do
      @comment.destroy
    end
  end
end
