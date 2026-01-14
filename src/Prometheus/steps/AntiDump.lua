-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- AntiDump.lua
--
-- This Script provides an Obfuscation Step, that pollutes the environment and causes instruction explosion during dumping.

local Step = require("prometheus.step");
local Parser = require("prometheus.parser");
local Enums = require("prometheus.enums");

local AntiDump = Step:extend();
AntiDump.Description = "Extreme runtime logic fragmentation and memory poisoning to break dumper reconstruction.";
AntiDump.Name = "Anti Dump";

AntiDump.SettingsDescriptor = {
    ExplosionSize = {
        type = "number",
        default = 100,
        description = "Size of the instruction explosion loop."
    }
}

function AntiDump:init(settings)
    settings = settings or {}
    self.ExplosionSize = settings.ExplosionSize or 100
end

function AntiDump:apply(ast, pipeline)
    -- Strategi: Ghost Logic & Memory Traps (Final)
    local code = [[
        do
            local _G = _G
            local _pcall = pcall
            local _debug = debug
            local _math = math
            local _type = type
            local _rawget = rawget
            local _string = string
            local _setfenv = setfenv or function() end
            
            local _poisoned = false

            -- Ghost Reconstructor: Logic tidak pernah utuh di memori
            local function _ghost_exec(data)
                if _poisoned then return end
                local logic = ""
                for _, b in ipairs(data) do
                    logic = logic .. _string.char(b)
                end
                local f = loadstring(logic)
                if f then 
                    _setfenv(f, getfenv(0))
                    f()
                end
                f = nil
            end

            -- Upvalue Poisoning Segitiga (Pemicu Crash)
            local _p = {}
            local function _trap()
                local a, b, c;
                a = function() return b, c, _p end
                b = function() return a, c, _p end
                c = function() return a, b, _p end
                return a
            end
            _p[1] = _trap()

            -- Runtime Dumper Monitoring
            local function _monitor()
                if _debug and _debug.getinfo then
                    local ok, info = _pcall(_debug.getinfo, _pcall)
                    if ok and info and info.what ~= "C" then _poisoned = true end
                    
                    -- Anti-Hook Detection for setmetatable, getmetatable, etc.
                    local sensitive = {setmetatable, getmetatable, pcall, error, type, getfenv, setfenv, loadstring, pairs, ipairs}
                    for _, f in ipairs(sensitive) do
                        local ok, sinfo = _pcall(_debug.getinfo, f)
                        if ok and sinfo and sinfo.what ~= "C" then _poisoned = true end
                    end
                end
                if getgenv then
                    local ok, env = _pcall(getgenv)
                    if ok and env and (env.hookfunction or env.getgc or env.hookmetamethod or env.replaceclosure or env.checkclosure) then _poisoned = true end
                end
                
                -- Check for common dumper global pollution
                if _G.UnveilR or _G.unveil or _G._DUMP or _G.dump_script then _poisoned = true end
            end

            -- Memory Poisoning: Luajit/LuaU specific garbage collection trap
            local function _mem_trap()
                if _poisoned then 
                    local junk = {}
                    for i = 1, 100000 do junk[i] = _trap() end
                    while true do end 
                end
            end

            _pcall(_monitor)
            _pcall(_mem_trap)
            -- Hello World FlameCoder in ByteStream
            _ghost_exec({112, 114, 105, 110, 116, 40, 34, 72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, 32, 70, 108, 97, 109, 101, 67, 111, 100, 101, 114, 34, 41})
        end
    ]]

    local parsed = Parser:new({LuaVersion = Enums.LuaVersion.Lua51}):parse(code);
    local doStat = parsed.body.statements[1];
    doStat.body.scope:setParent(ast.body.scope);
    table.insert(ast.body.statements, 1, doStat);

    return ast;
end

return AntiDump;
