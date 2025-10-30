# frozen_string_literal: true

require 'sqlite3'

def connect_to_db
  db = SQLite3::Database.new('./db/ad_db')

  # 結果をハッシュとして返す
  db.results_as_hash = true
  db
end

