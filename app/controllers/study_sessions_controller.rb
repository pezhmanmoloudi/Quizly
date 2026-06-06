class StudySessionsController < ApplicationController
  def index
    @study_sessions = Current.user.study_sessions
                                  .completed
                                  .includes(:deck)
                                  .recent
                                  .limit(50)
  end
end
