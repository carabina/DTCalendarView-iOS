#
# Be sure to run `pod lib lint DTCalendarView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DTCalendarView'
  s.version          = '0.7.1'
  s.summary          = 'A vertical scrolling calendar'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
DTCalendarView is a library to present a vertical scrolling calendar.
It supports single value and range selection and dragging of selected dates.
The font and color of most items can be styled.
                       DESC

  s.homepage         = 'https://stash.dynamit.com/projects/MOB/repos/dtcalendarview/browse'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tim LeMaster' => 'tim@dynamit.com' }
  s.source           = { :git => 'ssh://git@stash.dynamit.com/mob/dtcalendarview.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'DTCalendarView/Classes/**/*'

end
