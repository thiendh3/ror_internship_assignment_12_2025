require "test_helper"

class LikeTest < ActiveSupport::TestCase
  def setup
    @user = users(:michael)
    @micropost = microposts(:tau_manifesto) # Use micropost without existing like
    @like = Like.new(user: @user, micropost: @micropost)
  end

  test "should be valid" do
    assert @like.valid?
  end

  test "user should be present" do
    @like.user = nil
    assert_not @like.valid?
  end

  test "micropost should be present" do
    @like.micropost = nil
    assert_not @like.valid?
  end

  test "should not allow duplicate likes" do
    @like.save
    duplicate_like = @like.dup
    assert_not duplicate_like.valid?
  end

  test "should increment micropost likes_count" do
    assert_difference '@micropost.reload.likes_count', 1 do
      @like.save
    end
  end

  test "should decrement micropost likes_count on destroy" do
    @like.save
    assert_difference '@micropost.reload.likes_count', -1 do
      @like.destroy
    end
  end
end
