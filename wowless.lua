local handler = require('xmlhandler.dom')
local path = require('path')
local xml2lua = require('xml2lua')

local function loadFile(filename)
  local f = assert(io.open(filename:gsub('\\', '/'), 'rb'))
  local content = f:read('*all')
  f:close()
  if content:sub(1, 3) == '\239\187\191' then
    content = content:sub(4)
  end
  return content
end

local function loadXml(dir, xml)
  local h = handler:new()
  xml2lua.parser(h):parse(xml)
  assert(h.root._name == 'Ui')
  local luas = {}
  for _, v in ipairs(h.root._children) do
    if v._name == 'Script' then
      if v._attr and v._attr.file then
        assert(#v._children == 0)
        table.insert(luas, assert(loadstring(loadFile(path.join(dir, v._attr.file)))))
      elseif v._children then
        for _, x in ipairs(v._children) do
          if x._type == 'TEXT' then
            table.insert(luas, assert(loadstring(x._text)))
          end
        end
      else
        error('invalid script tag')
      end
    end
  end
  return luas
end

local function loadToc(toc)
  local dir = path.dirname(toc)
  local result = {}
  for line in io.lines(toc) do
    line = line:match('^%s*(.-)%s*$')
    if line ~= '' and line:sub(1, 1) ~= '#' then
      local filename = path.join(dir, line)
      local content = loadFile(filename)
      if line:sub(-4) == '.lua' then
        table.insert(result, {
          filename = line,
          lua = assert(loadstring(content)),
        })
      elseif line:sub(-4) == '.xml' then
        for _, lua in ipairs(loadXml(path.dirname(filename), content)) do
          table.insert(result, {
            filename = line,
            lua = lua,
          })
        end
      else
        error('unknown file type ' .. line)
      end
    end
  end
  return result
end

local bitlib = require('bit')

local UNIMPLEMENTED = function() end

local globalStrings = {
  -- luacheck: no max line length
  CONFIRM_CONTINUE = 'Do you wish to continue?',
  GUILD_REPUTATION_WARNING_GENERIC = 'You will lose one rank of guild reputation with your previous guild.',
  REMOVE_GUILDMEMBER_LABEL = 'Are you sure you want to remove %s from the guild?',
  VOID_STORAGE_DEPOSIT_CONFIRMATION = 'Depositing this item will remove all modifications and make it non-refundable and non-tradeable.',
}

local env = setmetatable({
  CreateFrame = function()
    return {
      Hide = UNIMPLEMENTED,
      RegisterEvent = UNIMPLEMENTED,
      SetForbidden = UNIMPLEMENTED,
      SetScript = UNIMPLEMENTED,
    }
  end,
  bit = {
    bor = bitlib.bor,
  },
  C_Club = {},
  C_GamePad = {},
  C_ScriptedAnimations = {
    GetAllScriptedAnimationEffects = function()
      return {}  -- UNIMPLEMENTED
    end,
  },
  C_Timer = {
    After = UNIMPLEMENTED,
  },
  C_VoiceChat = {},
  C_Widget = {},
  Enum = setmetatable({}, {
    __index = function(_, k)
      return setmetatable({}, {
        __index = function(_, k2)
          return 'AUTOGENERATED:Enum:' .. k .. ':' .. k2
        end,
      })
    end,
  }),
  FillLocalizedClassList = UNIMPLEMENTED,
  format = string.format,
  getfenv = getfenv,
  getmetatable = getmetatable,
  GetInventorySlotInfo = function()
    return 'UNIMPLEMENTED'
  end,
  GetItemQualityColor = function()
    return 0, 0, 0  -- UNIMPLEMENTED
  end,
  ipairs = ipairs,
  IsGMClient = UNIMPLEMENTED,
  IsOnGlueScreen = UNIMPLEMENTED,
  issecure = UNIMPLEMENTED,
  math = {},
  newproxy = function()
    return setmetatable({}, {})
  end,
  NUM_LE_ITEM_QUALITYS = 10,  -- UNIMPLEMENTED
  pairs = pairs,
  rawget = rawget,
  RegisterStaticConstants = UNIMPLEMENTED,
  select = select,
  seterrorhandler = UNIMPLEMENTED,
  setmetatable = setmetatable,
  string = {
    upper = string.upper,
  },
  table = {
    insert = table.insert,
  },
  tostring = tostring,
  type = type,
  UnitRace = function()
    return 'Human', 'Human', 1  -- UNIMPLEMENTED
  end,
  UnitSex = function()
    return 2  -- UNIMPLEMENTED
  end,
}, {
  __index = function(t, k)
    if k == '_G' then
      return t
    elseif string.sub(k, 1, 3) == 'LE_' then
      return 'AUTOGENERATED:' .. k
    else
      return globalStrings[k]
    end
  end
})

for _, code in ipairs(loadToc('wowui/classic/FrameXML/FrameXML.toc')) do
  local success, err = pcall(setfenv(code.lua, env))
  if not success then
    error('failure loading ' .. code.filename .. ': ' .. err)
  end
end
for k, v in pairs(env) do
  print(k .. ' = ' .. tostring(v))
end
