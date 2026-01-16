# frozen_string_literal: true

class ReactionsController < ApplicationController
  before_action :logged_in_user
  before_action :set_reactable

  def create
    @reaction = @reactable.reactions.find_by(user: current_user)

    if @reaction
      # Update existing reaction
      if @reaction.reaction_type == params[:reaction_type]
        # Same reaction type - remove it
        @reaction.destroy
        render json: { success: true, action: 'removed', reactions_data: reactions_data }
      else
        # Different reaction type - update it
        @reaction.update(reaction_type: params[:reaction_type])
        render json: { success: true, action: 'updated', reactions_data: reactions_data }
      end
    else
      # Create new reaction
      @reaction = @reactable.reactions.build(user: current_user, reaction_type: params[:reaction_type])
      if @reaction.save
        render json: { success: true, action: 'created', reactions_data: reactions_data }
      else
        render json: { success: false, errors: @reaction.errors.full_messages }, status: :unprocessable_entity
      end
    end

    broadcast_reaction_update
  end

  def destroy
    @reaction = @reactable.reactions.find_by(user: current_user)
    if @reaction&.destroy
      broadcast_reaction_update
      render json: { success: true, reactions_data: reactions_data }
    else
      render json: { success: false }, status: :not_found
    end
  end

  def index
    render json: { success: true, reactions_data: reactions_data }
  end

  private

  def set_reactable
    if params[:micropost_id]
      @reactable = Micropost.find(params[:micropost_id])
      @reactable_type = 'micropost'
    elsif params[:comment_id]
      @reactable = Comment.find(params[:comment_id])
      @reactable_type = 'comment'
    end
  end

  def reactions_data
    @reactable.reload # Reload to get updated counter_cache
    grouped = @reactable.reactions.group(:reaction_type).count
    user_reaction = @reactable.reactions.find_by(user: current_user)

    {
      total_count: @reactable.reactions_count,
      by_type: grouped,
      user_reaction: user_reaction&.reaction_type,
      top_reactions: grouped.sort_by { |_, v| -v }.first(3).map(&:first)
    }
  end

  def broadcast_reaction_update
    MicropostsChannel.broadcast_to(
      'feed',
      {
        action: 'reaction_update',
        reactable_id: @reactable.id,
        reactable_type: @reactable_type,
        micropost_id: @reactable_type == 'micropost' ? @reactable.id : @reactable.micropost_id,
        user_id: current_user.id,
        reactions_data: reactions_data
      }
    )
  rescue StandardError => e
    Rails.logger.error("Failed to broadcast reaction: #{e.message}")
  end
end
