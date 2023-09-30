_PluginName = 'JM_Live_Scenbuilder'
_VERSION = 'alpha_v0.1'

-- TODO: Description

-- Created by Johannes Münch
-- Last updated Aug 24, 2023
-- E-Mail: maplugins@jmlutra.de

-------------------------------------------------------------------------------
--------------------------------- User Config ---------------------------------
---------------------------- (you can edit them) ------------------------------

UsePreConf = true
Screen = 5
BuilderView = 31
SafeView = 32
Executors = { 1.2, 1.3, 1.4, 1.5, 1.6 }

-------------------------------------------------------------------------------
--------------------------- DO NOT EDIT BELOW HERE! ---------------------------
-------------------------------------------------------------------------------

-- Systemvariables
Feed = gma.feedback
Cmd = gma.cmd
Gui = gma.gui
Obj = gma.show.getobj


function Main(args)
    Feed('\n***Live Scenebuilder***\n\nVersion ' .. _VERSION .. '\n\nCreated by Johannes Münch')
    gma.echo('***Live Scenebuilder***\n\nVersion ' .. _VERSION .. '\n\nCreated by Johannes Münch')

    --if args == nil and gma.show.getvar('JM_Live_Scenebuilder_Setup') ~= "1" then
    if not Setup() then goto abortedSetup end
    --end
    ::abortedSetup::
end

function Setup()
    Feed('Setup')
    --gma.show.setvar('JM_Live_Scenebuilder_Setup', 1)
    local s = ''
    if not UsePreConf then
        s =
            'Welcome to the Live Scenebuilder Setup!\n\nThe following Inputs are needed to Setup the Live Scenebuilder:\n' ..
            '- The Screen on which the Live Scenebuilder will be displayed\n' ..
            '- The View that will be used for the Live Scenebuilder\n' ..
            '- The View that will be used to store your current view, so you can return back to it instantly\n' ..
            '- The Executors that will be used to trigger the build Scenes\n\n' ..
            'If you want to Cancel the Setup, press "Cancel", otherwise press "OK" to continue.\n' ..
            '(In order to streamline the setup in the future you can set the variables "UsePreConf", "Screen", "BuilderView" and "SafeView" in the plugin to your desired values)'
    else
        s =
            'Welcome to the Live Scenebuilder Setup!\n\nDue to the variable "UsePreConf" being set to true, the following Values will be used:\n' ..
            '- Screen: ' .. Screen .. '\n' ..
            '- BuilderView: ' .. BuilderView .. '\n' ..
            '- SafeView: ' .. SafeView .. '\n' ..
            '- Executors: ' .. tostring(Executors) .. '\n\n' ..
            'If you want to use those values, press "OK", otherwise press "Cancel" and go through the setup normally.'
    end
    if not Gui.confirm('Live Scenebuilder Setup', s) then
        if not UsePreConf then
            Feed('Setup aborted')
            return false
        else
            Feed('Setup aborted, using PreConf, rerunning Setup')
            UsePreConf = false
            Setup()
        end
    end

    SetupGetCheckValues()

    SetupScreen()
end

function SetupGetCheckValues()
    if not UsePreConf then
        Screen = 0
        while Screen < 1 or Screen > 6 do
            Screen = tonumber(GetNonEmptyUserInput('Screen', 'Enter Screen Number {1-6}'))
        end
        BuilderView = GetNonEmptyUserInput('BuilderView', 'Enter the View that will be used for the Live Scenebuilder')
    end
    --TODO: Undo
    --[[ while Obj.handle('View '..BuilderView) ~= nil do
        BuilderView = GetNonEmptyUserInput('BuilderView', 'Please make sure the View is empty')
    end ]]

    if not UsePreConf then
        SafeView = GetNonEmptyUserInput('SafeView', 'Enter the View that will be used to store your current view.')
    end
    --TODO: Undo
    --[[ while Obj.handle('View '..SafeView) ~= nil do
        SafeView = GetNonEmptyUserInput('SafeView', 'Please make sure the View is empty')
    end ]]
    if not UsePreConf then
        ::exStart::
        Gui.msgbox('Executor Setup', 'Please enter a maximum of 5 Executors one after another. {Page.Nr}')
        for i = 1, 5 do
            Executors[i] = GetUserInput('Executor ' .. i, 'Enter Executor {Page.Nr}')
            if Executors[i] == nil then
                if i > 1 then
                    goto exFin
                else
                    goto exStart
                end
            end
        end
        ::exFin::
    end
end

function SetupScreen()
    Cmd('Store View ' .. SafeView .. ' /screen=' .. Screen)
    Cmd('Delete Screen ' .. Screen)
    Cmd('Store Screen ' .. Screen .. '.1')
    Cmd('Assign Screen ' .. Screen .. '.1/Type=Macros /Height=1 /Width='..Tablelength(Executors)..' /Display=' .. Screen - 1)
    Cmd('Store View ' .. BuilderView .. ' /screen=' .. Screen)
    Cmd('Export View ' .. BuilderView .. ' \"JM_CreateBuilderView\" /o /nc /p=\"' .. gma.show.getvar('TEMPPATH') .. '\"')
    
    local path = gma.show.getvar('TEMPPATH') .. '/JM_CreateBuilderView.xml'
    if gma.show.getvar('OS') == 'WINDOWS' then
        path = string.gsub(path, '/', '\\')
    end
    Feed('Modifying the XML')
    ModifyFile('<Widget index="0" type="4d414352"', ' scroll_offset="1" scroll_index="'..index..'"', '>', path)
    Cmd('Import \"JM_CreateBuilderView\" At View '..BuilderView..'/nc /o /p=\"' .. gma.show.getvar('TEMPPATH') .. '\"' )
    Cmd('View '..BuilderView..'/Screen='..Screen)
    Gui.msgbox('Scenebuilder Setup', 'Now you can create your Live Scenebuilder View.\nIt works by storing the Programmer values into an executor, \nso keep in mind that it\'s not possible to use other Executors within a Live Scene \nYou can pretty much do what you want, \nonly the Macropool in the top left corner has to be somewhere on the view.\n In the end just activate the macro and your view will be stored.')
    gma.sleep(5)
    Cmd('View '..SafeView..'/Screen='..Screen)
end

--[[ function WorkXML()
    local path = gma.show.getvar('TEMPPATH') .. '/JM_CreateBuilderView.xml'
    if gma.show.getvar('OS') == 'WINDOWS' then
        path = string.gsub(path, '/', '\\')
    end
    Feed(path)
    ModifyFile('<Widget index="0" type="4d414352"', ' scroll_offset="1" scroll_index="1"', '>', path)
end ]]

function Cleanup()

end

-- Utility Functions
function Tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function CreateMacro(macroNum, label, macroLines)
    gma.cmd('Store Macro 1.' .. macroNum)
    gma.cmd('Label Macro 1.' .. macroNum .. ' \"' .. label .. '\"')

    for i = 1, Tablelength(macroLines) do
        gma.cmd('Store Macro 1.' .. macroNum .. '.' .. i)
        gma.cmd('Assign Macro 1.' .. macroNum .. "." .. i .. '/cmd=\"' .. macroLines[i] .. '\"')
    end
    gma.cmd('Assign Macro 1.' .. macroNum .. '.1 /info=\"' .. _PluginName .. '\"')
end

function GetUserInput(msg, placeholder)
    local userInput = gma.textinput(msg, placeholder)
    if userInput == placeholder then
        userInput = nil
    end
    return userInput
end

function GetNonEmptyUserInput(msg, placeholder)
    placeholder = placeholder or ''
    local userInput = ''
    repeat
        userInput = gma.textinput(msg, placeholder)
    until userInput ~= placeholder

    return userInput
end

--[[ function GetNthLine(fileName, n)
    local f = io.open(fileName, "r")
    local count = 1

    for line in f:lines() do
        if count == n then
            f:close()
            return line
        end
        count = count + 1
    end

    f:close()
    Feed("Not enough lines in file!")
end ]]

function ModifyFile(targetLinePrefix, insertAttributes, symbol, fileName)
    
    local file = io.open(fileName, 'r')

    if file then
        local modifiedContent = {}
        local lineModified = false

        for line in file:lines() do
            local position = line:find(targetLinePrefix)

            if position then
                local symbolPosition = line:find(symbol, position)

                if symbolPosition then
                    line = line:sub(1, symbolPosition - 1) .. insertAttributes .. line:sub(symbolPosition)
                    lineModified = true
                end
            end
            table.insert(modifiedContent, line)
        end

        file:close()

        if lineModified then
            file = io.open(fileName, 'w')

            if file then
                for _, line in ipairs(modifiedContent) do
                    file:write(line, '\n')
                end

                file:close()
                return true
            else
                return false  
            end
        else
            return false  
        end
    else
        return false 
    end
end

return Main, Cleanup;
