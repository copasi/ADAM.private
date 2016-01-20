require 'sqlite3'

class AlgoPiperStorage
  def createDB(name)
    @db_name = name
    begin
      @db = SQLite3::Database.new(@db_name)
      puts "Database " + @db_name + " created .."
    rescue SQLite3::Exception => e
      puts e
    ensure
      @db.close() if @db
    end
  end

  def createTables()
    begin
      @db = SQLite3::Database.open(@db_name)
      query = "CREATE TABLE IF NOT EXISTS Job (JobID INTEGER PRIMARY KEY, Input TEXT, Callback TEXT, Basicrvg TEXT, React TEXT, Sdds TEXT, Result TEXT)"
      @db.execute(query)
      puts "Tables created .."
    rescue SQLite3::Exception => e
      puts e
    ensure
      @db.close() if @db
    end
  end

  def insertJob(input_json, callback)
    begin
      @db = SQLite3::Database.open(@db_name)
      query = "INSERT INTO Job (Input, Callback) VALUES (\'" + input_json + "\',\'" + callback + "\')"
      @db.execute(query)
      job_id = @db.last_insert_row_id
      puts "Job " + String(job_id) + " inserted .."
      return job_id
    rescue SQLite3::Exception => e
      puts e
    ensure
      @db.close() if @db
    end
  end

  def deleteJob(job_id)
    begin
      @db = SQLite3::Database.open(@db_name)
      query = "DELETE FROM Job WHERE JobID = " + String(job_id)
      @db.execute(query)
      puts "Job " + String(job_id) + " deleted .."
      return true
    rescue SQLite3::Exception => e
      puts e
      return false
    ensure
      @db.close() if @db
    end
  end

  def updateModule(job_id, module_name, status)
    begin
      @db = SQLite3::Database.open(@db_name)
      query = "UPDATE Job SET " + module_name + " = \'" + status + "\' WHERE JobID = " + String(job_id)
      @db.execute(query)
      puts "Job " + String(job_id) + " updated at module " + module_name + " .."
      return true
    rescue SQLite3::Exception => e
      puts e
      return false
    ensure
      @db.close() if @db
    end
  end

  def postResult(job_id, result)
    begin
      @db = SQLite3::Database.open(@db_name)
      query = "UPDATE Job SET Result = \'" + result + "\' WHERE JobID = " + String(job_id)
      @db.execute(query)
      puts "Job " + String(job_id) + " updated with the final result .."
      return true
    rescue SQLite3::Exception => e
      puts e
      return false
    ensure
      @db.close() if @db
    end
  end

  def getJobRecord(job_id)
    begin
      @db = SQLite3::Database.open(@db_name)
      query = "SELECT * FROM Job WHERE JobID = " + String(job_id)
      stm = @db.prepare query
      rs = stm.execute
      puts "Job " + String(job_id) + " record returned .."
      rs.each do |row|
        record = Hash.new
        record["job_id"] = row[0]
        record["input"] = row[1]
        record["callback"] = row[2]
        record["basicrvg"] = row[3]
        record["react"] = row[4]
        record["sdds"] = row[5]
        record["result"] = row[6]
        return record
      end
    rescue SQLite3::Exception => e
      puts e
      return false
    ensure
      stm.close() if stm
      @db.close() if @db
    end
  end

end

if $0 == __FILE__ then
  myDB = AlgoPiperStorage.new
  myDB.createDB("storage.db")
  myDB.createTables()
  #myDB.insertJob("this is a json", "this is a callback")
  #myDB.updateModule(1,"sdds" , "")
  #myDB.deleteJob(1)
  #myDB.postResult(2, "json result")
  record = myDB.getJobRecord(4)
  puts record
end