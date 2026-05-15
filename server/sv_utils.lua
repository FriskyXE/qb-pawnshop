local QBCore = exports['qb-core']:GetCoreObject()

local function discordLog(title, message, color)
    if not Config.Webhook or Config.Webhook == "" then return end
    local embed = {{ ["color"] = color, ["title"] = "**" .. title .. "**", ["description"] = message, ["footer"] = { ["text"] = os.date("%c") }}}
    PerformHttpRequest(Config.Webhook, function(err, text, headers) end, 'POST', json.encode({ username = "Pawn Shop Logs", embeds = embed }), { ['Content-Type'] = 'application/json' })
end

local function exploitBan(id, reason)
    MySQL.insert('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        GetPlayerName(id), QBCore.Functions.GetIdentifier(id, 'license'), QBCore.Functions.GetIdentifier(id, 'discord'), QBCore.Functions.GetIdentifier(id, 'ip'),
        reason, 2147483647, 'qb-pawnshop'
    })
    TriggerEvent('qb-log:server:CreateLog', 'pawnshop', 'Player Banned', 'red', string.format('%s was banned for %s', GetPlayerName(id), reason), true)
    discordLog("🛑 CHEATER BANNED", string.format("**%s** (ID: %s) banned for: %s", GetPlayerName(id), id, reason), 15158332)
    DropPlayer(id, 'You were permanently banned: Exploiting')
end

exports('discordLog', discordLog)
exports('exploitBan', exploitBan)
