-- Obelius UI Library - LinoriaLib Compatible API
-- Main Library Module

local Library = {
    Version = "2.0.0",
    Unloaded = false,
    
    -- Services
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    HttpService = game:GetService("HttpService"),
    CoreGui = (function()
        local success, result = pcall(function()
            return game:GetService("CoreGui")
        end)
        if success then return result end
        return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end)(),
    
    -- State
    ToggleKeybind = nil,
    KeybindFrame = nil,
    ScreenGui = nil,
    Windows = {},
    
    -- Configuration
    MenuFadeTime = 0.2,
    
    -- Internal
    _connections = {},
    _unloadCallbacks = {},
}

-- Create global tables
if not getgenv().Toggles then getgenv().Toggles = {} end
if not getgenv().Options then getgenv().Options = {} end

local Toggles = getgenv().Toggles
local Options = getgenv().Options

-- Utility Functions
local function Create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then obj[k] = v end
    end
    if props.Parent then obj.Parent = props.Parent end
    return obj
end

local function Tween(obj, props, duration, callback)
    local tween = Library.TweenService:Create(
        obj,
        TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        props
    )
    tween:Play()
    if callback then tween.Completed:Connect(callback) end
    return tween
end

local function Connect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(Library._connections, conn)
    return conn
end

-- Element Base Class
local Element = {}
Element.__index = Element

function Element:OnChanged(callback)
    table.insert(self._callbacks, callback)
    return self
end

function Element:_FireCallbacks()
    for _, callback in ipairs(self._callbacks) do
        task.spawn(callback, self.Value)
    end
end

function Element:SetValue(value)
    if self.Value ~= value then
        self.Value = value
        self:_FireCallbacks()
        if self.Callback then
            task.spawn(self.Callback, value)
        end
    end
end

function Element:Get()
    return self.Value
end

-- Toggle Element
local Toggle = setmetatable({}, Element)
Toggle.__index = Toggle

function Toggle.new(parent, idx, options)
    local self = setmetatable({
        Type = "Toggle",
        Value = options.Default or false,
        Callback = options.Callback,
        _callbacks = {},
        _parent = parent,
    }, Toggle)
    
    -- Create UI
    local container = Create("Frame", {
        Size = UDim2.new(1, -8, 0, 20),
        BackgroundTransparency = 1,
        Parent = parent._content,
    })
    
    local button = Create("TextButton", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 0, 0, 2),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderColor3 = Color3.fromRGB(60, 60, 60),
        Text = "",
        Parent = container,
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, 3),
        Parent = button,
    })
    
    local checkmark = Create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "✓",
        TextColor3 = Color3.fromRGB(100, 200, 100),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        Visible = self.Value,
        Parent = button,
    })
    
    local label = Create("TextLabel", {
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.new(0, 24, 0, 0),
        BackgroundTransparency = 1,
        Text = options.Text or "Toggle",
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })
    
    button.MouseButton1Click:Connect(function()
        self:SetValue(not self.Value)
        checkmark.Visible = self.Value
        Tween(button, {
            BackgroundColor3 = self.Value and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(30, 30, 30)
        }, 0.1)
    end)
    
    self._ui = container
    self._checkmark = checkmark
    
    -- Register globally
    if idx then Toggles[idx] = self end
    
    return self
end

-- Button Element
local Button = {}
Button.__index = Button

function Button.new(parent, options)
    local self = setmetatable({
        Type = "Button",
        _parent = parent,
        _subButtons = {},
    }, Button)
    
    local container = Create("Frame", {
        Size = UDim2.new(1, -8, 0, 24),
        BackgroundTransparency = 1,
        Parent = parent._content,
    })
    
    local button = Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BorderColor3 = Color3.fromRGB(60, 60, 60),
        Text = options.Text or "Button",
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextSize = 13,
        Font = Enum.Font.Gotham,
        Parent = container,
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = button,
    })
    
    local clickCount = 0
    local lastClick = 0
    
    button.MouseButton1Click:Connect(function()
        if options.DoubleClick then
            local now = tick()
            if now - lastClick < 0.5 then
                clickCount = clickCount + 1
                if clickCount >= 2 then
                    if options.Func then task.spawn(options.Func) end
                    clickCount = 0
                end
            else
                clickCount = 1
            end
            lastClick = now
        else
            if options.Func then task.spawn(options.Func) end
        end
        
        Tween(button, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}, 0.1, function()
            Tween(button, {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}, 0.1)
        end)
    end)
    
    self._ui = container
    self._container = parent._content
    
    return self
end

function Button:AddButton(options)
    local subContainer = Create("Frame", {
        Size = UDim2.new(1, -16, 0, 22),
        BackgroundTransparency = 1,
        Parent = self._container,
    })
    
    local subButton = Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
        BorderColor3 = Color3.fromRGB(55, 55, 55),
        Text = "  " .. (options.Text or "Sub Button"),
        TextColor3 = Color3.fromRGB(180, 180, 180),
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = subContainer,
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = subButton,
    })
    
    local clickCount = 0
    local lastClick = 0
    
    subButton.MouseButton1Click:Connect(function()
        if options.DoubleClick then
            local now = tick()
            if now - lastClick < 0.5 then
                clickCount = clickCount + 1
                if clickCount >= 2 then
                    if options.Func then task.spawn(options.Func) end
                    clickCount = 0
                end
            else
                clickCount = 1
            end
            lastClick = now
        else
            if options.Func then task.spawn(options.Func) end
        end
        
        Tween(subButton, {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}, 0.1, function()
            Tween(subButton, {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}, 0.1)
        end)
    end)
    
    local newButton = {
        _ui = subContainer,
        _container = self._container,
        AddButton = Button.AddButton,
    }
    
    table.insert(self._subButtons, newButton)
    return newButton
end

-- Label Element
local Label = {}
Label.__index = Label

function Label.new(parent, text, wrap)
    local self = setmetatable({
        Type = "Label",
        _parent = parent,
    }, Label)
    
    local label = Create("TextLabel", {
        Size = UDim2.new(1, -8, 0, 14),
        BackgroundTransparency = 1,
        Text = text or "Label",
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = wrap or false,
        Parent = parent._content,
    })
    
    if wrap then
        label.Size = UDim2.new(1, -8, 0, 0)
        label.AutomaticSize = Enum.AutomaticSize.Y
    end
    
    self._ui = label
    return self
end

-- Divider Element
local Divider = {}
Divider.__index = Divider

function Divider.new(parent)
    local divider = Create("Frame", {
        Size = UDim2.new(1, -16, 0, 1),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
        BorderSizePixel = 0,
        Parent = parent._content,
    })
    
    return setmetatable({_ui = divider}, Divider)
end

-- Slider Element
local Slider = setmetatable({}, Element)
Slider.__index = Slider

function Slider.new(parent, idx, options)
    local self = setmetatable({
        Type = "Slider",
        Value = options.Default or options.Min,
        Min = options.Min,
        Max = options.Max,
        Rounding = options.Rounding or 0,
        Suffix = options.Suffix or "",
        Callback = options.Callback,
        _callbacks = {},
        _parent = parent,
    }, Slider)
    
    local height = options.Compact and 20 or 36
    local container = Create("Frame", {
        Size = UDim2.new(1, -8, 0, height),
        BackgroundTransparency = 1,
        Parent = parent._content,
    })
    
    if not options.Compact then
        Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            Text = options.Text or "Slider",
            TextColor3 = Color3.fromRGB(200, 200, 200),
            TextSize = 13,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container,
        })
    end
    
    local sliderBack = Create("Frame", {
        Size = options.Compact and UDim2.new(1, -60, 0, 4) or UDim2.new(1, -60, 0, 4),
        Position = options.Compact and UDim2.new(0, 0, 0.5, -2) or UDim2.new(0, 0, 1, -8),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderSizePixel = 0,
        Parent = container,
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = sliderBack})
    
    local sliderFill = Create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(100, 200, 100),
        BorderSizePixel = 0,
        Parent = sliderBack,
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = sliderFill})
    
    local valueLabel = Create("TextLabel", {
        Size = UDim2.new(0, 55, 1, 0),
        Position = UDim2.new(1, -55, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(self.Value) .. self.Suffix,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = container,
    })
    
    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
        local value = self.Min + (self.Max - self.Min) * pos
        value = math.floor(value * (10 ^ self.Rounding) + 0.5) / (10 ^ self.Rounding)
        
        self:SetValue(value)
        sliderFill.Size = UDim2.new(pos, 0, 1, 0)
        valueLabel.Text = options.HideMax and 
            tostring(value) .. self.Suffix or
            tostring(value) .. " / " .. tostring(self.Max) .. self.Suffix
    end
    
    local dragging = false
    sliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateSlider(input)
        end
    end)
    
    sliderBack.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    Library.UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)
    
    self._ui = container
    
    if idx then Options[idx] = self end
    
    -- Set initial state
    local initialPos = (self.Value - self.Min) / (self.Max - self.Min)
    sliderFill.Size = UDim2.new(initialPos, 0, 1, 0)
    valueLabel.Text = options.HideMax and 
        tostring(self.Value) .. self.Suffix or
        tostring(self.Value) .. " / " .. tostring(self.Max) .. self.Suffix
    
    return self
end

-- Groupbox Class
local Groupbox = {}
Groupbox.__index = Groupbox

function Groupbox.new(parent, name)
    local self = setmetatable({
        _parent = parent,
        _name = name,
    }, Groupbox)
    
    local container = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(45, 45, 45),
        BorderColor3 = Color3.fromRGB(13, 13, 13),
        BorderSizePixel = 1,
        Size = UDim2.new(1, 0, 0, 200),
        Parent = parent,
    })
    
    local title = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, -7),
        Size = UDim2.new(0, 0, 0, 14),
        AutomaticSize = Enum.AutomaticSize.X,
        Font = Enum.Font.Gotham,
        Text = " " .. name .. " ",
        TextColor3 = Color3.fromRGB(205, 205, 205),
        TextSize = 13,
        Parent = container,
    })
    
    local titleBg = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(19, 19, 19),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = title,
        ZIndex = 0,
    })
    
    local scrollFrame = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 4, 0, 8),
        Size = UDim2.new(1, -8, 1, -12),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Color3.fromRGB(65, 65, 65),
        Parent = container,
    })
    
    local layout = Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = scrollFrame,
    })
    
    self._container = container
    self._content = scrollFrame
    self._layout = layout
    
    return self
end

function Groupbox:AddToggle(idx, options)
    return Toggle.new(self, idx, options)
end

function Groupbox:AddButton(options)
    return Button.new(self, options)
end

function Groupbox:AddLabel(text, wrap)
    return Label.new(self, text, wrap)
end

function Groupbox:AddDivider()
    return Divider.new(self)
end

function Groupbox:AddSlider(idx, options)
    return Slider.new(self, idx, options)
end

function Groupbox:AddInput(idx, options)
    local Input = setmetatable({}, Element)
    Input.__index = Input
    
    local self = setmetatable({
        Type = "Input",
        Value = options.Default or "",
        Callback = options.Callback,
        _callbacks = {},
    }, Input)
    
    local container = Create("Frame", {
        Size = UDim2.new(1, -8, 0, 44),
        BackgroundTransparency = 1,
        Parent = parent._content,
    })
    
    Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Text = options.Text or "Input",
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })
    
    local textBox = Create("TextBox", {
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.new(0, 0, 0, 18),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderColor3 = Color3.fromRGB(60, 60, 60),
        Text = self.Value,
        PlaceholderText = options.Placeholder or "",
        TextColor3 = Color3.fromRGB(200, 200, 200),
        PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = container,
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = textBox})
    Create("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = textBox})
    
    if options.Numeric then
        textBox:GetPropertyChangedSignal("Text"):Connect(function()
            textBox.Text = textBox.Text:gsub("[^%d%.%-]", "")
        end)
    end
    
    if options.Finished then
        textBox.FocusLost:Connect(function(enter)
            if enter then
                self:SetValue(textBox.Text)
            end
        end)
    else
        textBox:GetPropertyChangedSignal("Text"):Connect(function()
            self:SetValue(textBox.Text)
        end)
    end
    
    self._ui = container
    if idx then Options[idx] = self end
    return self
end

function Groupbox:AddDropdown(idx, options)
    local Dropdown = setmetatable({}, Element)
    Dropdown.__index = Dropdown
    
    local self = setmetatable({
        Type = "Dropdown",
        Value = options.Multi and {} or (type(options.Default) == "number" and options.Values[options.Default] or options.Default or options.Values[1]),
        Multi = options.Multi or false,
        Values = options.Values or {},
        Callback = options.Callback,
        _callbacks = {},
        _open = false,
    }, Dropdown)
    
    if self.Multi and type(options.Default) == "number" then
        self.Value = {}
        self.Value[options.Values[options.Default]] = true
    end
    
    local container = Create("Frame", {
        Size = UDim2.new(1, -8, 0, 44),
        BackgroundTransparency = 1,
        Parent = parent._content,
    })
    
    Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Text = options.Text or "Dropdown",
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })
    
    local dropdownButton = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.new(0, 0, 0, 18),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderColor3 = Color3.fromRGB(60, 60, 60),
        Text = self.Multi and "..." or tostring(self.Value),
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = dropdownButton})
    Create("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 24), Parent = dropdownButton})
    
    local optionsFrame = Create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 42),
        BackgroundColor3 = Color3.fromRGB(25, 25, 25),
        BorderColor3 = Color3.fromRGB(60, 60, 60),
        Visible = false,
        ClipsDescendants = true,
        ScrollBarThickness = 4,
        ZIndex = 10,
        Parent = container,
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = optionsFrame})
    Create("UIListLayout", {Padding = UDim.new(0, 2), Parent = optionsFrame})
    
    local function updateText()
        if self.Multi then
            local selected = {}
            for k, v in pairs(self.Value) do
                if v then table.insert(selected, k) end
            end
            dropdownButton.Text = #selected > 0 and table.concat(selected, ", ") or "..."
        else
            dropdownButton.Text = tostring(self.Value)
        end
    end
    
    for _, value in ipairs(self.Values) do
        local optButton = Create("TextButton", {
            Size = UDim2.new(1, -4, 0, 20),
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            Text = "  " .. tostring(value),
            TextColor3 = Color3.fromRGB(180, 180, 180),
            TextSize = 12,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = optionsFrame,
        })
        
        Create("UICorner", {CornerRadius = UDim.new(0, 3), Parent = optButton})
        
        optButton.MouseButton1Click:Connect(function()
            if self.Multi then
                self.Value[value] = not self.Value[value]
                optButton.BackgroundColor3 = self.Value[value] and Color3.fromRGB(45, 45, 45) or Color3.fromRGB(30, 30, 30)
                updateText()
                self:_FireCallbacks()
            else
                self:SetValue(value)
                self._open = false
                Tween(optionsFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.15)
                task.delay(0.15, function() optionsFrame.Visible = false end)
                updateText()
            end
        end)
    end
    
    dropdownButton.MouseButton1Click:Connect(function()
        self._open = not self._open
        optionsFrame.Visible = true
        local targetSize = self._open and math.min(#self.Values * 22, 150) or 0
        Tween(optionsFrame, {Size = UDim2.new(1, 0, 0, targetSize)}, 0.15)
        if not self._open then
            task.delay(0.15, function() optionsFrame.Visible = false end)
        end
    end)
    
    self._ui = container
    if idx then Options[idx] = self end
    updateText()
    return self
end

function Groupbox:AddDependencyBox()
    local DependencyBox = {}
    DependencyBox.__index = DependencyBox
    
    local container = Create("Frame", {
        Size = UDim2.new(1, -16, 0, 0),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = parent._content,
    })
    
    local layout = Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        Parent = container,
    })
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        container.Size = UDim2.new(1, -16, 0, layout.AbsoluteContentSize.Y)
    end)
    
    local self = setmetatable({
        _container = container,
        _content = container,
        _dependencies = {},
        AddToggle = Groupbox.AddToggle,
        AddButton = Groupbox.AddButton,
        AddLabel = Groupbox.AddLabel,
        AddDivider = Groupbox.AddDivider,
        AddSlider = Groupbox.AddSlider,
        AddInput = Groupbox.AddInput,
        AddDropdown = Groupbox.AddDropdown,
    }, DependencyBox)
    
    function self:SetupDependencies(dependencies)
        self._dependencies = dependencies
        local function check()
            local allMet = true
            for _, dep in ipairs(dependencies) do
                if dep[1].Value ~= dep[2] then
                    allMet = false
                    break
                end
            end
            container.Visible = allMet
        end
        for _, dep in ipairs(dependencies) do
            dep[1]:OnChanged(check)
        end
        check()
    end
    
    function self:AddDependencyBox()
        return Groupbox.AddDependencyBox(self)
    end
    
    return self
end

-- Label Extensions
function Label:AddColorPicker(idx, options)
    local ColorPicker = setmetatable({}, Element)
    ColorPicker.__index = ColorPicker
    
    local self = setmetatable({
        Type = "ColorPicker",
        Value = options.Default or Color3.new(1, 1, 1),
        Transparency = options.Transparency or 0,
        Callback = options.Callback,
        _callbacks = {},
    }, ColorPicker)
    
    local colorBox = Create("TextButton", {
        Size = UDim2.new(0, 24, 0, 12),
        Position = UDim2.new(1, -28, 0, 1),
        BackgroundColor3 = self.Value,
        BorderColor3 = Color3.fromRGB(60, 60, 60),
        Text = "",
        Parent = parent._ui,
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 3), Parent = colorBox})
    
    colorBox.MouseButton1Click:Connect(function()
        local colors = {
            Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 0, 255),
            Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 0, 255), Color3.fromRGB(0, 255, 255),
        }
        for i, c in ipairs(colors) do
            if self.Value == c then
                self:SetValue(colors[i % #colors + 1])
                colorBox.BackgroundColor3 = self.Value
                return
            end
        end
        self:SetValue(colors[1])
        colorBox.BackgroundColor3 = self.Value
    end)
    
    function self:SetValueRGB(color)
        self:SetValue(color)
        colorBox.BackgroundColor3 = color
    end
    
    self._ui = colorBox
    if idx then Options[idx] = self end
    return self
end

function Label:AddKeyPicker(idx, options)
    local KeyPicker = setmetatable({}, Element)
    KeyPicker.__index = KeyPicker
    
    local self = setmetatable({
        Type = "KeyPicker",
        Value = options.Default or "None",
        Mode = options.Mode or "Toggle",
        Callback = options.Callback,
        ChangedCallback = options.ChangedCallback,
        _callbacks = {},
        _clickCallbacks = {},
        _state = false,
    }, KeyPicker)
    
    local keyButton = Create("TextButton", {
        Size = UDim2.new(0, 50, 0, 12),
        Position = UDim2.new(1, -82, 0, 1),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderColor3 = Color3.fromRGB(60, 60, 60),
        Text = self.Value,
        TextColor3 = Color3.fromRGB(180, 180, 180),
        TextSize = 11,
        Font = Enum.Font.Gotham,
        Parent = parent._ui,
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 3), Parent = keyButton})
    
    local listening = false
    keyButton.MouseButton1Click:Connect(function()
        if not listening then
            listening = true
            keyButton.Text = "..."
            local conn
            conn = Library.UserInputService.InputBegan:Connect(function(input)
                local key = ""
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    key = input.KeyCode.Name
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                    key = "MB1"
                elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                    key = "MB2"
                end
                if key ~= "" then
                    self.Value = key
                    keyButton.Text = key
                    if self.ChangedCallback then task.spawn(self.ChangedCallback, key) end
                    listening = false
                    conn:Disconnect()
                end
            end)
        end
    end)
    
    Connect(Library.UserInputService.InputBegan, function(input)
        if listening then return end
        local key = ""
        if input.UserInputType == Enum.UserInputType.Keyboard then
            key = input.KeyCode.Name
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            key = "MB1"
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            key = "MB2"
        end
        if key == self.Value then
            if self.Mode == "Toggle" then
                self._state = not self._state
                for _, cb in ipairs(self._clickCallbacks) do task.spawn(cb) end
                if self.Callback then task.spawn(self.Callback, self._state) end
            elseif self.Mode == "Hold" then
                self._state = true
                if self.Callback then task.spawn(self.Callback, true) end
            end
        end
    end)
    
    Connect(Library.UserInputService.InputEnded, function(input)
        if self.Mode == "Hold" then
            local key = ""
            if input.UserInputType == Enum.UserInputType.Keyboard then
                key = input.KeyCode.Name
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                key = "MB1"
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                key = "MB2"
            end
            if key == self.Value then
                self._state = false
                if self.Callback then task.spawn(self.Callback, false) end
            end
        end
    end)
    
    function self:OnClick(callback)
        table.insert(self._clickCallbacks, callback)
        return self
    end
    
    function self:GetState()
        return self._state
    end
    
    self._ui = keyButton
    if idx then Options[idx] = self end
    return self
end

-- Tab Class
local Tab = {}
Tab.__index = Tab

function Tab.new(window, name)
    local self = setmetatable({
        _window = window,
        _name = name,
    }, Tab)
    
    -- Tab content container
    local content = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        Parent = window._pageContainer,
    })
    
    -- Left column
    local leftColumn = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -5, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
        Parent = content,
    })
    
    Create("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = leftColumn,
    })
    
    -- Right column
    local rightColumn = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -5, 1, 0),
        Position = UDim2.new(0.5, 5, 0, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
        Parent = content,
    })
    
    Create("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = rightColumn,
    })
    
    self._content = content
    self._leftColumn = leftColumn
    self._rightColumn = rightColumn
    
    return self
end

function Tab:AddLeftGroupbox(name)
    return Groupbox.new(self._leftColumn, name)
end

function Tab:AddRightGroupbox(name)
    return Groupbox.new(self._rightColumn, name)
end

function Tab:AddLeftTabbox()
    return self:_CreateTabbox(self._leftColumn)
end

function Tab:AddRightTabbox()
    return self:_CreateTabbox(self._rightColumn)
end

function Tab:_CreateTabbox(parent)
    local TabBox = {}
    TabBox.__index = TabBox
    
    local container = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(45, 45, 45),
        BorderColor3 = Color3.fromRGB(13, 13, 13),
        BorderSizePixel = 1,
        Size = UDim2.new(1, 0, 0, 300),
        Parent = parent,
    })
    
    local tabButtons = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
        BorderSizePixel = 0,
        Parent = container,
    })
    
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 2),
        Parent = tabButtons,
    })
    
    local contentFrame = Create("Frame", {
        Position = UDim2.new(0, 0, 0, 24),
        Size = UDim2.new(1, 0, 1, -24),
        BackgroundTransparency = 1,
        Parent = container,
    })
    
    local self = setmetatable({
        _container = container,
        _tabButtons = tabButtons,
        _contentFrame = contentFrame,
        _tabs = {},
    }, TabBox)
    
    function self:AddTab(name)
        local tabContent = Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -8, 1, -8),
            Position = UDim2.new(0, 4, 0, 4),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Color3.fromRGB(65, 65, 65),
            Visible = false,
            Parent = contentFrame,
        })
        
        Create("UIListLayout", {
            Padding = UDim.new(0, 5),
            Parent = tabContent,
        })
        
        local tabButton = Create("TextButton", {
            Size = UDim2.new(0, 80, 1, 0),
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            BorderSizePixel = 0,
            Text = name,
            TextColor3 = Color3.fromRGB(180, 180, 180),
            TextSize = 12,
            Font = Enum.Font.Gotham,
            Parent = tabButtons,
        })
        
        local tab = setmetatable({
            _content = tabContent,
            _button = tabButton,
            AddToggle = Groupbox.AddToggle,
            AddButton = Groupbox.AddButton,
            AddLabel = Groupbox.AddLabel,
            AddDivider = Groupbox.AddDivider,
            AddSlider = Groupbox.AddSlider,
            AddInput = Groupbox.AddInput,
            AddDropdown = Groupbox.AddDropdown,
        }, {})
        
        tabButton.MouseButton1Click:Connect(function()
            for _, t in ipairs(self._tabs) do
                t._content.Visible = false
                t._button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            end
            tabContent.Visible = true
            tabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end)
        
        table.insert(self._tabs, tab)
        
        if #self._tabs == 1 then
            tabContent.Visible = true
            tabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end
        
        return tab
    end
    
    return self
end

-- Window Class
local Window = {}
Window.__index = Window

function Library:CreateWindow(options)
    local self = setmetatable({
        _title = options.Title or "Window",
        _tabs = {},
        Tabs = {},
    }, Window)
    
    -- Create ScreenGui
    if not Library.ScreenGui then
        Library.ScreenGui = Create("ScreenGui", {
            Name = "ObeliusLib",
            ZIndexBehavior = Enum.ZIndexBehavior.Global,
            ResetOnSpawn = false,
            Parent = Library.CoreGui,
        })
    end
    
    -- Main window frame
    local main = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(15, 15, 15),
        BorderSizePixel = 0,
        Position = options.Center and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 600, 0, 400),
        Visible = options.AutoShow ~= false,
        Parent = Library.ScreenGui,
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = main})
    
    -- Title bar
    local titleBar = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BorderSizePixel = 0,
        Parent = main,
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = titleBar})
    
    local titleLabel = Create("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = self._title,
        TextColor3 = Color3.fromRGB(220, 220, 220),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar,
    })
    
    -- Tab container
    local tabContainer = Create("Frame", {
        Position = UDim2.new(0, 0, 0, 35),
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = main,
    })
    
    local tabLayout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, options.TabPadding or 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabContainer,
    })
    
    -- Page container
    local pageContainer = Create("Frame", {
        Position = UDim2.new(0, 10, 0, 70),
        Size = UDim2.new(1, -20, 1, -80),
        BackgroundTransparency = 1,
        Parent = main,
    })
    
    self._main = main
    self._tabContainer = tabContainer
    self._pageContainer = pageContainer
    self._tabLayout = tabLayout
    
    table.insert(Library.Windows, self)
    
    return self
end

function Window:AddTab(name)
    local tab = Tab.new(self, name)
    table.insert(self._tabs, tab)
    self.Tabs[name] = tab
    
    -- Create tab button
    local tabButton = Create("TextButton", {
        Size = UDim2.new(0, 100, 1, 0),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        Text = name,
        TextColor3 = Color3.fromRGB(180, 180, 180),
        TextSize = 13,
        Parent = self._tabContainer,
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = tabButton})
    
    tabButton.MouseButton1Click:Connect(function()
        -- Hide all tabs
        for _, t in ipairs(self._tabs) do
            t._content.Visible = false
        end
        -- Show this tab
        tab._content.Visible = true
        
        -- Update button colors
        for _, button in ipairs(self._tabContainer:GetChildren()) do
            if button:IsA("TextButton") then
                button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                button.TextColor3 = Color3.fromRGB(180, 180, 180)
            end
        end
        tabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        tabButton.TextColor3 = Color3.fromRGB(220, 220, 220)
    end)
    
    -- Auto-show first tab
    if #self._tabs == 1 then
        tab._content.Visible = true
        tabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        tabButton.TextColor3 = Color3.fromRGB(220, 220, 220)
    end
    
    return tab
end

-- Library Management Functions
function Library:SetWatermarkVisibility(visible)
    if self._watermark then
        self._watermark.Visible = visible
    elseif visible then
        self:_CreateWatermark()
    end
end

function Library:SetWatermark(text)
    if not self._watermark then
        self:_CreateWatermark()
    end
    self._watermarkText.Text = text
end

function Library:_CreateWatermark()
    if self._watermark then return end
    
    local watermark = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 10),
        Size = UDim2.new(0, 200, 0, 20),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BorderColor3 = Color3.fromRGB(60, 60, 60),
        Parent = self.ScreenGui,
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = watermark})
    
    local text = Create("TextLabel", {
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Text = "Watermark",
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = watermark,
    })
    
    text:GetPropertyChangedSignal("TextBounds"):Connect(function()
        watermark.Size = UDim2.new(0, text.TextBounds.X + 20, 0, 20)
    end)
    
    self._watermark = watermark
    self._watermarkText = text
end

function Library:_CreateKeybindFrame()
    if self.KeybindFrame then return end
    
    local frame = Create("Frame", {
        Position = UDim2.new(1, -210, 0, 10),
        Size = UDim2.new(0, 200, 0, 200),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BorderColor3 = Color3.fromRGB(60, 60, 60),
        Visible = false,
        Parent = self.ScreenGui,
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = frame})
    
    local title = Create("TextLabel", {
        Size = UDim2.new(1, -10, 0, 20),
        Position = UDim2.new(0, 5, 0, 5),
        BackgroundTransparency = 1,
        Text = "Keybinds",
        TextColor3 = Color3.fromRGB(220, 220, 220),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })
    
    local list = Create("ScrollingFrame", {
        Position = UDim2.new(0, 5, 0, 30),
        Size = UDim2.new(1, -10, 1, -35),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        Parent = frame,
    })
    
    Create("UIListLayout", {
        Padding = UDim.new(0, 3),
        Parent = list,
    })
    
    self.KeybindFrame = frame
end

function Library:OnUnload(callback)
    table.insert(self._unloadCallbacks, callback)
end

function Library:Unload()
    self.Unloaded = true
    
    for _, callback in ipairs(self._unloadCallbacks) do
        task.spawn(callback)
    end
    
    for _, conn in ipairs(self._connections) do
        conn:Disconnect()
    end
    
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

return Library
