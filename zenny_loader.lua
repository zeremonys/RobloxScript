-- zenny private loader — auto-load main script (no UI, no checkbox)
-- cache-bust via ?v=tick() so GitHub CDN serves fresh file every time
loadstring(game:HttpGet("https://raw.githubusercontent.com/zeremonys/RobloxScript/main/zenny_private.lua?v=" .. tick()))()
