# frozen_string_literal: true

require 'sqlite3'

def connect_to_db
  db = SQLite3::Database.new('./db/ad_db')
  db.results_as_hash = true
  db
end

def numeric_sort(db)
  temp = nil
  count = 0

  db.create_function('numeric_sort', 1) do |func, value|
    content_title = value.match(/(.*?)\s\d+$/).nil? ? value : value.match(/(.*?)\s\d+$/)

    if content_title.is_a?(String)
      unless content_title == temp
        temp = content_title
        count += 1
      end
    elsif content_title.is_a?(Array)
      unless content_title[1] == temp
        temp = content_title[1]
        count += 1
      end
    end

    # match_data = value.match(/\s(\d+)$/)
    # numeric_part = match_data ? match_data[1].to_i : 1

    func.result = count
  end

end

