namespace :demo do
  desc "Build the database the browser loads (pwa/public/demo.sqlite3) from the corpus"
  task :database do
    build_path = "tmp/demo-build.sqlite3"
    target = "pwa/public/demo.sqlite3"

    # A fresh database every time rather than the development one, so the file holds exactly what
    # db/schema.rb and db/seeds.rb say today (db:seed skips the works it already has). A child
    # process, because DATABASE_URL has to be set before Rails connects.
    FileUtils.rm_f(build_path)
    system({ "DATABASE_URL" => "sqlite3:#{build_path}" }, "bin/rails", "db:prepare", "db:seed", exception: true)

    require "sqlite3"
    FileUtils.mkdir_p(File.dirname(target))
    FileUtils.rm_f(target)
    # VACUUM INTO writes a compact single-file copy. The copy still carries the WAL header the Rails
    # adapter set on the source, and sqlite-wasm has no shared memory for WAL, so the copy is
    # switched back to a rollback journal. The environment is relabelled so that the browser's
    # db:prepare does not take the file for another environment's database.
    SQLite3::Database.new(build_path) { |db| db.execute("VACUUM INTO ?", File.expand_path(target)) }
    copy = SQLite3::Database.new(target)
    copy.execute("PRAGMA journal_mode = DELETE")
    copy.execute("UPDATE ar_internal_metadata SET value = 'wasm' WHERE key = 'environment'")
    sections = copy.get_first_value("SELECT count(*) FROM sections")
    copy.close

    puts "#{target}: #{(File.size(target) / 1024.0 / 1024).round(1)} MB, #{sections} sections"
  end
end
