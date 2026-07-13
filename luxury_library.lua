--[[
    Fluent UI Roblox Library - V1.0.5
    An ultra-premium, Windows Fluent-inspired UI framework for Roblox.
    Features dynamic absolute dropdown tracking, drag-to-resize window support,
    integrated settings overlay dialog (keybind toggle, size reset), user profile card,
    clean focus-based outline borders, and smooth tab transitions.
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Library = {
    Themes = {
        Gold = {
            Background = Color3.fromRGB(32, 32, 32), -- Fluent Mica Dark
            Secondary = Color3.fromRGB(26, 26, 26),
            Surface = Color3.fromRGB(45, 45, 45),
            Border = Color3.fromRGB(60, 60, 60),
            Accent = Color3.fromRGB(212, 175, 55), -- Luxury Gold
            AccentHover = Color3.fromRGB(245, 215, 110),
            Text = Color3.fromRGB(245, 245, 245),
            TextDark = Color3.fromRGB(160, 160, 160),
            TextDim = Color3.fromRGB(110, 110, 110)
        },
        Indigo = {
            Background = Color3.fromRGB(30, 30, 35),
            Secondary = Color3.fromRGB(24, 24, 28),
            Surface = Color3.fromRGB(42, 42, 50),
            Border = Color3.fromRGB(55, 55, 70),
            Accent = Color3.fromRGB(124, 77, 255), -- Windows Violet
            AccentHover = Color3.fromRGB(179, 136, 255),
            Text = Color3.fromRGB(245, 245, 250),
            TextDark = Color3.fromRGB(160, 160, 175),
            TextDim = Color3.fromRGB(110, 110, 130)
        }
    },
    CurrentTheme = nil,
    WindowCount = 0,
    Toggled = true,
    Keybind = Enum.KeyCode.LeftControl, -- Default is LeftControl
    IsBinding = false,
    Gui = nil
}

-- Utility Functions
local function Tween(object, duration, properties, style, direction)
    local tweenInfo = TweenInfo.new(
        duration or 0.2,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

local function MakeDraggable(dragFrame, parentFrame)
    local dragging = false
    local dragInput, dragStart, startPos

    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = parentFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            parentFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ScreenGui Setup
function Library:InitGui()
    if self.Gui then return self.Gui end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FluentUI_" .. tostring(math.random(100000, 999999))
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 9999

    local success, _ = pcall(function()
        screenGui.Parent = CoreGui
    end)
    if not success then
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    self.Gui = screenGui

    -- Listen for toggle keybind
    UserInputService.InputBegan:Connect(function(input, processed)
        if self.IsBinding then return end
        if not processed and input.KeyCode == self.Keybind then
            self:Toggle()
        end
    end)

    return screenGui
end

function Library:Toggle()
    self.Toggled = not self.Toggled
    if self.Gui then
        for _, child in ipairs(self.Gui:GetChildren()) do
            if child:IsA("Frame") and child.Name == "MainFrame" then
                if self.Toggled then
                    child.Visible = true
                    Tween(child, 0.35, {Size = UDim2.new(0, child:GetAttribute("TargetWidth") or 650, 0, child:GetAttribute("TargetHeight") or 450)}, Enum.EasingStyle.Back)
                else
                    -- Fixed auto-resize spam bug: Do NOT save TargetWidth/Height dynamically inside toggle to prevent tween value corruption
                    local tween = Tween(child, 0.2, {Size = UDim2.new(0, child.AbsoluteSize.X, 0, 0)})
                    tween.Completed:Connect(function()
                        if not self.Toggled then
                            child.Visible = false
                        end
                    end)
                end
            end
        end
    end
end

-- Toast Notification System
function Library:Notify(options)
    local title = options.Title or "Notification"
    local content = options.Content or ""
    local duration = options.Duration or 4
    local icon = options.Icon or "rbxassetid://7072721666"

    local gui = self:InitGui()
    local theme = self.CurrentTheme or self.Themes.Gold

    local container = gui:FindFirstChild("NotificationContainer")
    if not container then
        container = Instance.new("Frame")
        container.Name = "NotificationContainer"
        container.Size = UDim2.new(0, 300, 1, -40)
        container.Position = UDim2.new(1, -320, 0, 20)
        container.BackgroundTransparency = 1
        container.Parent = gui

        local listLayout = Instance.new("UIListLayout")
        listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 10)
        listLayout.Parent = container
    end

    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(1, 0, 0, 70)
    toast.BackgroundColor3 = theme.Secondary
    toast.BorderSizePixel = 0
    toast.Position = UDim2.new(1, 10, 0, 0)
    toast.Parent = container

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = toast

    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = theme.Border
    uiStroke.Thickness = 1
    uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uiStroke.Parent = toast

    local accentStripe = Instance.new("Frame")
    accentStripe.Size = UDim2.new(0, 3, 0.4, 0)
    accentStripe.Position = UDim2.new(0, 3, 0.3, 0)
    accentStripe.BackgroundColor3 = theme.Accent
    accentStripe.BorderSizePixel = 0
    accentStripe.Parent = toast

    local stripeCorner = Instance.new("UICorner")
    stripeCorner.CornerRadius = UDim.new(0, 2)
    stripeCorner.Parent = accentStripe

    local imgIcon = Instance.new("ImageLabel")
    imgIcon.Size = UDim2.new(0, 20, 0, 20)
    imgIcon.Position = UDim2.new(0, 18, 0.5, -10)
    imgIcon.BackgroundTransparency = 1
    imgIcon.Image = icon
    imgIcon.ImageColor3 = theme.Accent
    imgIcon.Parent = toast

    local lblTitle = Instance.new("TextLabel")
    lblTitle.Size = UDim2.new(1, -60, 0, 20)
    lblTitle.Position = UDim2.new(0, 48, 0, 12)
    lblTitle.BackgroundTransparency = 1
    lblTitle.Font = Enum.Font.GothamBold
    lblTitle.TextSize = 13
    lblTitle.TextColor3 = theme.Text
    lblTitle.TextXAlignment = Enum.TextXAlignment.Left
    lblTitle.Text = title
    lblTitle.Parent = toast

    local lblContent = Instance.new("TextLabel")
    lblContent.Size = UDim2.new(1, -60, 0, 28)
    lblContent.Position = UDim2.new(0, 48, 0, 30)
    lblContent.BackgroundTransparency = 1
    lblContent.Font = Enum.Font.Gotham
    lblContent.TextSize = 11
    lblContent.TextColor3 = theme.TextDark
    lblContent.TextXAlignment = Enum.TextXAlignment.Left
    lblContent.TextYAlignment = Enum.TextYAlignment.Top
    lblContent.TextWrapped = true
    lblContent.Text = content
    lblContent.Parent = toast

    toast.Size = UDim2.new(1, 0, 0, 70)
    toast.BackgroundTransparency = 1
    uiStroke.Transparency = 1
    imgIcon.ImageTransparency = 1
    lblTitle.TextTransparency = 1
    lblContent.TextTransparency = 1
    accentStripe.BackgroundTransparency = 1

    Tween(toast, 0.25, {Size = UDim2.new(1, 0, 0, 70), BackgroundTransparency = 0.05})
    Tween(uiStroke, 0.25, {Transparency = 0})
    Tween(accentStripe, 0.25, {BackgroundTransparency = 0})
    Tween(imgIcon, 0.25, {ImageTransparency = 0})
    Tween(lblTitle, 0.25, {TextTransparency = 0})
    Tween(lblContent, 0.25, {TextTransparency = 0})

    task.spawn(function()
        task.wait(duration)
        Tween(toast, 0.25, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1})
        Tween(uiStroke, 0.25, {Transparency = 1})
        Tween(accentStripe, 0.25, {BackgroundTransparency = 1})
        Tween(imgIcon, 0.25, {ImageTransparency = 1})
        Tween(lblTitle, 0.25, {TextTransparency = 1})
        local fadeOut = Tween(lblContent, 0.25, {TextTransparency = 1})
        fadeOut.Completed:Connect(function()
            toast:Destroy()
        end)
    end)
end

-- Create Window function
function Library:CreateWindow(config)
    config = config or {}
    local winName = config.Name or "Fluent Hub"
    local selectedTheme = config.Theme or "Gold"
    local defaultWidth = config.Width or 650
    local defaultHeight = config.Height or 450
    
    local theme = self.Themes[selectedTheme] or self.Themes.Gold
    self.CurrentTheme = theme

    local gui = self:InitGui()
    self.WindowCount = self.WindowCount + 1

    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, defaultWidth, 0, 0) -- Start compressed for intro animation
    mainFrame.Position = UDim2.new(0.5, -defaultWidth/2, 0.5, -defaultHeight/2)
    mainFrame.BackgroundColor3 = theme.Background
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = gui

    mainFrame:SetAttribute("TargetWidth", defaultWidth)
    mainFrame:SetAttribute("TargetHeight", defaultHeight)

    local dragPanel = Instance.new("Frame")
    dragPanel.Name = "DragPanel"
    dragPanel.Size = UDim2.new(1, 0, 0, 45)
    dragPanel.BackgroundTransparency = 1
    dragPanel.ZIndex = 5
    dragPanel.Parent = mainFrame
    MakeDraggable(dragPanel, mainFrame)

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 8)
    frameCorner.Parent = mainFrame

    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = theme.Border
    frameStroke.Thickness = 1
    frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    frameStroke.Parent = mainFrame

    -- Drag-to-Resize Grip Handle
    local resizeGrip = Instance.new("ImageButton")
    resizeGrip.Name = "ResizeGrip"
    resizeGrip.Size = UDim2.new(0, 16, 0, 16)
    resizeGrip.Position = UDim2.new(1, -16, 1, -16)
    resizeGrip.BackgroundTransparency = 1
    resizeGrip.Image = "rbxassetid://5061617260" -- Diagonal grid resize icon
    resizeGrip.ImageColor3 = theme.TextDim
    resizeGrip.ZIndex = 1000
    resizeGrip.Parent = mainFrame

    local resizing = false
    local resizeStartPos
    local resizeStartSize

    resizeGrip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStartPos = input.Position
            resizeStartSize = Vector2.new(mainFrame.AbsoluteSize.X, mainFrame.AbsoluteSize.Y)

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStartPos
            local newWidth = math.clamp(resizeStartSize.X + delta.X, 500, 850)
            local newHeight = math.clamp(resizeStartSize.Y + delta.Y, 350, 650)
            mainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
            mainFrame:SetAttribute("TargetWidth", newWidth)
            mainFrame:SetAttribute("TargetHeight", newHeight)
        end
    end)

    -- Entrance Animation
    Tween(mainFrame, 0.5, {Size = UDim2.new(0, defaultWidth, 0, defaultHeight)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- Left Sidebar (Navigation)
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 160, 1, 0)
    sidebar.BackgroundColor3 = theme.Secondary
    sidebar.BackgroundTransparency = 0.15
    sidebar.BorderSizePixel = 0
    sidebar.Parent = mainFrame

    local sidebarCorner = Instance.new("UICorner")
    sidebarCorner.CornerRadius = UDim.new(0, 8)
    sidebarCorner.Parent = sidebar

    local separator = Instance.new("Frame")
    separator.Size = UDim2.new(0, 1, 1, 0)
    separator.Position = UDim2.new(0, 160, 0, 0)
    separator.BackgroundColor3 = theme.Border
    separator.BorderSizePixel = 0
    separator.Parent = mainFrame

    -- Brand/Logo
    local brandContainer = Instance.new("Frame")
    brandContainer.Size = UDim2.new(1, 0, 0, 60)
    brandContainer.BackgroundTransparency = 1
    brandContainer.Parent = sidebar

    local lblLogo = Instance.new("TextLabel")
    lblLogo.Size = UDim2.new(1, -20, 1, 0)
    lblLogo.Position = UDim2.new(0, 16, 0, 0)
    lblLogo.BackgroundTransparency = 1
    lblLogo.Font = Enum.Font.GothamBold
    lblLogo.TextSize = 14
    lblLogo.TextColor3 = theme.Text
    lblLogo.TextXAlignment = Enum.TextXAlignment.Left
    lblLogo.Text = winName
    lblLogo.Parent = brandContainer

    -- Sidebar Scroll Container for tabs
    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.Size = UDim2.new(1, -12, 1, -135)
    tabScroll.Position = UDim2.new(0, 6, 0, 60)
    tabScroll.BackgroundTransparency = 1
    tabScroll.BorderSizePixel = 0
    tabScroll.ScrollBarThickness = 0
    tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabScroll.Parent = sidebar

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 3)
    tabLayout.Parent = tabScroll

    -- Unified User Profile & Settings Section (Bottom Left Sidebar)
    local profileCard = Instance.new("Frame")
    profileCard.Name = "UserProfileCard"
    profileCard.Size = UDim2.new(1, -12, 0, 48) -- Full width card containing both Profile & Settings button
    profileCard.Position = UDim2.new(0, 6, 1, -56)
    profileCard.BackgroundColor3 = theme.Surface
    profileCard.BackgroundTransparency = 0.4
    profileCard.BorderSizePixel = 0
    profileCard.Parent = sidebar

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 6)
    cardCorner.Parent = profileCard

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = theme.Border
    cardStroke.Thickness = 1
    cardStroke.Parent = profileCard

    local avatarImage = Instance.new("ImageLabel")
    avatarImage.Size = UDim2.new(0, 32, 0, 32)
    avatarImage.Position = UDim2.new(0, 8, 0.5, -16)
    avatarImage.BackgroundColor3 = theme.Secondary
    avatarImage.BorderSizePixel = 0
    avatarImage.Parent = profileCard

    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(0, 16)
    avatarCorner.Parent = avatarImage

    -- Fetch Roblox Avatar Thumbnail
    task.spawn(function()
        local success, thumb = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        end)
        if success then
            avatarImage.Image = thumb
        else
            avatarImage.Image = "rbxassetid://10888373307"
        end
    end)

    local lblDisplayName = Instance.new("TextLabel")
    lblDisplayName.Size = UDim2.new(1, -74, 0, 16) -- Narrowed width to leave space for settings gear icon inside profileCard
    lblDisplayName.Position = UDim2.new(0, 46, 0.5, -15)
    lblDisplayName.BackgroundTransparency = 1
    lblDisplayName.Font = Enum.Font.GothamBold
    lblDisplayName.TextSize = 10
    lblDisplayName.TextColor3 = theme.Text
    lblDisplayName.TextXAlignment = Enum.TextXAlignment.Left
    lblDisplayName.Text = LocalPlayer.DisplayName
    lblDisplayName.Parent = profileCard

    local lblUsername = Instance.new("TextLabel")
    lblUsername.Size = UDim2.new(1, -74, 0, 12)
    lblUsername.Position = UDim2.new(0, 46, 0.5, 2)
    lblUsername.BackgroundTransparency = 1
    lblUsername.Font = Enum.Font.Gotham
    lblUsername.TextSize = 8
    lblUsername.TextColor3 = theme.TextDim
    lblUsername.TextXAlignment = Enum.TextXAlignment.Left
    lblUsername.Text = "@" .. LocalPlayer.Name
    lblUsername.Parent = profileCard

    -- Settings Gear Icon unified inside the Profile Card
    local settingsBtn = Instance.new("TextButton")
    settingsBtn.Name = "SettingsButton"
    settingsBtn.Size = UDim2.new(0, 24, 0, 24)
    settingsBtn.Position = UDim2.new(1, -30, 0.5, -12) -- Aligned on far right of the card
    settingsBtn.BackgroundTransparency = 1
    settingsBtn.BorderSizePixel = 0
    settingsBtn.Text = ""
    settingsBtn.Parent = profileCard

    local settingsIcon = Instance.new("ImageLabel")
    settingsIcon.Size = UDim2.new(0, 16, 0, 16)
    settingsIcon.Position = UDim2.new(0.5, -8, 0.5, -8)
    settingsIcon.BackgroundTransparency = 1
    settingsIcon.Image = "rbxassetid://7072721666" -- Public Settings Gear Icon
    settingsIcon.ImageColor3 = theme.TextDark
    settingsIcon.Parent = settingsBtn

    -- Settings Overlay Dialog Panel (Frame with Active = true to sink clicks without flashing)
    local settingsBackdrop = Instance.new("Frame")
    settingsBackdrop.Name = "SettingsBackdrop"
    settingsBackdrop.Size = UDim2.new(1, 0, 1, 0)
    settingsBackdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    settingsBackdrop.BackgroundTransparency = 1
    settingsBackdrop.Active = true -- blocks mouse click through
    settingsBackdrop.ZIndex = 800
    settingsBackdrop.Visible = false
    settingsBackdrop.Parent = gui

    local settingsFrame = Instance.new("Frame")
    settingsFrame.Size = UDim2.new(0, 320, 0, 220)
    settingsFrame.Position = UDim2.new(0.5, -160, 0.5, -110)
    settingsFrame.BackgroundColor3 = theme.Background
    settingsFrame.BorderSizePixel = 0
    settingsFrame.ZIndex = 801
    settingsFrame.Parent = settingsBackdrop

    local sfCorner = Instance.new("UICorner")
    sfCorner.CornerRadius = UDim.new(0, 8)
    sfCorner.Parent = settingsFrame

    local sfStroke = Instance.new("UIStroke")
    sfStroke.Color = theme.Border
    sfStroke.Thickness = 1
    sfStroke.Parent = settingsFrame

    local sfTitle = Instance.new("TextLabel")
    sfTitle.Size = UDim2.new(1, -24, 0, 40)
    sfTitle.Position = UDim2.new(0, 12, 0, 10)
    sfTitle.BackgroundTransparency = 1
    sfTitle.Font = Enum.Font.GothamBold
    sfTitle.TextSize = 14
    sfTitle.TextColor3 = theme.Text
    sfTitle.TextXAlignment = Enum.TextXAlignment.Left
    sfTitle.Text = "Interface Settings"
    sfTitle.ZIndex = 802
    sfTitle.Parent = settingsFrame

    -- Config option 1: Toggle Keybind
    local kbRow = Instance.new("Frame")
    kbRow.Size = UDim2.new(1, -24, 0, 36)
    kbRow.Position = UDim2.new(0, 12, 0, 50)
    kbRow.BackgroundTransparency = 1
    kbRow.ZIndex = 802
    kbRow.Parent = settingsFrame

    local kbLabel = Instance.new("TextLabel")
    kbLabel.Size = UDim2.new(1, -120, 1, 0)
    kbLabel.BackgroundTransparency = 1
    kbLabel.Font = Enum.Font.Gotham
    kbLabel.TextSize = 12
    kbLabel.TextColor3 = theme.Text
    kbLabel.TextXAlignment = Enum.TextXAlignment.Left
    kbLabel.Text = "Toggle Menu Key"
    kbLabel.ZIndex = 802
    kbLabel.Parent = kbRow

    local kbBtn = Instance.new("TextButton")
    kbBtn.Size = UDim2.new(0, 100, 0, 26)
    kbBtn.Position = UDim2.new(1, -100, 0.5, -13)
    kbBtn.BackgroundColor3 = theme.Surface
    kbBtn.Font = Enum.Font.GothamBold
    kbBtn.TextColor3 = theme.Accent
    kbBtn.TextSize = 10
    kbBtn.Text = Library.Keybind.Name
    kbBtn.ZIndex = 802
    kbBtn.Parent = kbRow

    local kbBtnCorner = Instance.new("UICorner")
    kbBtnCorner.CornerRadius = UDim.new(0, 4)
    kbBtnCorner.Parent = kbBtn

    local kbBtnStroke = Instance.new("UIStroke")
    kbBtnStroke.Color = theme.Border
    kbBtnStroke.Thickness = 1
    kbBtnStroke.Parent = kbBtn

    local bindingSettings = false
    kbBtn.MouseButton1Click:Connect(function()
        if not bindingSettings then
            bindingSettings = true
            Library.IsBinding = true
            kbBtn.Text = "..."
            Tween(kbBtnStroke, 0.1, {Color = theme.Accent})
        end
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if bindingSettings and not processed then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                bindingSettings = false
                task.defer(function()
                    Library.IsBinding = false
                end)
                Library.Keybind = input.KeyCode
                kbBtn.Text = input.KeyCode.Name
                Tween(kbBtnStroke, 0.1, {Color = theme.Border})
            end
        end
    end)

    -- Config option 2: Reset Window Size
    local sizeRow = Instance.new("Frame")
    sizeRow.Size = UDim2.new(1, -24, 0, 36)
    sizeRow.Position = UDim2.new(0, 12, 0, 95)
    sizeRow.BackgroundTransparency = 1
    sizeRow.ZIndex = 802
    sizeRow.Parent = settingsFrame

    local sizeLabel = Instance.new("TextLabel")
    sizeLabel.Size = UDim2.new(1, -120, 1, 0)
    sizeLabel.BackgroundTransparency = 1
    sizeLabel.Font = Enum.Font.Gotham
    sizeLabel.TextSize = 12
    sizeLabel.TextColor3 = theme.Text
    sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
    sizeLabel.Text = "Reset Window Size"
    sizeLabel.ZIndex = 802
    sizeLabel.Parent = sizeRow

    local sizeBtn = Instance.new("TextButton")
    sizeBtn.Size = UDim2.new(0, 100, 0, 26)
    sizeBtn.Position = UDim2.new(1, -100, 0.5, -13)
    sizeBtn.BackgroundColor3 = theme.Surface
    sizeBtn.Font = Enum.Font.GothamBold
    sizeBtn.TextColor3 = theme.Text
    sizeBtn.TextSize = 10
    sizeBtn.Text = "Reset"
    sizeBtn.ZIndex = 802
    sizeBtn.Parent = sizeRow

    local sizeBtnCorner = Instance.new("UICorner")
    sizeBtnCorner.CornerRadius = UDim.new(0, 4)
    sizeBtnCorner.Parent = sizeBtn

    local sizeBtnStroke = Instance.new("UIStroke")
    sizeBtnStroke.Color = theme.Border
    sizeBtnStroke.Thickness = 1
    sizeBtnStroke.Parent = sizeBtn

    sizeBtn.MouseButton1Click:Connect(function()
        mainFrame:SetAttribute("TargetWidth", defaultWidth)
        mainFrame:SetAttribute("TargetHeight", defaultHeight)
        Tween(mainFrame, 0.3, {Size = UDim2.new(0, defaultWidth, 0, defaultHeight)})
        Library:Notify({
            Title = "Settings Manager",
            Content = "Window size reset to default.",
            Duration = 3,
            Icon = "rbxassetid://7072721666"
        })
    end)

    -- Close Settings Button
    local closeSettingsBtn = Instance.new("TextButton")
    closeSettingsBtn.Size = UDim2.new(1, -24, 0, 32)
    closeSettingsBtn.Position = UDim2.new(0, 12, 1, -44)
    closeSettingsBtn.BackgroundColor3 = theme.Surface
    closeSettingsBtn.Font = Enum.Font.GothamBold
    closeSettingsBtn.TextColor3 = theme.Text
    closeSettingsBtn.TextSize = 11
    closeSettingsBtn.Text = "Close Settings"
    closeSettingsBtn.ZIndex = 802
    closeSettingsBtn.Parent = settingsFrame

    local csBtnCorner = Instance.new("UICorner")
    csBtnCorner.CornerRadius = UDim.new(0, 4)
    csBtnCorner.Parent = closeSettingsBtn

    local csBtnStroke = Instance.new("UIStroke")
    csBtnStroke.Color = theme.Border
    csBtnStroke.Thickness = 1
    csBtnStroke.Parent = closeSettingsBtn

    settingsBtn.MouseEnter:Connect(function()
        Tween(settingsIcon, 0.1, {ImageColor3 = theme.Accent})
    end)
    settingsBtn.MouseLeave:Connect(function()
        Tween(settingsIcon, 0.1, {ImageColor3 = theme.TextDark})
    end)

    settingsBtn.MouseButton1Click:Connect(function()
        settingsBackdrop.Visible = true
        Tween(settingsBackdrop, 0.2, {BackgroundTransparency = 0.5})
    end)

    closeSettingsBtn.MouseButton1Click:Connect(function()
        local f = Tween(settingsBackdrop, 0.15, {BackgroundTransparency = 1})
        f.Completed:Connect(function()
            settingsBackdrop.Visible = false
        end)
    end)

    -- Header Panel
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, -161, 0, 45)
    header.Position = UDim2.new(0, 161, 0, 0)
    header.BackgroundTransparency = 1
    header.Parent = mainFrame

    local lblCurrentTab = Instance.new("TextLabel")
    lblCurrentTab.Size = UDim2.new(0, 200, 1, 0)
    lblCurrentTab.Position = UDim2.new(0, 20, 0, 0)
    lblCurrentTab.BackgroundTransparency = 1
    lblCurrentTab.Font = Enum.Font.GothamBold
    lblCurrentTab.TextSize = 15
    lblCurrentTab.TextColor3 = theme.Text
    lblCurrentTab.TextXAlignment = Enum.TextXAlignment.Left
    lblCurrentTab.Text = "Dashboard"
    lblCurrentTab.Parent = header

    -- Header Controls (Minimize & Close)
    local controls = Instance.new("Frame")
    controls.Size = UDim2.new(0, 60, 1, 0)
    controls.Position = UDim2.new(1, -70, 0, 0)
    controls.BackgroundTransparency = 1
    controls.Parent = header

    local btnMin = Instance.new("TextButton")
    btnMin.Size = UDim2.new(0, 18, 0, 18)
    btnMin.Position = UDim2.new(0, 12, 0.5, -9)
    btnMin.BackgroundColor3 = Color3.fromRGB(0,0,0)
    btnMin.BackgroundTransparency = 0.95
    btnMin.Text = "-"
    btnMin.Font = Enum.Font.GothamBold
    btnMin.TextColor3 = theme.TextDark
    btnMin.TextSize = 12
    btnMin.Parent = controls

    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 4)
    minCorner.Parent = btnMin

    local btnClose = Instance.new("TextButton")
    btnClose.Size = UDim2.new(0, 18, 0, 18)
    btnClose.Position = UDim2.new(0, 34, 0.5, -9)
    btnClose.BackgroundColor3 = Color3.fromRGB(0,0,0)
    btnClose.BackgroundTransparency = 0.95
    btnClose.Text = "×"
    btnClose.Font = Enum.Font.GothamBold
    btnClose.TextColor3 = theme.TextDark
    btnClose.TextSize = 12
    btnClose.Parent = controls

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = btnClose

    btnMin.MouseButton1Click:Connect(function()
        Library:Toggle()
    end)

    btnClose.MouseButton1Click:Connect(function()
        local fade = Tween(mainFrame, 0.2, {Size = UDim2.new(0, mainFrame.AbsoluteSize.X, 0, 0)})
        fade.Completed:Connect(function()
            gui:Destroy()
        end)
    end)

    -- Container for Pages
    local pagesContainer = Instance.new("Frame")
    pagesContainer.Name = "PagesContainer"
    pagesContainer.Size = UDim2.new(1, -172, 1, -55)
    pagesContainer.Position = UDim2.new(0, 166, 0, 50)
    pagesContainer.BackgroundTransparency = 1
    pagesContainer.Parent = mainFrame

    local Window = {
        Tabs = {},
        ActiveTab = nil,
        TabCount = 0
    }

    -- Create Tab Method
    function Window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Name or "Tab"
        local tabIcon = tabConfig.Icon

        local hasIcon = (tabIcon ~= nil and tabIcon ~= "" and tabIcon ~= "none")

        Window.TabCount = Window.TabCount + 1
        local order = Window.TabCount

        -- Page Frame (CanvasGroup for smooth transitions)
        local page = Instance.new("CanvasGroup")
        page.Name = "Page_" .. tabName
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.GroupTransparency = 1
        page.Position = UDim2.new(0, 0, 0, 15)
        page.Visible = false
        page.Parent = pagesContainer

        -- Scroll list inside page
        local scrollList = Instance.new("ScrollingFrame")
        scrollList.Size = UDim2.new(1, 0, 1, 0)
        scrollList.BackgroundTransparency = 1
        scrollList.BorderSizePixel = 0
        scrollList.ScrollBarThickness = 2
        scrollList.ScrollBarImageColor3 = theme.Border
        scrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
        scrollList.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scrollList.Parent = page

        local pagePadding = Instance.new("UIPadding")
        pagePadding.PaddingTop = UDim.new(0, 4)
        pagePadding.PaddingBottom = UDim.new(0, 12)
        pagePadding.PaddingLeft = UDim.new(0, 4)
        pagePadding.PaddingRight = UDim.new(0, 10)
        pagePadding.Parent = scrollList

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, 6)
        pageLayout.Parent = scrollList

        -- Tab Navigation Button
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, -8, 0, 32)
        tabBtn.BackgroundColor3 = Color3.fromRGB(0,0,0)
        tabBtn.BackgroundTransparency = 1
        tabBtn.Text = ""
        tabBtn.Parent = tabScroll

        local tabBtnCorner = Instance.new("UICorner")
        tabBtnCorner.CornerRadius = UDim.new(0, 4)
        tabBtnCorner.Parent = tabBtn

        local tabIndicator = Instance.new("Frame")
        tabIndicator.Size = UDim2.new(0, 2, 0.4, 0)
        tabIndicator.Position = UDim2.new(0, 2, 0.3, 0)
        tabIndicator.BackgroundColor3 = theme.Accent
        tabIndicator.BorderSizePixel = 0
        tabIndicator.BackgroundTransparency = 1
        tabIndicator.Parent = tabBtn

        local indicatorCorner = Instance.new("UICorner")
        indicatorCorner.CornerRadius = UDim.new(0, 1)
        indicatorCorner.Parent = tabIndicator

        local tabImg = Instance.new("ImageLabel")
        tabImg.Size = UDim2.new(0, 14, 0, 14)
        tabImg.Position = UDim2.new(0, 12, 0.5, -7)
        tabImg.BackgroundTransparency = 1
        tabImg.Image = hasIcon and tabIcon or ""
        tabImg.ImageColor3 = theme.TextDark
        tabImg.Visible = hasIcon
        tabImg.Parent = tabBtn

        local tabLbl = Instance.new("TextLabel")
        -- Align tab label text left to stick to border if tab has no icon
        tabLbl.Size = hasIcon and UDim2.new(1, -40, 1, 0) or UDim2.new(1, -20, 1, 0)
        tabLbl.Position = hasIcon and UDim2.new(0, 32, 0, 0) or UDim2.new(0, 12, 0, 0)
        tabLbl.BackgroundTransparency = 1
        tabLbl.Font = Enum.Font.Gotham
        tabLbl.TextSize = 12
        tabLbl.TextColor3 = theme.TextDark
        tabLbl.TextXAlignment = Enum.TextXAlignment.Left
        tabLbl.Text = tabName
        tabLbl.Parent = tabBtn

        -- Select Tab Logic (Slide transitions + Double-Click prevention)
        local function Select()
            if Window.ActiveTab and Window.ActiveTab.Btn == tabBtn then
                return -- Stop if already selected, preventing disappear bug
            end

            if Window.ActiveTab then
                local prevTab = Window.ActiveTab
                Tween(prevTab.Page, 0.15, {GroupTransparency = 1, Position = UDim2.new(0, 0, 0, -10)})
                task.delay(0.15, function()
                    prevTab.Page.Visible = false
                end)
                prevTab.Btn.BackgroundTransparency = 1
                prevTab.Indicator.BackgroundTransparency = 1
                Tween(prevTab.Img, 0.15, {ImageColor3 = theme.TextDark})
                Tween(prevTab.Lbl, 0.15, {TextColor3 = theme.TextDark})
            end

            Window.ActiveTab = {
                Page = page,
                Btn = tabBtn,
                Indicator = tabIndicator,
                Img = tabImg,
                Lbl = tabLbl
            }

            page.Position = UDim2.new(0, 0, 0, 15)
            page.GroupTransparency = 1
            page.Visible = true
            lblCurrentTab.Text = tabName
            
            tabBtn.BackgroundColor3 = theme.Surface
            tabBtn.BackgroundTransparency = 0.5
            tabIndicator.BackgroundTransparency = 0
            
            Tween(page, 0.25, {GroupTransparency = 0, Position = UDim2.new(0, 0, 0, 4)})
            Tween(tabImg, 0.15, {ImageColor3 = theme.Accent})
            Tween(tabLbl, 0.15, {TextColor3 = theme.Text})
        end

        tabBtn.MouseButton1Click:Connect(Select)

        if order == 1 then
            page.Visible = true
            page.GroupTransparency = 0
            page.Position = UDim2.new(0, 0, 0, 4)
            Window.ActiveTab = {
                Page = page,
                Btn = tabBtn,
                Indicator = tabIndicator,
                Img = tabImg,
                Lbl = tabLbl
            }
            tabBtn.BackgroundColor3 = theme.Surface
            tabBtn.BackgroundTransparency = 0.5
            tabIndicator.BackgroundTransparency = 0
            tabImg.ImageColor3 = theme.Accent
            tabLbl.TextColor3 = theme.Text
        end

        local Tab = {
            Page = scrollList
        }

        -- 1. Create Section
        function Tab:CreateSection(secName)
            local sectionFrame = Instance.new("Frame")
            sectionFrame.Size = UDim2.new(1, 0, 0, 24)
            sectionFrame.BackgroundTransparency = 1
            sectionFrame.Parent = scrollList

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamBold
            label.TextSize = 10
            label.TextColor3 = theme.Accent
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Text = string.upper(secName)
            label.Parent = sectionFrame

            local line = Instance.new("Frame")
            line.Size = UDim2.new(1, -10 - label.TextBounds.X, 0, 1)
            line.Position = UDim2.new(0, label.TextBounds.X + 15, 0.5, 0)
            line.BackgroundColor3 = theme.Border
            line.BorderSizePixel = 0
            line.Parent = sectionFrame
        end

        -- 2. Create Button
        function Tab:CreateButton(btnConfig)
            btnConfig = btnConfig or {}
            local name = btnConfig.Name or "Button"
            local callback = btnConfig.Callback or function() end

            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, 0, 0, 36)
            button.BackgroundColor3 = theme.Secondary
            button.BorderSizePixel = 0
            button.Text = ""
            button.Parent = scrollList

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = button

            local stroke = Instance.new("UIStroke")
            stroke.Color = theme.Border
            stroke.Thickness = 1
            stroke.Parent = button

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -30, 1, 0)
            label.Position = UDim2.new(0, 14, 0, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.Gotham
            label.TextSize = 12
            label.TextColor3 = theme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Text = name
            label.Parent = button

            local icon = Instance.new("ImageLabel")
            icon.Size = UDim2.new(0, 14, 0, 14)
            icon.Position = UDim2.new(1, -26, 0.5, -7)
            icon.BackgroundTransparency = 1
            icon.Image = "rbxassetid://10888373307"
            icon.ImageColor3 = theme.TextDark
            icon.Parent = button

            button.MouseEnter:Connect(function()
                Tween(stroke, 0.1, {Color = theme.Accent})
                Tween(icon, 0.1, {ImageColor3 = theme.Accent})
            end)

            button.MouseLeave:Connect(function()
                Tween(stroke, 0.1, {Color = theme.Border})
                Tween(icon, 0.1, {ImageColor3 = theme.TextDark})
            end)

            button.MouseButton1Down:Connect(function()
                Tween(button, 0.05, {Size = UDim2.new(1, -2, 0, 35)})
            end)

            button.MouseButton1Up:Connect(function()
                Tween(button, 0.05, {Size = UDim2.new(1, 0, 0, 36)})
                callback()
            end)
        end

        -- 3. Create Toggle
        function Tab:CreateToggle(toggleConfig)
            toggleConfig = toggleConfig or {}
            local name = toggleConfig.Name or "Toggle"
            local default = toggleConfig.CurrentValue or false
            local callback = toggleConfig.Callback or function() end

            local state = default

            local toggleFrame = Instance.new("TextButton")
            toggleFrame.Size = UDim2.new(1, 0, 0, 36)
            toggleFrame.BackgroundColor3 = theme.Secondary
            toggleFrame.BorderSizePixel = 0
            toggleFrame.Text = ""
            toggleFrame.Parent = scrollList

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = toggleFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = theme.Border
            stroke.Thickness = 1
            stroke.Parent = toggleFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -60, 1, 0)
            label.Position = UDim2.new(0, 14, 0, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.Gotham
            label.TextSize = 12
            label.TextColor3 = theme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Text = name
            label.Parent = toggleFrame

            -- Toggle Pill
            local pill = Instance.new("Frame")
            pill.Size = UDim2.new(0, 30, 0, 16)
            pill.Position = UDim2.new(1, -44, 0.5, -8)
            pill.BackgroundColor3 = theme.Surface
            pill.BorderSizePixel = 0
            pill.Parent = toggleFrame

            local pillCorner = Instance.new("UICorner")
            pillCorner.CornerRadius = UDim.new(0, 8)
            pillCorner.Parent = pill

            local pillStroke = Instance.new("UIStroke")
            pillStroke.Color = theme.Border
            pillStroke.Thickness = 1
            pillStroke.Parent = pill

            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 10, 0, 10)
            dot.Position = UDim2.new(0, 2, 0.5, -5)
            dot.BackgroundColor3 = theme.TextDark
            dot.BorderSizePixel = 0
            dot.Parent = pill

            local dotCorner = Instance.new("UICorner")
            dotCorner.CornerRadius = UDim.new(0, 5)
            dotCorner.Parent = dot

            local function UpdateToggle()
                if state then
                    Tween(pill, 0.15, {BackgroundColor3 = theme.Accent})
                    Tween(pillStroke, 0.15, {Color = theme.Accent})
                    Tween(dot, 0.15, {Position = UDim2.new(1, -12, 0.5, -5), BackgroundColor3 = Color3.fromRGB(255,255,255)})
                else
                    Tween(pill, 0.15, {BackgroundColor3 = theme.Surface})
                    Tween(pillStroke, 0.15, {Color = theme.Border})
                    Tween(dot, 0.15, {Position = UDim2.new(0, 2, 0.5, -5), BackgroundColor3 = theme.TextDark})
                end
            end

            UpdateToggle()

            toggleFrame.MouseButton1Click:Connect(function()
                state = not state
                UpdateToggle()
                callback(state)
            end)

            toggleFrame.MouseEnter:Connect(function()
                Tween(stroke, 0.1, {Color = theme.Accent})
            end)

            toggleFrame.MouseLeave:Connect(function()
                Tween(stroke, 0.1, {Color = theme.Border})
            end)

            local toggleObj = {}
            function toggleObj:Set(newVal)
                state = newVal
                UpdateToggle()
                callback(state)
            end
            return toggleObj
        end

        -- 4. Create Slider (With manual text input field)
        function Tab:CreateSlider(sliderConfig)
            sliderConfig = sliderConfig or {}
            local name = sliderConfig.Name or "Slider"
            local min = sliderConfig.Min or 0
            local max = sliderConfig.Max or 100
            local default = sliderConfig.CurrentValue or 50
            local callback = sliderConfig.Callback or function() end

            local val = default

            local sliderFrame = Instance.new("Frame")
            sliderFrame.Size = UDim2.new(1, 0, 0, 46)
            sliderFrame.BackgroundColor3 = theme.Secondary
            sliderFrame.BorderSizePixel = 0
            sliderFrame.Parent = scrollList

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = sliderFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = theme.Border
            stroke.Thickness = 1
            stroke.Parent = sliderFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -100, 0, 24)
            label.Position = UDim2.new(0, 14, 0, 2)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.Gotham
            label.TextSize = 12
            label.TextColor3 = theme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Text = name
            label.Parent = sliderFrame

            -- Numeric text input box
            local valLabel = Instance.new("TextBox")
            valLabel.Size = UDim2.new(0, 50, 0, 18)
            valLabel.Position = UDim2.new(1, -64, 0, 4)
            valLabel.BackgroundColor3 = theme.Surface
            valLabel.BackgroundTransparency = 0.5
            valLabel.Font = Enum.Font.GothamBold
            valLabel.TextSize = 11
            valLabel.TextColor3 = theme.Accent
            valLabel.Text = tostring(default)
            valLabel.TextXAlignment = Enum.TextXAlignment.Center
            valLabel.ClearTextOnFocus = false
            valLabel.Parent = sliderFrame

            local valCorner = Instance.new("UICorner")
            valCorner.CornerRadius = UDim.new(0, 4)
            valCorner.Parent = valLabel

            local valStroke = Instance.new("UIStroke")
            valStroke.Color = theme.Accent
            valStroke.Thickness = 1
            valStroke.Transparency = 1 -- Hide by default
            valStroke.Parent = valLabel

            local track = Instance.new("TextButton")
            track.Size = UDim2.new(1, -28, 0, 4)
            track.Position = UDim2.new(0, 14, 0, 30)
            track.BackgroundColor3 = theme.Surface
            track.BorderSizePixel = 0
            track.Text = ""
            track.Parent = sliderFrame

            local trackCorner = Instance.new("UICorner")
            trackCorner.CornerRadius = UDim.new(0, 2)
            trackCorner.Parent = track

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
            fill.BackgroundColor3 = theme.Accent
            fill.BorderSizePixel = 0
            fill.Parent = track

            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(0, 2)
            fillCorner.Parent = fill

            local handle = Instance.new("Frame")
            handle.Size = UDim2.new(0, 10, 0, 10)
            handle.Position = UDim2.new((default - min)/(max - min), -5, 0.5, -5)
            handle.BackgroundColor3 = Color3.fromRGB(255,255,255)
            handle.BorderSizePixel = 0
            handle.Parent = track

            local handleCorner = Instance.new("UICorner")
            handleCorner.CornerRadius = UDim.new(0, 5)
            handleCorner.Parent = handle

            local handleStroke = Instance.new("UIStroke")
            handleStroke.Color = theme.Border
            handleStroke.Thickness = 1
            handleStroke.Parent = handle

            local dragging = false

            local function RefreshSliderVisuals()
                local percentage = math.clamp((val - min) / (max - min), 0, 1)
                fill.Size = UDim2.new(percentage, 0, 1, 0)
                handle.Position = UDim2.new(percentage, -5, 0.5, -5)
                valLabel.Text = tostring(val)
            end

            local function UpdateSlider(input)
                local sizeX = track.AbsoluteSize.X
                local percentage = math.clamp((input.Position.X - track.AbsolutePosition.X) / sizeX, 0, 1)
                val = math.floor(min + (max - min) * percentage)
                valLabel.Text = tostring(val)
                fill.Size = UDim2.new(percentage, 0, 1, 0)
                handle.Position = UDim2.new(percentage, -5, 0.5, -5)
                callback(val)
            end

            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    UpdateSlider(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSlider(input)
                end
            end)

            valLabel.Focused:Connect(function()
                Tween(valStroke, 0.1, {Transparency = 0})
            end)

            valLabel.FocusLost:Connect(function(enterPressed)
                Tween(valStroke, 0.1, {Transparency = 1})
                local textNum = tonumber(valLabel.Text)
                if not textNum then
                    valLabel.Text = tostring(val)
                else
                    if textNum > max then
                        val = max
                    elseif textNum < min then
                        val = min
                    else
                        val = math.floor(textNum)
                    end
                    RefreshSliderVisuals()
                    callback(val)
                end
            end)

            sliderFrame.MouseEnter:Connect(function()
                Tween(stroke, 0.1, {Color = theme.Accent})
            end)

            sliderFrame.MouseLeave:Connect(function()
                Tween(stroke, 0.1, {Color = theme.Border})
            end)

            local sliderObj = {}
            function sliderObj:Set(newVal)
                val = math.clamp(newVal, min, max)
                RefreshSliderVisuals()
                callback(val)
            end
            return sliderObj
        end

        -- 5. Create Dropdown (Floating menu with dynamic absolute scroll alignment)
        function Tab:CreateDropdown(dropdownConfig)
            dropdownConfig = dropdownConfig or {}
            local name = dropdownConfig.Name or "Dropdown"
            local optionsList = dropdownConfig.Options or {}
            local default = dropdownConfig.CurrentOption or ""
            local callback = dropdownConfig.Callback or function() end

            local currentVal = default
            local active = false

            local containerFrame = Instance.new("Frame")
            containerFrame.Size = UDim2.new(1, 0, 0, 36)
            containerFrame.BackgroundColor3 = theme.Secondary
            containerFrame.BorderSizePixel = 0
            containerFrame.Parent = scrollList

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = containerFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = theme.Border
            stroke.Thickness = 1
            stroke.Parent = containerFrame

            local dropBtn = Instance.new("TextButton")
            dropBtn.Size = UDim2.new(1, 0, 0, 36)
            dropBtn.BackgroundTransparency = 1
            dropBtn.Text = ""
            dropBtn.Parent = containerFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -120, 1, 0)
            label.Position = UDim2.new(0, 14, 0, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.Gotham
            label.TextSize = 12
            label.TextColor3 = theme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Text = name
            label.Parent = dropBtn

            local valLabel = Instance.new("TextLabel")
            valLabel.Size = UDim2.new(0, 80, 1, 0)
            valLabel.Position = UDim2.new(1, -114, 0, 0)
            valLabel.BackgroundTransparency = 1
            valLabel.Font = Enum.Font.GothamBold
            valLabel.TextSize = 11
            valLabel.TextColor3 = theme.Accent
            valLabel.TextXAlignment = Enum.TextXAlignment.Right
            valLabel.Text = currentVal
            valLabel.Parent = dropBtn

            local arrow = Instance.new("ImageLabel")
            arrow.Size = UDim2.new(0, 12, 0, 12)
            arrow.Position = UDim2.new(1, -24, 0.5, -6)
            arrow.BackgroundTransparency = 1
            arrow.Image = "rbxassetid://10888373307"
            arrow.ImageColor3 = theme.TextDark
            arrow.Parent = dropBtn

            local floatingMenu = nil
            local listConnection = nil
            local scrollConnection = nil
            local dragConnection = nil

            local function UpdateMenuPosition()
                if floatingMenu and dropBtn then
                    local p = dropBtn.AbsolutePosition
                    local s = dropBtn.AbsoluteSize
                    floatingMenu.Position = UDim2.new(0, p.X, 0, p.Y + s.Y + 4)
                end
            end

            local function DestroyFloatingMenu()
                if floatingMenu then
                    floatingMenu:Destroy()
                    floatingMenu = nil
                end
                if listConnection then
                    listConnection:Disconnect()
                    listConnection = nil
                end
                if scrollConnection then
                    scrollConnection:Disconnect()
                    scrollConnection = nil
                end
                if dragConnection then
                    dragConnection:Disconnect()
                    dragConnection = nil
                end
                active = false
                Tween(arrow, 0.2, {Rotation = 0})
            end

            local function OpenFloatingMenu()
                DestroyFloatingMenu()
                active = true
                Tween(arrow, 0.2, {Rotation = 90})

                floatingMenu = Instance.new("ScrollingFrame")
                floatingMenu.Name = "DropdownOverlay"
                floatingMenu.BackgroundColor3 = theme.Secondary
                floatingMenu.BackgroundTransparency = 0.05
                floatingMenu.BorderSizePixel = 0
                floatingMenu.ScrollBarThickness = 2
                floatingMenu.ScrollBarImageColor3 = theme.Border
                floatingMenu.CanvasSize = UDim2.new(0, 0, 0, 0)
                floatingMenu.AutomaticCanvasSize = Enum.AutomaticSize.Y
                floatingMenu.ZIndex = 100
                floatingMenu.Parent = gui

                local menuCorner = Instance.new("UICorner")
                menuCorner.CornerRadius = UDim.new(0, 6)
                menuCorner.Parent = floatingMenu

                local menuStroke = Instance.new("UIStroke")
                menuStroke.Color = theme.Border
                menuStroke.Thickness = 1
                menuStroke.Parent = floatingMenu

                local menuPadding = Instance.new("UIPadding")
                menuPadding.PaddingTop = UDim.new(0, 4)
                menuPadding.PaddingBottom = UDim.new(0, 4)
                menuPadding.PaddingLeft = UDim.new(0, 6)
                menuPadding.PaddingRight = UDim.new(0, 6)
                menuPadding.Parent = floatingMenu

                local menuLayout = Instance.new("UIListLayout")
                menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
                menuLayout.Padding = UDim.new(0, 3)
                menuLayout.Parent = floatingMenu

                -- Calculate absolute position dynamically
                local abSize = dropBtn.AbsoluteSize
                floatingMenu.Size = UDim2.new(0, abSize.X, 0, 0)
                UpdateMenuPosition()

                -- Connect scroll + drag signals to track dropdown positioning in real-time
                scrollConnection = scrollList:GetPropertyChangedSignal("CanvasPosition"):Connect(UpdateMenuPosition)
                dragConnection = mainFrame:GetPropertyChangedSignal("Position"):Connect(UpdateMenuPosition)

                -- Populate Options
                local optCount = 0
                for _, opt in ipairs(optionsList) do
                    optCount = optCount + 1
                    local optBtn = Instance.new("TextButton")
                    optBtn.Size = UDim2.new(1, 0, 0, 28)
                    optBtn.BackgroundColor3 = (opt == currentVal) and theme.Surface or Color3.fromRGB(0,0,0)
                    optBtn.BackgroundTransparency = (opt == currentVal) and 0.5 or 1
                    optBtn.BorderSizePixel = 0
                    optBtn.Text = ""
                    optBtn.ZIndex = 101
                    optBtn.Parent = floatingMenu

                    local optCorner = Instance.new("UICorner")
                    optCorner.CornerRadius = UDim.new(0, 4)
                    optCorner.Parent = optBtn

                    local leftIndicator = Instance.new("Frame")
                    leftIndicator.Size = UDim2.new(0, 2, 0.4, 0)
                    leftIndicator.Position = UDim2.new(0, 2, 0.3, 0)
                    leftIndicator.BackgroundColor3 = theme.Accent
                    leftIndicator.BorderSizePixel = 0
                    leftIndicator.BackgroundTransparency = (opt == currentVal) and 0 or 1
                    leftIndicator.ZIndex = 102
                    leftIndicator.Parent = optBtn

                    local optLabel = Instance.new("TextLabel")
                    optLabel.Size = UDim2.new(1, -20, 1, 0)
                    optLabel.Position = UDim2.new(0, 12, 0, 0)
                    optLabel.BackgroundTransparency = 1
                    optLabel.Font = Enum.Font.Gotham
                    optLabel.TextSize = 11
                    optLabel.TextColor3 = (opt == currentVal) and theme.Text or theme.TextDark
                    optLabel.TextXAlignment = Enum.TextXAlignment.Left
                    optLabel.ZIndex = 102
                    optLabel.Text = opt
                    optLabel.Parent = optBtn

                    optBtn.MouseEnter:Connect(function()
                        if opt ~= currentVal then
                            Tween(optBtn, 0.1, {BackgroundTransparency = 0.8, BackgroundColor3 = theme.Surface})
                        end
                    end)
                    optBtn.MouseLeave:Connect(function()
                        if opt ~= currentVal then
                            Tween(optBtn, 0.1, {BackgroundTransparency = 1})
                        end
                    end)

                    optBtn.MouseButton1Click:Connect(function()
                        currentVal = opt
                        valLabel.Text = currentVal
                        DestroyFloatingMenu()
                        callback(currentVal)
                    end)
                end

                local targetHeight = math.clamp((optCount * 31) + 8, 40, 200)
                Tween(floatingMenu, 0.2, {Size = UDim2.new(0, abSize.X, 0, targetHeight)})

                -- Close menu if clicked outside
                listConnection = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        local clickPos = UserInputService:GetMouseLocation()
                        local fPos = floatingMenu.AbsolutePosition
                        local fSize = floatingMenu.AbsoluteSize
                        if clickPos.X < fPos.X or clickPos.X > fPos.X + fSize.X or clickPos.Y < fPos.Y or clickPos.Y > fPos.Y + fSize.Y then
                            local dPos = dropBtn.AbsolutePosition
                            local dSize = dropBtn.AbsoluteSize
                            if clickPos.X < dPos.X or clickPos.X > dPos.X + dSize.X or clickPos.Y < dPos.Y or clickPos.Y > dPos.Y + dSize.Y then
                                DestroyFloatingMenu()
                            end
                        end
                    end
                end)
            end

            dropBtn.MouseButton1Click:Connect(function()
                if active then
                    DestroyFloatingMenu()
                else
                    OpenFloatingMenu()
                end
            end)

            containerFrame.MouseEnter:Connect(function()
                Tween(stroke, 0.1, {Color = theme.Accent})
            end)

            containerFrame.MouseLeave:Connect(function()
                Tween(stroke, 0.1, {Color = theme.Border})
            end)

            local dropdownObj = {}
            function dropdownObj:Set(newVal)
                currentVal = newVal
                valLabel.Text = currentVal
                callback(currentVal)
            end
            function dropdownObj:Refresh(newOptions)
                optionsList = newOptions
                if active then
                    OpenFloatingMenu()
                end
            end
            return dropdownObj
        end

        -- 6. Create TextBox (Fluent outline style)
        function Tab:CreateTextBox(textBoxConfig)
            textBoxConfig = textBoxConfig or {}
            local name = textBoxConfig.Name or "Text Input"
            local placeholder = textBoxConfig.Placeholder or "Type here..."
            local callback = textBoxConfig.Callback or function() end

            local textFrame = Instance.new("Frame")
            textFrame.Size = UDim2.new(1, 0, 0, 36)
            textFrame.BackgroundColor3 = theme.Secondary
            textFrame.BorderSizePixel = 0
            textFrame.Parent = scrollList

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = textFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = theme.Border
            stroke.Thickness = 1
            stroke.Parent = textFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -170, 1, 0)
            label.Position = UDim2.new(0, 14, 0, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.Gotham
            label.TextSize = 12
            label.TextColor3 = theme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Text = name
            label.Parent = textFrame

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(0, 140, 0, 24)
            box.Position = UDim2.new(1, -154, 0.5, -12)
            box.BackgroundColor3 = theme.Surface
            box.BorderSizePixel = 0
            box.Font = Enum.Font.Gotham
            box.TextSize = 11
            box.TextColor3 = theme.Text
            box.PlaceholderText = placeholder
            box.PlaceholderColor3 = theme.TextDim
            box.Text = ""
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.ClearTextOnFocus = false
            box.Parent = textFrame

            local boxPadding = Instance.new("UIPadding")
            boxPadding.PaddingLeft = UDim.new(0, 8)
            boxPadding.PaddingRight = UDim.new(0, 8)
            boxPadding.Parent = box

            local boxCorner = Instance.new("UICorner")
            boxCorner.CornerRadius = UDim.new(0, 4)
            boxCorner.Parent = box

            local boxStroke = Instance.new("UIStroke")
            boxStroke.Color = theme.Accent
            boxStroke.Thickness = 1
            boxStroke.Transparency = 1 -- Hide by default
            boxStroke.Parent = box

            box.Focused:Connect(function()
                Tween(boxStroke, 0.1, {Transparency = 0})
            end)

            box.FocusLost:Connect(function(enterPressed)
                Tween(boxStroke, 0.1, {Transparency = 1})
                callback(box.Text)
            end)

            textFrame.MouseEnter:Connect(function()
                Tween(stroke, 0.1, {Color = theme.Accent})
            end)

            textFrame.MouseLeave:Connect(function()
                Tween(stroke, 0.1, {Color = theme.Border})
            end)

            local boxObj = {}
            function boxObj:Set(newVal)
                box.Text = newVal
                callback(newVal)
            end
            return boxObj
        end

        -- 7. Create Keybind
        function Tab:CreateKeybind(keybindConfig)
            keybindConfig = keybindConfig or {}
            local name = keybindConfig.Name or "Keybind"
            local defaultKey = keybindConfig.CurrentKeybind or "None"
            local callback = keybindConfig.Callback or function() end

            local currentBind = defaultKey
            local binding = false

            local keyFrame = Instance.new("TextButton")
            keyFrame.Size = UDim2.new(1, 0, 0, 36)
            keyFrame.BackgroundColor3 = theme.Secondary
            keyFrame.BorderSizePixel = 0
            keyFrame.Text = ""
            keyFrame.Parent = scrollList

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = keyFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = theme.Border
            stroke.Thickness = 1
            stroke.Parent = keyFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -120, 1, 0)
            label.Position = UDim2.new(0, 14, 0, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.Gotham
            label.TextSize = 12
            label.TextColor3 = theme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Text = name
            label.Parent = keyFrame

            local keyDisplay = Instance.new("Frame")
            keyDisplay.Size = UDim2.new(0, 80, 0, 22)
            keyDisplay.Position = UDim2.new(1, -94, 0.5, -11)
            keyDisplay.BackgroundColor3 = theme.Surface
            keyDisplay.BorderSizePixel = 0
            keyDisplay.Parent = keyFrame

            local dispCorner = Instance.new("UICorner")
            dispCorner.CornerRadius = UDim.new(0, 4)
            dispCorner.Parent = keyDisplay

            local dispStroke = Instance.new("UIStroke")
            dispStroke.Color = theme.Border
            dispStroke.Thickness = 1
            dispStroke.Parent = keyDisplay

            local keyLabel = Instance.new("TextLabel")
            keyLabel.Size = UDim2.new(1, 0, 1, 0)
            keyLabel.BackgroundTransparency = 1
            keyLabel.Font = Enum.Font.GothamBold
            keyLabel.TextSize = 10
            keyLabel.TextColor3 = theme.Accent
            keyLabel.Text = currentBind
            keyLabel.Parent = keyDisplay

            keyFrame.MouseButton1Click:Connect(function()
                if not binding then
                    binding = true
                    Library.IsBinding = true
                    keyLabel.Text = "..."
                    Tween(dispStroke, 0.1, {Color = theme.Accent})
                end
            end)

            UserInputService.InputBegan:Connect(function(input, processed)
                if binding and not processed then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        binding = false
                        task.defer(function()
                            Library.IsBinding = false
                        end)
                        currentBind = input.KeyCode.Name
                        keyLabel.Text = currentBind
                        Tween(dispStroke, 0.1, {Color = theme.Border})
                        callback(input.KeyCode)
                    end
                end
            end)

            keyFrame.MouseEnter:Connect(function()
                Tween(stroke, 0.1, {Color = theme.Accent})
            end)

            keyFrame.MouseLeave:Connect(function()
                Tween(stroke, 0.1, {Color = theme.Border})
            end)

            local keybindObj = {}
            function keybindObj:Set(newVal)
                currentBind = newVal
                keyLabel.Text = currentBind
                callback(Enum.KeyCode[newVal])
            end
            return keybindObj
        end

        -- 8. Create Colorpicker (Windows Fluent Dialog Overlay Redesign)
        function Tab:CreateColorpicker(pickerConfig)
            pickerConfig = pickerConfig or {}
            local name = pickerConfig.Name or "Colorpicker"
            local defaultColor = pickerConfig.Default or Color3.fromRGB(255, 255, 255)
            local callback = pickerConfig.Callback or function() end

            local color = defaultColor

            local cpFrame = Instance.new("Frame")
            cpFrame.Size = UDim2.new(1, 0, 0, 36)
            cpFrame.BackgroundColor3 = theme.Secondary
            cpFrame.BorderSizePixel = 0
            cpFrame.Parent = scrollList

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = cpFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = theme.Border
            stroke.Thickness = 1
            stroke.Parent = cpFrame

            local cpHeaderBtn = Instance.new("TextButton")
            cpHeaderBtn.Size = UDim2.new(1, 0, 0, 36)
            cpHeaderBtn.BackgroundTransparency = 1
            cpHeaderBtn.Text = ""
            cpHeaderBtn.Parent = cpFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -120, 1, 0)
            label.Position = UDim2.new(0, 14, 0, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.Gotham
            label.TextSize = 12
            label.TextColor3 = theme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Text = name
            label.Parent = cpHeaderBtn

            local colorBox = Instance.new("Frame")
            colorBox.Size = UDim2.new(0, 24, 0, 16)
            colorBox.Position = UDim2.new(1, -38, 0.5, -8)
            colorBox.BackgroundColor3 = color
            colorBox.BorderSizePixel = 0
            colorBox.Parent = cpHeaderBtn

            local boxCorner = Instance.new("UICorner")
            boxCorner.CornerRadius = UDim.new(0, 4)
            boxCorner.Parent = colorBox

            local boxStroke = Instance.new("UIStroke")
            boxStroke.Color = theme.Border
            boxStroke.Thickness = 1
            boxStroke.Parent = colorBox

            -- Create Custom Fluent Colorpicker Dialog Box Popup
            local function OpenColorpickerDialog()
                -- Dialog background Frame with Active = true to sink clicks without flashing
                local dialogBackdrop = Instance.new("Frame")
                dialogBackdrop.Name = "ColorpickerBackdrop"
                dialogBackdrop.Size = UDim2.new(1, 0, 1, 0)
                dialogBackdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                dialogBackdrop.BackgroundTransparency = 0.5
                dialogBackdrop.Active = true
                dialogBackdrop.ZIndex = 500
                dialogBackdrop.Parent = gui

                local dialogFrame = Instance.new("Frame")
                dialogFrame.Size = UDim2.new(0, 300, 0, 260)
                dialogFrame.Position = UDim2.new(0.5, -150, 0.5, -130)
                dialogFrame.BackgroundColor3 = theme.Background
                dialogFrame.BorderSizePixel = 0
                dialogFrame.ZIndex = 501
                dialogFrame.Parent = dialogBackdrop

                local dCorner = Instance.new("UICorner")
                dCorner.CornerRadius = UDim.new(0, 8)
                dCorner.Parent = dialogFrame

                local dStroke = Instance.new("UIStroke")
                dStroke.Color = theme.Border
                dStroke.Thickness = 1
                dStroke.Parent = dialogFrame

                -- Saturation/Value palette
                local svPalette = Instance.new("ImageButton")
                svPalette.Size = UDim2.new(0, 150, 0, 140)
                svPalette.Position = UDim2.new(0, 12, 0, 40)
                svPalette.Image = "rbxassetid://415583266"
                svPalette.BackgroundTransparency = 0 -- Render background color behind transparent overlay image
                svPalette.BorderSizePixel = 0
                svPalette.ZIndex = 502
                svPalette.Parent = dialogFrame

                local paletteCorner = Instance.new("UICorner")
                paletteCorner.CornerRadius = UDim.new(0, 4)
                paletteCorner.Parent = svPalette

                local cursor = Instance.new("Frame")
                cursor.Size = UDim2.new(0, 8, 0, 8)
                cursor.AnchorPoint = Vector2.new(0.5, 0.5)
                cursor.BackgroundColor3 = Color3.fromRGB(255,255,255)
                cursor.ZIndex = 503
                cursor.Parent = svPalette

                local cursorCorner = Instance.new("UICorner")
                cursorCorner.CornerRadius = UDim.new(0, 4)
                cursorCorner.Parent = cursor

                local cursorStroke = Instance.new("UIStroke")
                cursorStroke.Color = Color3.fromRGB(0, 0, 0)
                cursorStroke.Thickness = 1
                cursorStroke.Parent = cursor

                -- Hue vertical slider
                local hueSlider = Instance.new("ImageButton")
                hueSlider.Size = UDim2.new(0, 12, 0, 140)
                hueSlider.Position = UDim2.new(0, 172, 0, 40)
                hueSlider.BorderSizePixel = 0
                hueSlider.ZIndex = 502
                hueSlider.Parent = dialogFrame

                local hueCorner = Instance.new("UICorner")
                hueCorner.CornerRadius = UDim.new(0, 6)
                hueCorner.Parent = hueSlider

                local hueGradient = Instance.new("UIGradient")
                hueGradient.Rotation = 90
                hueGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                })
                hueGradient.Parent = hueSlider

                local hueCursor = Instance.new("Frame")
                hueCursor.Size = UDim2.new(1, 4, 0, 4)
                hueCursor.Position = UDim2.new(0, -2, 0.5, -2)
                hueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                hueCursor.BorderSizePixel = 0
                hueCursor.ZIndex = 503
                hueCursor.Parent = hueSlider

                local hcStroke = Instance.new("UIStroke")
                hcStroke.Color = Color3.fromRGB(0,0,0)
                hcStroke.Thickness = 1
                hcStroke.Parent = hueCursor

                -- Red, Green, Blue on the right
                local rLabel = Instance.new("TextLabel")
                rLabel.Size = UDim2.new(0, 25, 0, 24)
                rLabel.Position = UDim2.new(0, 196, 0, 40)
                rLabel.BackgroundTransparency = 1
                rLabel.Font = Enum.Font.Gotham
                rLabel.TextSize = 10
                rLabel.TextColor3 = theme.TextDark
                rLabel.TextXAlignment = Enum.TextXAlignment.Left
                rLabel.Text = "Red:"
                rLabel.ZIndex = 502
                rLabel.Parent = dialogFrame

                local rInput = Instance.new("TextBox")
                rInput.Size = UDim2.new(0, 50, 0, 24)
                rInput.Position = UDim2.new(0, 238, 0, 40)
                rInput.BackgroundColor3 = theme.Surface
                rInput.Font = Enum.Font.GothamBold
                rInput.TextColor3 = theme.Text
                rInput.TextSize = 10
                rInput.ZIndex = 502
                rInput.Parent = dialogFrame

                local rCorner = Instance.new("UICorner")
                rCorner.CornerRadius = UDim.new(0, 4)
                rCorner.Parent = rInput

                local gLabel = rLabel:Clone()
                gLabel.Text = "Green:"
                gLabel.Position = UDim2.new(0, 196, 0, 70)
                gLabel.Parent = dialogFrame

                local gInput = rInput:Clone()
                gInput.Position = UDim2.new(0, 238, 0, 70)
                gInput.Parent = dialogFrame

                local bLabel = rLabel:Clone()
                bLabel.Text = "Blue:"
                bLabel.Position = UDim2.new(0, 196, 0, 100)
                bLabel.Parent = dialogFrame

                local bInput = rInput:Clone()
                bInput.Position = UDim2.new(0, 238, 0, 100)
                bInput.Parent = dialogFrame

                -- Title
                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, -24, 0, 36)
                title.Position = UDim2.new(0, 12, 0, 4)
                title.BackgroundTransparency = 1
                title.Font = Enum.Font.GothamBold
                title.TextSize = 12
                title.TextColor3 = theme.Text
                title.TextXAlignment = Enum.TextXAlignment.Left
                title.Text = name
                title.ZIndex = 502
                title.Parent = dialogFrame

                -- Current Color Indicator
                local previewColor = Instance.new("Frame")
                previewColor.Size = UDim2.new(0, 92, 0, 24)
                previewColor.Position = UDim2.new(0, 196, 0, 132)
                previewColor.BackgroundColor3 = color
                previewColor.ZIndex = 502
                previewColor.Parent = dialogFrame

                local pCorner = Instance.new("UICorner")
                pCorner.CornerRadius = UDim.new(0, 4)
                pCorner.Parent = previewColor

                local pStroke = Instance.new("UIStroke")
                pStroke.Color = theme.Border
                pStroke.Thickness = 1
                pStroke.Parent = previewColor

                local h, s, v = color:ToHSV()
                
                local function UpdateVisuals()
                    local selectedColor = Color3.fromHSV(h, s, v)
                    svPalette.BackgroundColor3 = Color3.fromHSV(h, 1, 1) -- Update background color to current hue color
                    previewColor.BackgroundColor3 = selectedColor
                    rInput.Text = tostring(math.floor(selectedColor.R * 255))
                    gInput.Text = tostring(math.floor(selectedColor.G * 255))
                    bInput.Text = tostring(math.floor(selectedColor.B * 255))

                    cursor.Position = UDim2.new(s, 0, 1 - v, 0)
                    hueCursor.Position = UDim2.new(0, -2, h, -2)
                end

                UpdateVisuals()

                -- Hue Drag handlers
                local hueDragging = false
                local function UpdateHue(input)
                    local y = math.clamp((input.Position.Y - hueSlider.AbsolutePosition.Y) / hueSlider.AbsoluteSize.Y, 0, 1)
                    h = y
                    UpdateVisuals()
                end

                hueSlider.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        hueDragging = true
                        UpdateHue(input)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        hueDragging = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if hueDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        UpdateHue(input)
                    end
                end)

                -- SV Drag handlers
                local svDragging = false
                local function UpdateSV(input)
                    local x = math.clamp((input.Position.X - svPalette.AbsolutePosition.X) / svPalette.AbsoluteSize.X, 0, 1)
                    local y = math.clamp((input.Position.Y - svPalette.AbsolutePosition.Y) / svPalette.AbsoluteSize.Y, 0, 1)
                    s = x
                    v = 1 - y
                    UpdateVisuals()
                end

                svPalette.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        svDragging = true
                        UpdateSV(input)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        svDragging = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if svDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        UpdateSV(input)
                    end
                end)

                local function TextInputsChanged()
                    local r = tonumber(rInput.Text) or 0
                    local g = tonumber(gInput.Text) or 0
                    local b = tonumber(bInput.Text) or 0
                    
                    r = math.clamp(r, 0, 255)
                    g = math.clamp(g, 0, 255)
                    b = math.clamp(b, 0, 255)

                    local newCol = Color3.fromRGB(r, g, b)
                    h, s, v = newCol:ToHSV()
                    UpdateVisuals()
                end

                rInput.FocusLost:Connect(TextInputsChanged)
                gInput.FocusLost:Connect(TextInputsChanged)
                bInput.FocusLost:Connect(TextInputsChanged)

                -- Done & Cancel Buttons
                local btnDone = Instance.new("TextButton")
                btnDone.Size = UDim2.new(0, 130, 0, 32)
                btnDone.Position = UDim2.new(0, 12, 1, -44)
                btnDone.BackgroundColor3 = theme.Accent
                btnDone.Font = Enum.Font.GothamBold
                btnDone.TextColor3 = Color3.fromRGB(255,255,255)
                btnDone.TextSize = 11
                btnDone.Text = "Done"
                btnDone.ZIndex = 502
                btnDone.Parent = dialogFrame

                local doneCorner = Instance.new("UICorner")
                doneCorner.CornerRadius = UDim.new(0, 4)
                doneCorner.Parent = btnDone

                local btnCancel = Instance.new("TextButton")
                btnCancel.Size = UDim2.new(0, 130, 0, 32)
                btnCancel.Position = UDim2.new(0, 158, 1, -44)
                btnCancel.BackgroundColor3 = theme.Surface
                btnCancel.Font = Enum.Font.GothamBold
                btnCancel.TextColor3 = theme.Text
                btnCancel.TextSize = 11
                btnCancel.Text = "Cancel"
                btnCancel.ZIndex = 502
                btnCancel.Parent = dialogFrame

                local cancelCorner = Instance.new("UICorner")
                cancelCorner.CornerRadius = UDim.new(0, 4)
                cancelCorner.Parent = btnCancel

                btnDone.MouseButton1Click:Connect(function()
                    color = Color3.fromHSV(h, s, v)
                    colorBox.BackgroundColor3 = color
                    dialogBackdrop:Destroy()
                    callback(color)
                end)

                btnCancel.MouseButton1Click:Connect(function()
                    dialogBackdrop:Destroy()
                end)
            end

            cpHeaderBtn.MouseButton1Click:Connect(OpenColorpickerDialog)

            cpFrame.MouseEnter:Connect(function()
                Tween(stroke, 0.1, {Color = theme.Accent})
            end)

            cpFrame.MouseLeave:Connect(function()
                Tween(stroke, 0.1, {Color = theme.Border})
            end)

            local cpObj = {}
            function cpObj:Set(newColor)
                color = newColor
                colorBox.BackgroundColor3 = color
                callback(color)
            end
            return cpObj
        end

        return Tab
    end

    return Window
end

return Library
