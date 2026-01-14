-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- AntiTamper.lua
--
-- This Script provides an Obfuscation Step, that breaks the script, when someone tries to tamper with it.

local Step = require("prometheus.step");
local Ast = require("prometheus.ast");
local Scope = require("prometheus.scope");
local RandomStrings = require("prometheus.randomStrings")
local Parser = require("prometheus.parser");
local Enums = require("prometheus.enums");
local logger = require("logger");

local AntiTamper = Step:extend();
AntiTamper.Description = "This Step Breaks your Script when it is modified. This is only effective when using the new VM.";
AntiTamper.Name = "Anti Tamper";

AntiTamper.SettingsDescriptor = {
    UseDebug = {
        type = "boolean",
        default = true,
        description = "Use debug library. (Recommended, however scripts will not work without debug library.)"
    }
}

function AntiTamper:init(settings)
        
end

function AntiTamper:apply(ast, pipeline)
    if pipeline.PrettyPrint then
        logger:warn(string.format("\"%s\" cannot be used with PrettyPrint, ignoring \"%s\"", self.Name, self.Name));
        return ast;
    end
        local code = "do local valid = true;";
    
    -- Cache natives at the start of the script execution (inside the 'do' block)
    code = code .. [[
        local _setmetatable = setmetatable;
        local _getmetatable = getmetatable;
        local _pcall = pcall;
        local _error = error;
        local _type = type;
        local _tostring = tostring;
        local _debug = debug;
        local _getfenv = getfenv;
        local _setfenv = setfenv;
        local _G = _G;
        local _math_huge = math.huge;

        local function err()
            while true do _error("Tamper Detected!") end
        end

        -- A. Anti setmetatable hook & Anti Function Hook
        local function check_native(f)
            if not _debug then return true end
            local info_success, info = _pcall(_debug.getinfo, f)
            if not info_success or not info or info.what ~= "C" then return false end
            
            -- E. Hook Detection (Enhanced)
        if _debug and _debug.getinfo(setmetatable).what ~= "C" then err() end
        if _debug and _debug.getinfo(getmetatable).what ~= "C" then err() end
        if _debug and _debug.getinfo(pcall).what ~= "C" then err() end
        if _debug and _debug.getinfo(type).what ~= "C" then err() end
        if _debug and _debug.getinfo(error).what ~= "C" then err() end
        if _debug and _debug.getinfo(debug.getinfo).what ~= "C" then err() end

        -- Anti Hookfunction / detour bypass
        local function secure_call(f, ...)
            if _debug and _debug.getinfo(f).what ~= "C" then err() end
            return f(...)
        end

        -- Anti-Hook Execution Barrier
        -- Redefine sensitive functions locally to prevent global hooks from working AFTER initialization
        local setmetatable = _setmetatable
        local getmetatable = _getmetatable
        local pcall = _pcall
        local type = _type
        local error = _error

            -- SAFE getupvalue loop for LuaU compatibility
            local has_upvalue = false
            for i = 1, 10 do 
                local success, name, val = _pcall(_debug.getupvalue, f, i)
                if not success then break end 
                if name then
                    has_upvalue = true
                    break
                end
            end
            
            if has_upvalue then return false end
            return true
        end

        if not check_native(_setmetatable) or not check_native(_pcall) or not check_native(_error) then
            valid = false
        end
    ]]

    if self.UseDebug then
        local string = RandomStrings.randomString();
        code = code .. [[
            -- Anti Beautify
                        local sethook = _debug and _debug.sethook or function() end;
                        local allowedLine = nil;
                        local called = 0;
                        sethook(function(s, line)
                                if not line then
                                        return
                                end
                                called = called + 1;
                                if allowedLine then
                                        if allowedLine ~= line then
                                                sethook(_error, "l", 5);
                                        end
                                else
                                        allowedLine = line;
                                end
                        end, "l", 5);
                        (function() end)();
                        (function() end)();
                        sethook();
                        if called < 2 then
                                valid = false;
                        end

            -- Anti Function Hook (Extended)
            local funcs = {_pcall, string.char, _debug.getinfo, string.dump, _setmetatable, _getmetatable}
            for i = 1, #funcs do
                if not check_native(funcs[i]) then
                    valid = false;
                end

                if _pcall(string.dump, funcs[i]) then
                    valid = false;
                end
            end

            -- Anti Beautify Traceback
            local function getTraceback()
                local str = (function(arg)
                    return _debug.traceback(arg)
                end)("]] .. string .. [[");
                return str;
            end
    
            local traceback = getTraceback();
            valid = valid and traceback:sub(1, traceback:find("\n") - 1) == "]] .. string .. [[";
            local iter = traceback:gmatch(":(%d*):");
            local v, c = iter(), 1;
            for i in iter do
                valid = valid and i == v;
                c = c + 1;
            end
            valid = valid and c >= 2;
        ]]
    end

    code = code .. [[
    local gmatch = string.gmatch;

    -- B. Anti __index hijack & D. Metatable lock
    local mt_check = _setmetatable({}, {
        __index = function() return "protected" end,
        __metatable = "locked"
    })
    if _getmetatable(mt_check) ~= "locked" then valid = false end
    
    -- E. Honeytoken anti dumper
    local honey = _setmetatable({}, {
        __index = function(t, k)
            if k == "__DUMP__" or k == "__THREAD__" or k == "__UNVEIL__" or k == "dump" then
                err()
            end
        end,
        __metatable = "locked"
    })

    -- F. Anti env logger
    if _getfenv and _setfenv then
        if not check_native(_getfenv) or not check_native(_setfenv) then
            valid = false
        end
    end

    local pcallIntact2 = false;
    local pcallIntact = _pcall(function()
        pcallIntact2 = true;
    end) and pcallIntact2;

    local random = math.random;
    local tblconcat = table.concat;
    local unpkg = table and table.unpack or unpack;
    local n = random(3, 65);
    local acc1 = 0;
    local acc2 = 0;
    local pcallRet = {_pcall(function() local a = ]] .. tostring(math.random(1, 2^24)) .. [[ - "]] .. RandomStrings.randomString() .. [[" ^ ]] .. tostring(math.random(1, 2^24)) .. [[ return "]] .. RandomStrings.randomString() .. [[" / a; end)};
    local origMsg = pcallRet[2];
    local line = tonumber(gmatch(_tostring(origMsg), ':(%d*):')());
    for i = 1, n do
        local len = math.random(1, 100);
        local n2 = random(0, 255);
        local pos = random(1, len);
        local shouldErr = random(1, 2) == 1;
        local msg = origMsg:gsub(':(%d*):', ':' .. _tostring(random(0, 10000)) .. ':');
        local arr = {_pcall(function()
            if random(1, 2) == 1 or i == n then
                local line2 = tonumber(gmatch(_tostring(({_pcall(function() local a = ]] .. tostring(math.random(1, 2^24)) .. [[ - "]] .. RandomStrings.randomString() .. [[" ^ ]] .. tostring(math.random(1, 2^24)) .. [[ return "]] .. RandomStrings.randomString() .. [[" / a; end)})[2]), ':(%d*):')());
                valid = valid and line == line2;
            end
            if shouldErr then
                _error(msg, 0);
            end
            local arr = {};
            for i = 1, len do
                arr[i] = random(0, 255);
            end
            arr[pos] = n2;
            return unpkg(arr);
        end)};
        if shouldErr then
            valid = valid and arr[1] == false and arr[2] == msg;
        else
            valid = valid and arr[1];
            acc1 = (acc1 + arr[pos + 1]) % 256;
            acc2 = (acc2 + n2) % 256;
        end
    end
    valid = valid and acc1 == acc2;

    if valid then else
        repeat 
            return (function()
                while true do
                    err();
                end
            end)(); 
        until true;
    end
    
    -- Anti Function Arg Hook
    local obj = _setmetatable({}, {
        __tostring = err,
    });
    obj[math.random(1, 100)] = obj;
    (function() end)(obj);

    repeat until valid;
end
]]

    local parsed = Parser:new({LuaVersion = Enums.LuaVersion.Lua51}):parse(code);
    local doStat = parsed.body.statements[1];
    doStat.body.scope:setParent(ast.body.scope);
    table.insert(ast.body.statements, 1, doStat);

    return ast;
end

return AntiTamper;
