local tsort = require('resty.tsort')
local util = require('wowless.util')
local Mixin = util.mixin

local UNIMPLEMENTED = function() end
local STUB_NUMBER = function() return 1 end
local STUB_TABLE = function() return {} end

local function toTexture(parent, tex)
  if type(tex) == 'string' then
    local t = parent:CreateTexture()
    t:SetTexture(tex)
    return t
  else
    return tex
  end
end

local function mkBaseUIObjectTypes(api)
  return {
    actor = {
      inherits = {'parentedobject', 'scriptobject'},
      intrinsic = true,
      name = 'Actor',
    },
    animationgroup = {
      inherits = {'parentedobject', 'scriptobject'},
      intrinsic = true,
      mixin = {
        IsPlaying = UNIMPLEMENTED,
        Play = UNIMPLEMENTED,
        Stop = UNIMPLEMENTED,
      },
      name = 'AnimationGroup',
    },
    button = {
      constructor = function(self)
        self.__fontstring = self:CreateFontString()
      end,
      inherits = {'frame'},
      intrinsic = true,
      mixin = {
        Disable = UNIMPLEMENTED,
        Enable = UNIMPLEMENTED,
        GetDisabledTexture = function(self)
          return self.__disabledTexture
        end,
        GetFontString = function(self)
          return self.__fontstring
        end,
        GetHighlightTexture = function(self)
          return self.__highlightTexture
        end,
        GetNormalTexture = function(self)
          return self.__normalTexture
        end,
        GetPushedTexture = function(self)
          return self.__pushedTexture
        end,
        GetText = UNIMPLEMENTED,
        GetTextWidth = STUB_NUMBER,
        IsEnabled = UNIMPLEMENTED,
        LockHighlight = UNIMPLEMENTED,
        RegisterForClicks = UNIMPLEMENTED,
        SetButtonState = UNIMPLEMENTED,
        SetDisabledFontObject = UNIMPLEMENTED,
        SetDisabledTexture = function(self, tex)
          self.__disabledTexture = toTexture(self, tex)
        end,
        SetEnabled = UNIMPLEMENTED,
        SetHighlightAtlas = UNIMPLEMENTED,
        SetHighlightFontObject = UNIMPLEMENTED,
        SetHighlightTexture = function(self, tex)
          self.__highlightTexture = toTexture(self, tex)
        end,
        SetNormalAtlas = UNIMPLEMENTED,
        SetNormalFontObject = UNIMPLEMENTED,
        SetNormalTexture = function(self, tex)
          self.__normalTexture = toTexture(self, tex)
        end,
        SetPushedAtlas = UNIMPLEMENTED,
        SetPushedTexture = function(self, tex)
          self.__pushedTexture = toTexture(self, tex)
        end,
        SetText = UNIMPLEMENTED,
        UnlockHighlight = UNIMPLEMENTED,
      },
      name = 'Button',
    },
    checkbutton = {
      inherits = {'button'},
      intrinsic = true,
      mixin = {
        GetCheckedTexture = function(self)
          return self.__checkedTexture
        end,
        GetDisabledCheckedTexture = function(self)
          return self.__disabledCheckedTexture
        end,
        SetChecked = UNIMPLEMENTED,
        SetCheckedTexture = function(self, tex)
          self.__checkedTexture = toTexture(self, tex)
        end,
        SetDisabledCheckedTexture = function(self, tex)
          self.__disabledCheckedTexture = toTexture(self, tex)
        end,
      },
      name = 'CheckButton',
    },
    cooldown = {
      inherits = {'frame'},
      intrinsic = true,
      mixin = {
        Clear = UNIMPLEMENTED,
        SetBlingTexture = function(self, tex)
          self.__blingTexture = toTexture(self, tex)
        end,
        SetEdgeTexture = function(self, tex)
          self.__edgeTexture = toTexture(self, tex)
        end,
        SetHideCountdownNumbers = UNIMPLEMENTED,
        SetSwipeColor = UNIMPLEMENTED,
        SetSwipeTexture = function(self, tex)
          self.__swipeTexture = toTexture(self, tex)
        end,
      },
      name = 'Cooldown',
    },
    dressupmodel = {
      inherits = {'playermodel'},
      intrinsic = true,
      name = 'DressUpModel',
    },
    editbox = {
      inherits = {'frame'},
      intrinsic = true,
      mixin = {
        GetNumber = STUB_NUMBER,
        SetNumber = UNIMPLEMENTED,
        SetSecureText = UNIMPLEMENTED,
      },
      name = 'EditBox',
    },
    font = {
      inherits = {'fontinstance'},
      intrinsic = true,
      name = 'Font',
    },
    fontinstance = {
      inherits = {'uiobject'},
      intrinsic = true,
      mixin = {
        GetFont = UNIMPLEMENTED,
        SetFontObject = UNIMPLEMENTED,
        SetIndentedWordWrap = UNIMPLEMENTED,
        SetJustifyH = UNIMPLEMENTED,
        SetSpacing = UNIMPLEMENTED,
        SetTextColor = UNIMPLEMENTED,
      },
      name = 'FontInstance',
    },
    fontstring = {
      inherits = {'fontinstance', 'layeredregion'},
      intrinsic = true,
      mixin = {
        GetText = UNIMPLEMENTED,
        IsTruncated = UNIMPLEMENTED,
        SetFormattedText = UNIMPLEMENTED,
        SetMaxLines = UNIMPLEMENTED,
        SetText = UNIMPLEMENTED,
      },
      name = 'FontString',
    },
    frame = {
      constructor = function(self, xmlattr)
        table.insert(api.frames, self)
        self.__attributes = self.__attributes or {}
        self.__registeredEvents = {}
        if xmlattr.id then
          self:SetID(xmlattr.id)
        end
      end,
      inherits = {'parentedobject', 'region', 'scriptobject'},
      intrinsic = true,
      mixin = {
        CreateFontString = function(self, name)
          return api:CreateUIObject('fontstring', name, self)
        end,
        CreateTexture = function(self, name)
          return api:CreateUIObject('texture', name, self)
        end,
        EnableMouse = UNIMPLEMENTED,
        GetAttribute = function(self, name)
          return self.__attributes[name]
        end,
        GetFrameLevel = STUB_NUMBER,
        GetID = function(self)
          return self.__id or 0
        end,
        IgnoreDepth = UNIMPLEMENTED,
        IsEventRegistered = UNIMPLEMENTED,
        IsUserPlaced = UNIMPLEMENTED,
        Raise = UNIMPLEMENTED,
        RegisterEvent = function(self, event)
          self.__registeredEvents[string.lower(event)] = true
        end,
        RegisterForDrag = UNIMPLEMENTED,
        RegisterUnitEvent = UNIMPLEMENTED,
        SetAttribute = function(self, name, value)
          api.log(4, 'setting attribute %s on %s to %s', name, tostring(self:GetName()), tostring(value))
          self.__attributes[name] = value
          self:__RunScript('OnAttributeChanged', name, value)
        end,
        SetClampRectInsets = UNIMPLEMENTED,
        SetFrameLevel = UNIMPLEMENTED,
        SetFrameStrata = UNIMPLEMENTED,
        SetHitRectInsets = UNIMPLEMENTED,
        SetID = function(self, id)
          self.__id = id
        end,
        SetMouseClickEnabled = UNIMPLEMENTED,
        SetUserPlaced = UNIMPLEMENTED,
        UnregisterEvent = function(self, event)
          self.__registeredEvents[string.lower(event)] = nil
        end,
      },
      name = 'Frame',
    },
    gametooltip = {
      inherits = {'frame'},
      intrinsic = true,
      mixin = {
        GetOwner = UNIMPLEMENTED,
        IsOwned = UNIMPLEMENTED,
        SetPadding = UNIMPLEMENTED,
      },
      name = 'GameTooltip',
    },
    layeredregion = {
      inherits = {'region'},
      intrinsic = true,
      mixin = {
        SetDrawLayer = UNIMPLEMENTED,
        SetVertexColor = UNIMPLEMENTED,
      },
      name = 'LayeredRegion',
    },
    messageframe = {
      inherits = {'frame'},
      intrinsic = true,
      name = 'MessageFrame',
    },
    minimap = {
      inherits = {'frame'},
      intrinsic = true,
      name = 'Minimap',
    },
    model = {
      inherits = {'frame'},
      intrinsic = true,
      mixin = {
        SetRotation = UNIMPLEMENTED,
      },
      name = 'Model',
    },
    modelscene = {
      inherits = {'frame'},
      intrinsic = true,
      mixin = {
        GetLightDirection = function()
          return 1, 1, 1  -- UNIMPLEMENTED
        end,
        GetLightPosition = function()
          return 1, 1, 1  -- UNIMPLEMENTED
        end,
        SetLightDirection = UNIMPLEMENTED,
        SetLightPosition = UNIMPLEMENTED,
      },
      name = 'ModelScene',
    },
    parentedobject = {
      inherits = {'uiobject'},
      intrinsic = true,
      mixin = {
        GetParent = function(self)
          return self.__parent
        end,
        SetForbidden = UNIMPLEMENTED,
      },
      name = 'ParentedObject',
    },
    playermodel = {
      inherits = {'model'},
      intrinsic = true,
      mixin = {
        RefreshCamera = UNIMPLEMENTED,
        RefreshUnit = UNIMPLEMENTED,
        SetPortraitZoom = UNIMPLEMENTED,
        SetUnit = UNIMPLEMENTED,
      },
      name = 'PlayerModel',
    },
    region = {
      inherits = {'parentedobject'},
      intrinsic = true,
      mixin = {
        ClearAllPoints = UNIMPLEMENTED,
        GetEffectiveScale = STUB_NUMBER,
        GetHeight = STUB_NUMBER,
        GetLeft = STUB_NUMBER,
        GetNumPoints = function()
          return 0  -- UNIMPLEMENTED
        end,
        GetPoint = UNIMPLEMENTED,
        GetRight = STUB_NUMBER,
        GetSize = function(self)
          return self:GetWidth(), self:GetHeight()
        end,
        GetTop = STUB_NUMBER,
        GetWidth = STUB_NUMBER,
        Hide = UNIMPLEMENTED,
        IsShown = UNIMPLEMENTED,
        IsVisible = UNIMPLEMENTED,
        SetAlpha = UNIMPLEMENTED,
        SetHeight = UNIMPLEMENTED,
        SetParent = UNIMPLEMENTED,
        SetPoint = UNIMPLEMENTED,
        SetScale = UNIMPLEMENTED,
        SetShown = UNIMPLEMENTED,
        SetSize = UNIMPLEMENTED,
        SetWidth = UNIMPLEMENTED,
        Show = UNIMPLEMENTED,
      },
      name = 'Region',
    },
    scriptobject = {
      constructor = function(self)
        self.__scripts = self.__scripts or {
          [0] = {},
          [1] = {},
          [2] = {},
        }
        self.__RunScript = function(_, name, ...)
          for i = 0, 2 do
            local script = self:GetScript(name, i)
            if script then
              api.log(4, 'begin %s[%d] for %s %s', name, i, self:GetObjectType(), tostring(self:GetName()))
              script(self, ...)
              api.log(4, 'end %s[%d] for %s %s', name, i, self:GetObjectType(), tostring(self:GetName()))
            end
          end
        end
        self.__SetScript = function(_, name, bindingType, script)
          api.log(4, 'setting %s[%d] for %s %s', name, bindingType, self:GetObjectType(), tostring(self:GetName()))
          self.__scripts[bindingType][string.lower(name)] = script
        end
      end,
      inherits = {},
      intrinsic = true,
      mixin = {
        GetScript = function(self, name, bindingType)
          return self.__scripts[bindingType or 1][string.lower(name)]
        end,
        SetScript = function(self, name, script)
          self:__SetScript(name, 1, script)
        end,
      },
      name = 'ScriptObject',
    },
    scrollframe = {
      inherits = {'frame'},
      intrinsic = true,
      mixin = {
        GetHorizontalScroll = STUB_NUMBER,
        GetVerticalScrollRange = STUB_NUMBER,
        GetScrollChild = function(self)
          return self.__scrollChild
        end,
        SetScrollChild = function(self, scrollChild)
          self.__scrollChild = scrollChild
        end,
        SetVerticalScroll = UNIMPLEMENTED,
        UpdateScrollChildRect = UNIMPLEMENTED,
      },
      name = 'ScrollFrame',
    },
    slider = {
      inherits = {'frame'},
      intrinsic = true,
      mixin = {
        Disable = UNIMPLEMENTED,
        Enable = UNIMPLEMENTED,
        GetMinMaxValues = UNIMPLEMENTED,
        GetThumbTexture = function(self)
          return self.__thumbTexture
        end,
        GetValue = STUB_NUMBER,
        SetMinMaxValues = UNIMPLEMENTED,
        SetStepsPerPage = UNIMPLEMENTED,
        SetThumbTexture = function(self, tex)
          self.__thumbTexture = toTexture(self, tex)
        end,
        SetValue = UNIMPLEMENTED,
        SetValueStep = UNIMPLEMENTED,
      },
      name = 'Slider',
    },
    statusbar = {
      inherits = {'frame'},
      intrinsic = true,
      mixin = {
        GetMinMaxValues = function()
          return 0, 0  -- UNIMPLEMENTED
        end,
        GetStatusBarTexture = function(self)
          return self.__statusBarTexture
        end,
        GetValue = function()
          return 0  -- UNIMPLEMENTED
        end,
        SetMinMaxValues = UNIMPLEMENTED,
        SetStatusBarColor = UNIMPLEMENTED,
        SetStatusBarTexture = function(self, tex)
          if type(tex) == 'number' then
            api.log(1, 'unimplemented call to SetStatusBarTexture')
            self.__statusBarTexture = self:CreateTexture()
          else
            self.__statusBarTexture = toTexture(self, tex)
          end
        end,
        SetValue = UNIMPLEMENTED,
      },
      name = 'StatusBar',
    },
    texture = {
      inherits = {'layeredregion', 'parentedobject'},
      intrinsic = true,
      mixin = {
        GetTexCoord = UNIMPLEMENTED,
        GetTexture = UNIMPLEMENTED,
        SetAtlas = UNIMPLEMENTED,
        SetDesaturated = UNIMPLEMENTED,
        SetGradient = UNIMPLEMENTED,
        SetHorizTile = UNIMPLEMENTED,
        SetTexCoord = UNIMPLEMENTED,
        SetTexture = UNIMPLEMENTED,
        SetVertTile = UNIMPLEMENTED,
      },
      name = 'Texture',
    },
    uiobject = {
      inherits = {},
      intrinsic = true,
      mixin = {
        GetName = function(self)
          return self.__name
        end,
        GetObjectType = function(self)
          return self.__type
        end,
        IsObjectType = UNIMPLEMENTED,
      },
      name = 'UIObject',
    },
    worldframe = {
      inherits = {'frame'},
      intrinsic = true,
      name = 'WorldFrame',
    },
  }
end

local function _InheritsFrom(api, a, b)
  local result = a == b
  for _, inh in ipairs(api.uiobjectTypes[a].inherits) do
    result = result or _InheritsFrom(api, inh, b)
  end
  return result
end

local function _IsIntrinsicType(api, t)
  local type = api.uiobjectTypes[string.lower(t)]
  return type and type.intrinsic
end

local function _IsUIObjectType(api, t)
  return api.uiobjectTypes[string.lower(t)] ~= nil
end

local function superTypes(api, type, inherits)
  local g = tsort.new()
  local function process(t)
    local ty = api.uiobjectTypes[t]
    assert(ty, t .. ' is not a uiobject type')
    for _, inh in ipairs(ty.inherits or {}) do
      g:add(inh, t)
      process(inh)
    end
  end
  process(type)
  for _, inh in ipairs(inherits or {}) do
    process(inh)
  end
  return g:sort()
end

local function _CreateUIObject(api, typename, objname, parent, inherits, xmlattr)
  assert(typename, 'must specify type for ' .. tostring(objname))
  local type = api.uiobjectTypes[typename]
  assert(type, 'unknown type ' .. typename .. ' for ' .. tostring(objname))
  api.log(3, 'creating %s%s', type.name, objname and (' named ' .. objname) or '')
  local supers = superTypes(api, typename, inherits)
  local wapi = {}
  for _, s in ipairs(supers) do
    Mixin(wapi, api.uiobjectTypes[s].mixin)
  end
  local obj = setmetatable({
    __name = objname,
    __parent = parent,
    __type = typename,
  }, {
    __index = wapi,
  })
  for _, t in ipairs(supers) do
    local ty = api.uiobjectTypes[t]
    if ty.constructor then
      api.log(4, 'running constructor for ' .. ty.name)
      ty.constructor(obj, xmlattr or {})
    end
  end
  if objname then
    if api.env[objname] then
      api.log(1, 'overwriting global ' .. objname)
    end
    api.env[objname] = obj
  end
  return obj
end

local function mkBaseEnv()
  local bitlib = require('bit')
  return setmetatable({
    assert = assert,
    bit = {
      bor = bitlib.bor,
    },
    ceil = math.ceil,
    floor = math.floor,
    format = string.format,
    getfenv = getfenv,
    getmetatable = getmetatable,
    getn = table.getn,
    ipairs = ipairs,
    math = {
      ceil = math.ceil,
      floor = math.floor,
      max = math.max,
      min = math.min,
    },
    max = math.max,
    min = math.min,
    mod = math.fmod,
    next = next,
    pairs = pairs,
    pcall = pcall,
    print = print,
    rawget = rawget,
    select = select,
    setmetatable = setmetatable,
    sort = table.sort,
    string = {
      find = string.find,
      format = string.format,
      gmatch = string.gmatch,
      gsub = string.gsub,
      len = string.len,
      lower = string.lower,
      match = string.match,
      rep = string.rep,
      sub = string.sub,
      upper = string.upper,
    },
    strlower = string.lower,
    strsub = string.sub,
    strupper = string.upper,
    table = {
      insert = table.insert,
      wipe = util.twipe,
    },
    tinsert = table.insert,
    tonumber = tonumber,
    tostring = tostring,
    tremove = table.remove,
    type = type,
  }, {
    __index = function(t, k)
      if k == '_G' then
        return t
      elseif k == '__dump' then
        return function(...)
          local dump = require('pl.pretty').dump
          for _, x in ipairs({...}) do
            dump(x)
          end
        end
      elseif string.sub(k, 1, 3) == 'LE_' then
        return 'AUTOGENERATED:' .. k
      end
    end
  })
end

local function mkWowEnv(api)
  return {
    AntiAliasingSupported = UNIMPLEMENTED,
    BNFeaturesEnabled = UNIMPLEMENTED,
    BNFeaturesEnabledAndConnected = UNIMPLEMENTED,
    CanAutoSetGamePadCursorControl = UNIMPLEMENTED,
    Constants = {
      CurrencyConsts = {},
    },
    CreateFont = function(name)
      return _CreateUIObject(api, 'font', name)
    end,
    CreateFrame = function(type, name, parent, templates)
      local ltype = string.lower(type)
      assert(_InheritsFrom(api, ltype, 'frame'), type .. ' does not inherit from frame')
      local inherits = {}
      for template in string.gmatch(templates or '', '[^, ]+') do
        table.insert(inherits, string.lower(template))
      end
      local obj = _CreateUIObject(api, ltype, name, parent, inherits)
      obj:__RunScript('OnLoad')
      return obj
    end,
    C_ChatInfo = {
      IsValidChatLine = UNIMPLEMENTED,
    },
    C_Club = {},
    C_Commentator = {
      IsSpectating = UNIMPLEMENTED,
    },
    C_CurrencyInfo = {
      GetCurrencyInfo = STUB_TABLE,
    },
    C_CVar = {
      GetCVar = function(var)
        return api.env.C_CVar.GetCVarDefault(var)  -- UNIMPLEMENTED
      end,
      GetCVarBool = UNIMPLEMENTED,
      GetCVarDefault = function(var)  -- UNIMPLEMENTED
        local defaults = {
          cameraSmoothStyle = '0',
          cameraSmoothTrackingStyle = '0',
          nameplateMotion = '0',
        }
        return defaults[var]
      end,
    },
    C_DeathInfo = {
      GetSelfResurrectOptions = UNIMPLEMENTED,
    },
    C_FriendList = {
      SetWhoToUi = UNIMPLEMENTED,
    },
    C_GamePad = {},
    C_GuildInfo = {
      GuildControlGetRankFlags = STUB_TABLE,
    },
    C_LootHistory = {
      GetItem = UNIMPLEMENTED,
      GetNumItems = STUB_NUMBER,
    },
    C_NamePlate = {
      GetNumNamePlateMotionTypes = STUB_NUMBER,
    },
    C_PaperDollInfo = {
      OffhandHasWeapon = UNIMPLEMENTED,
    },
    C_ProductChoice = {
      GetChoices = STUB_TABLE,
    },
    C_ScriptedAnimations = {
      GetAllScriptedAnimationEffects = STUB_TABLE,
    },
    C_Social = {
      TwitterCheckStatus = UNIMPLEMENTED,
    },
    C_StorePublic = {
      IsDisabledByParentalControls = UNIMPLEMENTED,
    },
    C_SummonInfo = {
      GetSummonConfirmTimeLeft = STUB_NUMBER,
      GetSummonReason = UNIMPLEMENTED,
      IsSummonSkippingStartExperience = UNIMPLEMENTED,
    },
    C_Texture = {
      GetAtlasInfo = UNIMPLEMENTED,
    },
    C_Timer = {
      After = UNIMPLEMENTED,
    },
    C_VoiceChat = {
      GetActiveChannelID = UNIMPLEMENTED,
      GetAvailableInputDevices = UNIMPLEMENTED,
      GetAvailableOutputDevices = UNIMPLEMENTED,
      GetCommunicationMode = UNIMPLEMENTED,
      GetInputVolume = UNIMPLEMENTED,
      GetMasterVolumeScale = UNIMPLEMENTED,
      GetOutputVolume = UNIMPLEMENTED,
      GetVADSensitivity = UNIMPLEMENTED,
    },
    C_Widget = {},
    DropCursorMoney = UNIMPLEMENTED,
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
    GetActionBarPage = STUB_NUMBER,
    GetActionCount = STUB_NUMBER,
    GetActionInfo = UNIMPLEMENTED,
    GetActionTexture = UNIMPLEMENTED,
    GetActiveLootRollIDs = STUB_TABLE,
    GetAddOnEnableState = UNIMPLEMENTED,
    GetAlternativeDefaultLanguage = UNIMPLEMENTED,
    GetArenaTeam = UNIMPLEMENTED,
    GetAvailableLocales = UNIMPLEMENTED,
    GetBattlefieldStatus = UNIMPLEMENTED,
    GetBindingKey = UNIMPLEMENTED,
    GetBindingText = UNIMPLEMENTED,
    GetChatTypeIndex = STUB_NUMBER,
    GetChatWindowInfo = UNIMPLEMENTED,
    GetChatWindowSavedDimensions = UNIMPLEMENTED,
    GetChatWindowSavedPosition = UNIMPLEMENTED,
    GetClassicExpansionLevel = STUB_NUMBER,
    GetComboPoints = STUB_NUMBER,
    GetContainerNumFreeSlots = STUB_NUMBER,
    GetCurrentScaledResolution = function()
      return 1024, 768  -- UNIMPLEMENTED
    end,
    GetCurrentTitle = UNIMPLEMENTED,
    GetCVarInfo = UNIMPLEMENTED,
    GetCVarSettingValidity = UNIMPLEMENTED,
    GetDefaultLanguage = function()
      return 'Common', 7  -- UNIMPLEMENTED
    end,
    GetDefaultVideoOptions = UNIMPLEMENTED,
    GetGameTime = function()
      return 1, 1  -- UNIMPLEMENTED
    end,
    GetGuildRosterShowOffline = UNIMPLEMENTED,
    GetInventoryAlertStatus = UNIMPLEMENTED,
    GetInventorySlotInfo = function()
      return 'UNIMPLEMENTED'
    end,
    GetItemQualityColor = function()
      return 0, 0, 0  -- UNIMPLEMENTED
    end,
    GetLootMethod = function()
      return 'freeforall'  -- UNIMPLEMENTED
    end,
    GetMaxPlayerLevel = STUB_NUMBER,
    GetMaxRenderScale = UNIMPLEMENTED,
    GetMinimapZoneText = UNIMPLEMENTED,
    GetMinRenderScale = UNIMPLEMENTED,
    GetMirrorTimerInfo = function()
      return 'UNKNOWN'  -- UNIMPLEMENTED
    end,
    GetModifiedClick = UNIMPLEMENTED,
    GetMouseFocus = UNIMPLEMENTED,
    GetNumAddOns = function()
      return 0  -- UNIMPLEMENTED
    end,
    GetNumLanguages = STUB_NUMBER,
    GetNumQuestWatches = function()
      return 0  -- UNIMPLEMENTED
    end,
    GetNumShapeshiftForms = STUB_NUMBER,
    GetNumSkillLines = STUB_NUMBER,
    GetNumSubgroupMembers = STUB_NUMBER,
    GetNumTitles = STUB_NUMBER,
    GetNumTrackingTypes = STUB_NUMBER,
    GetPetActionCooldown = UNIMPLEMENTED,
    GetPetActionInfo = UNIMPLEMENTED,
    GetPetExperience = STUB_NUMBER,
    GetPlayerTradeMoney = STUB_NUMBER,
    GetPVPLifetimeStats = UNIMPLEMENTED,
    GetPVPSessionStats = UNIMPLEMENTED,
    GetPVPYesterdayStats = UNIMPLEMENTED,
    GetReleaseTimeRemaining = STUB_NUMBER,
    GetRepairAllCost = STUB_NUMBER,
    GetRestState = function()
      return 2, 'Normal', 1  -- UNIMPLEMENTED
    end,
    GetScreenHeight = STUB_NUMBER,
    GetScreenWidth = STUB_NUMBER,
    GetSelectedSkill = STUB_NUMBER,
    GetSendMailPrice = STUB_NUMBER,
    GetShapeshiftFormCooldown = UNIMPLEMENTED,
    GetShapeshiftFormInfo = UNIMPLEMENTED,
    GetSkillLineInfo = function()
      return nil, nil, nil, 0, 0, 0, 1  -- UNIMPLEMENTED
    end,
    GetSpellConfirmationPromptsInfo = STUB_TABLE,
    GetSubZoneText = UNIMPLEMENTED,
    GetTabardCreationCost = STUB_NUMBER,
    GetText = UNIMPLEMENTED,
    GetTime = UNIMPLEMENTED,
    GetTotemInfo = UNIMPLEMENTED,
    GetTrackingInfo = UNIMPLEMENTED,
    GetXPExhaustion = UNIMPLEMENTED,
    GetZonePVPInfo = UNIMPLEMENTED,
    GetZoneText = UNIMPLEMENTED,
    GuildControlGetNumRanks = STUB_NUMBER,
    GuildControlGetRankName = UNIMPLEMENTED,
    HasAction = UNIMPLEMENTED,
    HasBonusActionBar = UNIMPLEMENTED,
    HasKey = UNIMPLEMENTED,
    HasPetUI = UNIMPLEMENTED,
    HasTempShapeshiftActionBar = UNIMPLEMENTED,
    InCinematic = UNIMPLEMENTED,
    InCombatLockdown = UNIMPLEMENTED,
    IsAddOnLoaded = UNIMPLEMENTED,
    IsAddonVersionCheckEnabled = UNIMPLEMENTED,
    IsAltKeyDown = UNIMPLEMENTED,
    IsBattlefieldArena = UNIMPLEMENTED,
    IsConsumableAction = UNIMPLEMENTED,
    IsControlKeyDown = UNIMPLEMENTED,
    IsEquippedAction = UNIMPLEMENTED,
    IsEveryoneAssistant = UNIMPLEMENTED,
    IsGMClient = UNIMPLEMENTED,
    IsInGroup = UNIMPLEMENTED,
    IsInGuild = UNIMPLEMENTED,
    IsInInstance = UNIMPLEMENTED,
    IsInRaid = UNIMPLEMENTED,
    IsItemAction = UNIMPLEMENTED,
    IsMacClient = UNIMPLEMENTED,
    IsOnGlueScreen = UNIMPLEMENTED,
    IsRestrictedAccount = UNIMPLEMENTED,
    issecure = UNIMPLEMENTED,
    IsShiftKeyDown = UNIMPLEMENTED,
    IsStackableAction = UNIMPLEMENTED,
    IsTitleKnown = UNIMPLEMENTED,
    IsTrialAccount = UNIMPLEMENTED,
    IsVeteranTrialAccount = UNIMPLEMENTED,
    IsWindowsClient = UNIMPLEMENTED,
    LE_EXPANSION_BURNING_CRUSADE = 2,  -- UNIMPLEMENTED
    LoadAddOn = function(name)
      api.log(1, 'failing to load addon ' .. name)
      return false, 'LOAD_FAILED'  -- UNIMPLEMENTED
    end,
    Kiosk = {
      IsEnabled = UNIMPLEMENTED,
    },
    MultiSampleAntiAliasingSupported = UNIMPLEMENTED,
    newproxy = function()
      return setmetatable({}, {})
    end,
    NUM_LE_ITEM_QUALITYS = 10,  -- UNIMPLEMENTED
    PetHasActionBar = UNIMPLEMENTED,
    PlaySound = UNIMPLEMENTED,
    RegisterStaticConstants = UNIMPLEMENTED,
    ResurrectGetOfferer = UNIMPLEMENTED,
    securecall = function(func, ...)
      assert(func, 'securecall of nil function')
      if type(func) == 'string' then
        assert(api.env[func], 'securecall of unknown function ' .. func)
        func = api.env[func]
      end
      func(...)
    end,
    SetActionBarToggles = UNIMPLEMENTED,
    SetActionUIButton = UNIMPLEMENTED,
    SetChatWindowName = UNIMPLEMENTED,
    seterrorhandler = UNIMPLEMENTED,
    SetPortraitTexture = UNIMPLEMENTED,
    SetPortraitToTexture = UNIMPLEMENTED,
    SetSelectedSkill = UNIMPLEMENTED,
    ShouldKnowUnitHealth = UNIMPLEMENTED,
    ShowBossFrameWhenUninteractable = UNIMPLEMENTED,
    Sound_GameSystem_GetNumOutputDrivers = STUB_NUMBER,
    Sound_GameSystem_GetOutputDriverNameByIndex = UNIMPLEMENTED,
    TriggerTutorial = UNIMPLEMENTED,
    UnitCastingInfo = UNIMPLEMENTED,
    UnitChannelInfo = UNIMPLEMENTED,
    UnitClass = UNIMPLEMENTED,
    UnitExists = UNIMPLEMENTED,
    UnitFactionGroup = UNIMPLEMENTED,
    UnitHealth = STUB_NUMBER,
    UnitHealthMax = STUB_NUMBER,
    UnitInBattleground = UNIMPLEMENTED,
    UnitIsConnected = UNIMPLEMENTED,
    UnitIsDead = UNIMPLEMENTED,
    UnitIsDeadOrGhost = UNIMPLEMENTED,
    UnitIsGhost = UNIMPLEMENTED,
    UnitIsGroupAssistant = UNIMPLEMENTED,
    UnitIsGroupLeader = UNIMPLEMENTED,
    UnitIsPossessed = UNIMPLEMENTED,
    UnitIsVisible = UNIMPLEMENTED,
    UnitLevel = STUB_NUMBER,
    UnitName = function()
      return 'Unitname'  -- UNIMPLEMENTED
    end,
    UnitOnTaxi = UNIMPLEMENTED,
    UnitPower = STUB_NUMBER,
    UnitPowerMax = STUB_NUMBER,
    UnitPowerType = function()
      return 0, 'MANA'  -- UNIMPLEMENTED
    end,
    UnitRace = function()
      return 'Human', 'Human', 1  -- UNIMPLEMENTED
    end,
    UnitRealmRelationship = UNIMPLEMENTED,
    UnitSex = function()
      return 2  -- UNIMPLEMENTED
    end,
    UnitXP = STUB_NUMBER,
    UnitXPMax = STUB_NUMBER,
  }
end

local function _SendEvent(api, event, ...)
  local args = {...}
  for _, frame in ipairs(api.frames) do
    if frame.__registeredEvents[string.lower(event)] then
      xpcall(function() frame:__RunScript('OnEvent', event, unpack(args)) end, function(err)
        print('error: ' .. err)
      end)
    end
  end
end

local function new(log)
  local env = mkBaseEnv()
  local api = {
    CreateUIObject = _CreateUIObject,
    env = env,
    frames = {},
    IsIntrinsicType = _IsIntrinsicType,
    IsUIObjectType = _IsUIObjectType,
    log = log,
    SendEvent = _SendEvent,
  }
  api.uiobjectTypes = mkBaseUIObjectTypes(api)
  Mixin(env, mkWowEnv(api), require('wowless.globalstrings'))
  return env, api
end

return {
  new = new,
}
