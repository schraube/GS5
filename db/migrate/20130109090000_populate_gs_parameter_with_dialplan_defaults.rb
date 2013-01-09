class PopulateGsParameterWithDialplanDefaults < ActiveRecord::Migration
  def up
    # sip account defaults
    GsParameter.create(:entity => 'sip_accounts', :section => 'parameters', :name => 'vm-enabled',  :value => 'true', :class_type => 'Boolean')
    GsParameter.create(:entity => 'sip_accounts', :section => 'parameters', :name => 'vm-email-all-messages',  :value => 'false', :class_type => 'Boolean')
    GsParameter.create(:entity => 'sip_accounts', :section => 'parameters', :name => 'vm-attach-file', :value => 'false', :class_type => 'Boolean')
    GsParameter.create(:entity => 'sip_accounts', :section => 'parameters', :name => 'vm-mailto',  :value => '', :class_type => 'String')
    GsParameter.create(:entity => 'sip_accounts', :section => 'parameters', :name => 'sip-force-contact',  :value => '', :class_type => 'String')

    #sofia defaults
    GsParameter.create(:entity => 'sofia', :section => 'profiles', :name => 'gemeinschaft',  :value => 1, :class_type => 'Integer')
    GsParameter.create(:entity => 'sofia', :section => 'parameters', :name => 'log-level',  :value => 3, :class_type => 'Integer')
    GsParameter.create(:entity => 'sofia', :section => 'parameters', :name => 'debug-presence',  :value => 0, :class_type => 'Integer')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'user-agent-string',  :value => 'Gemeinschaft5', :class_type => 'String')

    # default profile
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'debug',  :value => 0, :class_type => 'Integer')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'sip-trace',  :value => 'no', :class_type => 'String')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'log-auth-failures',  :value => 'false', :class_type => 'Boolean')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'context',  :value => 'default', :class_type => 'String')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'rfc2833-pt',  :value => 101, :class_type => 'Integer')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'pass-rfc2833',  :value => 'true', :class_type => 'Boolean')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'sip-port',  :value => 5060, :class_type => 'Integer')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'dialplan',  :value => 'XML', :class_type => 'String')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'dtmf-duration',  :value => 2000, :class_type => 'Integer')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'rtp-timer-name',  :value => 'soft', :class_type => 'String')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'inbound-codec-prefs',  :value => 'PCMA,G7221@32000h,G7221@16000h,G722,PCMU,GSM', :class_type => 'String')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'outbound-codec-prefs',  :value => 'PCMA,G7221@32000h,G7221@16000h,G722,PCMU,GSM', :class_type => 'String')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'inbound-codec-negotiation',  :value => 'greedy', :class_type => 'String')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'ext-rtp-ip',  :value => 'auto-nat', :class_type => 'String')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'ext-sip-ip',  :value => 'auto-nat', :class_type => 'String')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'hold-music',  :value => 'local_stream://moh', :class_type => 'String')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'manage-presence',  :value => 'true', :class_type => 'Boolean')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'tls',  :value => 'false', :class_type => 'Boolean')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'tls-sip-port',  :value => 5061, :class_type => 'Integer')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'tls-cert-dir',  :value => '/opt/freeswitch/conf/ssl', :class_type => 'String')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'accept-blind-reg',  :value => 'false', :class_type => 'Boolean')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'accept-blind-auth',  :value => 'false', :class_type => 'Boolean')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'nonce-ttl',  :value => 60, :class_type => 'Integer')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'disable-transcoding',  :value => 'false', :class_type => 'Boolean')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'manual-redirect',  :value => 'true', :class_type => 'Boolean')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'disable-transfer',  :value => 'false', :class_type => 'Boolean')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'disable-register',  :value => 'false', :class_type => 'Boolean')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'auth-calls',  :value => 'false', :class_type => 'Boolean')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'inbound-reg-force-matching-username',  :value => 'true', :class_type => 'Boolean')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'auth-all-packets',  :value => 'false', :class_type => 'Boolean')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'rtp-timeout-sec',  :value => 300, :class_type => 'Integer')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'rtp-hold-timeout-sec',  :value => 1800, :class_type => 'Integer')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'force-subscription-expires',  :value => 3600, :class_type => 'Integer')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'sip-force-expires',  :value => 3000, :class_type => 'Integer')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'sip-expires-max-deviation',  :value => 600, :class_type => 'Integer')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'challenge-realm',  :value => 'auto_from', :class_type => 'String')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'rtp-rewrite-timestamps',  :value => 'true', :class_type => 'Boolean')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'inbound-use-callid-as-uuid',  :value => 'false', :class_type => 'Boolean')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'outbound-use-callid-as-uuid',  :value => 'false', :class_type => 'Boolean')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'context',  :value => 'default', :class_type => 'String')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'record-template',  :value => '${user_name}_${uuid}_${strftime(%Y-%m-%d-%H-%M-%S)}.wav', :class_type => 'String')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'all-reg-options-ping',  :value => 'true', :class_type => 'Boolean')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'mark-dead-on-options-fail',  :value => 'true', :class_type => 'Boolean')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'registration-thread-frequency',  :value => 300, :class_type => 'Integer')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'NDLB-force-rport',  :value => 'false', :class_type => 'Boolean')
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'odbc-dsn',  :value => 'gemeinschaft:gemeinschaft:gemeinschaft', :class_type => 'String')

    # event manager defaults
    GsParameter.create(:entity => 'events', :section => 'modules', :name => 'cdr_save',  :value => 1, :class_type => 'Integer')
    GsParameter.create(:entity => 'events', :section => 'modules', :name => 'call_history_save',  :value => 2, :class_type => 'Integer')
    GsParameter.create(:entity => 'events', :section => 'modules', :name => 'presence_update',  :value => 3, :class_type => 'Integer')

    # perimeter defaults
    GsParameter.create(:entity => 'perimeter', :section => 'general', :name => 'malicious_contact_count',  :value => 20, :class_type => 'Integer')
    GsParameter.create(:entity => 'perimeter', :section => 'general', :name => 'malicious_contact_time_span',  :value => 2, :class_type => 'Integer')
    GsParameter.create(:entity => 'perimeter', :section => 'general', :name => 'ban_futile',  :value => 5, :class_type => 'Integer')
    GsParameter.create(:entity => 'perimeter', :section => 'general', :name => 'execute',  :value => 'sudo /usr/local/bin/ban_ip.sh {ip_address}', :class_type => 'String')

    # conferences defaults
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'caller-controls   ',  :value => 'speaker', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'moderator-controls',  :value => 'moderator', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'max-members       ',  :value => 100, :class_type => 'Integer')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'rate              ',  :value => 16000, :class_type => 'Integer')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'interval          ',  :value => 20, :class_type => 'Integer')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'energy-level      ',  :value => 300, :class_type => 'Integer')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'sound-prefix      ',  :value => '/opt/freeswitch/sounds/en/us/callie', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'muted-sound       ',  :value => 'conference/conf-muted.wav', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'unmuted-sound     ',  :value => 'conference/conf-unmuted.wav', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'alone-sound       ',  :value => 'conference/conf-alone.wav', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'moh-sound         ',  :value => 'local_stream://moh', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'enter-sound       ',  :value => 'tone_stream://%(200,0,500,600,700)', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'exit-sound        ',  :value => 'tone_stream://%(500,0,300,200,100,50,25)', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'kicked-sound      ',  :value => 'conference/conf-kicked.wav', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'locked-sound      ',  :value => 'conference/conf-locked.wav', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'is-locked-sound   ',  :value => 'conference/conf-is-locked.wav', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'is-unlocked-sound ',  :value => 'conference/conf-is-unlocked.wav', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'pin-sound         ',  :value => 'conference/conf-pin.wav', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'bad-pin-sound     ',  :value => 'conference/conf-bad-pin.wav', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'caller-id-name    ',  :value => 'Conference', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'caller-id-number  ',  :value => '', :class_type => 'String')
    GsParameter.create(:entity => 'conferences', :section => 'parameters', :name => 'comfort-noise     ',  :value => 'true', :class_type => 'Boolean')

    #dialplan defaults
    GsParameter.create(:entity => 'dialplan', :section => 'parameters', :name => 'node_id',  :value => 1, :class_type => 'Integer')
    GsParameter.create(:entity => 'dialplan', :section => 'parameters', :name => 'dial_timeout',  :value => '120', :class_type => 'Integer')
    GsParameter.create(:entity => 'dialplan', :section => 'parameters', :name => 'max_loops',  :value => '20', :class_type => 'Integer')
    GsParameter.create(:entity => 'dialplan', :section => 'parameters', :name => 'default_ringtone',  :value => '1', :class_type => 'Integer')
    GsParameter.create(:entity => 'dialplan', :section => 'parameters', :name => 'default_language',  :value => 'en', :class_type => 'String')
    GsParameter.create(:entity => 'dialplan', :section => 'parameters', :name => 'phone_book_entry_image_url',  :value => 'http://192.168.0.150/uploads/phone_book_entry/image', :class_type => 'String')
    GsParameter.create(:entity => 'dialplan', :section => 'parameters', :name => 'user_image_url',  :value => 'http://192.168.0.150/uploads/user/image', :class_type => 'String')
    GsParameter.create(:entity => 'dialplan', :section => 'parameters', :name => 'ringtone_url',  :value => 'http://192.168.0.150', :class_type => 'String')
    GsParameter.create(:entity => 'dialplan', :section => 'parameters', :name => 'ringback',  :value => '%(2000,4000,440.0,480.0)', :class_type => 'String')
    GsParameter.create(:entity => 'dialplan', :section => 'parameters', :name => 'tone_busy',  :value => '%(500,500,480,620);loops=4', :class_type => 'String')
    GsParameter.create(:entity => 'dialplan', :section => 'parameters', :name => 'phonebook_number_lookup',  :value => 'true', :class_type => 'Boolean')
    GsParameter.create(:entity => 'dialplan', :section => 'parameters', :name => 'geo_number_lookup',  :value => 'false', :class_type => 'Boolean')
    GsParameter.create(:entity => 'dialplan', :section => 'parameters', :name => 'send_ringing_to_gateways',  :value => 'false', :class_type => 'Boolean')    
    GsParameter.create(:entity => 'dialplan', :section => 'parameters', :name => 'bypass_media_network',  :value => 'false', :class_type => 'Boolean')
    GsParameter.create(:entity => 'dialplan', :section => 'parameters', :name => 'update_callee_display',  :value => 'false', :class_type => 'Boolean')
  end

  def down
    entities = ['sip_accounts', 'sofia', 'events', 'perimeter', 'conferences', 'dialplan']
    GsParameter.where(:entity => entities).destroy_all
  end
end
