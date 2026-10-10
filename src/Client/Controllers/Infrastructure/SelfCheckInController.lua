-- SelfCheckInController Controller
-- Jack_AviationRBX
-- October 11, 2021

--[[

SelfCheckInController manages all GUI popups given when a user interacts with the model.

--]]

local TweenService = game:GetService("TweenService")

local GUI
local MAX_QUANTITY_TICKETS = 5

local CurrentTicketPurchaseStats = {
    ["amountPerTicketMiles"] = 0,
    ["amountPerTicketRobux"] = 0,
    ["currentClass"] = "",
    ["currentQuantity"] = 0
}

local NameChanges = {
    ["Executive"] = "EX",
    ["Premium"] = "PR",
    ["Standard+"] = "ST+",
    ["Standard"] = "ST"
}

local FetchedInfo = {}
local CanPass = false


local SelfCheckInController = {}


function SelfCheckInController:Activate(Gui)
    GUI = Gui

    self:MonitorLaunch()
    self:MonitorClassSelection()
    self:MonitorTicketPurchase()
    self:MonitorNewPurchases()
    self:ManageFlightSummaryContinue()
    self:MonitorBaggageScreen()

    GUI.DefaultBackground.Exit.MouseButton1Click:Connect(function()
        
        local Success = self.Services.Game.Infrastructure.SelfCheckInService:RequestClosure()
        if Success then
            for _,v in pairs(GUI.Back.Frames:GetChildren()) do
                if v:IsA("Frame") then
                    v.Position = UDim2.new(-1, 0, 0.223, 0)
                end
            end
            GUI.Back.Frames.Launch.Position = UDim2.new(0, 0, 0.223, 0)
        end
    end)
end


function SelfCheckInController:PhaseOutFrame(frame)
    local TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local Tween = TweenService:Create(frame, TweenInfo, {Position = UDim2.new(1, 0, 0.223, 0)})
    Tween:Play()
end


function SelfCheckInController:PhaseInFrame(frame)
    frame.Position = UDim2.new(-1, 0, 0.223, 0)
    local TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
    local Tween = TweenService:Create(frame, TweenInfo, {Position = UDim2.new(0, 0, 0.223, 0)})
    Tween:Play()
end


function SelfCheckInController:RotateProcess()
    local TweenInformation = TweenInfo.new(1.25,
	Enum.EasingStyle.Linear);
    local Iterations = 0
    local function Tween()
        if Iterations >= 3 then
            self:PhaseOutFrame(GUI.Back.Frames.PrintingTicket)
            self:PhaseInFrame(GUI.Back.Frames.FinalScreen)
            GUI.DefaultBackground.Exit.Visible = true
            return
        else
            GUI.Back.Frames.PrintingTicket.Loading.Rotation = 0;
            Iterations = Iterations + 1
            local Create = game:GetService("TweenService"):Create(GUI.Back.Frames.PrintingTicket.Loading,TweenInformation,{Rotation = 359.9});
            Create.Completed:Connect(Tween);
            Create:Play();
        end
    end
    
    Tween();
end

function SelfCheckInController:MonitorBaggageScreen()
    local switch = false
    GUI.Back.Frames.PlaceBag.PlaceBag.MouseButton1Click:Connect(function()
        --> Request server to place bag
        --> Ensures user has booked, and hasn't handed in luggage.
        if switch == false then
            switch = true
            local Success = self.Services.Game.Infrastructure.SelfCheckInService:SendBaggage()
            self:PhaseInFrame(GUI.Back.Frames.PrintingTicket)
            self:PhaseOutFrame(GUI.Back.Frames.PlaceBag)

            self:RotateProcess()
            wait(1)
            switch = false
        end
    end)
end


function SelfCheckInController:ManageFlightSummaryContinue()
    GUI.Back.Frames.FlightSummary.Continue.MouseButton1Click:Connect(function()
        self:PhaseOutFrame(GUI.Back.Frames.FlightSummary)
        self:PhaseInFrame(GUI.Back.Frames.PlaceBag)
    end)
end


function SelfCheckInController:MonitorNewPurchases()
    local function requestClass(className)
        if CurrentTicketPurchaseStats["currentClass"] == className then
            if GUI.Back.Frames.TicketPurchase.Position == UDim2.new(0, 0, 0.223, 0) then
                local Success = self.Services.Game.Infrastructure.SelfCheckInService:RequestBooking(className)
                if Success then
                    self:PhaseOutFrame(GUI.Back.Frames.TicketPurchase)
                    self:UpdateFlightSummary(className)
                    self:PhaseInFrame(GUI.Back.Frames.FlightSummary)
                end
            end
        end
    end
    self.Services.Data.PurchaseService.PurchaseClient:Connect(function(category, _)
        local ClassName = string.gsub(category, "Class", "")
        requestClass(ClassName)
    end)
end


function SelfCheckInController:MonitorLaunch()
    GUI.Back.Frames.Launch.StartBtn.MouseButton1Click:Connect(function()
        local Data = self.Services.Game.Infrastructure.SelfCheckInService:GetStartingData()
        if Data then
            FetchedInfo = Data
            CanPass = true
            self:PhaseOutFrame(GUI.Back.Frames.Launch)
            self:UpdateClassSelection()
            self:PhaseInFrame(GUI.Back.Frames.ClassSelection)
            GUI.DefaultBackground.Exit.Visible = true
        else
            CanPass = false
        end
    end)
end


function SelfCheckInController:MonitorTicketPurchase()
    local function UpdatePriceDisplay(Quantity)
        GUI.Back.Frames.TicketPurchase.TotalPrice.Miles.Text = "| "..tostring(Quantity*CurrentTicketPurchaseStats["amountPerTicketMiles"]).." MILES"
        GUI.Back.Frames.TicketPurchase.TotalPrice.Robux.Text = tostring(Quantity*CurrentTicketPurchaseStats["amountPerTicketRobux"]).." ROBUX"
    end

    GUI.Back.Frames.TicketPurchase.TicketQuantity.Less.MouseButton1Click:Connect(function()
        if CurrentTicketPurchaseStats["currentQuantity"] > 0 then
            CurrentTicketPurchaseStats["currentQuantity"] += -1
            GUI.Back.Frames.TicketPurchase.TicketQuantity.Quantity.Text = tostring(CurrentTicketPurchaseStats["currentQuantity"])
            UpdatePriceDisplay(CurrentTicketPurchaseStats["currentQuantity"])
        end
    end)
    GUI.Back.Frames.TicketPurchase.TicketQuantity.More.MouseButton1Click:Connect(function()
        if CurrentTicketPurchaseStats["currentQuantity"] < MAX_QUANTITY_TICKETS then
            CurrentTicketPurchaseStats["currentQuantity"] += 1
            GUI.Back.Frames.TicketPurchase.TicketQuantity.Quantity.Text = tostring(CurrentTicketPurchaseStats["currentQuantity"])
            UpdatePriceDisplay(CurrentTicketPurchaseStats["currentQuantity"])
        end
    end)

    local MilesPurchaseDebounce = false

    GUI.Back.Frames.TicketPurchase.MilesBtn.MouseButton1Click:Connect(function()
        if MilesPurchaseDebounce then
            return
        else
            MilesPurchaseDebounce = true
        end
        if CurrentTicketPurchaseStats["currentQuantity"] > 0 then
            self:PhaseOutFrame(GUI.Back.Frames.TicketPurchase)
            GUI.Back.Processing.Position = UDim2.new(-1, 0, 0.4, 0)
            local Tween = TweenService:Create(GUI.Back.Processing, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {Position = UDim2.new(0.14, 0,0.4, 0)})
            Tween:Play()

            local function close()
                local Tween = TweenService:Create(GUI.Back.Processing, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Position = UDim2.new(1, 0,0.4, 0)})
                Tween:Play()
            end

            local Success, className = self.Services.Game.Infrastructure.SelfCheckInService:RequestMilesPurchase(CurrentTicketPurchaseStats["currentClass"], CurrentTicketPurchaseStats["currentQuantity"])
            if Success and className then
                local Req = self.Services.Game.Infrastructure.SelfCheckInService:RequestBooking(className)
                if Req then
                    close()
                    self:UpdateFlightSummary(className)
                    self:PhaseInFrame(GUI.Back.Frames.FlightSummary)
                else
                    self:PhaseInFrame(GUI.Back.Frames.TicketPurchase)
                    close()
                end
            else
                close()
                self:PhaseInFrame(GUI.Back.Frames.TicketPurchase)
            end
            
            task.wait(2)
            MilesPurchaseDebounce = false
        end
    end)
    GUI.Back.Frames.TicketPurchase.RobuxBtn.MouseButton1Click:Connect(function()
        if CurrentTicketPurchaseStats["currentQuantity"] > 0 then
            self.Services.Game.Infrastructure.SelfCheckInService:IssuePurchasePrompt(CurrentTicketPurchaseStats["currentClass"], CurrentTicketPurchaseStats["currentQuantity"])
        end
    end)
    GUI.Back.Frames.TicketPurchase.PermBtn.MouseButton1Click:Connect(function()
        self.Services.Game.Infrastructure.SelfCheckInService:IssuePurchasePrompt(CurrentTicketPurchaseStats["currentClass"], "perm")
    end)
    GUI.Back.Frames.TicketPurchase.BackBtn.MouseButton1Click:Connect(function()
        self:PhaseOutFrame(GUI.Back.Frames.TicketPurchase)
        self:UpdateClassSelection()
        self:PhaseInFrame(GUI.Back.Frames.ClassSelection)
    end)
end


function SelfCheckInController:UpdateClassSelection()
    if FetchedInfo["classes"] then
        for _,classObj in pairs(GUI.Back.Frames.ClassSelection.Classes:GetChildren()) do
            if not table.find(FetchedInfo["classes"], classObj.Name) then
                classObj.ButtonFrame.BackgroundTransparency = 0.3
                classObj.ButtonFrame.TextButton.TextTransparency = 0.3
                classObj.ButtonFrame.TextButton.Text = string.upper(classObj.Name).."\n(Full)"
            else
                classObj.ButtonFrame.BackgroundTransparency = 0
                classObj.ButtonFrame.TextButton.TextTransparency = 0
                classObj.ButtonFrame.TextButton.Text = NameChanges[classObj.Name]
            end
        end
    end
    if FetchedInfo["classesOwned"] then
        for _,classText in pairs(FetchedInfo["classesOwned"]) do
            GUI.Back.Frames.ClassSelection.Classes[classText].ButtonFrame.TextButton.Text = NameChanges[classText].."\n(Owned)"
        end
    end
end


function SelfCheckInController:UpdateFlightSummary(className)
    if FetchedInfo["flightInfo"] then
        local Info = GUI.Back.Frames.FlightSummary.Info
        Info.Aircraft.Text = "AIRCRAFT: "..FetchedInfo["flightInfo"]["aircraft"]
        Info.BoardingGate.Text = "BOARDING GATE: "..FetchedInfo["flightInfo"]["boardingGate"]
        Info.BoardingTime.Text = "BOARDING TIME: "..FetchedInfo["flightInfo"]["boardingTime"]
        Info.Class.Text = "CLASS: "..className
    end
end


function SelfCheckInController:UpdateTicketPurchase(className, robuxPrice, milesPrice)
    local RobuxPrice, MilesPrice = string.gsub(robuxPrice, "%D", ""), string.gsub(milesPrice, "%D", "")
    CurrentTicketPurchaseStats["amountPerTicketRobux"] = RobuxPrice
    CurrentTicketPurchaseStats["amountPerTicketMiles"] = MilesPrice
    CurrentTicketPurchaseStats["currentClass"] = className

    GUI.Back.Frames.TicketPurchase.TicketPrice.Miles.Text = " | "..milesPrice
    GUI.Back.Frames.TicketPurchase.TicketPrice.Robux.Text = robuxPrice
    
    local ClassLocation = GUI.Back.Frames.ClassSelection.Classes[className].ButtonFrame
    GUI.Back.Frames.TicketPurchase.ClassType.BackgroundColor3 = ClassLocation.BackgroundColor3
    GUI.Back.Frames.TicketPurchase.ClassType.TextBox.Text = string.upper(className)
end


function SelfCheckInController:MonitorClassSelection()
    for _,classObj in pairs(GUI.Back.Frames.ClassSelection.Classes:GetChildren()) do
        classObj.ButtonFrame.TextButton.MouseButton1Click:Connect(function()
            if CanPass then
                if table.find(FetchedInfo["classesOwned"], classObj.Name) then
                    self:PhaseOutFrame(GUI.Back.Frames.ClassSelection)
                    GUI.DefaultBackground.Exit.Visible = false

                    GUI.Back.Processing.Position = UDim2.new(-1, 0, 0.4, 0)
                    local Tween = TweenService:Create(GUI.Back.Processing, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {Position = UDim2.new(0.14, 0,0.4, 0)})
                    Tween:Play()

                    task.wait(2)

                    local Success = self.Services.Game.Infrastructure.SelfCheckInService:RequestBooking(classObj.Name)

                    local function close()
                        local Tween = TweenService:Create(GUI.Back.Processing, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Position = UDim2.new(1, 0,0.4, 0)})
                        Tween:Play()
                    end

                    if Success then
                        close()
                        self:UpdateFlightSummary(classObj.Name)
                        self:PhaseInFrame(GUI.Back.Frames.FlightSummary)
                        GUI.DefaultBackground.Exit.Visible = true
                    else
                        close()
                        self:PhaseInFrame(GUI.Back.Frames.ClassSelection)
                        GUI.DefaultBackground.Exit.Visible = true
                    end
                else
                    self:PhaseOutFrame(GUI.Back.Frames.ClassSelection)
                    self:PhaseInFrame(GUI.Back.Frames.TicketPurchase)
                    self:UpdateTicketPurchase(classObj.Name, classObj.Robux.Text, classObj.Miles.Text)
                end
            end
        end)
    end
end


return SelfCheckInController