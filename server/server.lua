function getEmbedTimestamp()
    return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

function sendToDiscord(title, message, color, playerId, includeId)
    local playerName = GetPlayerName(playerId) or "Unknown"
    local discordId = "Not Found"
    local identifiers = GetPlayerIdentifiers(playerId)
    for _, id in pairs(identifiers) do
        if string.find(id, "discord:") then
            discordId = id:gsub("discord:", "")
            break
        end
    end

    local embed = {
        {
            ["title"] = title,
            ["description"] = message,
            ["color"] = color,
            ["fields"] = {
                {["name"] = "Player Name", ["value"] = playerName, ["inline"] = true},
                {["name"] = "Discord ID", ["value"] = discordId, ["inline"] = true}
            },
            ["footer"] = {
                ["text"] = "Guardian - Server Logs",
                ["icon_url"] = "https://cdn.discordapp.com/icons/1337271515808530543/a_c39ac61c8cd6642dc3ce0222c24780ce.gif?size=4096"
            },
            ["timestamp"] = getEmbedTimestamp()
        }
    }

    if includeId then
        table.insert(embed[1]["fields"], {["name"] = "Player ID", ["value"] = tostring(playerId), ["inline"] = true})
    end

    PerformHttpRequest(
        Config.Webhook,
        function()
        end,
        "POST",
        json.encode({username = "Server Logs", embeds = embed}),
        {["Content-Type"] = "application/json"}
    )
end

-- Player Connect Logging
AddEventHandler(
    "playerConnecting",
    function(name, setKickReason, deferrals)
        local msg = name .. " is connecting to the server."
        sendToDiscord("Player Connecting", msg, 3066993, source, false)
    end
)

-- Player Disconnect Logging
AddEventHandler(
    "playerDropped",
    function(reason)
        local name = GetPlayerName(source)
        local msg = name .. " (ID: " .. source .. ") has left the server. Reason: " .. reason
        sendToDiscord("Player Disconnected", msg, 15158332, source, true)
    end
)

-- Chat Logging
AddEventHandler(
    "chatMessage",
    function(source, _, message)
        local msg = GetPlayerName(source) .. " said: " .. message
        sendToDiscord("Chat Message", msg, 3447003, source, true)
    end
)

-- Admin Kick Logging
RegisterServerEvent("admin:kick")
AddEventHandler(
    "admin:kick",
    function(target, reason)
        local msg = GetPlayerName(target) .. " was kicked for: " .. reason
        sendToDiscord("Admin Kick", msg, 15105570, target, true)
        DropPlayer(target, reason)
    end
)

local WeaponNames = {
    [GetHashKey("WEAPON_UNARMED")] = "Melee",
    [GetHashKey("WEAPON_PISTOL")] = "Pistol",
    [GetHashKey("WEAPON_ASSAULTRIFLE")] = "Assault Rifle",
    [GetHashKey("WEAPON_EXPLOSION")] = "Explosion",
    [GetHashKey("WEAPON_FALL")] = "Fall Damage",
    [GetHashKey("WEAPON_DROWNING")] = "Drowning",
    [GetHashKey("WEAPON_RUN_OVER")] = "Ran Over",
    [GetHashKey("WEAPON_FIRE")] = "Fire"
}

local function GetDeathCauseText(deathCause)
    for hash, name in pairs(WeaponNames) do
        if hash == deathCause then
            return name
        end
    end
    return "Unknown"
end

RegisterServerEvent("baseevents:onPlayerDied")
AddEventHandler(
    "baseevents:onPlayerDied",
    function(deathCause)
        local victimId = source
        local victimName = GetPlayerName(victimId) or "Unknown"
        local causeText = GetDeathCauseText(deathCause)
        local msg = victimName .. " died. (Cause: " .. causeText .. ")"

        sendToDiscord("Death Log", msg, 16711680, victimId)
    end
)

RegisterServerEvent("baseevents:onPlayerKilled")
AddEventHandler(
    "baseevents:onPlayerKilled",
    function(killerId, deathCause)
        local victimId = source
        local victimName = GetPlayerName(victimId) or "Unknown"
        local killerName = killerId and GetPlayerName(killerId) or "Unknown"
        local causeText = GetDeathCauseText(deathCause)
        local msg = killerName .. " killed " .. victimName .. " (Cause: " .. causeText .. ")"

        sendToDiscord("Kill Log", msg, 16711680, victimId)
    end
)
