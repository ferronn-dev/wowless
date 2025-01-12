local args = (function()
  local parser = require('argparse')()
  parser:option('-p --products', 'products to process'):count('*')
  parser:option('-t --types', 'types to write'):count('*')
  parser:option('-f --filter', 'api filter')
  return parser:parse()
end)()
if not next(args.types) then
  args.types = { 'apis', 'constants', 'enums', 'events', 'structures' }
end
local enabledTypes = {}
for _, ty in ipairs(args.types) do
  enabledTypes[ty] = true
end
local lfs = require('lfs')
local writeFile = require('pl.file').write
local pprintYaml = require('wowapi.yaml').pprint
local products = next(args.products) and args.products
  or { -- priority order
    'wow_beta',
    'wowt',
    'wow',
    'wow_classic_beta',
    'wow_classic_ptr',
    'wow_classic',
    'wow_classic_era_ptr',
    'wow_classic_era',
  }
local docs = {}
local enum = {}
local function processDocDir(docdir)
  if lfs.attributes(docdir) then
    for f in lfs.dir(docdir) do
      if f:sub(-4) == '.lua' then
        pcall(setfenv(loadfile(docdir .. '/' .. f), {
          APIDocumentation = {
            AddDocumentationTable = function(_, t)
              docs[f] = docs[f] or t
            end,
          },
        }))
      end
    end
  end
end
for _, product in ipairs(products) do
  local prefix = 'extracts/' .. product .. '/Interface/AddOns/'
  processDocDir(prefix .. 'Blizzard_APIDocumentation')
  processDocDir(prefix .. 'Blizzard_APIDocumentationGenerated')
  local globals = require('wowapi.yaml').parseFile('data/products/' .. product .. '/globals.yaml')
  for en, em in pairs(globals.Enum) do
    enum[en] = enum[en] or em
  end
end
local expectedTopLevelFields = {
  Events = true,
  Functions = true,
  Name = true,
  Namespace = true,
  Tables = true,
  Type = true,
}
local expectedTypes = {
  ScriptObject = true,
  System = true,
}
local tabs, funcs, events = {}, {}, {}
for f, t in pairs(docs) do
  for k in pairs(t) do
    assert(expectedTopLevelFields[k], ('unexpected field %q in %q'):format(k, f))
  end
  assert(not t.Type or expectedTypes[t.Type], 'unexpected type in ' .. f)
  if not t.Type or t.Type == 'System' and t.Namespace ~= 'C_ConfigurationWarnings' then
    for _, tab in ipairs(t.Tables or {}) do
      local name = (t.Namespace and (t.Namespace .. '.') or '') .. tab.Name
      tabs[name] = tabs[name] or tab
    end
    for _, func in ipairs(t.Functions or {}) do
      local name = (t.Namespace and (t.Namespace .. '.') or '') .. func.Name
      funcs[name] = funcs[name] or func
    end
    for _, event in ipairs(t.Events or {}) do
      local name = (t.Namespace and (t.Namespace .. '.') or '') .. event.Name
      events[name] = events[name] or event
    end
  end
end
local types = {
  bool = 'boolean',
  number = 'number',
  string = 'string',
  table = 'table',
}
local tys = {}
for name in pairs(tabs) do
  tys[name] = true
end
for k, v in pairs(require('wowapi.data').structures) do
  if v.status == 'implemented' then
    tys[k] = true
  end
end
local expectedArgumentKeys = {
  Default = true,
  Documentation = true,
  InnerType = true,
  Mixin = true,
  Name = true,
  Nilable = true,
  Type = true,
}
local knownMixinStructs = {
  ColorMixin = 'Color',
  Vector2DMixin = 'Vector2D',
}
local function t2ty(t, ns, mixin)
  if enum[t] then
    return 'number'
  elseif t == 'table' then
    return mixin and knownMixinStructs[mixin] or t
  elseif types[t] then
    return types[t]
  elseif ns and tys[ns .. '.' .. t] then
    local n = ns .. '.' .. t
    local b = tabs[n]
    if b then
      if b.Type == 'Structure' then
        return n
      elseif b.Type == 'CallbackType' then
        return 'function'
      elseif b.Type == 'Enumeration' then
        return 'number'
      end
    end
    error('confused by ' .. n)
  elseif tys[t] then
    return t
  else
    print('unknown type ' .. t)
    return 'unknown'
  end
end
local function insig(fn, ns)
  local t = {}
  for _, a in ipairs(fn.Arguments or {}) do
    for k in pairs(a) do
      assert(expectedArgumentKeys[k], ('invalid argument key %q in %q'):format(k, fn.Name))
    end
    table.insert(t, {
      default = a.Default,
      innerType = a.InnerType and t2ty(a.InnerType, ns),
      mixin = a.Mixin,
      name = a.Name,
      nilable = a.Nilable or nil,
      type = t2ty(a.Type, ns, a.Mixin),
    })
  end
  return t
end
local expectedReturnKeys = {
  Default = true,
  Documentation = true,
  InnerType = true,
  Mixin = true,
  Name = true,
  Nilable = true,
  StrideIndex = true,
  Type = true,
}
local function outsig(fn, ns)
  local outputs = {}
  for _, r in ipairs(fn.Returns or {}) do
    for k in pairs(r) do
      assert(expectedReturnKeys[k], ('unexpected key %q'):format(k))
    end
    table.insert(outputs, {
      default = enum[r.Type] and enum[r.Type][r.Default] or r.Default,
      innerType = r.InnerType and t2ty(r.InnerType, ns),
      mixin = r.Mixin,
      name = r.Name,
      nilable = r.Nilable or nil,
      type = t2ty(r.Type, ns, r.Mixin),
    })
  end
  return outputs
end
if enabledTypes.apis then
  for name, fn in pairs(funcs) do
    if name:sub(1, #args.filter) == args.filter then
      local dotpos = name:find('%.')
      local ns = dotpos and name:sub(1, dotpos - 1)
      local tt = {
        name = name,
        status = 'autogenerated',
        inputs = { insig(fn, ns) },
        outputs = outsig(fn, ns),
      }
      writeFile('data/api/' .. name .. '.yaml', pprintYaml(tt))
    end
  end
end
local expectedStructureKeys = {
  Name = true,
  Type = true,
  Fields = true,
  Documentation = true,
}
local expectedStructureFieldKeys = {
  Name = true,
  Nilable = true,
  Type = true,
  InnerType = true,
  Mixin = true,
  Documentation = true,
  Default = true,
}
local existingStructures = require('wowapi.data').structures
local structures = {}
for name, tab in pairs(tabs) do
  local existing = existingStructures[name]
  if tab.Type == 'Structure' and (not existing or existing.status == 'autogenerated') then
    for k in pairs(tab) do
      assert(expectedStructureKeys[k], ('unexpected structure key %q in %q'):format(k, name))
    end
    local dotpos = name:find('%.')
    local ns = dotpos and name:sub(1, dotpos - 1)
    structures[name] = structures[name]
      or {
        name = name,
        status = 'autogenerated',
        fields = (function()
          local ret = {}
          for _, field in ipairs(tab.Fields) do
            for k in pairs(field) do
              assert(expectedStructureFieldKeys[k], ('unexpected field key %q in %q'):format(k, name))
            end
            table.insert(ret, {
              name = field.Name,
              nilable = field.Nilable or nil,
              type = t2ty(field.Type, ns, field.Mixin),
              innerType = field.InnerType and t2ty(field.InnerType, ns),
              mixin = field.Mixin,
              default = field.Default,
            })
          end
          table.sort(ret, function(a, b)
            return a.name < b.name
          end)
          return ret
        end)(),
      }
  end
end
if enabledTypes.structures then
  for k, v in pairs(structures) do
    writeFile('data/structures/' .. k .. '.yaml', pprintYaml(v))
  end
end
local expectedEventKeys = {
  Documentation = true,
  Name = true,
  LiteralName = true,
  Payload = true,
  Type = true,
}
local expectedEventPayloadKeys = {
  Default = true,
  Documentation = true,
  InnerType = true,
  Mixin = true,
  Name = true,
  Nilable = true,
  StrideIndex = true,
  Type = true,
}
if enabledTypes.events then
  assert(#products == 1)
  local filename = ('data/products/%s/events.yaml'):format(products[1])
  local out = require('wowapi.yaml').parseFile(filename)
  for name, ev in pairs(events) do
    for k in pairs(ev) do
      assert(expectedEventKeys[k], ('unexpected event key %q in %q'):format(k, name))
    end
    assert(ev.Type == 'Event')
    assert(ev.LiteralName ~= nil)
    local dotpos = name:find('%.')
    local ns = dotpos and name:sub(1, dotpos - 1)
    local value = {
      payload = (function()
        local t = {}
        for _, arg in ipairs(ev.Payload or {}) do
          for k in pairs(arg) do
            assert(expectedEventPayloadKeys[k], ('unexpected field key %q in %q'):format(k, name))
          end
          table.insert(t, {
            innerType = arg.InnerType and t2ty(arg.InnerType, ns),
            mixin = arg.Mixin,
            name = arg.Name,
            nilable = arg.Nilable or nil,
            type = t2ty(arg.Type, ns, arg.Mixin),
          })
        end
        return t
      end)(),
    }
    local k = ev.LiteralName
    if out[k] and out[k].docsarewrong then
      assert(not require('pl.tablex').deepcompare(out[k].payload, value.payload))
    else
      out[k] = value
    end
  end
  writeFile(filename, pprintYaml(out))
end

if enabledTypes.enums then
  local t = {}
  for _, v in pairs(tabs) do
    if v.Type == 'Enumeration' then
      local vt = {}
      assert(type(v.MinValue) == 'number')
      assert(type(v.MaxValue) == 'number')
      assert(type(v.NumValues) == 'number')
      assert(type(v.Fields) == 'table')
      for _, fv in ipairs(v.Fields) do
        assert(type(fv.Name) == 'string', 'missing name for field of ' .. v.Name)
        assert(fv.Type == v.Name, 'wrong type for ' .. v.Name .. '.' .. fv.Name)
        assert(type(fv.EnumValue) == 'number')
        vt[fv.Name] = fv.EnumValue
      end
      t[v.Name] = vt
      t[v.Name .. 'Meta'] = {
        MaxValue = v.MaxValue,
        MinValue = v.MinValue,
        NumValues = v.NumValues,
      }
    end
  end
  for _, p in ipairs(products) do
    local y = require('wowapi.yaml')
    local f = 'data/products/' .. p .. '/globals.yaml'
    local g = y.parseFile(f)
    for k, v in pairs(t) do
      g.Enum[k] = v
    end
    require('pl.file').write(f, y.pprint(g))
  end
end

if enabledTypes.constants then
  local t = {}
  for _, v in pairs(tabs) do
    if v.Type == 'Constants' then
      local vt = {}
      assert(type(v.Values) == 'table')
      for _, fv in ipairs(v.Values) do
        assert(type(fv.Name) == 'string', 'missing name for field of ' .. v.Name)
        -- TODO fv.Type validation
        -- TODO support non-number-literal constants
        vt[fv.Name] = type(fv.Value) == 'number' and fv.Value or 0
      end
      t[v.Name] = vt
    end
  end
  for _, p in ipairs(products) do
    local y = require('wowapi.yaml')
    local f = 'data/products/' .. p .. '/globals.yaml'
    local g = y.parseFile(f)
    for k, v in pairs(t) do
      g.Constants[k] = v
    end
    require('pl.file').write(f, y.pprint(g))
  end
end
