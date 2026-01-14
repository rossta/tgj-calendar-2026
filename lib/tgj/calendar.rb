require "net/http"
require "uri"
require "icalendar"
require "date"
require "fileutils"
require "puppeteer"

module Tgj
  class Calendar
    URL = "https://www.golfersjournal.com/tgj-events/"
    OUTPUT_DIR = "feeds"

    def self.generate
      FileUtils.mkdir_p(OUTPUT_DIR)

      puts "Launching headless browser..."

      Puppeteer.launch(headless: true, args: ["--no-sandbox", "--disable-setuid-sandbox"]) do |browser|
        page = browser.new_page
        page.goto(URL, wait_until: "networkidle0")

        sleep 2 # let JS finish rendering

        puts "Extracting events from rendered DOM..."

        # Evaluate JS in the context of the page to get structured event data
        events_data = page.evaluate(<<~JS)
          () => {
            const items = []
            // Use DESKTOP blocks to avoid duplicates; they contain clean title/date/location/registration
            document.querySelectorAll('.event-calendar-item-wrapper.event-calendar-desktop').forEach(wrapper => {
              const item = wrapper.querySelector('.event-calendar-item')
              if (!item) return

              const title = item.querySelector('.event-title')?.innerText?.trim()
              const date = item.querySelector('.event-dates')?.innerText?.trim()
              const location = item.querySelector('.event-location')?.innerText?.trim()
              const reg = item.querySelector('.event-registration .registration-date')?.innerText?.trim()
              const url = wrapper.querySelector('a.event-calendar-item-link')?.getAttribute('href')

              if (title && date) {
                items.push({ title, date, registration: reg, location, url })
              }
            })
            return items
          }
        JS

        puts "Found #{events_data.length} events"

        cal = Icalendar::Calendar.new
        cal.prodid = "-//The Golfer's Journal Events//EN"
        cal.version = "2.0"

        events_data.each do |ev|
          next unless ev["title"] && ev["date"]

          title = ev["title"].to_s.strip
          date_text = ev["date"].to_s.strip
          reg_text = ev["registration"].to_s.strip
          location = ev["location"].to_s.strip
          url = ev["url"].to_s.strip

          # Parse event dates:
          # TGJ date formats like "Apr 19–21, 2026" or "Mar 20, 2026"
          year = Date.today.year
          # Normalize dashes and split on en dash/hyphen
          parts = date_text.split(/\u2013|–|—|-/).map(&:strip)
          # Extract month name from the first part
          month = parts.first.split.first

          begin
            start_date = Date.parse("#{parts.first} #{year}")
            # If the end part is just a day number, reuse month; otherwise trust parsing
            end_part = (parts.length > 1) ? parts.last : parts.first
            end_part = "#{month} #{end_part}" if end_part =~ /^\d{1,2}$/ && month
            end_date = Date.parse("#{end_part} #{year}") + 1
          rescue
            puts "Skipping event (date parse failed): #{title} (#{date_text})"
            next
          end

          uid_base = title.downcase.gsub(/[^a-z0-9]+/, "-")

          # Event
          cal.event do |e|
            e.uid = "tgj-#{uid_base}-#{start_date}@golfersjournal.com"
            e.summary = "TGJ: #{title}"
            e.dtstart = Icalendar::Values::Date.new(start_date)
            e.dtend = Icalendar::Values::Date.new(end_date)
            desc_lines = []
            desc_lines << "Location: #{location}" unless location.nil? || location.empty?
            desc_lines << "Registration: #{reg_text}" unless reg_text.nil? || reg_text.empty?
            desc_lines << "Source: #{url.empty? ? URL : url}"
            e.description = desc_lines.join("\n")
            e.url = (url.empty? ? URL : url)
          end

          # Registration open date
          next unless reg_text&.match(%r{(\d{1,2})/(\d{1,2})})

          month = ::Regexp.last_match(1).to_i
          day = ::Regexp.last_match(2).to_i
          reg_date = begin
            Date.new(year, month, day)
          rescue
            nil
          end

          next unless reg_date

          cal.event do |r|
            r.uid = "tgj-reg-#{uid_base}-#{reg_date}@golfersjournal.com"
            r.summary = "TGJ Registration Opens: #{title}"
            r.dtstart = Icalendar::Values::Date.new(reg_date)
            r.dtend = Icalendar::Values::Date.new(reg_date + 1)
            r.description = "Registration opens today for #{title}"
            r.url = (url.empty? ? URL : url)
          end
        end

        ics_content = cal.to_ical

        File.write("#{OUTPUT_DIR}/tgj.ics", ics_content)
        File.write("#{OUTPUT_DIR}/tgj.webcal", ics_content)

        puts "Feeds generated:"
        puts " - feeds/tgj.ics"
        puts " - feeds/tgj.webcal"
      end
    end
  end
end
