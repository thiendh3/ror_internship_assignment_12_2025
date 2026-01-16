class LikesController < ApplicationController
  before_action :logged_in_user
  before_action :set_micropost

  # GET /microposts/:id/likes
  def index
    likes = @micropost.likes.includes(:user).limit(500)
    # Force rendering the partial as HTML even when request.format == :json
    html = render_to_string(partial: 'likes/list', locals: { likes: likes }, formats: [:html])
    render json: { html: html }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def create
    reaction_type = params[:reaction_type].presence || 'like'

    @micropost.like!(current_user, reaction_type) unless handle_existing_like(reaction_type)

    # Create notification
    NotificationService.create_like_notification(current_user, @micropost, reaction_type)

    broadcast_reaction_update

    render json: reaction_response(reaction_type), status: :created
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    unless @micropost.liked_by?(current_user)
      render json: { error: 'Not liked yet' }, status: :unprocessable_entity
      return
    end

    @micropost.unlike!(current_user)

    # Remove notification
    NotificationService.remove_like_notification(current_user, @micropost)

    broadcast_reaction_update

    render json: {
      liked: false,
      likes_count: @micropost.likes_count,
      reaction_counts: @micropost.reaction_counts
    }, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_micropost
    @micropost = Micropost.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Micropost not found' }, status: :not_found
  end

  def handle_existing_like(reaction_type)
    existing_like = @micropost.likes.find_by(user_id: current_user.id)
    return false unless existing_like

    if existing_like.reaction_type == reaction_type
      render json: { error: 'Already reacted' }, status: :unprocessable_entity
      return true
    end

    existing_like.update(reaction_type: reaction_type)
    true
  end

  def reaction_response(reaction_type)
    {
      liked: true,
      reaction_type: reaction_type,
      likes_count: @micropost.likes_count,
      reaction_counts: @micropost.reaction_counts
    }
  end

  def broadcast_reaction_update
    ActionCable.server.broadcast(
      'microposts',
      {
        type: 'reaction',
        micropost_id: @micropost.id,
        reaction_counts: @micropost.reaction_counts,
        likes_count: @micropost.likes_count
      }
    )
  end
end
