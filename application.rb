require 'sinatra'

get '/' do
  erb :index
end

post '/' do
  parseReport(params[:DARSreport])
  erb :index
end

##
#   Method: parseReport
#   Params: reportText - the DARS report
#   Returns: None
#   Purpose: Sets instance variables needed for report ERB templates
def parseReport(reportText)
  # First, get credit summary
  creditSummary = getCredits(reportText)
  @totalEarnedCredits        = creditSummary[:totalEarned]
  @totalInProgressCredits    = creditSummary[:totalInProgress]
  @totalNeededCredits        = creditSummary[:totalNeeded]
  @upperDivEarnedCredits     = creditSummary[:upperDivEarned]
  @upperDivInProgressCredits = creditSummary[:upperDivInProgress]
  @upperDivNeededCredits     = creditSummary[:upperDivNeeded]

  # Get GPA summary and color red or green based on min requirements
  gpaSummary = getGPA(reportText)
  @cumulativeGPA = gpaSummary[:cumulativeGPA]
  @majorGPA = gpaSummary[:majorGPA]

  if @cumulativeGPA.to_i > 2
    @cumulativeGPAStatus = 'color: green'
    @cumulativeGPAIconClass = 'glyphicon glyphicon-ok'
  else
    @cumulativeGPAStatus = 'color: red'
    @cumulativeGPAIconClass = 'glyphicon glyphicon-remove'
  end

  if @majorGPA.to_i > 2
    @majorGPAStatus = 'color: green'
    @majorGPAIconClass = 'glyphicon glyphicon-ok'
  else
    @majorGPAStatus = 'color: red'
    @majorGPAIconClass = 'glyphicon glyphicon-remove'
  end

  # Get general and sub requirement status
  @genRequirementsArray = getGeneralRequirements(reportText)
  @subRequirementsArray = getSubRequirements(reportText)
  @verboseSectionsArray = getVerboseSections(reportText)
end

##
#   Method: getCredits
#   Params: reportText - the DARS report
#   Returns: creditSummary - a hash of credit values
def getCredits(reportText)
  creditSummary = Hash.new()
  # Regular Expressions
  totalEarnedCredits        = /EARNED:? {0,2}?(\d{1,3}\.\d{2}) CREDITS/;
  totalInProgressCredits    = /IN-PROGRESS:? {0,2}?(\d{1,3}\.\d{2}) CREDITS/;
  neededCredits             = /NEEDS:? *(\d{1,3}\.\d{2})* CREDITS/;
  upperDivEarnedCredits     = /\( *(\d{1,3}\.\d{2}) HOURS TAKEN *\)/; # The first one
  upperDivInProgressCredits = /In-Prog-> *(\d{1,3}.\d{2}) CREDITS/;   # The first one

  # Matches
  totalEarnedCredits        = reportText.match(totalEarnedCredits)
  totalInProgressCredits    = reportText.match(totalInProgressCredits)
  upperDivEarnedCredits     = reportText.match(upperDivEarnedCredits)
  upperDivInProgressCredits = reportText.match(upperDivInProgressCredits)

  totalEarnedCredits = 0 if totalEarnedCredits == nil
  totalInProgressCredits = 0 if totalInProgressCredits == nil
  upperDivEarnedCredits = 0 if upperDivEarnedCredits == nil
  upperDivInProgressCredits = 0 if upperDivInProgressCredits == nil

  # Needed credits section. This is needed due to DARS formatting
  neededCreditArray = Array.new()
  neededCreditArray = reportText.scan(neededCredits)
  if neededCreditArray == [[nil]]
    neededCreditArray = ['0.00', '0.00']
  elsif neededCreditArray[0] == [nil]
    neededCreditArray[0] = '0.00'
  elsif neededCreditArray.length == 1
    neededCreditArray << ['0.00']
  end

  creditSummary[:totalEarned]        = totalEarnedCredits[1]
  creditSummary[:totalInProgress]    = totalInProgressCredits[1]
  creditSummary[:totalNeeded]        = neededCreditArray[0][0]
  creditSummary[:upperDivEarned]     = upperDivEarnedCredits[1]
  creditSummary[:upperDivInProgress] = upperDivInProgressCredits[1]
  creditSummary[:upperDivNeeded]     = neededCreditArray[1][0]
  return creditSummary
end

##
#   Method: getGPA
#   Params: reportText - the DARS report
#   Returns: gpaSummary - a hash of GPA values
def getGPA(reportText)
  gpaSummary = Hash.new()
  # We need to scan this way due to DARS formatting
  gpaArray = Array.new()
  gpaArray = reportText.scan(/(\d\.\d{2}) GPA/)
  if gpaArray == nil
    gpaArray = ['0.00', '0.00']
  elsif gpaArray.length == 1
    gpaArray[1] = '0.00'
  end

  gpaSummary[:cumulativeGPA] = gpaArray[0][0]
  gpaSummary[:majorGPA]      = gpaArray[1][0]
  return gpaSummary
end

##
#   Method: getGeneralRequirements
#   Params: reportText - the DARS report
#   Returns: genRequirementArray - an array of prepared HTML
def getGeneralRequirements(reportText)
  genRequirementsArray = Array.new()
  mainRequirements = reportText.scan(/(NO  |OK  |IP  )(?!=)(.*)/)
  mainRequirements.each do |req|
    if req[0] == 'OK  '
      rectClasses = 'dataRect alert alert-success'
      iconClass   = 'glyphicon glyphicon-ok'
      tipMsg      = 'Requirement Completed!'
    elsif req[0] == 'IP  '
      rectClasses = 'dataRect alert alert-warning'
      iconClass   = 'glyphicon glyphicon-refresh'
      tipMsg      = 'Requirement In Progress'
    elsif req[0] == 'NO  '
      rectClasses = 'dataRect alert alert-danger'
      iconClass   = 'glyphicon glyphicon-remove'
      tipMsg      = 'Requirement Not Completed'
    end
    genRequirementsArray << "<div class='#{rectClasses}' title='#{tipMsg}' onclick=\"window.location.hash='#{req[1][0..30].gsub(/\s+/,"")}'; \"'> #{req[1].to_s.strip} <span class='#{iconClass} statusIcon'></span></div>"
  end
  return genRequirementsArray
end

##
#   Method: getSubRequirements
#   Params: reportText - the DARS report
#   Returns: subRequirementArray - an array of prepared HTML
def getSubRequirements(reportText)
  subRequirementsArray = Array.new()
  subRequirements = reportText.scan(/(\+|\-) *\d{1,2}\)(.*)/)

  subRequirements.each do |req|
  puts req[0].inspect
    if req[0] == '+'
      rectClasses = 'dataRect alert alert-success';
      iconClass   = 'glyphicon glyphicon-ok';
      tipMsg      = 'Requirement Completed!';
    else
      rectClasses = 'dataRect alert alert-danger';
      iconClass   = 'glyphicon glyphicon-remove';
      tipMsg      = 'Requirement Not Completed';
    end
    subRequirementsArray << "<div class='#{rectClasses}' title='#{tipMsg}'> #{req[1].to_s.strip} <span class='#{iconClass} statusIcon'></span></div>"
  end
  return subRequirementsArray
end

def getVerboseSections(reportText)
  reportArray = Array.new()
  sectionArray = reportText.scan(/(NO  |OK  |IP  )([^=]+)(?!={66})/)
  sectionArray.each do |section|
    if section[0] =~ /NO/
      classes   = 'callout callout-danger'
      iconClass = 'glyphicon glyphicon-remove'
    elsif section[0] =~ /OK/
      classes   = 'callout callout-success'
      iconClass = 'glyphicon glyphicon-ok'
    else
      classes   = 'callout callout-warning'
      iconClass = 'glyphicon glyphicon-refresh'
    end
    puts section[1][0..20].gsub(/\s+/, "")
    reportArray << "<div class='#{classes}' id='#{section[1][0..30].gsub(/\s+/, "")}'><pre>#{section[1].to_s}</pre> <span class='#{iconClass} statusIcon'></span></div>"
  end

  return reportArray
end
