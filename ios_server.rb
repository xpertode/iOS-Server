require 'sinatra'

#bypass ssh authenticaiion by adding public key to authorised keys of ios device

module Settings
    SupportedBrowsers = ["safari"]
    IP = Hash.new('0.0.0.0')
    IP['ad48717167ad0d8d4b979331efe046cefb2dca95'] = "192.168.83.104"
end


class Server < Sinatra::Base

    get '/start' do
        device_id = params[:device_id]
        browser = params[:browser]
        url = params[:url]
        if device_id==nil or browser==nil or url ==nil
            return "Bad Request"
        end
        Activity.start(device_id,browser,url)
    end

    get '/stop' do
        device_id = params[:device_id]
        browser = params[:browser] 
        if Activity.checkDevice(device_id)
            status = Activity.stop(device_id,browser)
        else
            return "#{device_id} is not running any such activity "
        end
    end
end





class Activity
    @@activities = Hash.new(0)
    include Settings


    def self.validateArgs(browser,url)
        if url[/^www.[a-z0-9]*.com$/]!=url
            return "Url should be similar to www.example.com"
        end
        if not Settings::SupportedBrowsers.include?(browser)
            return "Sorry, #{browser} isn't available."
        end
        return "OK"
    end



    def self.start(device_id,browser,url)
        valid_status = validateArgs(browser,url)
        
        unless valid_status == "OK"
            return valid_status
        end
        
        @@activities[device_id]+=1
        puts @@activities[device_id]
        
        ip = Settings::IP[device_id] 
        if browser == 'safari'
           status = system("ssh root\@#{ip} uiopen http://#{url}")
           if not status
                return "Device #{device_id} not found."
            else
                return "#{url} opened successfully in #{browser} on #{device_id}"
            end
        end

    end


    def self.stop(device_id,browser)
        unless Settings::SupportedBrowsers.include?(browser)
            return "Sorry,#{browser} isn't available."
        end
        ip=Settings::IP[device_id]        
        if browser == 'safari'
            status = system("ssh root@#{ip} killall MobileSafari")        
            respond(status,device_id,browser)
        end
    end



    def self.checkDevice(device_id)
        return @@activities.has_key?(device_id)
    end


    def self.removeDevice(device_id)
        if checkDevice(device_id)
            @@activities[device_id]-=1
            @@activities.delete(device_id) if @@activities[device_id]==0
        end
    end

    def self.respond(status,device_id,browser)
        if status
            removeDevice(device_id)
            puts @@activities[device_id]
            return "#{browser} closed on #{device_id}"
        else
            return "#{device_id} is not running any such activity."
        end
    end
end

run Server.run!
