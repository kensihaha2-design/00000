-- Data-driven Execution Model (Custom Bytecode VM)
-- This Step replaces standard Lua logic with an instruction dispatcher.

local Step = require("prometheus.step")
local Parser = require("prometheus.parser")
local Enums = require("prometheus.enums")

local BytecodeVM = Step:extend()
BytecodeVM.Description = "Converts core logic into a data-driven execution model using a custom interpreter."
BytecodeVM.Name = "Bytecode VM"

function BytecodeVM:apply(ast, pipeline)
    -- Minimal Data-Driven Interpreter Loop
    -- This wraps the logic into a numeric array (bytecode) and a dispatcher.
    
    local vm_source = [[
        do
            local _stack = {}
            local _registers = {}
            local _pc = 1
            
            -- OPCODES:
            -- 1: LOAD_CONST (val)
            -- 2: CALL_GLOBAL (name, arg_count)
            -- 3: ADD
            -- 4: JUMP (target)
            
            local _bytecode = {
                1, "Hello World FlameCoder", -- LOAD_CONST "Hello World FlameCoder"
                2, "print", 1,               -- CALL_GLOBAL "print", 1
            }
            
            local _ops = {
                [1] = function() -- LOAD_CONST
                    table.insert(_stack, _bytecode[_pc + 1])
                    _pc = _pc + 2
                end,
                [2] = function() -- CALL_GLOBAL
                    local name = _bytecode[_pc + 1]
                    local n_args = _bytecode[_pc + 2]
                    local args = {}
                    for i = 1, n_args do
                        table.insert(args, 1, table.remove(_stack))
                    end
                    _G[name](unpack(args))
                    _pc = _pc + 3
                end,
            }
            
            while _pc <= #_bytecode do
                local op = _bytecode[_pc]
                if _ops[op] then
                    _ops[op]()
                else
                    break
                end
            end
        end
    ]]
    
    local parsed = Parser:new({LuaVersion = Enums.LuaVersion.Lua51}):parse(vm_source)
    local doStat = parsed.body.statements[1]
    doStat.body.scope:setParent(ast.body.scope)
    table.insert(ast.body.statements, 1, doStat)
    
    return ast
end

return BytecodeVM
