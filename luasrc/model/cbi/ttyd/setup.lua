-- Copyright 2017 Harry Gabriel (rootdesign@gmail.com)
-- Copyright 2018 Anton Kikin (a.kikin@tano-systems.com)
-- This is free software, licensed under the Apache License, Version 2.0

local ttydcfg = "/etc/config/ttyd"
local fs = require("nixio.fs")

local m, s, o

m = Map("ttyd", translate("Terminal settings"))

s = m:section(TypedSection, "server", translate("TTYd server settings"))
s.anonymous = true
s.addremove = false

---------------------------

s:tab("basic", translate("Basic Settings"))
s:tab("advanced", translate("Advanced Settings"))
s:tab("ssl", translate("SSL Settings"))
s:tab("basic_auth", translate("Basic Authentication"))

---------------------------

-- [port, -p]
-- Port to listen (default: 7681, use `0` for random port)
o = s:taboption("basic", Value, "port",
	translate("Port"),
	translate("Port to listen (default: 7681)"))

o.default = 7681
o.datatype = "port"
o.rmempty = true
o.placeholder = 7681

-- [interface, -i]
-- Network interface to bind (eg: eth0), or UNIX domain socket path (eg: /var/run/ttyd.sock)
o = s:taboption("basic", Value, "interface",
	translate("Interface"),
	translate("Network interface to bind"))

o.default = nil
o.template = "cbi/network_netlist"
o.nocreate = true
o.unspecified = true
o.nobridges = false

---------------------------

-- [reconnect, -r]
-- Time to reconnect for the client in seconds (default: 10)
o= s:taboption("advanced", Value, "reconnect",
	translate("Reconnect"),
	translate("Time to reconnect for the client in seconds (default: 10)"))

o.datatype = "integer"
o.rmempty = true
o.placeholder = 10
o.default = 10

-- [readonly, -R]
-- Do not allow clients to write to the TTY
o = s:taboption("advanced", Flag, "readonly",
	translate("Read only"),
	translate("Do not allow clients to write to the TTY"))

o.rmempty = true
o.default = false
o.optional = false

-- [check-origin, -O]
-- Do not allow websocket connection from different origin
o = s:taboption("advanced", Flag, "check_origin",
	translate("Check origin"),
	translate("Do not allow websocket connection from different origin"))

o.rmempty = true
o.default = false
o.optional = false

-- [max-clients, -m]
-- Maximum clients to support (default: 0, no limit)
o = s:taboption("advanced", Value, "max_clients",
	translate("Maximum clients"),
	translate("Maximum clients to support (default: 0, no limit)"))

o.placeholder = 0
o.default = 0

-- [debug, -d]
-- Set log level (default: 7)
o = s:taboption("advanced", MultiValue, "debug",
	translate("Message types for logging"),
	translate("Select websockets library message types for logging (default: LLL_ERR and LLL_WARN)"))

o.default = "1 2"
o.delimiter = " "
o.widget = "checkbox"
o.size = 11

o:value(   1, translate("LLL_ERR"))
o:value(   2, translate("LLL_WARN"))
o:value(   4, translate("LLL_NOTICE"))
o:value(   8, translate("LLL_INFO"))
o:value(  16, translate("LLL_DEBUG"))
o:value(  32, translate("LLL_HEADER"))
o:value( 128, translate("LLL_EXT"))
o:value( 256, translate("LLL_CLIENT"))
o:value( 512, translate("LLL_LATENCY"))
o:value(1024, translate("LLL_USER"))
o:value(2048, translate("LLL_THREAD"))

---------------------------

local ssl = nil
local ssl_cert = nil
local ssl_key = nil

-- [ssl, -S]
-- Enable SSL
ssl = s:taboption("ssl", Flag, "ssl",
	translate("Enable SSL"))

function ssl.validate(self, value, section)
	if ssl and ssl:formvalue(section) and (#(ssl:formvalue(section)) > 0) then
		if ((not ssl_cert) or
		    (not ssl_cert:formvalue(section)) or
		    (ssl_cert:formvalue(section) == "")) then
			return nil, translate("Must have certificate when using SSL")
		end
		
		if ((not ssl_key) or
		    (not ssl_key:formvalue(section)) or
		    (ssl_key:formvalue(section) == "")) then
			return nil, translate("Must have key when using SSL")
		end
	end

	return value
end

-- [ssl-cert, -C]
-- SSL certificate file path
ssl_cert = s:taboption("ssl", FileUpload, "ssl_cert",
	translate("HTTPS certificate (PEM&nbsp;format)"),
	translate("SSL certificate file path"))
	
ssl_cert:depends("ssl", 1)
ssl_cert.default = '/etc/ttyd/ttyd.crt'

-- [ssl-key, -K]
-- SSL key file path
ssl_key = s:taboption("ssl", FileUpload, "ssl_key",
	translate("HTTPS private key (PEM&nbsp;format)"),
	translate("SSL key file path"))
	
ssl_key:depends("ssl", 1)
ssl_key.default = '/etc/ttyd/ttyd.key'

o = s:taboption("ssl", Button, "remove_ssl_cert_and_key",
	translate("Remove certificate and key"),
	translate("TTYd will generate a new self-signed certificate using the configuration shown below"))

o.inputstyle = "remove"
o:depends("ssl", 1)

function o.write(self, section)
	if ssl_cert:cfgvalue(section) and fs.access(ssl_cert:cfgvalue(section)) then
		fs.unlink(ssl_cert:cfgvalue(section))
	end

	if ssl_key:cfgvalue(section) and fs.access(ssl_key:cfgvalue(section)) then
		fs.unlink(ssl_key:cfgvalue(section))
	end

	luci.sys.call("/etc/init.d/ttyd restart")
	luci.http.redirect(luci.dispatcher.build_url("admin", "system", "terminal", "configure"))
end

---------------------------

-- [credential, -c]
-- Credential for Basic Authentication (format: username:password)
o = s:taboption("basic_auth", Flag, "credential",
	translate("Use basic authentication"),
	translate("Credentials for basic authentication"))

o.default = 0

o = s:taboption("basic_auth", Value, "username",
	translate("Username"),
	translate("Username for basic authentication"))

o.rmempty = true
o:depends("credential", 1)

o = s:taboption("basic_auth", Value, "password",
	translate("Password"),
	translate("Password for basic authentication"))

o.password = true
o.rmempty = true
o:depends("credential", 1)

---------------------------

s = m:section(TypedSection, "ssl",
	translate("Self-signed SSL certificate parameters"))

s.template  = "cbi/tsection"
s.anonymous = true


o = s:option(Value, "days",
	translate("Number of days a generated certificate is valid"))

o.default = 730
o.placeholder = 730
o.datatype = "uinteger"


o = s:option(Value, "bits",
	translate("Length of the private key in bits"))

o.default = 2048
o.datatype = "min(1024)"
o.placeholder = 2048


o = s:option(Value, "country",
	translate("Country name (/C)"),
	translate("The two-letter country code where your company is legally located"))

o.default = "RU"
o.placeholder = "RU"


o = s:option(Value, "state",
	translate("State or province name (/ST)"),
	translate("The state/province where your company is legally located"))

o.default = ""
o.placeholder = "Saint-Petersburg"


o = s:option(Value, "locality",
	translate("Locality name (/L)"),
	translate("The city where your company is legally located"))

o.default = ""
o.placeholder = "Saint-Petersburg"


o = s:option(Value, "organization",
	translate("Organization name (/O)"),
	translate("Your company's legally registered name"))

o.default = ""
o.placeholder = "Your Company, Inc."


o = s:option(Value, "organizational_unit",
	translate("Organizational unit name (/OU)"),
	translate("The name of your department within the organization"))

o.default = ""
o.placeholder = "IT department"


o = s:option(Value, "commonname",
	translate("Common name (/CN)"),
	translate("The fully-qualified domain name"))

o.default = luci.sys.hostname()
o.placeholder = "www.example.com"

---------------------------

return m
