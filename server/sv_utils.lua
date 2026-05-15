local QBCore = exports['qb-core']:GetCoreObject()

function discordLog(type, title, message, color)
    local webhook = Config.Webhooks[type]
    if not webhook or webhook == "" then return end
    
    local embed = {{
        ["color"] = color,
        ["title"] = "**" .. title .. "**",
        ["description"] = message,
        ["footer"] = { ["text"] = os.date("%c") }
    }}
    
    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({ 
        username = "Pawn Shop " .. type:gsub("^%l", string.upper), 
        embeds = embed 
    }), { ['Content-Type'] = 'application/json' })
end

function exploitBan(id, reason)
    local Player = QBCore.Functions.GetPlayer(id)
    if not Player then return end

    MySQL.insert('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        GetPlayerName(id), QBCore.Functions.GetIdentifier(id, 'license'), QBCore.Functions.GetIdentifier(id, 'discord'), QBCore.Functions.GetIdentifier(id, 'ip'),
        reason, 2147483647, 'qb-pawnshop'
    })

    TriggerEvent('qb-log:server:CreateLog', 'pawnshop', 'Player Banned', 'red', string.format('%s was banned for %s', GetPlayerName(id), reason), true)
    discordLog("security", "🛑 CHEATER BANNED", string.format("**%s** (ID: %s) banned for: %s", GetPlayerName(id), id, reason), 15158332)
    DropPlayer(id, 'You were permanently banned: Exploiting')
end
