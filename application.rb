require 'sinatra'

get '/' do
  erb :index
end

post '/' do
  @totalEarnedCredits = 180
  @totalInProgressCredits = 13
  @totalNeededCredits = 10
  @upperDivEarnedCredits = 70
  @upperDivInProgressCredits = 13
  @upperDivNeededCredits = 4
  #params[:content]
  erb :index
end
