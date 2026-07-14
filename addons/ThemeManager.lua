-- Obelius Theme Manager Addon
local ThemeManager = {
    Library = nil,
    Folder = "ObeliusLib",
    BuiltInThemes = {
        ["Default"] = {
            Accent = Color3.fromRGB(170, 85, 235),
        },
        ["Green"] = {
            Accent = Color3.fromRGB(76, 175, 80),
        },
        ["Blue"] = {
            Accent = Color3.fromRGB(33, 150, 243),
        },
        ["Red"] = {
            Accent = Color3.fromRGB(244, 67, 54),
        },
        ["Orange"] = {
            Accent = Color3.fromRGB(255, 152, 0),
        },
        ["Purple"] = {
            Accent = Color3.fromRGB(156, 39, 176),
        },
        ["Cyan"] = {
            Accent = Color3.fromRGB(0, 188, 212),
        },
        ["Pink"] = {
            Accent = Color3.fromRGB(233, 30, 99),
        },
    }
}

function ThemeManager:SetLibrary(library)
    self.Library = library
end

function ThemeManager:SetFolder(folder)
    self.Folder = folder
end

function ThemeManager:ApplyTheme(themeName)
    local theme = self.BuiltInThemes[themeName]
    if not theme then return end
    
    -- Apply theme to library (placeholder for actual implementation)
    if self.Library then
        -- TODO: Apply accent color to all UI elements
    end
end

function ThemeManager:ApplyToTab(tab)
    -- Create theme selection UI in the tab
    local groupbox = tab:AddLeftGroupbox("Themes")
    
    groupbox:AddLabel("Built-in Themes")
    
    for themeName, _ in pairs(self.BuiltInThemes) do
        groupbox:AddButton({
            Text = themeName,
            Func = function()
                self:ApplyTheme(themeName)
            end
        })
    end
end

function ThemeManager:ApplyToGroupbox(groupbox)
    -- Apply theme selector to specific groupbox
    for themeName, _ in pairs(self.BuiltInThemes) do
        groupbox:AddButton({
            Text = themeName,
            Func = function()
                self:ApplyTheme(themeName)
            end
        })
    end
end

return ThemeManager
