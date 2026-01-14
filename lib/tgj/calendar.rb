require "net/http"
require "uri"
require "nokogiri"
require "icalendar"
require "date"
require "fileutils"

module Tgj
  class Calendar
    URL = "https://www.golfersjournal.com/tgj-events/"
    OUTPUT_DIR = "feeds"

    def self.generate
      FileUtils.mkdir_p(OUTPUT_DIR)

      html = Net::HTTP.get(URI(URL))
      doc = Nokogiri::HTML(html)

      calendar = Icalendar::Calendar.new
      calendar.prodid = "-//The Golfer's Journal Events//EN"
      calendar.version = "2.0"

      current_year = Date.today.year + 1

      doc.css(".tgj-event").each do |event_node|
        title = event_node.at_css(".tgj-event__title")&.text&.strip
        date_text = event_node.at_css(".tgj-event__date")&.text&.strip
        reg_text = event_node.at_css(".tgj-event__register")&.text&.strip

        next unless title && date_text

        parts = date_text.split(/–|-/).map(&:strip)
        start_date = Date.parse("#{parts.first} #{current_year}")
        end_date = Date.parse("#{parts.last} #{current_year}") + 1

        calendar.event do |e|
          e.summary = "TGJ: #{title}"
          e.dtstart = Icalendar::Values::Date.new(start_date)
          e.dtend = Icalendar::Values::Date.new(end_date)
          e.description = "Registration: #{reg_text}\nSource: #{URL}"
          e.uid = "tgj-#{title.downcase.gsub(/[^a-z0-9]+/, "-")}-#{start_date}@golfersjournal.com"
        end

        # Add registration open event if date is present
        next unless reg_text&.match(%r{(\d{1,2})/(\d{1,2})})

        month = ::Regexp.last_match(1).to_i
        day = ::Regexp.last_match(2).to_i
        reg_date = Date.new(current_year, month, day)

        calendar.event do |e|
          e.summary = "TGJ Registration Opens: #{title}"
          e.dtstart = Icalendar::Values::Date.new(reg_date)
          e.dtend = Icalendar::Values::Date.new(reg_date + 1)
          e.description = "Registration opens today for #{title}"
          e.uid = "tgj-reg-#{title.downcase.gsub(/[^a-z0-9]+/, "-")}-#{reg_date}@golfersjournal.com"
        end
      end

      ics_content = calendar.to_ical

      File.write("#{OUTPUT_DIR}/tgj.ics", ics_content)
      File.write("#{OUTPUT_DIR}/tgj.webcal", ics_content)

      puts "Generated feeds:"
      puts " - feeds/tgj.ics"
      puts " - feeds/tgj.webcal"
    end
  end
end
