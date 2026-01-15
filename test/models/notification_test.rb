require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  def setup
    @recipient = users(:michael)
    @actor = users(:archer)
    @micropost = microposts(:orange)
    @notification = Notification.new(
      recipient: @recipient,
      actor: @actor,
      notifiable: @micropost,
      action: 'liked'
    )
  end

  test 'should be valid' do
    assert @notification.valid?
  end

  test 'recipient should be present' do
    @notification.recipient = nil
    assert_not @notification.valid?
  end

  test 'actor should be present' do
    @notification.actor = nil
    assert_not @notification.valid?
  end

  test 'action should be present' do
    @notification.action = nil
    assert_not @notification.valid?
  end

  test 'read should default to false' do
    @notification.save
    assert_equal false, @notification.read
  end

  test 'mark_as_read! should mark notification as read' do
    @notification.save
    @notification.mark_as_read!
    assert @notification.read
  end

  test 'message should return correct format for liked action' do
    @notification.action = 'liked'
    assert_includes @notification.message, 'liked your micropost'
  end

  test 'message should return correct format for commented action' do
    @notification.action = 'commented'
    assert_includes @notification.message, 'commented on your micropost'
  end

  test 'message should return correct format for mentioned action' do
    @notification.action = 'mentioned'
    assert_includes @notification.message, 'mentioned you'
  end
end
