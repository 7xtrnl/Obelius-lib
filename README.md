# Obelius UI Library

A modern, lightweight Roblox UI library with LinoriaLib-compatible API. Create beautiful, feature-rich interfaces with minimal code.

## Features

- 🎨 **Clean Modern Design** - Dark theme with smooth animations
- 📦 **Modular Architecture** - Load only what you need
- 🔧 **Full Element Support** - Toggles, Sliders, Dropdowns, ColorPickers, KeyPickers, and more
- 💾 **Config System** - Save/Load configurations easily
- 🎨 **Theme Manager** - Multiple built-in themes
- 🔗 **LinoriaLib Compatible** - Familiar API for easy migration
- 📱 **Lightweight** - Optimized for performance

## Installation

### Via HTTP (Recommended)

```lua
local repo = 'https://raw.githubusercontent.com/YOUR_USERNAME/ObeliusLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
```

## Quick Start

```lua
-- Create Window
local Window = Library:CreateWindow({
    Title = 'My Script',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Create Tabs
local Tabs = {
    Main = Window:AddTab('Main'),
    Settings = Window:AddTab('Settings'),
}

-- Add Elements
local LeftGroupBox = Tabs.Main:AddLeftGroupbox('Features')

-- Toggle
LeftGroupBox:AddToggle('MyToggle', {
    Text = 'Enable Feature',
    Default = false,
    Callback = function(Value)
        print('Toggle:', Value)
    end
})

-- Access via global tables
Toggles.MyToggle:OnChanged(function()
    print('New value:', Toggles.MyToggle.Value)
end)

-- Slider
LeftGroupBox:AddSlider('MySlider', {
    Text = 'Speed',
    Default = 16,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        print('Speed:', Value)
    end
})

-- Input/TextBox
LeftGroupBox:AddInput('MyInput', {
    Default = '',
    Numeric = false,
    Finished = false,
    Text = 'Username',
    Placeholder = 'Enter name...',
})

-- Dropdown
LeftGroupBox:AddDropdown('MyDropdown', {
    Values = { 'Option 1', 'Option 2', 'Option 3' },
    Default = 1,
    Multi = false,
    Text = 'Select Option',
})

-- Button
LeftGroupBox:AddButton({
    Text = 'Click Me',
    Func = function()
        print('Clicked!')
    end
})

-- ColorPicker (attached to label)
LeftGroupBox:AddLabel('Color'):AddColorPicker('MyColor', {
    Default = Color3.new(1, 0, 0),
    Title = 'Choose Color',
})

-- KeyPicker (attached to label)
LeftGroupBox:AddLabel('Keybind'):AddKeyPicker('MyKey', {
    Default = 'E',
    Mode = 'Toggle',
    Text = 'Activate',
})
```

## Available Elements

### Basic Elements
- **Toggle** - Checkbox with on/off state
- **Button** - Clickable button (supports sub-buttons)
- **Label** - Text label (supports text wrapping)
- **Divider** - Visual separator line
- **Slider** - Value slider with min/max range
- **Input** - Text input box (supports numeric only)
- **Dropdown** - Single or multi-select dropdown

### Advanced Elements
- **ColorPicker** - Color selection (attachable to labels)
- **KeyPicker** - Keybind selector (attachable to labels)
- **TabBox** - Tabbed container within groupbox
- **DependencyBox** - Show/hide elements based on other values

## Groupboxes and Layout

```lua
-- Left/Right Groupboxes
local Left = Tab:AddLeftGroupbox('Left Side')
local Right = Tab:AddRightGroupbox('Right Side')

-- TabBox (tabs within groupbox)
local TabBox = Tab:AddLeftTabbox()
local Tab1 = TabBox:AddTab('Tab 1')
local Tab2 = TabBox:AddTab('Tab 2')
-- Now add elements to Tab1 or Tab2

-- Dependency Box (conditional visibility)
local Depbox = Groupbox:AddDependencyBox()
Depbox:AddToggle('SubToggle', { Text = 'Sub Feature' })
Depbox:SetupDependencies({
    { Toggles.MasterToggle, true } -- Show only when MasterToggle is true
})
```

## Global Access

All elements are accessible via global tables:

```lua
-- Toggles
getgenv().Toggles.MyToggle.Value -- true/false
Toggles.MyToggle:SetValue(true)

-- Options (everything else)
getgenv().Options.MySlider.Value -- number
getgenv().Options.MyDropdown.Value -- string or table
Options.MyColor.Value -- Color3
```

## Configuration System

```lua
-- Setup managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

-- Ignore theme settings in configs
SaveManager:IgnoreThemeSettings()

-- Ignore specific indexes
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

-- Set folders
ThemeManager:SetFolder('MyScript')
SaveManager:SetFolder('MyScript/GameName')

-- Add UI to settings tab
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

-- Autoload
SaveManager:LoadAutoloadConfig()
```

## Watermark

```lua
Library:SetWatermarkVisibility(true)

-- Dynamic watermark
game:GetService('RunService').RenderStepped:Connect(function()
    Library:SetWatermark(('My Script | %s fps'):format(math.floor(FPS)))
end)
```

## Cleanup

```lua
Library:OnUnload(function()
    print('Cleaning up...')
    -- Your cleanup code here
end)

-- To unload
Library:Unload()
```

## Element Options Reference

### Toggle
```lua
{
    Text = string,
    Default = boolean,
    Tooltip = string,
    Callback = function(Value)
}
```

### Slider
```lua
{
    Text = string,
    Default = number,
    Min = number,
    Max = number,
    Rounding = number, -- decimal places
    Suffix = string,   -- e.g., " studs"
    Compact = boolean, -- hide title
    HideMax = boolean, -- show only value
    Callback = function(Value)
}
```

### Input
```lua
{
    Default = string,
    Numeric = boolean, -- only allow numbers
    Finished = boolean, -- callback on enter only
    Text = string,
    Placeholder = string,
    Tooltip = string,
    Callback = function(Value)
}
```

### Dropdown
```lua
{
    Values = table,
    Default = number | string,
    Multi = boolean,
    Text = string,
    Tooltip = string,
    Callback = function(Value)
}
```

### Button
```lua
{
    Text = string,
    Func = function(),
    DoubleClick = boolean,
    Tooltip = string
}
```

### ColorPicker
```lua
{
    Default = Color3,
    Title = string,
    Transparency = number,
    Callback = function(Value)
}
```

### KeyPicker
```lua
{
    Default = string, -- "E", "MB1", "MB2", etc.
    Mode = string,    -- "Toggle", "Hold", "Always"
    Text = string,
    NoUI = boolean,
    SyncToggleState = boolean,
    Callback = function(Value),
    ChangedCallback = function(New)
}
```

## Contributing

Contributions are welcome! Please feel free to submit pull requests.

## License

MIT License - Feel free to use in your projects!

## Credits

- Inspired by LinoriaLib
- Created for the Roblox scripting community

---

**Made with ❤️ for Roblox scripters**
