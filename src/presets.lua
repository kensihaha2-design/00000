-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- pipeline.lua
--
-- This Script Provides some configuration presets

return {
    ["Minify"] = {
        LuaVersion = "Lua51";
        VarNamePrefix = "";
        NameGenerator = "MangledShuffled";
        PrettyPrint = false;
        Seed = 0;
        Steps = {}
    },
    ["Weak"] = {
        LuaVersion = "Lua51";
        VarNamePrefix = "";
        NameGenerator = "MangledShuffled";
        PrettyPrint = false;
        Seed = 0;
        Steps = {
            { Name = "Vmify", Settings = {} },
            { Name = "ConstantArray", Settings = { Treshold = 1, StringsOnly = true } },
            { Name = "WrapInFunction", Settings = {} },
        }
    },
    ["Vmify"] = {
        LuaVersion = "Lua51";
        VarNamePrefix = "";
        NameGenerator = "MangledShuffled";
        PrettyPrint = false;
        Seed = 0;
        Steps = {
            { Name = "Vmify", Settings = {} },
        }
    },
    ["Medium"] = {
        LuaVersion = "Lua51";
        VarNamePrefix = "";
        NameGenerator = "MangledShuffled";
        PrettyPrint = false;
        Seed = 0;
        Steps = {
            { Name = "AntiDump", Settings = { ExplosionSize = 10000 } },
            { Name = "EncryptStrings", Settings = {} },
            { Name = "AntiTamper", Settings = { UseDebug = false } },
            { Name = "Vmify", Settings = {} },
            { Name = "ConstantArray", Settings = { Treshold = 0.5, StringsOnly = true, Shuffle = true } },
            { Name = "NumbersToExpressions", Settings = {} },
            { Name = "WrapInFunction", Settings = {} },
        }
    },
}
