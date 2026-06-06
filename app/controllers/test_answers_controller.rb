class TestAnswersController < ApplicationController
  def create
    @test_session = find_test_session
    return head :not_found unless @test_session && !@test_session.finished?

    @question = @test_session.current_question
    @correct  = QuestionEngine.check_answer(@question, params[:answer])
    @user_answer = params[:answer].to_s

    @test_session.increment!(:score) if @correct

    if @test_session.last_question?
      @test_session.update!(finished_at: Time.current, current_index: @test_session.current_index + 1)
      session.delete(:test_session_id)
      @finished = true
    else
      @test_session.increment!(:current_index)
      @next_question = @test_session.reload.current_question
    end

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def find_test_session
    sid = session[:test_session_id]
    return nil unless sid
    Current.user.test_sessions.find_by(id: sid, finished_at: nil)
  end
end
