-- lust - Lua test framework
-- https://github.com/bjornswenson/lust
-- License - MIT, see LICENSE for details.

local lust = {}
lust.level = 0

local function table_has(t, x)
  for k, v in pairs(t) do
    if v == x then return true end
  end
  return false
end

local function strict_eq(t1, t2)
  if type(t1) ~= type(t2) then return false end
  if type(t1) ~= 'table' then return t1 == t2 end
  if #t1 ~= #t2 then return false end
  for k, _ in pairs(t1) do
    if not strict_eq(t1[k], t2[k]) then return false end
  end
  for k, _ in pairs(t2) do
    if not strict_eq(t2[k], t1[k]) then return false end
  end
  return true
end

function lust.describe(name, fn)
  print(string.rep('\t', lust.level) .. name)
  lust.level = lust.level + 1
  fn()
  lust.level = lust.level - 1
end

function lust.test(name, fn)
  print(string.rep('\t', lust.level) .. name)
  lust.level = lust.level + 1
  if type(lust.before) == 'function' then lust.before() end
  local success, err = pcall(fn)
  if not success then
    print(string.rep('\t', lust.level) .. 'FAIL: ' .. err)
    --error(name .. ' (' .. err .. ')', 0)
  else
    print(string.rep('\t', lust.level) .. 'PASS')
  end
  lust.level = lust.level - 1
  if type(lust.after) == 'function' then lust.after() end
end

-- Assertions
local function isa(v, x)
  if type(x) == 'string' then return type(v) == x, tostring(v) .. ' is not a ' .. x end
  return false, 'invalid type ' .. tostring(x)
end

local paths = {
  [''] = {'to'},
  to = {'have', 'equal', 'be', 'exist'},
  be = {'a', 'an', 'truthy', 'falsy', f = function(v, x)
    return strict_eq(v, x), tostring(v) .. ' and ' .. tostring(x) .. ' are not strictly equal!'
  end},
  a = {f = isa},
  an = {f = isa},
  exist = {f = function(v) return v == nil, tostring(v) .. ' is nil!' end},
  truthy = {f = function(v) return v, tostring(v) .. ' is not truthy!' end},
  falsy = {f = function(v) return not v, tostring(v) .. ' is not falsy!' end},
  equal = {f = function(v, x) return v == x, tostring(v) .. ' and ' .. tostring(x) .. ' are not equal!' end},
  have = {f = function(v, x) return v[x], 'table does not have key ' .. tostring(x)  end}
}

function lust.expect(v)
  local assertion = {}
  assertion.val = v
  assertion.action = ''
  
  setmetatable(assertion, {
    __index = function(t, k)
      if table_has(paths[rawget(t, 'action')], k) then
        rawset(t, 'action', k)
        return t
      end
      return rawget(t, k)
    end,
    __call = function(t, ...)
      if paths[t.action].f then
        local res, err = paths[t.action].f(t.val, ...)
        if not res then
          error(err or 'unknown failure!', 2)
        end
      end
    end
  })
  
  return assertion
end

return lust
