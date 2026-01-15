# frozen_string_literal: true

class MicropostsController < ApplicationController
  include ActionView::Helpers::DateHelper

  before_action :logged_in_user, only: %i[create destroy update share]
  before_action :correct_user, only: %i[destroy update]
  before_action :set_micropost, only: [:show, :share]

  def show
    @micropost = Micropost.find(params[:id])
    respond_to do |format|
      format.html
      format.json do
        # Only owner can see edit history
        include_versions = logged_in? && current_user.id == @micropost.user_id
        render json: micropost_json(@micropost, include_versions: include_versions)
      end
    end
  end

  def create
    @micropost = current_user.microposts.build(micropost_params)
    @micropost.image.attach(params[:micropost][:image]) if params[:micropost][:image].present?

    respond_to do |format|
      if @micropost.save
        broadcast_micropost(@micropost, 'create')
        format.html do
          flash[:success] = 'Micropost created!'
          redirect_to root_url
        end
        format.json { render json: { success: true, micropost: micropost_json(@micropost), html: render_micropost_html(@micropost) }, status: :created }
      else
        format.html do
          @feed_items = current_user.feed.paginate(page: params[:page])
          render 'static_pages/home'
        end
        format.json { render json: { success: false, errors: @micropost.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @micropost.update(micropost_params)
        broadcast_micropost(@micropost, 'update')
        format.html do
          flash[:success] = 'Micropost updated!'
          redirect_to root_url
        end
        format.json { render json: { success: true, micropost: micropost_json(@micropost), html: render_micropost_html(@micropost) } }
      else
        format.html { redirect_to root_url, alert: 'Failed to update micropost' }
        format.json { render json: { success: false, errors: @micropost.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @micropost.destroy
    broadcast_micropost(@micropost, 'destroy')

    respond_to do |format|
      format.html do
        flash[:success] = 'Micropost is deleted'
        redirect_to request.referrer || root_url
      end
      format.json { render json: { success: true, id: params[:id] } }
    end
  end

  # Share a post - creates a new micropost with original_post_id
  def share
    original = @micropost.root_post # Always share the root post
    
    shared_post = current_user.microposts.build(
      content: params[:content].presence || '',
      original_post_id: original.id
    )

    if shared_post.save
      # Update shares_count on original
      original.increment!(:shares_count)
      
      # Notify original post owner
      notify_share(original, shared_post) if original.user_id != current_user.id
      
      broadcast_micropost(shared_post, 'create')
      
      render json: {
        success: true,
        micropost: micropost_json(shared_post),
        html: render_micropost_html(shared_post),
        redirect_url: user_path(current_user, anchor: "micropost-#{shared_post.id}")
      }, status: :created
    else
      render json: { success: false, errors: shared_post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def notify_share(original, shared_post)
    Notification.create!(
      user: original.user,
      notifiable: shared_post,
      notification_type: 'share'
    )
  rescue StandardError => e
    Rails.logger.error("Failed to notify share: #{e.message}")
  end

  def micropost_params
    params.require(:micropost).permit(:content, :image, :visibility)
  end

  def set_micropost
    @micropost = Micropost.find_by(id: params[:id])
  end

  def correct_user
    @micropost = current_user.microposts.find_by(id: params[:id])
    return if @micropost.present?

    respond_to do |format|
      format.html { redirect_to root_url }
      format.json { render json: { success: false, error: 'Unauthorized' }, status: :forbidden }
    end
  end

  def micropost_json(micropost, include_versions: false)
    result = {
      id: micropost.id,
      content: micropost.content,
      created_at: micropost.created_at,
      updated_at: micropost.updated_at,
      time_ago: time_ago_in_words(micropost.created_at),
      edited: micropost.updated_at > micropost.created_at,
      user: {
        id: micropost.user.id,
        name: micropost.user.name,
        gravatar_url: gravatar_url(micropost.user)
      },
      image_url: micropost.image.attached? ? url_for(micropost.display_image) : nil
    }

    if include_versions && micropost.versions.any?
      result[:versions] = micropost.versions.map do |v|
        {
          content: v.content,
          edited_at: v.edited_at,
          time_ago: time_ago_in_words(v.edited_at)
        }
      end
    end

    result
  end

  def gravatar_url(user, size: 50)
    gravatar_id = Digest::MD5.hexdigest(user.email.downcase)
    "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
  end

  def render_micropost_html(micropost)
    render_to_string(partial: 'microposts/micropost', locals: { micropost: micropost }, formats: [:html])
  end

  def broadcast_micropost(micropost, action)
    MicropostsChannel.broadcast_to(
      'feed',
      {
        action: action,
        micropost: micropost_json(micropost),
        html: action != 'destroy' ? render_micropost_html(micropost) : nil,
        micropost_id: micropost.id,
        user_id: micropost.user_id
      }
    )
  rescue StandardError => e
    Rails.logger.error("Failed to broadcast micropost: #{e.message}")
  end
end
