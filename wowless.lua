local function loader(mkapi, sink)

  local handler = require('xmlhandler.dom')
  local path = require('path')
  local xml2lua = require('xml2lua')

  local function readFile(filename)
    local f = assert(io.open(filename:gsub('\\', '/'), 'rb'))
    local content = f:read('*all')
    f:close()
    if content:sub(1, 3) == '\239\187\191' then
      content = content:sub(4)
    end
    return content
  end

  local function loadLuaString(filename, str)
    sink(filename, assert(loadstring(str)))
  end

  local loadFile

  local function loadXml(filename)
    local api = mkapi(filename)
    local dir = path.dirname(filename)

    -- TODO enable xml
    local enableXml = arg[1] == 'xml'

    local function loadKids(e)
      for _, v in ipairs(e._children) do
        assert(v._type == 'ELEMENT')
        if v._name == 'Include' then
          assert(v._attr and v._attr.file and #v._children == 0)
          loadFile(path.join(dir, v._attr.file))
        elseif v._name == 'ScopedModifier' then
          -- TODO support ScopedModifier attributes
          loadKids(v)
        elseif api.IsUIObjectType(v._name) then
          api.CreateUIObject({
            inherits = v._attr.inherits,
            intrinsic = v._attr.intrinsic,
            name = v._attr.name,
            type = v._name,
            virtual = v._attr.virtual,
          })
        elseif enableXml and v._name == 'Script' then
          if v._attr and v._attr.file then
            assert(#v._children == 0)
            loadFile(path.join(dir, v._attr.file))
          elseif v._children then
            for _, x in ipairs(v._children) do
              assert(x._type == 'TEXT', 'invalid script child')
              loadLuaString(filename, x._text)
            end
          else
            error('invalid script tag')
          end
        else
          print('skipping ' .. filename .. ' ' .. v._name)
        end
      end
    end

    local h = handler:new()
    h.options.commentNode = false
    xml2lua.parser(h):parse(readFile(filename))
    assert(h.root._name == 'Ui')
    loadKids(h.root)
  end

  function loadFile(filename)
    if filename:sub(-4) == '.lua' then
      loadLuaString(filename, readFile(filename))
    elseif filename:sub(-4) == '.xml' then
      return loadXml(filename)
    else
      error('unknown file type ' .. filename)
    end
  end

  local function loadToc(toc)
    local dir = path.dirname(toc)
    for line in io.lines(toc) do
      line = line:match('^%s*(.-)%s*$')
      if line ~= '' and line:sub(1, 1) ~= '#' then
        loadFile(path.join(dir, line))
      end
    end
  end

  return loadToc
end

local env = (function()
  local bitlib = require('bit')
  return setmetatable({
    assert = assert,
    bit = {
      bor = bitlib.bor,
    },
    error = error,
    getfenv = getfenv,
    getmetatable = getmetatable,
    ipairs = ipairs,
    math = {},
    pairs = pairs,
    print = print,
    rawget = rawget,
    select = select,
    setmetatable = setmetatable,
    string = {
      format = string.format,
      gmatch = string.gmatch,
      gsub = string.gsub,
      lower = string.lower,
      match = string.match,
      sub = string.sub,
      upper = string.upper,
    },
    table = {
      insert = table.insert,
    },
    tostring = tostring,
    type = type,
  }, {
    __index = function(t, k)
      if k == '_G' then
        return t
      elseif string.sub(k, 1, 3) == 'LE_' then
        return 'AUTOGENERATED:' .. k
      end
    end
  })
end)()

do
  local function wrap(filename, fn, ...)
    local success, arg = pcall(fn, ...)
    assert(success, 'failure in ' .. filename .. ': ' .. tostring(arg))
    return arg
  end
  local api = setfenv(loadfile('env.lua'), env)()
  local mkapi = function(filename)
    return setmetatable({}, {
      __index = function(_, k)
        return setmetatable({}, {
          __call = function(_, ...)
            return wrap(filename, api[k], ...)
          end,
        })
      end,
    })
  end
  local sink = function(filename, lua)
    wrap(filename, setfenv(lua, env))
  end
  local toc = require('datafile').path('wowui/classic/FrameXML/FrameXML.toc')
  loader(mkapi, sink)(toc)
end

local size = 0
for _ in pairs(env) do
  size = size + 1
end
print('global environment has ' .. size .. ' symbols')
