local TestSuite = {}
TestSuite.__index = TestSuite
TestSuite.testsQueue = {}
TestSuite.isRunningTests = false 
TestSuite.runningTests = 0 
function TestSuite.new()
	local self = setmetatable({
		passes = 0,
		fails = 0,
		undefined = 0,
		running = 0,
		tests = {},
	}, TestSuite)

	return self
end

function TestSuite:getGlobal(path)
	local current = getfenv(0)

	for name in string.gmatch(path, "[^.]+") do
		current = current[name]
		if current == nil then return nil end
	end

	return current
end

function TestSuite:reportResults(name, status, message)
	if status == "pass" then
		self.passes += 1
		print("✅ " .. name .. (message and " • " .. message or ""))
	else
		self.fails += 1
		warn("⛔ " .. name .. (message and ": " .. message or " failed"))
	end
end

function TestSuite:checkUndefinedAliases(aliases)
	local undefinedAliases = {}
	for _, alias in ipairs(aliases) do
		if self:getGlobal(alias) == nil then
			table.insert(undefinedAliases, alias)
		end
	end
	if #undefinedAliases > 0 then
		self.undefined += 1
		warn("⚠️ Undefined aliases: " .. table.concat(undefinedAliases, ", "))
	end
end




function TestSuite:runTest(name, aliases, callback)

	table.insert(self.testsQueue, {name = name, aliases = aliases, callback = callback})


	if not self.isRunningTests then
		self:processQueue()
	end
end


function TestSuite:processQueue()
	self.isRunningTests = true 

	local function runNextTest()
		if #self.testsQueue == 0 then
	

			if #self.testsQueue == 0 and self.runningTests == 0 then
				
				task.defer(function()
					self:summaryReport()
				end)
				self.isRunningTests = false
				return
			elseif #self.testsQueue == 0 then
				return 
			end
	
			self.isRunningTests = false
			return
		end


		local nextTest = table.remove(self.testsQueue, 1)

		task.spawn(function()
			task.wait(0.003)


			local name, aliases, callback = nextTest.name, nextTest.aliases, nextTest.callback

			local success, message = pcall(function()
				if callback then
					callback() 
				end
				self:checkUndefinedAliases(aliases)
				return "success"
			end)

	
			self:reportResults(name, success and "pass" or "fail", success and message or "Error occurred: " .. message)

	
			runNextTest()
		end)
	end

	runNextTest()
end

function TestSuite:validator()
	local Passes, Tests = 0, 0
	local OriginalIdentity = ""
	local NewThreadIdentity = ""

	local Connection; Connection = game:GetService("LogService").MessageOut:Connect(function(message)
		if message:lower():find("current identity is") and OriginalIdentity == "" then
			OriginalIdentity = message:lower():gsub("current identity is", ""):match("%d+")
		end

		if OriginalIdentity ~= "" and NewThreadIdentity == "" then
			NewThreadIdentity = message:lower():gsub("current identity is", ""):match("%d+")
			Connection:Disconnect()
		end
	end)

	printidentity()
	repeat task.wait() until OriginalIdentity

	local PrintIdentitySource = debug.info(printidentity, 's')
	if tonumber(OriginalIdentity) > 9 then
		warn("Executor is faking identity, identity is over 9")
		return
	end

	local SetFunctionEnvSuccess = select(1, pcall(function()
		setfenv(PrintIdentitySource, {})
	end))

	local SuccessSetThread = false
	local SetThreadIdentity = set_thread_identity or setthreadidentity


	if SetThreadIdentity then
		SetThreadIdentity(3)

		printidentity()
		repeat task.wait() until NewThreadIdentity
		SuccessSetThread = tonumber(NewThreadIdentity) ~= 3
		SetThreadIdentity(tonumber(OriginalIdentity))
	end

	local IdentityChecks = {
		{
			PrintIdentitySource ~= "[C]",
			"Created a Lua Closure function for printidentity"
		},
		{
			SetFunctionEnvSuccess,
			"Tried to hide their function with newcclosure or a metatable"
		},
		{
			SuccessSetThread,
			"set_thread_identity did not set the correct identity"
		},
		{
			iscclosure and not iscclosure(printidentity),
			"Created a Lua Closure function for printidentity"
		}
	}
	Tests = #IdentityChecks

	for _, Checks in ipairs(IdentityChecks) do
		if Checks[1] then
			warn("⚠️ " .. Checks[2])
			continue
		else
			Passes += 1
		end
	end

	if Passes == Tests then
		print("✅ Your executor does not fake it's identity!")
	else
		warn("⚠️ Your executor is likely faking their identity! " .. string.format("%.1f", (Passes / Tests) * 100))
	end
end

function TestSuite:summaryReport()
	
	repeat task.wait() until self.running == 0
	
	local totalTests = self.passes + self.fails
	local successRate = totalTests > 0 and math.round(self.passes / totalTests * 100) or 0
	task.wait(0.1)
	
	print("⌛ Starting identity test...")
	self:validator()
	--print("⌛ Starting loadstring test...")
	--print("\n")
	--loadstring(game:HttpGet("https://raw.githubusercontent.com/orangexd/stuf/refs/heads/main/eaea.lua"))()
	print("✅ Success rate: " .. successRate .. "% (" .. self.passes .. " out of " .. totalTests .. ")")
	print("⛔ " .. self.fails .. " tests failed")
	print("⚠️ " .. self.undefined .. " globals are missing aliases")
	print("ℹ️ Test developed by the Element Script Team. This is the TRUE ultimate unc test")
	print("ℹ️ This script is in very early beta and we will be adding more functionality in the future")
	local endtime = os.clock()
	local elapsed = os.difftime(readable,endtime)
	local precisewtv = endtime - readable
	print(string.format("ℹ️ Elapsed time: %.2f seconds", precisewtv))
	
	print("⌛ Generating Report...")
	print(string.rep("\n", 5))
	local timeddd = os.date("%Y-%m-%d %H:%M:%S")
	print(string.format("➡️ ENC TEST REPORT | Generated at %s | ✅ Success rate: %d%% (%d out of %d) | ⛔ %d tests failed | ⚠️ %d globals are missing aliases | Elapsed test time: %.2f seconds.",
		timeddd, successRate, self.passes, totalTests, self.fails, self.undefined, precisewtv))

end



local function shallowEqual(t1, t2)
	if t1 == t2 then
		return true
	end

	local UNIQUE_TYPES = {
		["function"] = true,
		["table"] = true,
		["userdata"] = true,
		["thread"] = true,
	}

	for k, v in pairs(t1) do
		if UNIQUE_TYPES[type(v)] then
			if type(t2[k]) ~= type(v) then
				return false
			end
		elseif t2[k] ~= v then
			return false
		end
	end

	for k, v in pairs(t2) do
		if UNIQUE_TYPES[type(v)] then
			if type(t2[k]) ~= type(v) then
				return false
			end
		elseif t1[k] ~= v then
			return false
		end
	end

	return true
end

function TestSuite:defineTests()

	self:runTest("cache.invalidate", {}, function()
		local container = Instance.new("Folder")
		local part = Instance.new("Part", container)
		cache.invalidate(container:FindFirstChild("Part"))
		assert(part ~= container:FindFirstChild("Part"), "Reference `part` could not be invalidated")
	end)
	

	self:runTest("cache.iscached", {}, function()
		local part = Instance.new("Part")
		assert(cache.iscached(part), "Part should be cached")
		cache.invalidate(part)
		assert(not cache.iscached(part), "Part should not be cached")
	end)

	self:runTest("cache.replace", {}, function()
		local part = Instance.new("Part")
		local fire = Instance.new("Fire")
		cache.replace(part, fire)
		assert(part ~= fire, "Part was not replaced with Fire")
	end)



	self:runTest("compareinstances", {}, function()
		local part = Instance.new("Part")
		local clone = cloneref(part)
		assert(part ~= clone, "Clone should not be equal to original")
		assert(compareinstances(part, clone), "Clone should be equal to original when using compareinstances()")
	end)

	self:runTest("checkcaller", {}, function()
		assert(checkcaller(), "Main scope should return true")
	end)

	self:runTest("clonefunction", {}, function()
		local function test()
			return "success"
		end
		local copy = clonefunction(test)
		assert(test() == copy(), "The clone should return the same value as the original")
		assert(test ~= copy, "The clone should not be equal to the original")
	end)
	
	self:runTest("cloneref", {}, function()
		local part = Instance.new("Part")
		local clone = cloneref(part)
		assert(part ~= clone, "Clone should not be equal to original")
		clone.Name = "Test"
		assert(part.Name == "Test", "Clone should have updated the original")
	end)
	
	self:runTest("getscriptclosure", {"getscriptfunction"}, function()
		local module = game:GetService("CoreGui").RobloxGui.Modules.Common.Constants
		local constants = getrenv().require(module)
		local generated = getscriptclosure(module)()
		assert(constants ~= generated, "Generated module should not match the original")
		assert(shallowEqual(constants, generated), "Generated constant table should be shallow equal to the original")
	end)
	
	

	self:runTest("hookfunction", {"replaceclosure"}, function()
		local function test()
			return true
		end
		local ref = hookfunction(test, function()
			return false
		end)
		assert(test() == false, "Function should return false")
		assert(ref() == true, "Original function should return true")
		assert(test ~= ref, "Original function should not be same as the reference")
	end)

	self:runTest("iscclosure", {}, function()
		assert(iscclosure(print) == true, "Function 'print' should be a C closure")
		assert(iscclosure(function() end) == false, "Executor function should not be a C closure")
	end)
	
	self:runTest("getgenv", {},function()
		getgenv().__TEST_GLOBAL = true
		assert(__TEST_GLOBAL, "Failed to set a global variable")
		getgenv().__TEST_GLOBAL = nil
	end)
	
	self:runTest("getrenv", {}, function()
		assert(_G ~= getrenv()._G, "The variable _G in the executor is identical to _G in the game")
	end)
	self:runTest("getreg", {}, function()
		assert(type(getreg()) == "table", "Did not return a table (Lua Registry)")
	end)
	self:runTest("getsenv", {}, function()
		local animate = game:GetService("Players").LocalPlayer.Character.Animate
		local env = getsenv(animate)
		assert(type(env) == "table", "Did not return a table for Character.Animate (a " .. animate.ClassName .. ")")
		assert(env.script == animate, "The script global is not identical to Character.Animate")
	end)
	self:runTest("getgc", {}, function()
		local gc = getgc()
		assert(type(gc) == "table", "Did not return a table")
		assert(#gc > 0, "Did not return a table with any values")
	end)
	self:runTest("getthreadidentity", {"getidentity", "getthreadcontext"}, function()
		assert(type(getthreadidentity()) == "number", "Did not return a number")
	end)
	
	self:runTest("setthreadidentity", {"setidentity", "setthreadcontext"}, function()
		local previous = getthreadidentity()
		setthreadidentity(3)
		assert(getthreadidentity() == 3, "Did not set the thread identity")
		setthreadidentity(previous)
	end)
	
	self:runTest("getrunningscripts", {}, function()
		local scripts = getrunningscripts()
		assert(type(scripts) == "table", "Did not return a table")
		assert(#scripts > 0, "Did not return a table with any values")
		assert(typeof(scripts[1]) == "Instance", "First value is not an Instance")
		assert(scripts[1]:IsA("ModuleScript") or scripts[1]:IsA("LocalScript"), "First value is not a ModuleScript or LocalScript")
	end)
	
	self:runTest("getscriptbytecode", {}, function()
		local animate = game:GetService("Players").LocalPlayer.Character.Animate
		local bytecode = getscriptbytecode(animate)
		assert(type(bytecode) == "string", "Did not return a string for Character.Animate (a " .. animate.ClassName .. ")")
	end)
	self:runTest("request", {"http.request", "http_request"}, function()
		local response = request({
			Url = "https://httpbin.org/user-agent",
			Method = "GET",
		})
		assert(type(response) == "table", "Response must be a table")
		assert(response.StatusCode == 200, "Did not return a 200 status code")
		local data = game:GetService("HttpService"):JSONDecode(response.Body)
		assert(type(data) == "table" and type(data["user-agent"]) == "string", "Did not return a table with a user-agent key")
		return "User-Agent: " .. data["user-agent"]
	end)

	self:runTest("setclipboard", {"toclipboard"}, function()
		assert(type(setclipboard or toclipboard) == "function", "Not a function")
	end)
	self:runTest("setwindowtitle", {})
	self:runTest("setwindowicon", {})
	self:runTest("messagebox", {})
	self:runTest("setfpscap", {}, function()
		local renderStepped = game:GetService("RunService").RenderStepped
		local function step()
			renderStepped:Wait()
			local sum = 0
			for _ = 1, 5 do
				sum += 1 / renderStepped:Wait()
			end
			return math.round(sum / 5)
		end
		setfpscap(60)
		local step60 = step()
		setfpscap(0)
		local step0 = step()
		return step60 .. "fps @60 • " .. step0 .. "fps @0"
	end)

	self:runTest("getscripthash", {}, function()
		local animate = game:GetService("Players").LocalPlayer.Character.Animate:Clone()
		local hash = getscripthash(animate)
		local source = animate.Source
		animate.Source = "print('Hello, world!')"
		task.defer(function()
			animate.Source = source
		end)
		local newHash = getscripthash(animate)
		assert(hash ~= newHash, "Did not return a different hash for a modified script")
		assert(newHash == getscripthash(animate), "Did not return the same hash for a script with the same source")
	end)
	
	self:runTest("getscripts", {}, function()
		local scripts = getscripts()
		assert(type(scripts) == "table", "Did not return a table")
		assert(#scripts > 0, "Did not return a table with any values")
		assert(typeof(scripts[1]) == "Instance", "First value is not an Instance")
		assert(scripts[1]:IsA("ModuleScript") or scripts[1]:IsA("LocalScript"), "First value is not a ModuleScript or LocalScript")
	end)

	self:runTest("isnetworkowner", {}, function()
		local part = workspace:FindFirstChildWhichIsA("Part", true)
		local client_part = Instance.new('Part')
		assert(part, "Why the fuck does ur game have no parts?")
		assert(client_part.ReceiveAge == 0, "Client Part should be on your network")
		task.defer(client_part.Destroy, client_part)
	end)

	self:runTest("islclosure", {}, function()
		assert(islclosure(print) == false, "Function 'print' should not be a Lua closure")
		assert(islclosure(function() end) == true, "Executor function should be a Lua closure")
	end)
	
	self:runTest("getloadedmodules", {}, function()
		local modules = getloadedmodules()
		assert(type(modules) == "table", "Did not return a table")
		assert(#modules > 0, "Did not return a table with any values")
		assert(typeof(modules[1]) == "Instance", "First value is not an Instance")
		assert(modules[1]:IsA("ModuleScript"), "First value is not a ModuleScript")
	end)

	self:runTest("isexecutorclosure", {"checkclosure", "isourclosure"}, function()
		assert(isexecutorclosure(isexecutorclosure) == true, "Did not return true for an executor global")
		assert(isexecutorclosure(newcclosure(function() end)) == true, "Did not return true for an executor C closure")
		assert(isexecutorclosure(function() end) == true, "Did not return true for an executor Luau closure")
		assert(isexecutorclosure(print) == false, "Did not return false for a Roblox global")
	end)
	
	self:runTest("isrenderobj",{},function()
		local drawing = Drawing.new("Image")
		drawing.Visible = true
		assert(isrenderobj(drawing) == true, "Did not return true for an Image")
		assert(isrenderobj(newproxy()) == false, "Did not return false for a blank table")
	end)
	
	self:runTest("getrenderproperty", {}, function()
		local drawing = Drawing.new("Image")
		drawing.Visible = true
		assert(type(getrenderproperty(drawing, "Visible")) == "boolean", "Did not return a boolean value for Image.Visible")
		local success, result = pcall(function()
			return getrenderproperty(drawing, "Color")
		end)
		if not success or not result then
			return "Image.Color is not supported"
		end
	end)

	self:runTest("setrenderproperty", {}, function()
		local drawing = Drawing.new("Square")
		drawing.Visible = true
		setrenderproperty(drawing, "Visible", false)
		assert(drawing.Visible == false, "Did not set the value for Square.Visible")
	end)
	self:runTest("fireclickdetector", {}, function()
		local detector = Instance.new("ClickDetector")
		fireclickdetector(detector, 50, "MouseHoverEnter")
	end)

	self:runTest("getcallbackvalue", {}, function()
		local bindable = Instance.new("BindableFunction")
		local function test()
		end
		bindable.OnInvoke = test
		assert(getcallbackvalue(bindable, "OnInvoke") == test, "Did not return the correct value")
	end)

	self:runTest("getconnections", {}, function()
		local types = {
			Enabled = "boolean",
			ForeignState = "boolean",
			LuaConnection = "boolean",
			Function = "function",
			Thread = "thread",
			Fire = "function",
			Defer = "function",
			Disconnect = "function",
			Disable = "function",
			Enable = "function",
		}
		local bindable = Instance.new("BindableEvent")
		bindable.Event:Connect(function() end)
		local connection = getconnections(bindable.Event)[1]
		for k, v in pairs(types) do
			assert(connection[k] ~= nil, "Did not return a table with a '" .. k .. "' field")
			assert(type(connection[k]) == v, "Did not return a table with " .. k .. " as a " .. v .. " (got " .. type(connection[k]) .. ")")
		end
	end)

	self:runTest("getcustomasset", {}, function()
		writefile(".tests/getcustomasset.txt", "success")
		local contentId = getcustomasset(".tests/getcustomasset.txt")
		assert(type(contentId) == "string", "Did not return a string")
		assert(#contentId > 0, "Returned an empty string")
		assert(string.match(contentId, "rbxasset://") == "rbxasset://", "Did not return an rbxasset url")
	end)

	self:runTest("gethiddenproperty", {}, function()
		local fire = Instance.new("Fire")
		local property, isHidden = gethiddenproperty(fire, "size_xml")
		assert(property == 5, "Did not return the correct value")
		assert(isHidden == true, "Did not return whether the property was hidden")
	end)

	self:runTest("sethiddenproperty", {}, function()
		local fire = Instance.new("Fire")
		local hidden = sethiddenproperty(fire, "size_xml", 10)
		assert(hidden, "Did not return true for the hidden property")
		assert(gethiddenproperty(fire, "size_xml") == 10, "Did not set the hidden property")
	end)

	self:runTest("gethui", {}, function()
		assert(typeof(gethui()) == "Instance", "Did not return an Instance")
	end)

	self:runTest("getinstances", {}, function()
		assert(getinstances()[1]:IsA("Instance"), "The first value is not an Instance")
	end)

	self:runTest("getnilinstances", {}, function()
		assert(getnilinstances()[1]:IsA("Instance"), "The first value is not an Instance")
		assert(getnilinstances()[1].Parent == nil, "The first value is not parented to nil")
	end)

	self:runTest("isscriptable", {}, function()
		local fire = Instance.new("Fire")
		assert(isscriptable(fire, "size_xml") == false, "Did not return false for a non-scriptable property (size_xml)")
		assert(isscriptable(fire, "Size") == true, "Did not return true for a scriptable property (Size)")
	end)

	self:runTest("setscriptable", {}, function()
		local fire = Instance.new("Fire")
		local wasScriptable = setscriptable(fire, "size_xml", true)
		assert(wasScriptable == false, "Did not return false for a non-scriptable property (size_xml)")
		assert(isscriptable(fire, "size_xml") == true, "Did not set the scriptable property")
		fire = Instance.new("Fire")
		assert(isscriptable(fire, "size_xml") == false, "⚠️⚠️ setscriptable persists between unique instances ⚠️⚠️")
	end)

	self:runTest("setrbxclipboard", {})
	self:runTest("getrawmetatable", {}, function()
		local metatable = { __metatable = "Locked!" }
		local object = setmetatable({}, metatable)
		assert(getrawmetatable(object) == metatable, "Did not return the metatable")
	end)

	self:runTest("hookmetamethod", {}, function()
		local object = setmetatable({}, { __index = newcclosure(function() return false end), __metatable = "Locked!" })
		local ref = hookmetamethod(object, "__index", function() return true end)
		assert(object.test == true, "Failed to hook a metamethod and change the return value")
		assert(ref() == false, "Did not return the original function")
	end)

	self:runTest("getnamecallmethod", {}, function()
		local method
		local ref
		ref = hookmetamethod(game, "__namecall", function(...)
			if not method then
				method = getnamecallmethod()
			end
			return ref(...)
		end)
		game:GetService("Lighting")
		assert(method == "GetService", "Did not get the correct method (GetService)")
	end)

	self:runTest("isreadonly", {}, function()
		local object = {}
		table.freeze(object)
		assert(isreadonly(object), "Did not return true for a read-only table")
	end)

	self:runTest("setrawmetatable", {}, function()
		local object = setmetatable({}, { __index = function() return false end, __metatable = "Locked!" })
		local objectReturned = setrawmetatable(object, { __index = function() return true end })
		assert(object, "Did not return the original object")
		assert(object.test == true, "Failed to change the metatable")
		if objectReturned then
			return objectReturned == object and "Returned the original object" or "Did not return the original object"
		end
	end)
	self:runTest("setreadonly", {}, function()
		local object = { success = false }
		table.freeze(object)
		setreadonly(object, false)
		object.success = true
		assert(object.success, "Did not allow the table to be modified")
	end)
	self:runTest("cleardrawcache", {}, function()
		cleardrawcache()
	end)
	self:runTest("identifyexecutor", {"getexecutorname"}, function()
		local name, version = identifyexecutor()
		assert(type(name) == "string", "Did not return a string for the name")
		return type(version) == "string" and "Returns version as a string" or "Does not return version"
	end)
	self:runTest("messagebox", {})

	self:runTest("queue_on_teleport", {"queueonteleport"})
	self:runTest("lz4compress", {}, function()
		local raw = "Hello, world!"
		local compressed = lz4compress(raw)
		assert(type(compressed) == "string", "Compression did not return a string")
		assert(lz4decompress(compressed, #raw) == raw, "Decompression did not return the original string")
	end)

	self:runTest("lz4decompress", {}, function()
		local raw = "Hello, world!"
		local compressed = lz4compress(raw)
		assert(type(compressed) == "string", "Compression did not return a string")
		assert(lz4decompress(compressed, #raw) == raw, "Decompression did not return the original string")
	end)

	--self:runTest("loadstring", {}, function()
	--	local animate = game:GetService("Players").LocalPlayer.Character.Animate
	--	local bytecode = getscriptbytecode(animate)
	--	local func = loadstring(bytecode)
	--	assert(type(func) ~= "function", "Luau bytecode should not be loadable!")
	--	assert(assert(loadstring("return ... + 1"))(1) == 2, "Failed to do simple math")
	--	assert(type(select(2, loadstring("f"))) == "string", "Loadstring did not return anything for a compiler error")
	--end)

	self:runTest("newcclosure", {}, function()
		local function test()
			return true
		end
		local testC = newcclosure(test)
		assert(test() == testC(), "New C closure should return the same value as the original")
		assert(test ~= testC, "New C closure should not be same as the original")
		assert(iscclosure(testC), "New C closure should be a C closure")
	end)
	
	-- rconsole stuff
	local rconsolefunctions = {
		["rconsolecreate"] = {
			false;
			rconsolecreate or consolecreate;
			{"consolecreate"};
		};
		["rconsoleclear"] = {
			false;
			rconsoleclear or consoleclear;
			{"consoleclear"};
		};
		["rconsolewarn"] = {
			false;
			rconsolewarn or consoleclear;
			{"consoleclear"};
		};
		["rconsoleerror"] = {
			false;
			rconsoleerror or consoleclear;
			{"consoleclear"};
		};
		["rconsoledestroy"] = {
			false;
			rconsoledestroy or consoledestroy;
			{"consoledestroy"};
		};
		["rconsoleinput"] = {
			false;
			rconsoleinput or consoleinput;
			{"consoleinput"};
		};
		["rconsoleprint"] = {
			false;
			rconsoleprint or consoleprint;
			{"consoleprint"};
		};
		["rconsolesettitle"] = {
			false;
			rconsolesettitle or rconsolename;
			{"rconsolename", "consolesettitle"};
		};
	}
	
	for ConsoleFunction, ConsoleInfo in pairs(rconsolefunctions) do
		self:runTest(ConsoleFunction, ConsoleInfo[3], function()
			assert(ConsoleInfo[2], "Unable to find rconsole function, " .. ConsoleFunction)
			assert(getgenv()[ConsoleFunction] == ConsoleInfo[2], "rconsole functions are not the same in, Global Env and Exploit Env")
			assert(type(ConsoleInfo[2]) == "function", "rconsole method should be a function")
			assert(type(getgenv()[ConsoleFunction]) == "function", "rconsole method should be a function")
			assert(type(getgenv()[ConsoleFunction]) == type(getgenv(ConsoleFunction)[ConsoleFunction]), "Did not return the correct type")
		end)
	end
	
	-- crypt library
	
	self:runTest("crypt", {})
	self:runTest("crypt.base64encode", {"crypt.base64.encode", "crypt.base64_encode", "base64.encode", "base64_encode"}, function()
		assert(crypt.base64encode("willywigguh") == "d2lsbHl3aWdndWg=", "Encoding Base64 failiure")
	end)
	self:runTest("crypt.base64decode", {"crypt.base64.decode", "crypt.base64_decode", "base64.decode", "base64_decode"}, function()
		assert(crypt.base64decode("d2lsbHl3aWdndWg=") == "willywigguh", "Encoding Base64 failiure")
	end)
	self:runTest("crypt.encrypt", {}, function()
		local key = crypt.generatekey()
		local encrypted, iv = crypt.encrypt("willywigguh", key, nil, "CBC")
		assert(iv, "crypt.encrypt should return an IV")
		local decrypted = crypt.decrypt(encrypted, key, iv, "CBC")
		assert(decrypted == "willywigguh", "Failed to decrypt string")
	end)
	self:runTest("crypt.decrypt", {}, function()
		local key, iv = crypt.generatekey(), crypt.generatekey()
		local encrypted = crypt.encrypt("test", key, iv, "CBC")
		local decrypted = crypt.decrypt(encrypted, key, iv, "CBC")
		assert(decrypted == "test", "Failed to decrypt raw string from encrypted data")

		end)
	self:runTest("crypt.generatebytes", {}, function()
		local size = math.random(10, 100)
		local bytes = crypt.generatebytes(size)
		assert(#crypt.base64decode(bytes) == size, "The decoded result should be " .. size .. " bytes long (got " .. #crypt.base64decode(bytes) .. " decoded, " .. #bytes .. " raw)")
	end)
	self:runTest("crypt.generatekey", {}, function()
		local key = crypt.generatekey()
		assert(#crypt.base64decode(key) == 32, "Generated key should be 32 bytes long when decoded")
	end)
	self:runTest("crypt.hash", {}, function()
		local algorithms = {'sha1', 'sha384', 'sha512', 'md5', 'sha256', 'sha3-224', 'sha3-256', 'sha3-512'}
		for _, algorithm in ipairs(algorithms) do
			local hash = crypt.hash("test", algorithm)
			assert(hash, "crypt.hash on algorithm '" .. algorithm .. "' should return a hash")
		end
	end)
	
	self:runTest("printidentity", {}, function()
		if iscclosure then
			assert(iscclosure(printidentity), "printidentity must be a C Closure")
		else
			assert(debug.info(printidentity, 's') == '[C]', "printidentity must be a C Closure")
		end
	end)
	
	-- debug library
	
	self:runTest("debug.getconstant", {}, function()
		local function test()
			print("Hello, world!")
		end
		assert(debug.getconstant(test, 1) == "print", "First constant must be print")
		assert(debug.getconstant(test, 2) == nil, "Second constant must be nil")
		assert(debug.getconstant(test, 3) == "Hello, world!", "Third constant must be 'Hello, world!'")
	end)
	self:runTest("debug.getregistry", {}, function()
		assert(type(debug.getregistry()) == "table", "Registry is not a table")
	end)
	self:runTest("debug.getconstants", {}, function()
		local function test()
			local num = 5000 .. 50000
			print("Hello, world!", num, warn)
		end
		local constants = debug.getconstants(test)
		assert(constants[1] == 50000, "First constant must be 50000")
		assert(constants[2] == "print", "Second constant must be print")
		assert(constants[3] == nil, "Third constant must be nil")
		assert(constants[4] == "Hello, world!", "Fourth constant must be 'Hello, world!'")
		assert(constants[5] == "warn", "Fifth constant must be warn")
	end)
		self:runTest("debug.getinfo", {}, function()
		local types = {
			source = "string",
			short_src = "string",
			func = "function",
			what = "string",
			currentline = "number",
			name = "string",
			nups = "number",
			numparams = "number",
			is_vararg = "number",
		}
		local function test(...)
			print(...)
		end
		local info = debug.getinfo(test)
		for k, v in pairs(types) do
			assert(info[k] ~= nil, "Did not return a table with a '" .. k .. "' field")
			assert(type(info[k]) == v, "Did not return a table with " .. k .. " as a " .. v .. " (got " .. type(info[k]) .. ")")
		end
	end)
		self:runTest("debug.getproto", {}, function()
		local function test()
			local function proto()
				return true
			end
		end
		local proto = debug.getproto(test, 1, true)[1]
		local realproto = debug.getproto(test, 1)
		assert(proto, "Failed to get the inner function")
		assert(proto() == true, "The inner function did not return anything")
		if not realproto() then
			return "Proto return values are disabled on this executor"
		end
	end)
		self:runTest("debug.getprotos", {}, function()
		local function test()
			local function _1()
				return true
			end
			local function _2()
				return true
			end
			local function _3()
				return true
			end
		end
		for i in ipairs(debug.getprotos(test)) do
			local proto = debug.getproto(test, i, true)[1]
			local realproto = debug.getproto(test, i)
			assert(proto(), "Failed to get inner function " .. i)
			if not realproto() then
				return "Proto return values are disabled on this executor"
			end
		end
	end)

	self:runTest("debug.getstack", {}, function()
		local _ = "a" .. "b"
		assert(debug.getstack(1, 1) == "ab", "The first item in the stack should be 'ab'")
		assert(debug.getstack(1)[1] == "ab", "The first item in the stack table should be 'ab'")
	end)

	self:runTest("debug.getupvalue", {}, function()
		local upvalue = function() end
		local function test()
			print(upvalue)
		end
		assert(debug.getupvalue(test, 1) == upvalue, "Unexpected value returned from debug.getupvalue")
	end)

	self:runTest("debug.getupvalues", {}, function()
		local upvalue = function() end
		local function test()
			print(upvalue)
		end
		local upvalues = debug.getupvalues(test)
		assert(upvalues[1] == upvalue, "Unexpected value returned from debug.getupvalues")
	end)

	self:runTest("debug.setconstant", {}, function()
		local function test()
			return "fail"
		end
		debug.setconstant(test, 1, "success")
		assert(test() == "success", "debug.setconstant did not set the first constant")
	end)

	self:runTest("debug.setstack", {}, function()
		local function test()
			return "fail", debug.setstack(1, 1, "success")
		end
		assert(test() == "success", "debug.setstack did not set the first stack item")
	end)

	self:runTest("debug.setupvalue", {}, function()
		local function upvalue()
			return "fail"
		end
		local function test()
			return upvalue()
		end
		debug.setupvalue(test, 1, function()
			return "success"
		end)
		assert(test() == "success", "debug.setupvalue did not set the first upvalue")
	end)
	
	
	
	
	if isfolder and makefolder and delfolder then
		if isfolder(".tests") then
			delfolder(".tests")
		end
		makefolder(".tests")
	end

	self:runTest("readfile", {}, function()
		writefile(".tests/readfile.txt", "success")
		assert(readfile(".tests/readfile.txt") == "success", "Did not return the contents of the file")
	end)

	self:runTest("listfiles", {}, function()
		makefolder(".tests/listfiles")
		writefile(".tests/listfiles/test_1.txt", "success")
		writefile(".tests/listfiles/test_2.txt", "success")
		local files = listfiles(".tests/listfiles")
		assert(#files == 2, "Did not return the correct number of files")
		assert(isfile(files[1]), "Did not return a file path")
		assert(readfile(files[1]) == "success", "Did not return the correct files")
		makefolder(".tests/listfiles_2")
		makefolder(".tests/listfiles_2/test_1")
		makefolder(".tests/listfiles_2/test_2")
		local folders = listfiles(".tests/listfiles_2")
		assert(#folders == 2, "Did not return the correct number of folders")
		assert(isfolder(folders[1]), "Did not return a folder path")
	end)

	self:runTest("writefile", {}, function()
		writefile(".tests/writefile.txt", "success")
		assert(readfile(".tests/writefile.txt") == "success", "Did not write the file")
		local requiresFileExt = pcall(function()
			writefile(".tests/writefile", "success")
			assert(isfile(".tests/writefile.txt"))
		end)
		if not requiresFileExt then
			return "This executor requires a file extension in writefile"
		end
	end)

	self:runTest("makefolder", {}, function()
		makefolder(".tests/makefolder")
		assert(isfolder(".tests/makefolder"), "Did not create the folder")
	end)

	self:runTest("appendfile", {}, function()
		writefile(".tests/appendfile.txt", "su")
		appendfile(".tests/appendfile.txt", "cce")
		appendfile(".tests/appendfile.txt", "ss")
		assert(readfile(".tests/appendfile.txt") == "success", "Did not append the file")
	end)

	self:runTest("isfile", {}, function()
		writefile(".tests/isfile.txt", "success")
		assert(isfile(".tests/isfile.txt") == true, "Did not return true for a file")
		assert(isfile(".tests") == false, "Did not return false for a folder")
		assert(isfile(".tests/doesnotexist.exe") == false, "Did not return false for a nonexistent path (got " .. tostring(isfile(".tests/doesnotexist.exe")) .. ")")
	end)

	self:runTest("isfolder", {}, function()
		assert(isfolder(".tests") == true, "Did not return false for a folder")
		assert(isfolder(".tests/doesnotexist.exe") == false, "Did not return false for a nonexistent path (got " .. tostring(isfolder(".tests/doesnotexist.exe")) .. ")")
	end)

	self:runTest("delfolder", {}, function()
		makefolder(".tests/delfolder")
		delfolder(".tests/delfolder")
		assert(isfolder(".tests/delfolder") == false, "Failed to delete folder (isfolder = " .. tostring(isfolder(".tests/delfolder")) .. ")")
	end)

	self:runTest("delfile", {}, function()
		writefile(".tests/delfile.txt", "Hello, world!")
		delfile(".tests/delfile.txt")
		assert(isfile(".tests/delfile.txt") == false, "Failed to delete file (isfile = " .. tostring(isfile(".tests/delfile.txt")) .. ")")
	end)

	self:runTest("loadfile", {}, function()
		writefile(".tests/loadfile.txt", "return ... + 1")
		assert(assert(loadfile(".tests/loadfile.txt"))(1) == 2, "Failed to load a file with arguments")
		writefile(".tests/loadfile.txt", "f")
		local callback, err = loadfile(".tests/loadfile.txt")
		assert(err and not callback, "Did not return an error message for a compiler error")
	end)

	self:runTest("dofile", {})
	
	self:runTest("isrbxactive", {"isgameactive"}, function()
		assert(type(isrbxactive()) == "boolean", "Did not return a boolean value")
	end)

	local mousefunctions = {
		["mouse1click"] = {
			false;
			mouse1click or nil;
			{"mouse1click"};
		};
		["mouse1press"] = {
			false;
			mouse1press or nil;
			{"mouse1press"};
		};
		["mouse1release"] = {
			false;
			mouse1release or nil;
			{"mouse1release"};
		};
		["mouse2click"] = {
			false;
			mouse2click or nil;
			{"mouse2click"};
		};
		["mouse2press"] = {
			false;
			mouse2press or nil;
			{"mouse2press"};
		};
		["mouse2release"] = {
			false;
			mouse2release or nil;
			{"mouse2release"};
		};
		["mousemoveabs"] = {
			false;
			mousemoveabs or nil;
			{"mousemoveabs"};
		};
		["mousemoverel"] = {
			false;
			mousemoverel or nil;
			{"mousemoverel"};
		};
		["mousescroll"] = {
			false;
			mousescroll or nil;
			{"mousescroll"};
		};
	}

	for MouseFunction, MouseInfo in pairs(mousefunctions) do
		self:runTest(MouseFunction, MouseInfo[3], function()
			assert(MouseInfo[2], "Unable to find mouse function, " .. MouseFunction)
			assert(getgenv()[MouseFunction] == MouseInfo[2], "input functions are not the same in, Global Env and Exploit Env")
			assert(type(MouseInfo[2]) == "function", "input method should be a function")
			assert(type(getgenv()[MouseFunction]) == "function", "mouse method should be a function")
			assert(type(getgenv()[MouseFunction]) == type(getgenv()[MouseFunction]), "Did not return the correct type")
		end)
	end


	self:runTest("islclosure", {}, function()
		assert(type(islclosure) == 'function', "Not a valid function")
		assert(islclosure(function() end) == true, 'Failed to return LClosure')
	end)
	
	self:runTest("isfunctionhooked", {}, function()
		local function HookMe()
			return false
		end
		hookfunction(HookMe, function()
			return true
		end)
		assert(isfunctionhooked(HookMe), "Unexpected return value")
	end)
	
	self:runTest("restorefunction", {"restoreproto"}, function()
		local function RestoreMe()
			return false
		end
		hookfunction(RestoreMe, function()
			return true
		end)
		restorefunction(RestoreMe)
		assert(RestoreMe() == false, "Unexpected return value")
	end)

	self:runTest("WebSocket", {})
	self:runTest("WebSocket.connect", {}, function()
		local types = {
			Send = "function",
			Close = "function",
			OnMessage = {"table", "userdata"},
			OnClose = {"table", "userdata"},
		}
		local ws = WebSocket.connect("ws://echo.websocket.events")
		assert(type(ws) == "table" or type(ws) == "userdata", "Did not return a table or userdata")
		for k, v in pairs(types) do
			if type(v) == "table" then
				assert(table.find(v, type(ws[k])), "Did not return a " .. table.concat(v, ", ") .. " for " .. k .. " (a " .. type(ws[k]) .. ")")
			else
				assert(type(ws[k]) == v, "Did not return a " .. v .. " for " .. k .. " (a " .. type(ws[k]) .. ")")
			end
		end
		ws:Close()
	end)
	
	self:runTest("firesignal", {}, function()
		local Remote = Instance.new("BindableEvent")
		local Fired = false
		Remote.Event:Connect(function()
			Fired = true
		end)
		local err = select(2, pcall(firesignal, Remote.Event))

		assert(type(err) ~= "string", "Error firing signal, invalid")
		assert(err == nil, "Error firing signal, not nil")
		assert(Fired == true, "Could not fire Signal")
		task.defer(Remote.Destroy, Remote)
	end)
	self:runTest("cansignalreplicate", {})

	self:runTest("loadstring", {}, function()
		local luacode = [=[getgenv().success = true]=]
		local moonsec = (game.HttpGet or game.HttpGetAsync)(game, "https://pastebin.com/raw/RvRLNVJc")
		local luaobfus = (game.HttpGet or game.HttpGetAsync)(game, "https://pastebin.com/raw/Yp0q4nb9")
		
		assert(loadstring("return ... + 1")(1) == 2, "Unable to do simple mathematics")
		assert(type(select(2, loadstring("hi"))), "Loadstring did not return an error when running code 'hi'")
		
		local function TestCode(Code, Name)
			getgenv().success = false
			local code_success = select(1, pcall(function()
				local compile_success, loaded = pcall(function()
					return loadstring(Code)
				end)
				
				assert(compile_success, "Unable to create a function from loadstring")
				assert(type(loaded) == "function", "Loadstring return must be callable")
				loaded()
			end))

			assert(code_success, `Failed to run {Name} obfuscated script`)
			assert(getgenv().success, `{Name} script did not execute`)
		end
		
		local success, err = pcall(function()
			TestCode(luacode, "LuaU")
			TestCode(moonsec, "MoonSec")
			TestCode(luaobfus, "LuaObfuscator")
		end)
		
		assert(success, ((err and type(err) == 'string') and err) or "Unable to execute code blocks")
	end)
end

local testSuite = TestSuite.new()

print("\nUNC Environment Check")
print("✅ - Pass, ⛔ - Fail, ⏺️ - No test, ⚠️ - Missing aliases\n")
print("ℹ️ Grabbing executor name...")
local execname = nil
pcall(function()
	execname = identifyexecutor()
end)

if execname == nil then
	print("⛔ IdentifyExecutor did not return executor name.")
end
local currenttime = os.date("%Y-%m-%d %H:%M:%S")
readable = os.clock()
print("ℹ️ Running ENC test for " .. execname .. " at " .. currenttime .. "\n")
print("ℹ️ This should only take a few seconds.")


testSuite:defineTests() 
