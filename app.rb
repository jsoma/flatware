DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/dev.sqlite3")

class Spreadsheet
  include DataMapper::Resource

  property :id, Serial
  property :google_key, String, :unique => true, :required => true, :format => /\A[\w\-]*\z/

  def base_json_path
    "/feeds/worksheets/#{google_key}/public/basic?alt=json-in-script&callback=Tabletop.singleton.loadSheets"
  end

  def base_json_content
    @base_json_content ||= open(endpoint + base_json_path).read
  end

  def sheet_paths
    if ENV.key('FLATWARE_USE_OLD_SHEETS') && ENV['FLATWARE_USE_OLD_SHEETS'] == true
      sq = "&sq="
    else
      sq = ""
    end

    @sheet_paths ||= @sheet_ids.map{ |sheet_id|
      "/feeds/list/#{google_key}/#{sheet_id}/public/values?alt=json-in-script#{sq}&callback=Tabletop.singleton.loadSheet"
    }
  end

  def sheet_ids
    @sheet_ids ||= base_json_content.scan(/\/public\/basic\/([\w\-]*)/).flatten.uniq
  end

  def storage
    @storage ||= Fog::Storage.new({:provider => 'AWS', 
                                   :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
                                   :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
                                   :connection_options => {
                                     :ssl_version => :TLSv1_2 # AWS disabled SSLv3 connections
                                   }})
  end

  def directory
    storage.directories.get(ENV['AWS_BUCKET']) || storage.directories.create(:key => ENV['AWS_BUCKET'], :public => true)
  end

  def write(path, options = {})
    cached_filename = path.gsub(/[^\w\-]/,'')
    content = options[:content] || open(endpoint + path).read
    # File.open("#{Sinatra::Application.settings.root}/tmp/#{cached_filename}", 'w') { |f| f.write(content) }
    upload(options[:filename] || cached_filename, content)
  end

  def upload(filename, content)
    # Using an obsolete content_type because IE8 and before chokes on application/javascript and hey, Google does it.
    directory.files.create(:key => filename, :body => content, :public => true, :content_type => "text/javascript")
  end

  def write_content
    if ENV.key('FLATWARE_USE_OLD_SHEETS') && ENV['FLATWARE_USE_OLD_SHEETS'] == true
      sq = "&sq="
    else
      sq = ""
    end
    write(base_json_path, :content => base_json_content, :filename => google_key)

    sheet_ids.each do |sheet_id|
      path = "/feeds/list/#{google_key}/#{sheet_id}/public/values?alt=json-in-script#{sq}&callback=Tabletop.singleton.loadSheet"
      write(path, :filename => "#{google_key}-#{sheet_id}")
    end
  rescue OpenURI::HTTPError => e
    # Fail silently for the time being
  end

  def endpoint
    "https://spreadsheets.google.com"
  end

  class << self

    def from_key(key)
      clean_key = key.gsub(/.*key=(.*?)\&.*/,'\1')
      Spreadsheet.new.tap do |sheet|
        sheet.google_key = clean_key
      end
    end

  end

end

DataMapper.finalize.auto_upgrade!

get '/' do
  erb :index
end

post '/' do
  spreadsheet = Spreadsheet.from_key(params[:key])
  if spreadsheet.save
    @notice = "Added spreadsheet"
  else
    @error = "Could not add spreadsheet"
  end

  erb :index
end

get '/process' do
  redirect '/'
end

post '/process/:key' do
  spreadsheet = Spreadsheet.first(:google_key => params[:key])
  if spreadsheet and spreadsheet.write_content
    @notice = "Successful"
  else
    @error = "Unsuccessful"
  end
  redirect '/'
end

post '/process' do
  @updated = Spreadsheet.select(&:write_content)
  @notice = "Updated #{@updated.length} spreadsheets"
  erb :index
end
