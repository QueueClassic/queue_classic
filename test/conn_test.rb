require File.expand_path("../helper.rb", __FILE__)

class ConnTest < QCTest

  def setup
    init_db
  end

  def test_extracts_the_segemnts_to_connect
    database_url = "postgres://ryan:secret@localhost:1234/application_db"
    normalized = QC::Conf.normalized_db_url(URI.parse(database_url))
    assert_equal ["localhost",
                  1234,
                  nil, "",
                  "application_db",
                  "ryan",
                  "secret"], normalized
  end

  def test_regression_database_url_without_host
    database_url = "postgres:///my_db"
    normalized = QC::Conf.normalized_db_url(URI.parse(database_url))
    assert_equal [nil, 5432, nil, "", "my_db", nil, nil], normalized
  end

end
