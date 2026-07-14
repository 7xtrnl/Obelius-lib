-- Obelius Save Manager Addon
local SaveManager = {
    Library = nil,
    Folder = "ObeliusLib",
    IgnoreIndexes = {},
    ConfigsList = {},
    CurrentConfig = nil,
}

local HttpService = game:GetService("HttpService")

function SaveManager:SetLibrary(library)
    self.Library = library
end

function SaveManager:SetFolder(folder)
    self.Folder = folder
    self:RefreshConfigList()
end

function SaveManager:SetIgnoreIndexes(indexes)
    for _, index in ipairs(indexes) do
        self.IgnoreIndexes[index] = true
    end
end

function SaveManager:IgnoreThemeSettings()
    -- Add theme-related indexes to ignore list
    self.IgnoreIndexes["ThemeColor"] = true
    self.IgnoreIndexes["BackgroundColor"] = true
end

function SaveManager:RefreshConfigList()
    self.ConfigsList = {}
    
    if not isfolder then return end
    if not isfolder(self.Folder) then
        makefolder(self.Folder)
    end
    
    if listfiles then
        local files = listfiles(self.Folder)
        for _, file in ipairs(files) do
            if file:sub(-5) == ".json" then
                local name = file:match("([^/\\]+)%.json$")
                if name then
                    table.insert(self.ConfigsList, name)
                end
            end
        end
    end
end

function SaveManager:SaveConfig(name)
    if not writefile then
        warn("SaveManager: writefile not available")
        return
    end
    
    local data = {}
    
    -- Save Toggles
    for idx, toggle in pairs(getgenv().Toggles or {}) do
        if not self.IgnoreIndexes[idx] then
            data[idx] = {
                Type = "Toggle",
                Value = toggle.Value
            }
        end
    end
    
    -- Save Options
    for idx, option in pairs(getgenv().Options or {}) do
        if not self.IgnoreIndexes[idx] then
            local value = option.Value
            local valueType = typeof(value)
            
            if valueType == "Color3" then
                data[idx] = {
                    Type = "Color3",
                    Value = {value.R, value.G, value.B}
                }
            elseif valueType == "EnumItem" then
                data[idx] = {
                    Type = "EnumItem",
                    Value = tostring(value)
                }
            else
                data[idx] = {
                    Type = "Value",
                    Value = value
                }
            end
        end
    end
    
    local json = HttpService:JSONEncode(data)
    
    if not isfolder(self.Folder) then
        makefolder(self.Folder)
    end
    
    writefile(self.Folder .. "/" .. name .. ".json", json)
    self:RefreshConfigList()
end

function SaveManager:LoadConfig(name)
    if not readfile then
        warn("SaveManager: readfile not available")
        return
    end
    
    local path = self.Folder .. "/" .. name .. ".json"
    
    if not isfile or not isfile(path) then
        warn("SaveManager: Config not found:", name)
        return
    end
    
    local json = readfile(path)
    local success, data = pcall(HttpService.JSONDecode, HttpService, json)
    
    if not success then
        warn("SaveManager: Failed to decode config")
        return
    end
    
    for idx, info in pairs(data) do
        if info.Type == "Toggle" then
            local toggle = getgenv().Toggles[idx]
            if toggle then
                toggle:SetValue(info.Value)
            end
        elseif info.Type == "Color3" then
            local option = getgenv().Options[idx]
            if option then
                option:SetValue(Color3.new(unpack(info.Value)))
            end
        elseif info.Type == "Value" then
            local option = getgenv().Options[idx]
            if option then
                option:SetValue(info.Value)
            end
        end
    end
    
    self.CurrentConfig = name
end

function SaveManager:DeleteConfig(name)
    if not delfile then
        warn("SaveManager: delfile not available")
        return
    end
    
    local path = self.Folder .. "/" .. name .. ".json"
    
    if isfile and isfile(path) then
        delfile(path)
        self:RefreshConfigList()
    end
end

function SaveManager:LoadAutoloadConfig()
    -- Check for autoload config
    local autoloadPath = self.Folder .. "/autoload.txt"
    
    if isfile and readfile and isfile(autoloadPath) then
        local configName = readfile(autoloadPath)
        self:LoadConfig(configName)
        return true
    end
    
    return false
end

function SaveManager:SetAutoloadConfig(name)
    if not writefile then return end
    
    if not isfolder(self.Folder) then
        makefolder(self.Folder)
    end
    
    writefile(self.Folder .. "/autoload.txt", name)
end

function SaveManager:BuildConfigSection(tab)
    local groupbox = tab:AddRightGroupbox("Configuration")
    
    groupbox:AddLabel("Config Name")
    
    -- Config name input (placeholder - needs actual implementation)
    local configName = "default"
    
    groupbox:AddDivider()
    
    groupbox:AddButton({
        Text = "Save Config",
        Func = function()
            self:SaveConfig(configName)
        end
    })
    
    groupbox:AddButton({
        Text = "Load Config",
        Func = function()
            self:LoadConfig(configName)
        end
    })
    
    groupbox:AddButton({
        Text = "Delete Config",
        Func = function()
            self:DeleteConfig(configName)
        end
    })
    
    groupbox:AddDivider()
    
    groupbox:AddButton({
        Text = "Refresh Configs",
        Func = function()
            self:RefreshConfigList()
        end
    })
end

return SaveManager
