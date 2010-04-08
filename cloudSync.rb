require 'rubygems'
require 'cloudfiles'
require 'date'
require 'find'

now = DateTime.now
errorLog = File.new("/var/log/cloudSync.err", "a")
log = File.new("/var/log/cloudSync.log", "a")
user = ""
apikey = ""

def cfconnect(user, apikey, attempts, errorLog, now)
    begin
    cf = CloudFiles::Connection.new(user, apikey)
    rescue Errno::ETIMEDOUT => e
        if attempts <= 5 then
            log.puts(now.strftime('%d/%m/%Y %I:%M:%S') + " Connection timed out: #{e} - Attempted " + $attempts + " time - trying again ... ")
            cf = cfconnect( user, apikey, $attempts+1,errorLog,now )
         else
            errorLog.puts(now.strftime('%d/%m/%Y %I:%M:%S') + " Connection timed out: #{e} - Attempted max retries. Giving up.")
            return false
         end
    end
    return cf
end

# Log into the Cloud Files system
cf = cfconnect( user, apikey, 0, errorLog, now )
if cf then
    if ARGV.empty? then
        print "Usage: \n"
        print "cloudSync.rb <container> <localdir>\n"
    else
        container = cf.container(ARGV[0])
        basedir = ARGV[1]
        Find.find(basedir.chomp) do |path|
            if FileTest.directory?(path)
                if File.basename(path)[0] == ?.
                    Find.prune       
                else
                    next
                end
            else
                strpath = 
                if container.object_exists?(path)
                    tmpo = container.object(path)
                    if tmpo.bytes.eql? File.size(path) then
                        container.delete_object(path)
                        newfile = container.create_object(path, true)
                        newfile.load_from_filename(path)
                        log.puts(now.strftime('%d/%m/%Y %I:%M:%S') + " Transferred " + path)
                    end
                else
                    newfile = container.create_object(path, true)
                    newfile.load_from_filename(path)
                    log.puts(now.strftime('%d/%m/%Y %I:%M:%S') + " Transferred " + path)
                end
            end
        end
    end
end

