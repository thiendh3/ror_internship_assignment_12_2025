# frozen_string_literal: true

require 'test_helper'

class NotificationServiceTest < ActiveSupport::TestCase
  def setup
    @follower = users(:michael)
    @followed = users(:archer)
  end

  test 'create_follow_notification creates notification for followed user' do
    relationship = Relationship.create!(follower: @follower, followed: @followed)

    assert_difference 'Notification.count', 1 do
      NotificationService.create_follow_notification(relationship)
    end

    notification = Notification.last
    assert_equal @followed, notification.user
    assert_equal relationship, notification.notifiable
    assert_equal 'follow', notification.notification_type
    assert_not notification.read

    relationship.destroy
  end
end
