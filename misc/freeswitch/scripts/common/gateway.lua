-- Gemeinschaft 5 module: gateway class
-- (c) AMOOMA GmbH 2013
-- 

module(...,package.seeall)

Gateway = {}

-- Create Gateway object
function Gateway.new(self, arg)
  arg = arg or {}
  object = arg.object or {}
  setmetatable(object, self);
  self.__index = self;
  self.class = 'gateway';
  self.log = arg.log;
  self.database = arg.database;
  self.record = arg.record;
  return object;
end


function Gateway.list(self, technology)
  technology = technology or 'sip';
  local sql_query = 'SELECT * FROM `gateways` WHERE (`outbound` IS TRUE OR `inbound` IS TRUE) AND `technology` = "' .. technology .. '"';
  local gateways = {};
  self.database:query(sql_query, function(entry)
    table.insert(gateways, entry);
  end)

  return gateways;
end


function Gateway.find_by_sql(self, where)
  local sql_query = 'SELECT * FROM `gateways` WHERE ' .. where .. ' LIMIT 1';

  local gateway = nil;
  self.database:query(sql_query, function(entry)
    gateway = Gateway:new(self);
    gateway.record = entry;
    gateway.id = tonumber(entry.id);
    gateway.uuid = entry.uuid;
  end)

  return gateway;
end


-- find gateway by id
function Gateway.find_by_id(self, id)
  local sql_query = '`id`= ' .. tonumber(id);
  return self:find_by_sql(sql_query);
end

-- find gateway name
function Gateway.find_by_name(self, name)
  local sql_query = '`name`= "' .. name .. '"';

  return self:find_by_sql(sql_query);
end


function Gateway.profile_get(self, gateway_id)
  local sql_query = 'SELECT `value` FROM `gateway_settings` WHERE `gateway_id` = ' .. tonumber(gateway_id) .. ' AND `name` = "profile" LIMIT 1';

  return self.database:query_return_value(sql_query);
end


function Gateway.config_table_get(self, config_table, gateway_id)
  require 'common.str'

  local sql_query = 'SELECT * FROM `'.. config_table ..'` WHERE `gateway_id` = ' .. tonumber(gateway_id);

  local settings = {};
  self.database:query(sql_query, function(entry)
    local p_class_type = common.str.strip(entry.class_type):lower();
    local p_name = common.str.strip(entry.name):lower();

    if p_class_type == 'boolean' then
      settings[p_name] = common.str.to_b(entry.value);
    elseif p_class_type == 'integer' then
      settings[p_name] = common.str.to_i(entry.value);
    else
      settings[p_name] = tostring(entry.value);
    end
  end)

  return settings
end


function Gateway.parameters_build(self, gateway_id)
  local settings = self:config_table_get('gateway_settings', gateway_id);
  local parameters = {
    realm = settings.domain,
    extension = 'auto_to_user', 
  };

  require 'common.str'

  if common.str.blank(settings.username) then
    parameters.username = 'gateway' .. gateway_id;
    parameters.register = false;
  else
    parameters.username = settings.username;
    parameters.register = true;
  end

  if common.str.blank(settings.password) then
    parameters.password = 'gateway' .. gateway_id;
  else
    parameters.password = settings.password;
  end

  for key, value in pairs(self:config_table_get('gateway_parameters', gateway_id)) do 
    parameters[key] = value; 
  end

  return parameters;
end