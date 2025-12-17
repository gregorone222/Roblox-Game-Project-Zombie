-- DialogueConfig.lua (ModuleScript)
-- Path: ReplicatedStorage/ModuleScript/DialogueConfig.lua
-- Script Place: Lobby, ACT 1: Village

--[[
    NPC Dialogue Database.
    Structure: [DialogueID] = { Array of Nodes }
    Each Node has:
        - ID (number): Unique identifier within this dialogue.
        - Speaker (string): Name of the speaker.
        - Text (string): Text to display.
        - Actions (table?): Optional actions (PlaySound, SetAttribute, etc).
        - NextID (number?): ID of the next node. If nil, dialogue ends.
        - Choices (table?): Choices for the player (not yet implemented).
]]

local DialogueConfig = {}

-- === LOBBY DIALOGUES ===

DialogueConfig.Dialogues = {
    -- Alexander: First greeting when player approaches
    ["alexander_intro"] = {
        {
            ID = 1,
            Speaker = "Alexander",
            Text = "Welcome, Operator. I'm glad to see you still standing.",
            NextID = 2
        },
        {
            ID = 2,
            Speaker = "Alexander",
            Text = "This station is our last safe haven. Use your time to prepare yourself.",
            NextID = 3
        },
        {
            ID = 3,
            Speaker = "Alexander",
            Text = "We have new intel from the \"Cursed Village\". That is Ground Zero of the outbreak.",
            NextID = 4
        },
        {
            ID = 4,
            Speaker = "Alexander",
            Text = "When you are ready, meet me at the command table. We will discuss your mission.",
            NextID = nil,
            Choices = {
                {
                    Text = "I'm ready now.",
                    NextID = 5,
                    Signal = "OpenLobby"
                },
                {
                    Text = "I need more time.",
                    NextID = nil
                }
            }
        },
        {
            ID = 5,
            Speaker = "Alexander",
            Text = "That's the spirit. Check the map board behind me to start ACT 1.",
            NextID = nil
        }
    },

    -- Alexander: Mission Briefing (called from LobbyRoomUI or directly)
    ["alexander_mission_briefing"] = {
        {
            ID = 1,
            Speaker = "Alexander",
            Text = "Alright, Operator. Listen closely.",
            Actions = { PlaySound = "RadioStatic" },
            NextID = 2
        },
        {
            ID = 2,
            Speaker = "Alexander",
            Text = "Our target is the Village in the Red Zone. Intel suggests high-level mutation activity.",
            NextID = 3
        },
        {
            ID = 3,
            Speaker = "Alexander",
            Text = "Main Objective: Survive until Wave 50 and neutralize the biggest threats.",
            NextID = 4
        },
        {
            ID = 4,
            Speaker = "Alexander",
            Text = "Good luck. Prepare your weapons and choose your difficulty at the command board.",
            NextID = nil
        }
    },

    -- Quartermaster: Short greeting
    ["quartermaster_greet"] = {
        {
            ID = 1,
            Speaker = "Quartermaster",
            Text = "Need something? Coins and Achievement Points can be exchanged here.",
            NextID = nil
        }
    }
}

-- Helper to get dialogue
function DialogueConfig.GetDialogue(dialogueID)
    return DialogueConfig.Dialogues[dialogueID]
end

-- Helper to get specific node in dialogue
function DialogueConfig.GetNode(dialogueID, nodeID)
    local dialogue = DialogueConfig.Dialogues[dialogueID]
    if not dialogue then return nil end

    for _, node in ipairs(dialogue) do
        if node.ID == nodeID then
            return node
        end
    end
    return nil
end

return DialogueConfig
