# Marco Mornati 2012
# OffLineMessagePlugin for RBot
#  Active on #kermit channel
# With this plugin you can send a message to registered user. A registered user must 
# insert the email address, so any time user want to contact an offline|away user, 
# can reach it by mail

class OffLineMessagePlugin < Plugin
  
  def initialize
    super
  end

  def help(plugin, topic="")
    "offlinemessage to <nick> <message> => send messages to a non connected kermit developer (a bot registered user)\n
offlinemessage list => list registred user\n
offlinemessage set <nick> <mail> => add user to registered list\n
offlinemessage remove <nick> => remove user from registered list"
  end

  def message(m)
     #m.reply "message!"
  end

  private
  def send_message(m, params)
    nick = params[:nick]
    mail = @registry[nick]
    if mail.nil? or mail.empty?
      m.reply "#{nick} has no message forwarder configured"
    else
      begin
        require 'net/smtp'
        Net::SMTP.start('localhost', 25) do |smtp|
          smtp.open_message_stream('kerbot-noreply@kermit.fr', [mail]) do |f|
            f.puts "From: #{m.sourcenick}@irc.kermit"
            f.puts "To: #{mail}"
            f.puts "Subject: [IRC #kermit] - Message from Kermit IRC Channel"
            f.puts "#{params[:message]}"
          end
        end
        m.reply "Message to #{nick} sent!"
      rescue Exception => e
	m.reply "Error: Cannot send message: #{e.message}"
	log "Send message error: #{e}"
      end
    end
  end

  def confmessage(m, params)
    nick = (params[:nick] || m.sourcenick).to_s
    @registry[nick] = params[:mail]
    m.reply "Configured message forward for #{nick}"
  end

  def del_nick(m, params)
    @registry.delete(params[:nick])
    m.reply "Removed #{nick} from mail forwarder"
  end

 
  def list_users(m, params)
    @registry.each { |user,mail|
      m.reply "* #{user}"
    }
  end

end

plugin = OffLineMessagePlugin.new

plugin.default_auth( 'edit', false )

plugin.map 'offlinemessage to :nick *message', :action => 'send_message'
plugin.map 'offlinemessage list', :action => 'list_users'
plugin.map 'offlinemessage set :nick :mail', :auth_path => 'edit::set!', :action => 'confmessage'
plugin.map 'offlinemessage remove :nick', :auth_path => 'edit::set!', :action => 'del_nick'
