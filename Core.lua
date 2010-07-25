local addonName = ...

-- In the beginning...
WarnOMatic = LibStub("AceAddon-3.0"):NewAddon("WarnOMatic", "AceConsole-3.0", "AceBucket-3.0")
local WarnOMatic = WarnOMatic

-- Extract version
WarnOMatic.version = GetAddOnMetadata(addonName, 'Version')
WarnOMatic.vMajor, WarnOMatic.vMinor, WarnOMatic.vBuild = WarnOMatic.version:match("(%d-)%.(%d-)%-(.-)")

-- Debugging support
WarnOMatic.debug = GetAddOnMetadata(addonName,"X-Debug") == "1"

local debug = WarnOMatic.debug

local defaults = {
  global = {
    channel = "SAY" -- This is where it should warn people eventually, not coded yet.
  },
  char = {
    class = nil
  },
  profile = {
    player = {
      warn_level = 25
    },
    party = {
      warn_level = 25
    } 
  } 
}
local options = {
  type = "group",
  args = {
    -- player options
    player = {
      name = "Player options",
      type = "group",
      args = {
        warnlevel = {
          name = "Warn level in percent",
          desc = "At what percentage of health you want to warn about low health!",
          type = "range",
          min = 0.01,
          max = 0.8,
          isPercent = true, -- No need to have it any higher, it would spam all the time.
          set = function(info, value)
            WarnOMatic.db.profile.player.warn_level = value
          end,
          get = function() return WarnOMatic.db.profile.player.warn_level end
        }
      }
    },
    -- party options
    party = {
      name = "Party options",
      type = "group",
      args = {
        warnlevel = {
          name = "Warn level in percent",
          desc = "At what percentage of health you want to warn about low health!",
          type = "range",
          min = 0.01,
          max = 0.8, -- No need to have it any higher, it would spam all the time.
          isPercent = true,
          set = function(info, value)
            WarnOMatic.db.profile.party.warn_level = value
          end,
          get = function() return WarnOMatic.db.profile.party.warn_level end
        }
      }
    }
  }
}
WarnOMatic:RegisterChatCommand("wom", "ChatCommand")

-- Show the GUI if no input is supplied, otherwise handle the chat input.
function WarnOMatic:ChatCommand(input)
  -- Assuming "MyOptions" is the appName of a valid options table
  if not input or input:trim() == "" then
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
  else
    LibStub("AceConfigCmd-3.0").HandleCommand(WarnOMatic, "wom", "WarnOMatic", input)
  end
end

function WarnOMatic:OnInitialize()
  -- Code that you want to run when the addon is first loaded goes here.
  self.db = LibStub("AceDB-3.0"):New("WarnOMaticDB", defaults)
  self.db.char.class = select(2, UnitClass("player"))
  LibStub("AceConfig-3.0"):RegisterOptionsTable("WarnOMatic", options)
  self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WarnOMatic", "WarnOMatic")
  WarnOMatic:Printf("Loaded! Version: %s, use /wom to show/hide options menu", WarnOMatic.version)
end

function WarnOMatic:OnEnable()
    -- Called when the addon is enabled
    self:RegisterBucketEvent({"UNIT_HEALTH", "UNIT_MAXHEALTH"}, 1, "UpdateHealth")
end
function WarnOMatic:UpdateHealth(units)
  local event, unit = nil
  for k, v in pairs(units) do
    event = k:match("(%a+)%d+") or k:match("(%a+)") -- Get the actual event happening ("party from party1")
    unit = k
    --WarnOMatic:Printf("[DEBUG]: k: %s, v: %s", k, v)
  end
  --WarnOMatic:Printf("UpdateHealth(event: %s, unit: %s)", event, unit)
  local unitHealth = UnitHealth(unit)
  local unitHealthMax = UnitHealthMax(unit)
  local unitName = GetUnitName(unit, false) -- Get unit name, leave out servername.
  if event == "player" then
    if unitHealth < unitHealthMax*WarnOMatic.db.profile.player.warn_level and unitHealth > 0 then
      self:Printf("Your HP is very low!")
    end
 
  elseif event == "party" then
    if unitHealth < unitHealthMax*WarnOMatic.db.profile.party.warn_level and unitHealth > 0 then
      self:Printf("%s's health is very low!", unitName)
    end
    --self:Printf("Health for %s in your party changed!: %s/%s",unitName, unitHealth,unitHealthMax)
  end
end

function WarnOMatic:OnDisable()
    -- Called when the addon is disabled
    self:UnregisterAllBuckets()
end
