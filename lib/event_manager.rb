# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip) # rubocop:disable Metrics/MethodLength
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

# template_letter = File.read('form_letter.erb')
# erb_template = ERB.new template_letter

# contents.each do |row|
#   id = row[0]
#   name = row[:first_name]
#   zipcode = row[:zipcode]
#
#   zipcode = clean_zipcode(row[:zipcode])
#
#   legislators = legislators_by_zipcode(zipcode)
#
#   form_letter = erb_template.result(binding)
#
#   save_thank_you_letter(id,form_letter)
#
# end

def clean_phone_number(phone_number)
  phone_number.gsub!(/\D/, '')
  if phone_number.length == 11 && phone_number[0] == '1'
    phone_number.slice!(0)
  elsif phone_number.length > 10 || phone_number.length < 10
    phone_number.to_s.rjust(10, '0')[0..9]
  else
    phone_number
  end
end

def most_common_reg_hours(content)
  reg_hours = []
  content.each do |row|
    reg_date = row[:regdate]
    reg_hour = Time.strptime(reg_date, '%m/%d/%y %k:%M').strftime('%k')
    reg_hours.push(reg_hour)
  end
  reg_hours.tally.sort_by { |_k, v| -v }.to_h.keys
end

def most_common_reg_days(content)
  reg_days = []
  content.each do |row|
    reg_date = row[:regdate]
    reg_day = Time.strptime(reg_date, '%m/%d/%y %k:%M').strftime('%A')
    reg_days << reg_day
  end
  reg_days.tally.sort_by { |_k, v| -v }.to_h.keys
end


puts 'The most common registration days in descending order are: '
puts(most_common_reg_days(contents).each { |day| puts day })
 contents.rewind
puts 'The most common registration hours in descending order are: '
most_common_reg_hours(contents).each { |hour| p "#{hour}:00" }


