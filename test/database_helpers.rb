module DatabaseHelpers

  def init_db(table_name=nil)
    database  = QC::Database.new(table_name)
    database.silence_warnings
    database.init_db
    database.disconnect
    true
  end

end
