class ConfigSnomController < ApplicationController
	MAX_SIP_ACCOUNTS_COUNT = 11
	MAX_SOFTKEYS_COUNT = 12 + (42 * 3) - 1
  MAX_DIRECTORY_ENTRIES = 20
  KEY_REGEXP = {
    '0' => "[ -.,_0]+",
    '1' => "[ -.,_1]+",
    '2' => "[abc2\xC3\xA4]",
    '3' => "[def3\xC3\xA9]",
    '4' => "[ghi4\xC3\xAF]",
    '5' => "[jkl5]",
    '6' => "[mno6\xC3\xB6]",
    '7' => "[pqrs7\xC3\x9F]",
    '8' => "[tuv8\xC3\xBC]",
    '9' => "[wxyz9]",
  }

	skip_authorization_check
	
	before_filter { |controller|
    @mac_address = params[:mac_address].to_s.upcase.gsub(/[^0-9A-F]/,'')
    @provisioning_authenticated = false

    if !params[:provisioning_key].blank?
      @phone = Phone.where({ :provisioning_key => params[:provisioning_key] }).first
      if @phone
        @provisioning_authenticated = true
        @mac_address = @phone.mac_address
      end
    end

    if ! @mac_address.blank? then
      if !@phone
        @phone = Phone.where({ :mac_address => @mac_address }).first
      end

      if ! @phone && GsParameter.get('PROVISIONING_AUTO_ADD_PHONE')
        tenant = Tenant.where(:id => GsParameter.get('PROVISIONING_AUTO_TENANT_ID')).first
        if ! tenant
          render(
            :status => 404,
            :layout => false,
            :content_type => 'text/plain',
            :text => "<!-- Tenant not found -->",
          )
          return
        end

        @phone = tenant.phones.build
        @phone.mac_address = @mac_address
        @phone.hot_deskable = true
        @phone.tenant = tenant

        mac_address_to_model = {
          '00041325' => 'Snom 300',
          '00041328' => 'Snom 300',
          '0004132D' => 'Snom 300',
          '0004132F' => 'Snom 300',
          '00041334' => 'Snom 300',
          '00041350' => 'Snom 300',
          '0004133B' => 'Snom 300',
          '00041337' => 'Snom 300',
          '00041324' => 'Snom 320',
          '00041327' => 'Snom 320',
          '0004132C' => 'Snom 320',
          '00041331' => 'Snom 320',
          '00041335' => 'Snom 320',
          '00041338' => 'Snom 320',
          '00041351' => 'Snom 320',
          '00041323' => 'Snom 360',
          '00041329' => 'Snom 360',
          '0004132B' => 'Snom 360',
          '00041339' => 'Snom 360',
          '00041390' => 'Snom 360',
          '00041326' => 'Snom 370',
          '0004132E' => 'Snom 370',
          '0004133A' => 'Snom 370',
          '00041352' => 'Snom 370',
          '00041340' => 'Snom 820',
          '00041345' => 'Snom 821',
          '00041348' => 'Snom 821',
          '00041341' => 'Snom 870',
          '00041332' => 'Snom meetingPoint',
        }

        @phone.phone_model = PhoneModel.where(:name => mac_address_to_model[@mac_address[0, 8]]).first
        if ! @phone.save
          render(
            :status => 500,
            :layout => false,
            :content_type => 'text/plain',
            :text => "<!-- #{@phone.errors.messages.inspect} -->",
          )
          return
        end

        if ! GsParameter.get('PROVISIONING_AUTO_ADD_SIP_ACCOUNT')
          return
        end

        caller_name_index = 0
        sip_account_last = tenant.sip_accounts.where('caller_name LIKE ?', "#{GsParameter.get('PROVISIONING_AUTO_SIP_ACCOUNT_CALLER_PREFIX')}%").sort { |item1, item2| 
          item1.caller_name.gsub(/[^0-9]/, '').to_i <=> item2.caller_name.gsub(/[^0-9]/, '').to_i
        }.last

        if sip_account_last
          caller_name_index = sip_account_last.caller_name.gsub(/[^0-9]/, '').to_i
        end
        caller_name_index = caller_name_index + 1

        @sip_account = tenant.sip_accounts.build
        @sip_account.caller_name = "#{GsParameter.get('PROVISIONING_AUTO_SIP_ACCOUNT_CALLER_PREFIX')}#{caller_name_index}"
        @sip_account.call_waiting = GsParameter.get('CALL_WAITING')
        @sip_account.clir = GsParameter.get('DEFAULT_CLIR_SETTING')
        @sip_account.clip = GsParameter.get('DEFAULT_CLIP_SETTING')
        @sip_account.voicemail_pin = random_pin
        @sip_account.callforward_rules_act_per_sip_account = GsParameter.get('CALLFORWARD_RULES_ACT_PER_SIP_ACCOUNT_DEFAULT')
        @sip_account.hotdeskable = false
        loop do
          @sip_account.auth_name = SecureRandom.hex(GsParameter.get('DEFAULT_LENGTH_SIP_AUTH_NAME'))
          break unless SipAccount.exists?(:auth_name => @sip_account.auth_name)
        end
        @sip_account.password = SecureRandom.hex(GsParameter.get('DEFAULT_LENGTH_SIP_PASSWORD'))

        if ! @sip_account.save
          render(
            :status => 500,
            :layout => false,
            :content_type => 'text/plain',
            :text => "<!-- #{@sip_account.errors.messages.inspect} -->",
          )
          return
        end

        @phone.fallback_sip_account = @sip_account
        if ! @phone.save
          render(
            :status => 500,
            :layout => false,
            :content_type => 'text/plain',
            :text => "<!-- #{@phone.errors.messages.inspect} -->",
          )
          return
        end
      end
    elsif ! params[:phone].blank? then
      @phone = Phone.where({ :id => params[:phone].to_i }).first
    end    

    if ! @phone
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- Phone not found -->",
      )
    end

    if ! params[:sip_account].blank?
      @sip_account = @phone.sip_accounts.where({ :id => params[:sip_account].to_i }).first
      if ! @sip_account && @phone.fallback_sip_account && @phone.fallback_sip_account.id == params[:sip_account].to_i
        @sip_account = @phone.fallback_sip_account
      end
      if ! @sip_account
        render(
          :status => 404,
          :layout => false,
          :content_type => 'text/plain',
          :text => "<!-- SipAccount ID:#{params[:sip_account].to_i} not found -->",
        )
      end
    end

    if ! params[:type].blank?
      @type = params[:type].to_s.strip.downcase
    end

    if ! params[:keys].blank?
      @dialpad_keys = params[:keys].to_s.strip
    end
	}
	
	
	def show
    send_sensitve = @provisioning_authenticated || !@phone.provisioning_key_active
    @phone_settings = Hash.new()

    if !GsParameter.get('PROVISIONING_KEY_LENGTH').nil? && GsParameter.get('PROVISIONING_KEY_LENGTH') > 0
      if @phone.provisioning_key.blank?
        @phone.update_attributes({ :provisioning_key => SecureRandom.hex(GsParameter.get('PROVISIONING_KEY_LENGTH')), :provisioning_key_active => false })
      elsif @provisioning_authenticated
        @phone.update_attributes({ :provisioning_key_active => true })
      end

      if send_sensitve
        if defined?(PROVISIONING_PROTOCOL) && PROVISIONING_PROTOCOL
          provisioning_protocol = PROVISIONING_PROTOCOL
        else
          provisioning_protocol = request.protocol
        end
        @phone_settings[:setting_server] = "#{provisioning_protocol}#{request.host_with_port}/snom-#{@phone.provisioning_key}.xml"
      end
    end

    if !GsParameter.get('PROVISIONING_SET_HTTP_USER').nil? && @phone.http_user.blank?
      if GsParameter.get('PROVISIONING_SET_HTTP_USER').class == Fixnum
        @phone.update_attributes({ :http_user => SecureRandom.hex(GsParameter.get('PROVISIONING_SET_HTTP_USER')) })
      elsif GsParameter.get('PROVISIONING_SET_HTTP_USER').class == String
        @phone.update_attributes({ :http_user => GsParameter.get('PROVISIONING_SET_HTTP_USER') })
      end
    end

    if !GsParameter.get('PROVISIONING_SET_HTTP_PASSWORD').nil? && @phone.http_password.blank?
      if GsParameter.get('PROVISIONING_SET_HTTP_PASSWORD').class == Fixnum
        @phone.update_attributes({ :http_password => SecureRandom.hex(GsParameter.get('PROVISIONING_SET_HTTP_PASSWORD')) })
      elsif GsParameter.get('PROVISIONING_SET_HTTP_PASSWORD').class == String
        @phone.update_attributes({ :http_password => GsParameter.get('PROVISIONING_SET_HTTP_PASSWORD') })
      end
    end

    if send_sensitve
      @phone_settings[:http_user] = @phone.http_user
      @phone_settings[:http_pass] = @phone.http_password
      if defined?(PROVISIONING_ADMIN_PASSWORD)
        if PROVISIONING_ADMIN_PASSWORD.class == TrueClass
          @phone_settings[:admin_mode_password] = @phone.http_password
        elsif PROVISIONING_ADMIN_PASSWORD.class == String
          @phone_settings[:admin_mode_password] = PROVISIONING_ADMIN_PASSWORD
        end
      end
    end

		if ! request.env['HTTP_USER_AGENT'].index('snom')
			Rails.logger.info "---> User-Agent indicates not a Snom phone (#{request.env['HTTP_USER_AGENT'].inspect})"
		else
			Rails.logger.info "---> Phone #{@mac_address.inspect}, IP address #{request.remote_ip.inspect}"
			@phone.update_attributes({ :ip_address => request.remote_ip })
		end

    @softkeys = Array.new()
		@sip_accounts = Array.new()
    phone_sip_accounts = Array.new()

    if send_sensitve
      if @phone.sip_accounts && @phone.sip_accounts.count > 0
        phone_sip_accounts = @phone.sip_accounts
      elsif @phone.fallback_sip_account
        phone_sip_accounts.push( @phone.fallback_sip_account )
      end
      expiry_seconds = GsParameter.get('SIP_EXPIRY_SECONDS')
      phone_sip_accounts.each do |sip_account|
        if (sip_account.sip_accountable_type == @phone.phoneable_type) and (sip_account.sip_accountable_id == @phone.phoneable_id)
        	snom_sip_account = {
            :id         => sip_account.id,
            :active     => 'on',
        		:pname      => sip_account.auth_name,
        		:pass       => sip_account.password,
        		:host       => sip_account.host,
        		:outbound   => sip_account.host,
        		:name       => sip_account.auth_name,
        		:realname   => 'Call',
        		:idle_text  => sip_account.caller_name,
            :mailbox    => "<sip:#{sip_account.auth_name}@#{sip_account.host}>",
            :expiry     => expiry_seconds, 
          }
          @sip_accounts.push(snom_sip_account)
          sip_account_index = @sip_accounts.length
          sip_account.softkeys.order(:position).each do |softkey|
            if softkey.softkey_function
              softkey_function = softkey.softkey_function.name
            end
            case softkey_function
            when 'blf'
              @softkeys.push({:context => sip_account_index, :label => softkey.label, :data => "blf <sip:#{softkey.number}@#{sip_account.host}>|f-ia-"})
            when 'speed_dial'
              @softkeys.push({:context => sip_account_index, :label => softkey.label, :data => "speed #{softkey.number}"})
            when 'dtmf'
              @softkeys.push({:context => sip_account_index, :label => softkey.label, :data => "dtmf #{softkey.number}"})
            when 'log_out'
              @softkeys.push({:context => sip_account_index, :label => softkey.label, :data => "speed f-lo"})
            when 'log_in'
              @softkeys.push({:context => sip_account_index, :label => softkey.label, :data => "speed f-li-#{softkey.number}"})
            when 'conference'
              @softkeys.push({:context => sip_account_index, :label => softkey.label, :data => "blf <sip:#{softkey.number}@#{sip_account.host}>|f-ta-"})
            when 'parking_stall'
              parking_stall = softkey.softkeyable
              if parking_stall.class == ParkingStall
                @softkeys.push({
                  :context => sip_account_index,
                  :function => softkey.softkey_function.name,
                  :label => softkey.label,
                  :softkey => softkey,
                  :general_type => t("softkeys.functions.#{softkey.softkey_function.name}"),
                  :subscription => {
                    :to => "sip:park+#{parking_stall.name}@#{sip_account.host}",
                    :for => "sip:park+#{parking_stall.name}@#{sip_account.host}",
                  },
                  :actions => [{
                    :type => :dial, 
                    :target => "f-cpa-#{parking_stall.name}",
                    :when => 'on press',
                    :states => 'connected,holding',
                  },{
                    :type => :dial, 
                    :target => "f-cpa-#{parking_stall.name}",
                    :when => 'on press',
                  }],
                })
              end
            when 'call_forwarding'
              if softkey.softkeyable.class == CallForward then
                @softkeys.push({
                  :context => sip_account_index,
                  :function => softkey.softkey_function.name,
                  :label => softkey.label,
                  :softkey => softkey,
                  :general_type => t("softkeys.functions.#{softkey.softkey_function.name}"),
                  :subscription => {
                    :to => "sip:f-cftg-#{softkey.softkeyable_id}@#{sip_account.host}",
                    :for => "sip:f-cftg-#{softkey.softkeyable_id}@#{sip_account.host}"
                  },
                  :actions => [{
                    :type => :url, 
                    :target => "#{request.protocol}#{request.host_with_port}/config_snom/#{@phone.id}/#{snom_sip_account[:id]}/call_forwarding.xml?id=#{softkey.softkeyable_id}&function=toggle",
                    :when => 'on press',
                  }],
                })
              end
            when 'call_forwarding_always'
              phone_number = PhoneNumber.where(:number => softkey.number, :phone_numberable_type => 'SipAccount').first
              if phone_number
                account_param = (phone_number.phone_numberable_id != snom_sip_account[:id] ? "&account=#{phone_number.phone_numberable_id}" : '')
              else
                phone_number = sip_account.phone_numbers.first
                account_param = ''
              end

              @softkeys.push({
                :context => sip_account_index,
                :function => softkey.softkey_function.name,
                :label => softkey.label,
                :softkey => softkey,
                :general_type => t("softkeys.functions.#{softkey.softkey_function.name}"),
                :subscription => {
                  :to => "f-cfutg-#{phone_number.id}@#{sip_account.host}",
                  :for => "#{sip_account.auth_name}@#{sip_account.host}"
                },
                :actions => [{
                  :type => :url, 
                  :target => "#{request.protocol}#{request.host_with_port}/config_snom/#{@phone.id}/#{snom_sip_account[:id]}/call_forwarding.xml?type=always&function=toggle#{account_param}",
                  :when => 'on press',
                }],
              })
            when 'call_forwarding_assistant'
              phone_number = PhoneNumber.where(:number => softkey.number, :phone_numberable_type => 'SipAccount').first
              if phone_number
                account_param = (phone_number.phone_numberable_id != snom_sip_account[:id] ? "&account=#{phone_number.phone_numberable_id}" : '')
              else
                phone_number = sip_account.phone_numbers.first
                account_param = ''
              end

              @softkeys.push({
                :context => sip_account_index,
                :function => softkey.softkey_function.name,
                :label => softkey.label,
                :softkey => softkey,
                :general_type => t("softkeys.functions.#{softkey.softkey_function.name}"),
                :subscription => {
                  :to => "f-cfatg-#{phone_number.id}@#{sip_account.host}",
                  :for => "#{sip_account.auth_name}@#{sip_account.host}"
                },
                :actions => [{
                  :type => :url, 
                  :target => "#{request.protocol}#{request.host_with_port}/config_snom/#{@phone.id}/#{snom_sip_account[:id]}/call_forwarding.xml?type=assistant&function=toggle#{account_param}",
                  :when => 'on press',
                }],
              })
            when 'hunt_group_membership'
              phone_number = PhoneNumber.where(:number => softkey.number, :phone_numberable_type => 'HuntGroup').first
              if phone_number
                hunt_group = HuntGroup.where(:id => phone_number.phone_numberable_id).first
              end

              sip_account_phone_numbers = Array.new()
              SipAccount.where(:id => @sip_accounts.first[:id]).first.phone_numbers.each do |phone_number|
                sip_account_phone_numbers.push(phone_number.number)
              end

              hunt_group_member_numbers = PhoneNumber.where(:number => sip_account_phone_numbers, :phone_numberable_type => 'HuntGroupMember')

              hunt_group_member = nil
              if hunt_group and hunt_group_member_numbers
                hunt_group_member_numbers.each do |hunt_group_member_number|
                  hunt_group_member = hunt_group.hunt_group_members.where(:id => hunt_group_member_number.phone_numberable_id).first
                  if hunt_group_member
                    break
                  end
                end
              end

              if hunt_group_member 
                @softkeys.push({
                  :context => sip_account_index,
                  :function => softkey.softkey_function.name,
                  :label => softkey.label,
                  :softkey => softkey,
                  :general_type => t("softkeys.functions.#{softkey.softkey_function.name}"),
                  :subscription => {
                    :to => "f-hgmtg-#{hunt_group_member.id}@#{sip_account.host}",
                    :for => "#{sip_account.auth_name}@#{sip_account.host}"
                  },
                  :actions => [{
                    :type => :url, 
                    :target => "#{request.protocol}#{request.host_with_port}/config_snom/#{@phone.id}/#{snom_sip_account[:id]}/hunt_group.xml?group=#{hunt_group.id}&account=#{hunt_group_member.id}&function=toggle",
                    :when => 'on press',
                  }],
                })
              else
                @softkeys.push({:context => sip_account_index, :label => softkey.label, :data => 'none'})
              end
            when 'acd_membership'
              acd_agent = nil
              phone_number = PhoneNumber.where(:number => softkey.number, :phone_numberable_type => 'AutomaticCallDistributor').first
              if phone_number
                acd = AutomaticCallDistributor.where(:id => phone_number.phone_numberable_id).first
                if acd
                  acd_agent = acd.acd_agents.where(:destination_type => 'SipAccount', :destination_id => sip_account.id).first
                end
              end

              if acd_agent
                @softkeys.push({
                  :context => sip_account_index,
                  :function => softkey.softkey_function.name,
                  :label => softkey.label,
                  :softkey => softkey,
                  :general_type => t("softkeys.functions.#{softkey.softkey_function.name}"),
                  :subscription => {
                    :to => "f-acdmtg-#{acd_agent.id}@#{sip_account.host}",
                    :for => "#{sip_account.auth_name}@#{sip_account.host}"
                  },
                  :actions => [{
                    :type => :url, 
                    :target => "#{request.protocol}#{request.host_with_port}/config_snom/#{@phone.id}/#{snom_sip_account[:id]}/acd.xml?acd=#{acd.id}&agent=#{acd_agent.id}&function=toggle",
                    :when => 'on press',
                  }],
                })
              else
                @softkeys.push({:context => sip_account_index, :label => softkey.label, :data => 'none'})
              end
            when 'hold'
              @softkeys.push({:context => sip_account_index, :label => softkey.label, :data => "keyevent F_R"})
            else
              @softkeys.push({:label => softkey.label, :data => 'none'})
            end
          end
        end
      end
    end

    languages_map = {
      'ca' => 'Catalan',
      'bs' => 'Bosanski', 
      'da' => 'Dansk', 
      'de' => 'Deutsch', 
      'cs' => 'Cestina', 
      'en' => 'English', 
      'es' => 'Espanol', 
      'fi' => 'Suomi', 
      'et' => 'Estonian',
      'fr' => 'Francais', 
      'he' => 'Hebrew', 
      'hu' => 'Hungarian', 
      'it' => 'Italiano', 
      'nl' => 'Dutch', 
      'no' => 'Norsk', 
      'pl' => 'Polski',
      'pt' => 'Portugues', 
      'si' => 'Slovenian', 
      'sk' => 'Slovencina',
      'ru' => 'Russian', 
      'sv' => 'Svenska', 
      'tr' => 'Turkce', 
    }

    tone_schemes_map = {
       '1' => 'USA', # United States
      '61' => 'AUS', # Australia
      '43' => 'AUT', # Austria
      '86' => 'CHN', # China
      '45' => 'DNK', # Denmark
      '33' => 'FRA', # France
      '49' => 'GER', # Germany
      '44' => 'GBR', # Great Britain
      '91' => 'IND', # India
      '39' => 'ITA', # Italy
      '81' => 'JPN', # Japan
      '52' => 'MEX', # Mexico
      '31' => 'NLD', # Netherlands
      '47' => 'NOR', # Norway
      '64' => 'NZL', # New Zealand
      '34' => 'ESP', # Spain
      '46' => 'SWE', # Sweden
      '41' => 'SWI', # Switzerland
    }

    if @phone.phoneable
      if @phone.phoneable_type == 'Tenant'
        tenant = @phone.phoneable
        language = tenant.language.code
      elsif @phone.phoneable_type == 'User'
        tenant = @phone.phoneable.current_tenant
        language = @phone.phoneable.language.code
      end
    end

    if tenant && tenant.country
      tone_scheme = tenant.country.country_code
    end

    @phone_settings[:tone_scheme] = tone_schemes_map.include?(tone_scheme.to_s) ? tone_schemes_map[tone_scheme.to_s] : 'USA'
    @phone_settings[:language] = languages_map.include?(language.to_s) ? languages_map[language.to_s] : 'English'
    
    xml_applications_url = "#{request.protocol}#{request.host_with_port}/config_snom/#{@phone.id}/#{(@sip_accounts.blank? ? '0' : @sip_accounts.first[:id])}"
    @dkeys = {
      :menu => 'keyevent F_SETTINGS',
      :retrieve => 'speed f-vmcheck',
      :conf => 'keyevent F_CONFERENCE',
      :redial => "url #{xml_applications_url}/call_history.xml?type=dialed",
      :directory => "url #{xml_applications_url}/phone_book.xml",
      :idle_ok => "url #{xml_applications_url}/call_history.xml?type=dialed",
      :idle_cancel => "keyevent F_CANCEL",
      :idle_up => "keyevent F_PREV_ID",
      :idle_down => "keyevent F_NEXT_ID",
      :idle_left => "url #{xml_applications_url}/call_history.xml?type=received",
      :idle_right => "url #{xml_applications_url}/call_history.xml?type=missed",
      :touch_idle_adr_book => "url #{xml_applications_url}/phone_book.xml",
      :touch_idle_list_missed => "url #{xml_applications_url}/call_history.xml?type=missed",
      :touch_idle_list_taken => "url #{xml_applications_url}/call_history.xml?type=received",
      :touch_idle_redial => "url #{xml_applications_url}/call_history.xml?type=dialed",
      :touch_idle_dialog => "url #{xml_applications_url}/call_history.xml",
    }
    
    # Remap conference key to first conference if found
    #conference = Conference.where(:conferenceable_type => @phone.phoneable_type, :conferenceable_id => @phone.phoneable_id).first
    #if conference and conference.phone_numbers
    #  @dkeys[:conf] = "speed f_ta_#{conference.phone_numbers.first.number}"
    #end
    
    @sip_accounts.length().upto(MAX_SIP_ACCOUNTS_COUNT) do |index|
    	snom_sip_account = {
          :id         => index,
          :active     => 'off',
      		:pname      => '',
      		:pass       => '',
      		:host       => '',
      		:outbound   => '',
      		:name       => '',
      		:realname   => '',
      		:idle_text  => '',
        }
        @sip_accounts.push(snom_sip_account)
    end

    @softkeys.length().upto(MAX_SOFTKEYS_COUNT) do |index|
    	@softkeys.push({:label => "", :data => "none"})
		end

    @state_settings_url = "#{request.protocol}#{request.host_with_port}/config_snom/#{@phone.id}/state_settings.xml"

		respond_to { |format|
			format.any {
				self.formats = [ :xml ]
				render
			}
		}
	end

  def idle_screen

    snom_360_bg = 'Qk0+BAAAAAAAAD4AAAAoAAAAgAAAAEAAAAABAAEAAAAAAAAEAAATCwAAEwsAAAIAAAACAAAA////
AAAAAAAAAAAAAAAAAAAAAbbZxzbbAAAAAAAAAAAAAAG222222wAAAAAAAAAAAAAB9ttttt8AAAAA
AAAAAAAAAbbbbbbbAAAAAAAAAAAAAAG222222wAAAAAAAAAAAAABttttttsAAAAAAAAAAAAAAOPx
xx+OAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAkkkkkkkkkkkkkkAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAJJJJJJJJJJJJJJAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAACSSSSSSSSSSSSSQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAA'

    @phone_xml_object = {
      :image => {
        :data => snom_360_bg,
        :location_x => 0,
        :location_y => 0,
        :invert => 0
      },
      :clock => {
        :location_x => 128,
        :location_y => 0,
      },
      :date => {
        :location_x => 100,
        :location_y => 40,
      },
      :line => {
        :location_x => 0,
        :location_y => 0,
      },    
    }

    respond_to { |format|
      format.any {
        self.formats = [ :xml ]
        render
      }
    }
  end

  def log_in

    base_url = "#{request.protocol}#{request.host_with_port}#{request.fullpath.split("?")[0]}"
    exit_url = "#{request.protocol}#{request.host_with_port}#{request.fullpath.rpartition("/")[0]}/exit.xml"

    log_in_number = params[:log_in].to_s.gsub(/[^0-9]/,'')
    pin = params[:pin].to_s.gsub(/[^0-9]/,'')

    if ! params[:user].blank?
      user = User.where(:id => params[:user].to_i).first
      phone_number = PhoneNumber.where(:number => log_in_number, :phone_numberable_type => 'SipAccount').first
      if phone_number
        sip_account = phone_number.phone_numberable
      end
    elsif ! params[:log_in].blank?
      phone_number = PhoneNumber.where(:number => log_in_number, :phone_numberable_type => 'SipAccount').first
      if phone_number && phone_number.phone_numberable && phone_number.phone_numberable.sip_accountable && phone_number.phone_numberable.sip_accountable_type == 'User'
        user = phone_number.phone_numberable.sip_accountable
      end
    end

    @phone_xml_object = { 
      :name => "snom_phone_text",
      :title => "Error",
      :prompt => "Log in",
      :text => 'Log in failed!',
      :fetch_url => base_url,
      :fetch_mil => '2000',
    }

    if ! user
      @phone_xml_object = { 
        :name => "snom_phone_input",
        :title => "Log In",
        :prompt => "Log In",
        :url => base_url,
        :display_name => "Log In",
        :query_string_param => "log_in",
        :default_value => log_in_number,
        :input_flags => "n",
        :softkeys => [
          {:name => "F1", :label => "Exit", :url => exit_url}
        ]
      }
    elsif pin.blank?
      @phone_xml_object = { 
        :name => "snom_phone_input",
        :title => "PIN",
        :prompt => "PIN",
        :url => base_url,
        :display_name => "PIN",
        :query_string_param => "user=#{user.id}&log_in=#{log_in_number}&pin",
        :default_value => "",
        :input_flags => "pn",
        :softkeys => [
          {:name => "F1", :label => "Exit", :url => exit_url}
        ]
      }
    elsif user.authenticate_by_pin?(pin)
      if @phone.user_login(user, sip_account)
        @phone_xml_object = { 
          :name => "snom_phone_text",
          :title => "Log in successful",
          :prompt => "Log in",
          :text => "#{user.to_s} logged in",
          :fetch_url => exit_url,
          :fetch_mil => '1000',
        }
      end
    end

    respond_to { |format|
      format.any {
        self.formats = [ :xml ]
        render :action => "_#{@phone_xml_object[:name]}"
      }
    }
  end

  def log_out
    if ! @phone
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- Phone not found -->",
      )
      return
    end

    exit_url = "#{request.protocol}#{request.host_with_port}#{request.fullpath.rpartition("/")[0]}/exit.xml"

    if @phone.user_logout()     
      @phone_xml_object = { 
        :name => "snom_phone_text",
        :title => "Log out successful",
        :prompt => "Log out",
        :text => 'Log out successful',
        :fetch_url => exit_url,
        :fetch_mil => '1000',
      }
    else
      @phone_xml_object = { 
        :name => "snom_phone_text",
        :title => "Error",
        :prompt => "Log out",
        :text => 'Log out failed!',
        :fetch_url => exit_url,
        :fetch_mil => '2000',
      }
    end

    respond_to { |format|
      format.any {
        self.formats = [ :xml ]
        render :action => "_#{@phone_xml_object[:name]}"
      }
    }
  end

  def phone_book

    if ! @sip_account
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- SipAccount not found -->",
      )
      return
    end

    @phone_xml_object = { 
      :name => 'snom_phone_directory',
      :title => "$(lang:menu100_phone_book) #{@dialpad_keys}".strip,
      :entries => [],
      :softkeys => [],
    }

    key_regexp = ''
    if !@dialpad_keys.blank?
      @dialpad_keys.to_s.each_char do |dialpad_key|
        key_regexp.concat(KEY_REGEXP[dialpad_key].to_s)
      end
      key_regexp = '^' + key_regexp
    end

    phone_books = Array.new()
    phone_books = phone_books + @sip_account.sip_accountable.try(:phone_books).all
    if @sip_account.sip_accountable.class == User
      phone_books = phone_books + @sip_account.sip_accountable.try(:current_tenant).try(:phone_books).all
    end

    phone_book_ids = Array.new()
    phone_books.each do |phone_book|
      phone_book_ids << phone_book.id
    end

    if key_regexp.blank?
      phone_book_entries = PhoneBookEntry.where(:phone_book_id => phone_book_ids).order(:last_name).order(:first_name).limit(MAX_DIRECTORY_ENTRIES)
    else
      phone_book_entries = PhoneBookEntry.where(:phone_book_id => phone_book_ids).order(:last_name).order(:first_name).where('last_name REGEXP ? OR first_name REGEXP ? OR organization REGEXP ?', key_regexp, key_regexp, key_regexp).limit(MAX_DIRECTORY_ENTRIES)
    end

    phone_book_entries.each do |phone_book_entry|
      if phone_book_entry.phone_numbers.count > 1
        @phone_xml_object[:entries] << { :text => phone_book_entry.to_s, :number => phone_book_entry.phone_numbers.first }
      end
      phone_book_entry.phone_numbers.each do |phone_number|
        if phone_book_entry.phone_numbers.count > 1
          entry_name = "  #{phone_number.name} #{phone_number.number}"
        else
          entry_name = "#{phone_book_entry.to_s} #{phone_number.number}"
        end

        @phone_xml_object[:entries] << { :text => entry_name, :number => phone_number.number }
      end
    end

    base_url = "#{request.protocol}#{request.host_with_port}#{request.fullpath.split("?")[0]}"
    phone_book_url = "#{base_url}?type=#{@type.to_s}"
    for key_id in (0..9)
      @phone_xml_object[:softkeys] << {:name => key_id, :url => "#{phone_book_url}&keys=#{@dialpad_keys.to_s}#{key_id}" }
    end
    @phone_xml_object[:softkeys] << {:name => '*', :url => "#{phone_book_url}&keys=#{@dialpad_keys.to_s[0..-2]}" }
    @phone_xml_object[:softkeys] << {:name => '#', :url => "#{phone_book_url}&keys=" }

    respond_to { |format|
      format.any {
        self.formats = [ :xml ]
        render :action => "_#{@phone_xml_object[:name]}"
      }
    }

  end

  def call_history

    if ! @sip_account
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- SipAccount not found -->",
      )
      return
    end

    if ['dialed', 'missed', 'received'].include? @type
      @phone_xml_object = { 
        :name => "snom_phone_directory",
        :title => "$(lang:menu100_call_lists) - #{@type.to_s.camelize}",
        :entries => []
      }

      if @type == 'missed'
        hunt_group_member_ids = PhoneNumber.where(:phone_numberable_type => 'HuntGroupMember', :number => @sip_account.phone_numbers.map {|a| a.number}).map {|a| a.phone_numberable_id}
        hunt_group_ids = HuntGroupMember.where(:id => hunt_group_member_ids, :active => true).map {|a| a.hunt_group_id}
        calls = CallHistory.where('entry_type = ? AND ((call_historyable_type = "SipAccount" AND call_historyable_id = ?) OR (call_historyable_type = "HuntGroup" AND call_historyable_id IN (?)))', @type, @sip_account.id, hunt_group_ids).order('start_stamp DESC').limit(MAX_DIRECTORY_ENTRIES)
      else
        calls = @sip_account.call_histories.where(:entry_type => @type).order('start_stamp DESC').limit(MAX_DIRECTORY_ENTRIES)
      end

      calls.each do |call|
        display_name = call.display_name
        phone_number = call.display_number
        phone_book_entry = call.phone_book_entry_by_number(phone_number)
        if display_name.blank?
          display_name = phone_book_entry.to_s
        end

        @phone_xml_object[:entries].push({
            :selected => false, 
            :number => phone_number,
            :text => "#{call_date_compact(call.start_stamp)} #{display_name} #{call.display_number}",
            })
      end
    else
      base_url = "#{request.protocol}#{request.host_with_port}#{request.fullpath.split("?")[0]}"
      @phone_xml_object = { 
        :name => 'snom_phone_menu',
        :title => '$(lang:menu100_call_lists)',
        :entries => [
          {:text => '$(lang:list_missed)', :url => "#{base_url}?&type=missed",   :selected => false},
          {:text => '$(lang:list_taken)',  :url => "#{base_url}?&type=received", :selected => false},
          {:text => '$(lang:list_dialed)', :url => "#{base_url}?&type=dialed",   :selected => false},
        ]
      }
    end

    respond_to { |format|
      format.any {
        self.formats = [ :xml ]
        render :action => "_#{@phone_xml_object[:name]}"
      }
    }

  end

  def state_settings
    @base_url = "#{request.protocol}#{request.host_with_port}#{request.fullpath.rpartition("/")[0]}"

    @sip_account_ids = Array.new()
    @phone.sip_accounts.each do |sip_account|
      if (sip_account.sip_accountable_type == @phone.phoneable_type) and (sip_account.sip_accountable_id == @phone.phoneable_id)
        @sip_account_ids.push(sip_account.id)
      end
    end

    if @phone.hot_deskable
      @enable_login = true
      if @phone.phoneable_type != 'Tenant'
        @enable_logout = true
      end
    end

    respond_to { |format|
      format.any {
        self.formats = [ :xml ]
        render
      }
    }
  end

  def call_forwarding
    if ! params[:type].blank?
      @type = params[:type]
    end

    if ! params[:function].blank?
      @function = params[:function]
    end

    if ! params[:id].blank?
      @call_forwarding_id = params[:id].to_i
    end

    if ! params[:sip_account].blank?
      @sip_account = SipAccount.where({ :id => params[:sip_account].to_i }).first
    end

    if ! params[:account].blank?
      @sip_account = SipAccount.where({ :id => params[:account].to_i }).first
    end


    if ! @sip_account
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- SipAccount not found -->",
      )
      return
    end

    exit_url = "#{request.protocol}#{request.host_with_port}#{request.fullpath.rpartition("/")[0]}/exit.xml"

    if @function == 'toggle'
      if @call_forwarding_id 
        call_forwarding = @sip_account.call_forwards.where(:id => @call_forwarding_id).first

        if !call_forwarding and @sip_account.softkeys.where(:softkeyable_id => @call_forwarding_id, :softkeyable_type => 'CallForward').count > 0
          call_forwarding = CallForward.where(:id => @call_forwarding_id).first
        end

        if call_forwarding
          call_forwarding.toggle
        end
      elsif @type
        call_forwarding = @sip_account.call_forwarding_toggle(@type)
      end
      if !call_forwarding
        render(
          :status => 500,
          :layout => false,
          :content_type => 'text/plain',
          :text => "<!-- Call forwarding not set: #{@sip_account.errors.messages.inspect} -->",
        )
        return
      end

      if !call_forwarding.errors.blank?
        error_messages = Array.new()
        call_forwarding.errors.messages.each_pair do |key, message|
          error_messages.push(message.join(';'))
        end
        @phone_xml_object = { 
          :name => 'snom_phone_text',
          :title => t("call_forwards.name"),
          :prompt => t("call_forwards.name"),
          :text => "ERROR #{error_messages.join(',')} #{call_forwarding.to_s})",
          :fetch_url => exit_url,
          :fetch_mil => '1000',
        }
      elsif call_forwarding.active
        @phone_xml_object = { 
          :name => 'snom_phone_text',
          :title => t("call_forwards.name"),
          :prompt => t("call_forwards.name"),
          :text => "ON #{call_forwarding.to_s})",
          :fetch_url => exit_url,
          :fetch_mil => '1000',
        }
      else
        @phone_xml_object = { 
          :name => 'snom_phone_text',
          :title => t("call_forwards.name"),
          :prompt => t("call_forwards.name"),
          :text => "OFF #{call_forwarding.to_s}",
          :fetch_url => exit_url,
          :fetch_mil => '1000',
        }
      end
    end

    respond_to { |format|
      format.any {
        self.formats = [ :xml ]
        render :action => "_#{@phone_xml_object[:name]}"
      }
    }
  end

  def hunt_group
    if ! params[:function].blank?
      @function = params[:function]
    end

    if ! params[:sip_account].blank?
      @sip_account = SipAccount.where({ :id => params[:sip_account].to_i }).first
    end

    if ! params[:group].blank?
      @hunt_group = HuntGroup.where({ :id => params[:group].to_i }).first
    end

    if ! @sip_account
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- SipAccount not found -->",
      )
      return
    end

    if ! @hunt_group
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- HuntGroup not found -->",
      )
      return
    end

    if ! params[:account].blank?
      hunt_group_member = @hunt_group.hunt_group_members.where({ :id => params[:account].to_i }).first
    end

    if ! hunt_group_member
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- HuntGroupMember not found -->",
      )
      return
    end

    exit_url = "#{request.protocol}#{request.host_with_port}#{request.fullpath.rpartition("/")[0]}/exit.xml"

    if @function == 'toggle'
      if hunt_group_member.can_switch_status_itself == true
        if hunt_group_member.active
          hunt_group_member.active = false
        else
          hunt_group_member.active = true
        end

        if ! hunt_group_member.save
          render(
            :status => 500,
            :layout => false,
            :content_type => 'text/plain',
            :text => "<!-- #{hunt_group_member.errors.inspect} -->",
          )
          return
        end
      end

      if hunt_group_member.active
        @phone_xml_object = { 
          :name => 'snom_phone_text',
          :title => 'Hunt Group',
          :prompt => 'Hunt Group',
          :text => "#{@hunt_group.name} on",
          :fetch_url => exit_url,
          :fetch_mil => '1000',
        }
      else
        @phone_xml_object = { 
          :name => 'snom_phone_text',
          :title => 'Hunt Group',
          :prompt => 'Hunt Group',
          :text => "#{@hunt_group.name} off",
          :fetch_url => exit_url,
          :fetch_mil => '1000',
        }
      end

    respond_to { |format|
      format.any {
        self.formats = [ :xml ]
        render :action => "_#{@phone_xml_object[:name]}"
      }
    }
    end
  end

  def acd
    if ! params[:function].blank?
      @function = params[:function]
    end

    if ! params[:sip_account].blank?
      @sip_account = SipAccount.where({ :id => params[:sip_account].to_i }).first
    end

    if ! params[:acd].blank?
      @acd = AutomaticCallDistributor.where({ :id => params[:acd].to_i }).first
    end

    if ! @sip_account
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- SipAccount not found -->",
      )
      return
    end

    if ! @acd
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- AutomaticCallDistributor not found -->",
      )
      return
    end

    if ! params[:agent].blank?
      acd_agent = @acd.acd_agents.where({ :id => params[:agent].to_i }).first
    end

    if ! acd_agent
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- ACD Agent not found -->",
      )
      return
    end

    exit_url = "#{request.protocol}#{request.host_with_port}#{request.fullpath.rpartition("/")[0]}/exit.xml"

    if @function == 'toggle'
      if acd_agent.status == 'active'
        acd_agent.status = 'inactive'
      else
        acd_agent.status = 'active'
      end

      if ! acd_agent.save
        render(
          :status => 500,
          :layout => false,
          :content_type => 'text/plain',
          :text => "<!-- #{acd_agent.errors.inspect} -->",
        )
        return
      end

      if acd_agent.status == 'active'
        @phone_xml_object = { 
          :name => 'snom_phone_text',
          :title => 'ACD',
          :prompt => 'ACD',
          :text => "#{@acd.name} on",
          :fetch_url => exit_url,
          :fetch_mil => '1000',
        }
      else
        @phone_xml_object = { 
          :name => 'snom_phone_text',
          :title => 'ACD',
          :prompt => 'ACD',
          :text => "#{@acd.name} off",
          :fetch_url => exit_url,
          :fetch_mil => '1000',
        }
      end

    respond_to { |format|
      format.any {
        self.formats = [ :xml ]
        render :action => "_#{@phone_xml_object[:name]}"
      }
    }
    end
  end

  def exit
    render(
      :status => 200,
      :layout => false,
      :content_type => 'text/xml',
      :text => "<exit />",
    )
  end

  def call_date_compact(date)
    if date.strftime('%Y%m%d') == DateTime::now.strftime('%Y%m%d')
      return date.strftime('%H:%M')
    end
    return date.strftime('%d.%m %H:%M')
  end

end
