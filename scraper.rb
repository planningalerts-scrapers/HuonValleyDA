#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
Bundler.require

require "scraperwiki"
require "mechanize"

# Parses a single application from an accordion grid item
def parse_application(accordion_item)
  header = accordion_item.at(".accordion-grid-item__header").inner_text.strip
  return nil unless header.include?("Planning Application")
  
  title = accordion_item.at(".accordion-grid-item__title").inner_text.strip
  description = accordion_item.at(".accordion-grid-item__description").inner_text.strip

  # Extract address and CT number from the description
  match = description.match(/(.*)\s+-\s+(.+)\s+(\(CT-[^)]+\))/)
  
  if match
    council_reference = title
    ct_number = match[3].strip
    description_text = "#{match[1].strip} #{ct_number}"
    address = match[2].strip
  else
    council_reference = title
    description_text = description
    address = description.split(" - ").last.strip rescue ""
  end

  more_info = accordion_item.at(".accordion-body")
  info_url = nil
  if more_info && more_info.at(".plan-file-list__item")
    info_url = more_info.at(".plan-file-list__item")["href"]
  end

  address = "#{address} TAS" unless address.include?("TAS")

  # Uncomment this when we have more information about dates
  # "date_received" => date_received ? Date.parse(date_received).to_s : nil,
  # "on_notice_to" => on_notice_to ? Date.parse(on_notice_to).to_s : nil,

  {
    "council_reference" => council_reference,
    "description" => description_text,
    "address" => address,
    "date_scraped" => Date.today.to_s,
    "info_url" => info_url
  }
end

def scrape_page(url, max_pages)
  max_pages -= 1
  return if max_pages < 0

  agent = Mechanize.new
  agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
  page = agent.get(url)
  
  page.search(".accordion-grid-item").each do |item|
    record = parse_application(item)
    next if record.nil?
    
    puts "Saving #{record['council_reference']}..."
    ScraperWiki.save_sqlite(["council_reference"], record)
  end
  
  next_link = page.at(".pagination .next")
  if next_link && !next_link.attr("class").include?("disabled")
    next_url = next_link["href"]
    puts "Following next page: #{next_url}"
    scrape_page(next_url, max_pages)
  end
end

scrape_page("https://www.huonvalley.tas.gov.au/development/planning/advertised-applications/", 100)
