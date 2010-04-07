require 'rubygems'
require 'cloudfiles'
require 'date'

now = DateTime.now
log = File.new("/var/log/pushToCloud.err", "a")

def cfconnect(attempts, log, now)
    begin
    cf = CloudFiles::Connection.new(<USERNAME>, <APIKEY>)
    rescue Errno::ETIMEDOUT => e
        if attempts <= 5 then
            log.puts(now.strftime('%d/%m/%Y %I:%M:%S') + " Connection timed out: #{e} - Attempted " + $attempts + " time - trying again ... ")
            cf = cfconnect( $attempts+1,log,now ) 
         else 
            log.puts(now.strftime('%d/%m/%Y %I:%M:%S') + " Connection timed out: #{e} - Attempted max retries. Giving up.")
            return false
         end
    end
    return cf
end

# Log into the Cloud Files system
cf = cfconnect( 0, log, now )

if cf then
    if ARGV.empty? then
        print "Usage: \n"
        print "pushToCloud.rb <container> <remotefile> <localfile> \n"
        print "remote file MUST contain relative path under the container!\n"
    else 
    
        if File.exists?(ARGV[2]) then
            container = cf.container(ARGV[0])
            if container.object_exists?(ARGV[1]) then
                # object (file) exists
            else
                # object does not exist...
                newfile = container.create_object(ARGV[1], true)
                newfile.load_from_filename(ARGV[2])
            end
        else
            log.puts(now.strftime('%d/%m/%Y %I:%M:%S') + " Pushing failed for file " + ARGV[2]) 
        end
    end
end
