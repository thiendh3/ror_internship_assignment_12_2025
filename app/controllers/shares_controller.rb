# frozen_string_literal: true

class SharesController < ApplicationController
  include ActionView::Helpers::DateHelper

  before_action :logged_in_user
  before_action :set_micropost, only: [:create, :index]

  def create
    @share = @micropost.shares.build(
      user: current_user,
      share_type: params[:share_type] || 'share',
      content: params[:content]
    )

    if @share.save
      broadcast_share('create')
      render json: {
        success: true,
        share: share_json(@share),
        share_html: render_share_html(@share),
        shares_count: @micropost.reload.shares_count,
        shared_by_user: true,
        redirect_url: user_path(current_user, tab: 'shares', anchor: "share-#{@share.id}")
      }, status: :created
    else
      render json: { success: false, errors: @share.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @share = current_user.shares.find_by(id: params[:id])
    return render json: { success: false, error: 'Share not found' }, status: :not_found unless @share

    @micropost = @share.micropost # May be nil if original deleted
    
    if @share.destroy
      if @micropost
        broadcast_share('destroy')
        render json: {
          success: true,
          shares_count: @micropost.reload.shares_count,
          shared_by_user: @micropost.shares.exists?(user: current_user)
        }
      else
        render json: { success: true }
      end
    else
      render json: { success: false, error: 'Failed to delete' }, status: :unprocessable_entity
    end
  end

  def index
    render json: {
      success: true,
      shares_count: @micropost.shares_count,
      shared_by_user: @micropost.shares.exists?(user: current_user)
    }
  end

  private

  def set_micropost
    @micropost = Micropost.find(params[:micropost_id])
  end

  def share_json(share)
    {
      id: share.id,
      content: share.content,
      created_at: share.created_at,
      time_ago: time_ago_in_words(share.created_at),
      user: {
        id: share.user.id,
        name: share.user.name,
        gravatar_url: gravatar_url(share.user)
      },
      original_post: {
        id: share.micropost.id,
        content: share.micropost.content,
        user: {
          id: share.micropost.user.id,
          name: share.micropost.user.name,
          gravatar_url: gravatar_url(share.micropost.user)
        },
        image_url: share.micropost.image.attached? ? url_for(share.micropost.display_image) : nil
      }
    }
  end

  def gravatar_url(user, size: 50)
    gravatar_id = Digest::MD5.hexdigest(user.email.downcase)
    "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
  end

  def render_share_html(share)
    render_to_string(partial: 'shares/share', locals: { share: share }, formats: [:html])
  end

  def broadcast_share(action)
    MicropostsChannel.broadcast_to(
      'feed',
      {
        action: "share_#{action}",
        micropost_id: @micropost.id,
        shares_count: @micropost.reload.shares_count,
        user_id: current_user.id,
        share: action == 'create' ? share_json(@share) : nil,
        share_html: action == 'create' ? render_share_html(@share) : nil
      }
    )
  rescue StandardError => e
    Rails.logger.error("Failed to broadcast share: #{e.message}")
  end
end
