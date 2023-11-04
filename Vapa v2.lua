                                                                                 local Library=        
                                                                        loadstring(game:HttpGet(                        
                                                                                                                                  
                                                                                                                                        
                                                            "https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))( 
                                                          );local Window=Library.CreateLib("Vapa v2","DarkTheme");local AimBot=Window:      
                                                        NewTab("AimBot");local AimBotSN=AimBot:NewSection("AimBot");AimBotSN:NewButton(       
                                                      "Open Aimbot/Restart","Open Aimbot/Restart",function()loadstring(game:HttpGet(            
                                                    "https://raw.githubusercontent.com/Exunys/Aimbot-V2/main/Resources/Scripts/Main.lua"))();     
                                                  getgenv().Aimbot.Functions:Restart();end);AimBotSN:NewToggle("Open/Close","Open/Close",function(  
                                                  open)if open then getgenv().Aimbot.Settings.Enabled=true;else getgenv().Aimbot.Settings.Enabled=    
                                                false;end end);AimBotSN:NewToggle("FOV:  Open/Close","FOV:  Open/Close",function(open)if open then      
                                                getgenv().Aimbot.FOVSettings.Enabled=true;else getgenv().Aimbot.FOVSettings.Enabled=false;end end);       
                                              AimBotSN:NewKeybind("Hotkey(open)","Hotkey",Enum.KeyCode.E,function()getgenv().Aimbot.FOVSettings.Enabled=    
                                              true;end);AimBotSN:NewKeybind("Hotkey(close)","Hotkey",Enum.KeyCode.E,function()getgenv().Aimbot.FOVSettings. 
                                            Enabled=false;end);AimBotSN:NewSlider("Sensitivity","Sensitivity",100,0,function(Sensitivity)getgenv().Aimbot.    
                                            Settings.Sensitivity=Sensitivity/10 ;end);AimBotSN:NewSlider("FOV size","FOV size",1000,10,function(size)getgenv(). 
                                          Aimbot.FOVSettings.Amount=size;end);AimBotSN:NewSlider("FOV Sides","FOV Sides",100,0,function(Sides)getgenv().Aimbot.   
                                          FOVSettings.Sides=Sides;end);AimBotSN:NewSlider("FOV Transparency","FOV Transparency",100,0,function(Transparency)getgenv 
                                          ().Aimbot.FOVSettings.Transparency=Transparency;end);AimBotSN:NewSlider("Thickness","Thickness",100,0.5,function(Thickness) 
                                          getgenv().Aimbot.FOVSettings.Thickness=Thickness;end);AimBotSN:NewButton("Raimbo FOV","Raimbo FOV",function()local fovColor 
                                        ={0,0,0};local speed={5,15,20};function ContinuousColorChange()for i=1,3 do fovColor[i]=(fovColor[i] + speed[i])%256 ;end       
                                        getgenv().Aimbot.FOVSettings.Color=table.concat(fovColor,", ");wait(  --[[==============================]]0.1);end while true do  
                                        ContinuousColorChange();end end);AimBotSN:NewButton(        --[[============================================]]"EXIT AIMBOT",      
                                        "EXIT AIMBOT",function()getgenv().Aimbot.Functions:Exit --[[======================================================]]();end);local   
                                      HitBox=Window:NewTab("HitBox/ESP");local HitBoxSN=    --[[==========================================================]]HitBox:NewSection 
                                      ("HitBox");HitBoxSN:NewSlider("HitBox Size",        --[[==============================================================]]"HitBox Size",  
                                      500,0,function(HitBoxSize)_G.HeadSize=HitBoxSize;_G --[[================================================================]].Disabled=true; 
                                      game:GetService("RunService").RenderStepped:connect --[[==================================================================]](function()if 
                                       _G.Disabled then for i,v in next,game:GetService(  --[[==================================================================]]"Players"):       
                                    GetPlayers() do if (v.Name~=game:GetService("Players" --[[====================================================================]]).LocalPlayer 
                    .Name) then pcall(function()v.Character.HumanoidRootPart.Size=Vector3 --[[====================================================================]].new(_G.        
              HeadSize,_G.HeadSize,_G.HeadSize);v.Character.HumanoidRootPart.Transparency --[[======================================================================]]=0.7;v.       
            Character.HumanoidRootPart.BrickColor=BrickColor.new("Really blue");v.        --[[======================================================================]]Character.    
          HumanoidRootPart.Material="Neon";v.Character.HumanoidRootPart.CanCollide=false; --[[======================================================================]]end);end end  
        end end);end);HitBoxSN:NewSlider("HitBox Size v2","HitBox Size",10000,500,        --[[======================================================================]]function(     
        HitBoxSize)_G.HeadSize=HitBoxSize;_G.Disabled=true;game:GetService("RunService"). --[[======================================================================]]RenderStepped 
      :connect(function()if _G.Disabled then for i,v in next,game:GetService("Players"):  --[[======================================================================]]GetPlayers()  
      do if (v.Name~=game:GetService("Players").LocalPlayer.Name) then pcall(function()v.   --[[==================================================================]]Character.      
      HumanoidRootPart.Size=Vector3.new(_G.HeadSize,_G.HeadSize,_G.HeadSize);v.Character.   --[[================================================================]]HumanoidRootPart. 
    Transparency=0.7;v.Character.HumanoidRootPart.BrickColor=BrickColor.new("Really blue"); --[[==============================================================]]v.Character.      
    HumanoidRootPart.Material="Neon";v.Character.HumanoidRootPart.CanCollide=false;end);end   --[[==========================================================]]end end end);end);  
    local ESPSN=HitBox:NewSection("ESP");ESPSN:NewButton("Open ESP/Restart","Open ESP/Restart", --[[====================================================]]function()loadstring(   
    game:HttpGet(                                                                                 --[[==============================================]]                          
    "https://raw.githubusercontent.com/Exunys/Wall-Hack/main/Resources/Scripts/Main.lua"))();local    --[[====================================]]Environment=getgenv().        
    WallHack;Environment.Settings.Enabled=true;Environment.Settings.TeamCheck=false;Environment.Settings. --[[========================]]AliveCheck=true;Environment.Visuals.  
    ESPSettings.Enabled=true;Environment.Visuals.TracersSettings.Enabled=true;Environment.Visuals.BoxSettings.Enabled=true;Environment.Visuals.HeadDotSettings.Enabled=true 
  ;Environment.Crosshair.CrosshairSettings.Enabled=true;getgenv().WallHack.Functions:ResetSettings();end);ESPSN:NewToggle("Open/Close","Open/Close",function(open)if open 
   then getgenv().WallHack.Settings.Enabled=true;else getgenv().WallHack.Settings.Enabled=false;end end);ESPSN:NewToggle("Display Name","Display Name",function(name)if 
   name then getgenv().WallHack.Visuals.ESPSettings.DisplayName=true;else getgenv().WallHack.Visuals.ESPSettings.DisplayName=false;end end);ESPSN:NewSlider(              
  "Tracersu style","Tracersu style",5,0,function(style)getgenv().WallHack.Visuals.TracersSettings.Type=style;end);ESPSN:NewSlider("ESPBox style","ESPBox style",5,0,      
  function(style)getgenv().WallHack.Visuals.BoxSettings.Type=style;end);ESPSN:NewButton("Rambo ESP","Raimbo",function()local headDotColor={0,0,0};local boxColor={0,0,0}; 
  local Tracer={0,0,0};local textColor={0,0,0};local speed={5,15,20};function ContinuousColorChange()for i=1,3 do headDotColor[i]=(headDotColor[i] + speed[i])%256 ;      
  boxColor[i]=(boxColor[i] + speed[i])%256 ;textColor[i]=(textColor[i] + speed[i])%256 ;Tracer[i]=(textColor[i] + speed[i])%256 ;end getgenv().WallHack.Visuals.          
  HeadDotSettings.Color=table.concat(headDotColor,", ");getgenv().WallHack.Visuals.BoxSettings.Color=table.concat(boxColor,", ");getgenv().WallHack.Visuals.ESPSettings.  
  TextColor=table.concat(textColor,", ");getgenv().WallHack.Visuals.TracersSettings.Color=table.concat(Tracer,", ");wait(0.1);end while true do ContinuousColorChange();  
  end end);local Player=Window:NewTab("Player");local PlayerSN=Player:NewSection("Player");PlayerSN:NewSlider("Player height","Player height",300,1,function(HipHeight)   
  game:GetService("Players").LocalPlayer.Character.Humanoid.HipHeight=HipHeight;end);PlayerSN:NewButton("Flashlight","Flashlight",function()character=game:GetService(    
  "Players").LocalPlayer.Character;pointLight=Instance.new("PointLight");pointLight.Parent=character.HumanoidRootPart;end);PlayerSN:NewButton("plain block",                
  "Turns your character's head into a plain block.",function()game:GetService("Players").LocalPlayer.Head.Mesh:Destroy();end);local Move=Window:NewTab("Move");local MoveSN 
  =Move:NewSection("Move");MoveSN:NewSlider("Gravity","Gravity",0,196.2,function(Gravity)workspace.Gravity=Gravity;end);MoveSN:NewSlider("Walk Speed","Walk Speed",500,20,  
  function(Speed)local walkspeedplayer=game:GetService("Players").LocalPlayer;local walkspeedmouse=walkspeedplayer:GetMouse();local walkspeedenabled=false;if (             
  walkspeedenabled==false) then _G.WS=Speed;local Humanoid=game:GetService("Players").LocalPlayer.Character.Humanoid;Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect 
  (function()Humanoid.WalkSpeed=_G.WS;end);Humanoid.WalkSpeed=_G.WS;walkspeedenabled=true;elseif (walkspeedenabled==true) then _G.WS=Speed;local Humanoid=game:GetService(  
  "Players").LocalPlayer.Character.Humanoid;Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()Humanoid.WalkSpeed=_G.WS;end);Humanoid.WalkSpeed=_G.WS;        
  walkspeedenabled=false;end walkspeedmouse.KeyDown:connect(x_walkspeed);end);MoveSN:NewSlider("Jump Power","Jump Power",500,30,function(Power)local JumpPowerplayer=game:  
  GetService("Players").LocalPlayer;local JumpPowermouse=JumpPowerplayer:GetMouse();local JumpPowerenabled=false;if (JumpPowerenabled==false) then _G.WS=Power;local        
  Humanoid=game:GetService("Players").LocalPlayer.Character.Humanoid;Humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()Humanoid.JumpPower=_G.WS;end);        
  Humanoid.JumpPower=_G.WS;JumpPowerenabled=true;elseif (JumpPowerenabled==true) then _G.WS=Power;local Humanoid=game:GetService("Players").LocalPlayer.Character.Humanoid; 
  Humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()Humanoid.JumpPower=_G.WS;end);Humanoid.JumpPower=_G.WS;JumpPowerenabled=false;end JumpPowermouse.KeyDown 
  :connect(x_JumpPower);end);MoveSN:NewButton("infinite Jump","infinite Jump",function()game:GetService("UserInputService").JumpRequest:connect(function()game("Players").  
  LocalPlayer.Character("Humanoid"):ChangeState("Jumping");end);end);MoveSN:NewButton("Air Walk(v)","Air Walk",function()local UIS=game:GetService("UserInputService");   
  local isClimbing=false;local tracker=nil;UIS.InputBegan:Connect(function(input,gpe)if gpe then return;end if (input.KeyCode==Enum.KeyCode.V) then isClimbing=true;if    
  tracker then tracker:Destroy();end local instance=Instance.new("Part");tracker=instance;while isClimbing do wait();instance.Parent=workspace;instance.Position=game:    
    GetService("Players").LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, -2,0) ;instance.Anchored=true;end end end);UIS.InputEnded:Connect(function(    
    input,gpe)if gpe then return;end if (input.KeyCode==Enum.KeyCode.V) then isClimbing=false;end end);end);MoveSN:NewButton("Noclip","Noclip",function()local Noclip=nil 
    ;local Clip=nil;function noclip()Clip=false;local function Nocl()if ((Clip==false) and (game.Players.LocalPlayer.Character~=nil)) then for _,v in pairs(game.Players. 
    LocalPlayer.Character:GetDescendants()) do if (v:IsA("BasePart") and v.CanCollide and (v.Name~=floatName)) then v.CanCollide=false;end end end wait(0.21);end Noclip= 
      game:GetService("RunService").Stepped:Connect(Nocl);end function clip()if Noclip then Noclip:Disconnect();end Clip=true;end noclip();end);MoveSN:NewButton("Fly", 
      "Fly",function()while wait(3) do local uis=game:GetService("UserInputService");local rs=game:GetService("RunService");wait(3);local myPlayer=game.Players.        
      LocalPlayer;local myChar=myPlayer.Character;local myHRP=myChar:WaitForChild("HumanoidRootPart");local camera=game.Workspace.CurrentCamera;local LastTapped,Tapped 
        =false,false;local flyUpSpeed=20;local flyDownSpeed=20;local wdown=false;local toggle=false;local flying=false;local speed=5;local bp=nil;local bg=nil;local    
        bodyVel=nil;function fly()bp=Instance.new("BodyPosition",myHRP);bp.MaxForce=Vector3.new();bp.D=100;bg=Instance.new("BodyGyro",myHRP);bg.MaxTorque=Vector3.new() 
        ;bg.D=100;flying=true;bp.Position=myHRP.Position + Vector3.new(0,10,0) ;bp.MaxForce=Vector3.new(400000,400000,400000);bg.MaxTorque=Vector3.new(400000,400000,   
          400000);end while flying do rs.RenderStepped:wait();bp.Position=myHRP.Position + ((myHRP.Position-camera.CFrame.p).unit * speed) ;bg.CFrame=CFrame.new(     
            camera.CFrame.p,myHRP.Position);end uis.InputBegan:connect(function(Input)if ((Input.KeyCode==Enum.KeyCode.W) and (flying==true) and (wdown==false)) then 
               if (toggle==false) then bp:Destroy();wdown=true;bodyVel=Instance.new("BodyVelocity",myHRP);bodyVel.MaxForce=Vector3.new(math.huge,math.huge,math.huge) 
                ;while flying and wait()  do bodyVel.Velocity=camera.CFrame.LookVector * speed * 100 ;end end end end);uis.InputEnded:Connect(function(Input)if ((    
                  Input.KeyCode==Enum.KeyCode.W) and (flying==true) and (wdown==true)) then if (toggle==false) then wdown=false;bodyVel:Destroy();bp=Instance.new(  
                      "BodyPosition",myHRP);bp.MaxForce=Vector3.new(math.huge,math.huge,math.huge);bp.D=100;bp.Position=myHRP.Position;end end end);function        
                                  endFlying()bp:Destroy();bg:Destroy();flying=false;end uis.InputBegan:connect(function(input)if (input.KeyCode==Enum.KeyCode.F)    
                                      then if  not flying then fly();else endFlying();end end end);end end);etService("UserInputService");local mouse=player:       
                                      GetMouse();repeat wait();until mouse UserInputService.                InputBegan:Connect(function(input,gameProcessed)player. 
                                      Character:MoveTo(Vector3.new(mouse.Hit.x,mouse.Hit.y,mouse.           Hit.z));end);local Fun=Window:NewTab("Fun");local     
                                      FunSN=Fun:NewSection("Fun");FunSN:NewButton("Anti-Anti-Cheat"         ,"Prevent cheating in advance",function()local player 
                                      =game.Players.LocalPlayer;local character=player.Character;           local maxDistance=30;local nowPot=character.          
                                      HumanoidRootPart.Position;if AntiCheat then while true do               wait(1);local currentPosition=character.            
                                      HumanoidRootPart.Position;local distance=(currentPosition-              nowPot).Magnitude;if (distance>maxDistance) then    
                                      character:SetPrimaryPartCFrame(CFrame.new(nowPot));else                 nowPot=currentPosition;end end else end end);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
--------------------------------------------------------------------------------
