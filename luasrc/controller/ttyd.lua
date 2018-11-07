-- Copyright 2017 Harry Gabriel (rootdesign@gmail.com)
-- Copyright 2018 Anton Kikin (a.kikin@tano-systems.com)
-- This is free software, licensed under the Apache License, Version 2.0

module("luci.controller.ttyd", package.seeall)

local fs    = require("nixio.fs")
local util  = require("luci.util")
local tmpl  = require("luci.template")
local i18n  = require("luci.i18n")

function index()
	if not nixio.fs.access("/etc/config/ttyd") then
		nixio.fs.writefile("/etc/config/ttyd", "")
	end

	-- menu items
	entry({"admin", "system", "terminal"}, firstchild(), _("Terminal"), 80)
	entry({"admin", "system", "terminal", "terminal"}, call("view_terminal"), _("Terminal"), 10)
	entry({"admin", "system", "terminal", "configure"}, cbi("ttyd/setup"), _("Setup"), 20)

	-- actions
	entry({"admin", "system", "ttyd", "start"}, call("action_start"))
end

function view_terminal()
	local is_running = luci.sys.exec("/etc/init.d/ttyd status")

	local uci  = require "luci.model.uci".cursor()
	local ssl  = uci:get("ttyd", "server", "ssl") or "0"
	local port = uci:get("ttyd", "server", "port") or "7681"

	tmpl.render("ttyd/terminal", {
		is_running = tonumber(is_running),
		ssl = tonumber(ssl),
		port = tonumber(port)
	})
end

function action_start()
	local http = require "luci.http"
	luci.sys.init.start("ttyd")
	http.redirect(luci.dispatcher.build_url('admin/system/ttyd/terminal'))
end
