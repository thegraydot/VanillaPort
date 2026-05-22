-- VanillaPort: world map teleport pins for GMs.
-- Hooks WorldMapFrame_Update to display clickable pins for the current zone.
-- Clicking a pin sends the .go command and closes the map.
--
-- Coordinate system for .go commands:
--   param1 = position_x (increases going north)
--   param2 = position_y (increases going west)
--
-- Zone bounds come from WorldMapArea.dbc (vanilla 1.12).
-- xMin/xMax bound param2 (position_y, east-west).
-- yMin/yMax bound param1 (position_x, north-south).

local VP = CreateFrame("Frame", "VanillaPort", UIParent)
VP.pins   = {}
VP.bounds = {}
VP.zones  = {}

-- Actual zone map extents sourced from WorldMapArea.dbc via pfQuest client-data.
-- xMax = DBC y_max (westernmost), xMin = DBC y_min (easternmost)
-- yMax = DBC x_max (northernmost), yMin = DBC x_min (southernmost)
local VP_ZONE_BOUNDS = {
    -- Eastern Kingdoms
    ["Alterac Mountains"]   = { yMin=-366.666656494,    yMax=1500.0,            xMin=-2016.66662598,    xMax=783.333312988    },
    ["Arathi Highlands"]    = { yMin=-2533.33325195,    yMax=-133.333328247,    xMin=-4466.66650391,    xMax=-866.666625977   },
    ["Badlands"]            = { yMin=-7547.91650391,    yMax=-5889.58300781,    xMin=-4566.66650391,    xMax=-2079.16650391   },
    ["Blasted Lands"]       = { yMin=-12800.0,          yMax=-10566.6660156,    xMin=-4591.66650391,    xMax=-1241.66662598   },
    ["Burning Steppes"]     = { yMin=-8983.33300781,    yMax=-7031.24951172,    xMin=-3195.83325195,    xMax=-266.666656494   },
    ["Deadwind Pass"]       = { yMin=-11533.3330078,    yMax=-9866.66601562,    xMin=-3333.33325195,    xMax=-833.333312988   },
    ["Dun Morogh"]          = { yMin=-7160.41650391,    yMax=-3877.08325195,    xMin=-3122.91650391,    xMax=1802.08325195    },
    ["Duskwood"]            = { yMin=-11516.6660156,    yMax=-9716.66601562,    xMin=-1866.66662598,    xMax=833.333312988    },
    ["Eastern Plaguelands"] = { yMin=1218.75,           yMax=3799.99975586,     xMin=-6056.25,          xMax=-2185.41650391   },
    ["Elwynn Forest"]       = { yMin=-10254.1660156,    yMax=-7939.58300781,    xMin=-1935.41662598,    xMax=1535.41662598    },
    ["Hillsbrad Foothills"] = { yMin=-1733.33325195,    yMax=400.0,             xMin=-2133.33325195,    xMax=1066.66662598    },
    ["Hinterlands"]         = { yMin=-1100.0,           yMax=1466.66662598,     xMin=-5425.0,           xMax=-1575.0          },
    ["Ironforge"]           = { yMin=-5096.84570312,    yMax=-4569.24121094,    xMin=-1504.21643066,    xMax=-713.591369629   },
    ["Loch Modan"]          = { yMin=-6327.08300781,    yMax=-4487.5,           xMin=-4752.08300781,    xMax=-1993.74987793   },
    ["Redridge Mountains"]  = { yMin=-10022.9160156,    yMax=-8575.0,           xMin=-3741.66650391,    xMax=-1570.83325195   },
    ["Searing Gorge"]       = { yMin=-7587.49951172,    yMax=-6100.0,           xMin=-2554.16650391,    xMax=-322.916656494   },
    ["Silverpine Forest"]   = { yMin=-1133.33325195,    yMax=1666.66662598,     xMin=-750.0,            xMax=3449.99975586    },
    ["Stormwind City"]      = { yMin=-9175.20507812,    yMax=-8278.85058594,    xMin=36.700630188,      xMax=1380.97143555    },
    ["Stranglethorn Vale"]  = { yMin=-15422.9160156,    yMax=-11168.75,         xMin=-4160.41650391,    xMax=2220.83325195    },
    ["Swamp of Sorrows"]    = { yMin=-11150.0,          yMax=-9620.83300781,    xMin=-4516.66650391,    xMax=-2222.91650391   },
    ["Tirisfal Glades"]     = { yMin=824.999938965,     yMax=3837.49975586,     xMin=-1485.41662598,    xMax=3033.33325195    },
    ["Undercity"]           = { yMin=1237.84118652,     yMax=1877.9453125,      xMin=-86.1824035645,    xMax=873.192626953    },
    ["Western Plaguelands"] = { yMin=499.999969482,     yMax=3366.66650391,     xMin=-3883.33325195,    xMax=416.666656494    },
    ["Westfall"]            = { yMin=-11733.3330078,    yMax=-9400.0,           xMin=-483.333312988,    xMax=3016.66650391    },
    ["Wetlands"]            = { yMin=-4904.16650391,    yMax=-2147.91650391,    xMin=-4525.0,           xMax=-389.583312988   },
    -- Kalimdor
    ["Ashenvale"]           = { yMin=829.166625977,     yMax=4672.91650391,     xMin=-4066.66650391,    xMax=1699.99987793    },
    ["Azshara"]             = { yMin=1960.41662598,     yMax=5341.66650391,     xMin=-8347.91601562,    xMax=-3277.08325195   },
    ["Darkshore"]           = { yMin=3966.66650391,     yMax=8333.33300781,     xMin=-3608.33325195,    xMax=2941.66650391    },
    ["Darnassus"]           = { yMin=9532.58691406,     yMax=10238.3164062,     xMin=1880.02954102,     xMax=2938.36279297    },
    ["Desolace"]            = { yMin=-2545.83325195,    yMax=452.083312988,     xMin=-262.5,            xMax=4233.33300781    },
    ["Durotar"]             = { yMin=-1716.66662598,    yMax=1808.33325195,     xMin=-7249.99951172,    xMax=-1962.49987793   },
    ["Dustwallow Marsh"]    = { yMin=-5533.33300781,    yMax=-2033.33325195,    xMin=-6225.0,           xMax=-974.999938965   },
    ["Felwood"]             = { yMin=3299.99975586,     yMax=7133.33300781,     xMin=-4108.33300781,    xMax=1641.66662598    },
    ["Feralas"]             = { yMin=-6999.99951172,    yMax=-2366.66650391,    xMin=-1508.33325195,    xMax=5441.66650391    },
    ["Moonglade"]           = { yMin=6952.08300781,     yMax=8491.66601562,     xMin=-3689.58325195,    xMax=-1381.25         },
    ["Mulgore"]             = { yMin=-3697.91650391,    yMax=-272.916656494,    xMin=-3089.58325195,    xMax=2047.91662598    },
    ["Orgrimmar"]           = { yMin=1338.46057129,     yMax=2273.87719727,     xMin=-5083.20556641,    xMax=-3680.60107422   },
    ["Silithus"]            = { yMin=-8281.25,          yMax=-5958.33398438,    xMin=-945.833984375,    xMax=2537.5           },
    ["Stonetalon Mountains"]= { yMin=-339.583312988,    yMax=2916.66650391,     xMin=-1637.49987793,    xMax=3245.83325195    },
    ["Tanaris"]             = { yMin=-10475.0,          yMax=-5875.0,           xMin=-7118.74951172,    xMax=-218.749984741   },
    ["Teldrassil"]          = { yMin=8437.5,            yMax=11831.25,          xMin=-1277.08325195,    xMax=3814.58325195    },
    ["The Barrens"]         = { yMin=-5143.75,          yMax=1612.49987793,     xMin=-7510.41650391,    xMax=2622.91650391    },
    ["Thousand Needles"]    = { yMin=-6899.99951172,    yMax=-3966.66650391,    xMin=-4833.33300781,    xMax=-433.333312988   },
    ["Thunder Bluff"]       = { yMin=-1545.83325195,    yMax=-849.999938965,    xMin=-527.083312988,    xMax=516.666625977    },
    ["Un'Goro Crater"]      = { yMin=-8433.33300781,    yMax=-5966.66650391,    xMin=-3166.66650391,    xMax=533.333312988    },
    ["Winterspring"]        = { yMin=3799.99975586,     yMax=8533.33300781,     xMin=-7416.66650391,    xMax=-316.666656494   },
}

-- Parse a .go command; returns worldY (param1), worldX (param2).
local function ParseCmd(cmd)
    local _, _, wy, wx = string.find(cmd, "%.go ([%d%.%-]+) ([%d%.%-]+)")
    if wy then
        return tonumber(wy), tonumber(wx)
    end
end

local function Clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- Populate bounds from the hardcoded DBC table where available.
-- Falls back to data-extent + 15% padding for any zone not listed
-- (e.g. Hyjal, which has no vanilla WorldMapArea entry).
function VP:ComputeBounds()
    for cont, zones in pairs(VanillaPort_Data) do
        self.bounds[cont] = {}
        for zone, locs in pairs(zones) do
            if VP_ZONE_BOUNDS[zone] then
                self.bounds[cont][zone] = VP_ZONE_BOUNDS[zone]
            else
                local yMax, yMin =  -1e9,  1e9
                local xMax, xMin =  -1e9,  1e9
                local count = 0
                for _, loc in ipairs(locs) do
                    local wy, wx = ParseCmd(loc.cmd)
                    if wy then
                        if wy > yMax then yMax = wy end
                        if wy < yMin then yMin = wy end
                        if wx > xMax then xMax = wx end
                        if wx < xMin then xMin = wx end
                        count = count + 1
                    end
                end
                if count > 0 then
                    local yPad = math.max((yMax - yMin) * 0.15, 200)
                    local xPad = math.max((xMax - xMin) * 0.15, 200)
                    self.bounds[cont][zone] = {
                        yMax = yMax + yPad,
                        yMin = yMin - yPad,
                        xMax = xMax + xPad,
                        xMin = xMin - xPad,
                    }
                end
            end
        end
    end
end

-- Cache zone name arrays for both continents at load time.
-- self.zones[cont][zoneIndex] = zoneName string.
function VP:CacheZones()
    self.zones[1] = { GetMapZones(1) }
    self.zones[2] = { GetMapZones(2) }
end

-- Convert world coordinates to 0-1 map fractions.
-- fx=0 is the west edge (xMax), fx=1 is the east edge (xMin).
-- fy=0 is the north edge (yMax), fy=1 is the south edge (yMin).
-- position_y (worldX) increases going west, so west has the largest value.
-- position_x (worldY) increases going north, so north has the largest value.
local function WorldToFraction(worldY, worldX, b)
    local fx = (b.xMax - worldX) / (b.xMax - b.xMin)
    local fy = (b.yMax - worldY) / (b.yMax - b.yMin)
    fx = Clamp(fx, 0.02, 0.98)
    fy = Clamp(fy, 0.02, 0.98)
    return fx, fy
end

-- Return the pin at index idx, creating it if it does not yet exist.
function VP:GetPin(idx)
    if not self.pins[idx] then
        local btn = CreateFrame("Button", "VanillaPortPin"..idx, WorldMapButton)
        btn:SetWidth(12)
        btn:SetHeight(12)
        btn:SetFrameLevel(WorldMapButton:GetFrameLevel() + 5)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(btn)
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetVertexColor(0, 0, 0, 0.6)

        local icon = btn:CreateTexture(nil, "OVERLAY")
        icon:SetWidth(10)
        icon:SetHeight(10)
        icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
        icon:SetTexture("Interface\\Buttons\\WHITE8X8")
        icon:SetVertexColor(0.2, 0.9, 0.3, 1)
        btn.icon = icon

        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", btn, "RIGHT", 3, 0)
        label:SetTextColor(0.2, 0.9, 0.3, 1)
        btn.label = label

        btn:SetScript("OnClick", function()
            SendChatMessage(this.vpCmd, "SAY")
            HideUIPanel(WorldMapFrame)
        end)

        btn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine("|cff33ffcc"..this.vpName.."|r")
            GameTooltip:AddLine(this.vpCmd, 0.7, 0.7, 0.7, 1)
            GameTooltip:Show()
        end)

        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        self.pins[idx] = btn
    end
    return self.pins[idx]
end

-- Hide all pins from index n onwards.
function VP:HideFrom(n)
    for i = n, table.getn(self.pins) do
        if self.pins[i] then
            self.pins[i]:Hide()
        end
    end
end

-- Rebuild visible pins for the currently displayed zone.
function VP:Refresh()
    if not WorldMapFrame:IsVisible() then
        self:HideFrom(1)
        return
    end

    local cont = GetCurrentMapContinent()
    local zid  = GetCurrentMapZone()
    if cont <= 0 or zid <= 0 then
        self:HideFrom(1)
        return
    end

    local zoneList = self.zones[cont]
    if not zoneList then
        self:HideFrom(1)
        return
    end

    local zoneName = zoneList[zid]
    if not zoneName then
        self:HideFrom(1)
        return
    end

    local contData = VanillaPort_Data[cont]
    local locs = contData and contData[zoneName]
    if not locs then
        self:HideFrom(1)
        return
    end

    local b = self.bounds[cont] and self.bounds[cont][zoneName]
    if not b then
        self:HideFrom(1)
        return
    end

    local mapW = WorldMapDetailFrame:GetWidth()
    local mapH = WorldMapDetailFrame:GetHeight()
    local n = 0

    for _, loc in ipairs(locs) do
        local wy, wx = ParseCmd(loc.cmd)
        if wy then
            n = n + 1
            local pin = self:GetPin(n)
            local fx, fy = WorldToFraction(wy, wx, b)
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", WorldMapDetailFrame, "TOPLEFT", fx * mapW, -(fy * mapH))
            pin.vpName = loc.name
            pin.vpCmd  = loc.cmd
            pin.label:SetText(loc.name)
            pin:Show()
        end
    end

    self:HideFrom(n + 1)
end

-- Hook WorldMapFrame_Update using the vanilla manual save-and-replace pattern.
local _VP_orig_WorldMapFrame_Update = WorldMapFrame_Update
function WorldMapFrame_Update()
    if _VP_orig_WorldMapFrame_Update then
        _VP_orig_WorldMapFrame_Update()
    end
    VP:Refresh()
end

VP:RegisterEvent("ADDON_LOADED")
VP:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "VanillaPort" then
        this:UnregisterEvent("ADDON_LOADED")
        VP:CacheZones()
        VP:ComputeBounds()
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccVanillaPort|r loaded.")
    end
end)
