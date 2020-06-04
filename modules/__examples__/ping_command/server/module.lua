M('command')
local utils = M("utils")

module.init = function()
  -- Command.Register(
  --   "ping",
  --   "admin",
  --   function(player, args, showError)
  --     print(json_encode(player))
  --   end,
  --   false,
  --   {help = "Ping me, I'll pong you"}
  -- )
  local pingCommand = Command("ping", "admin", "I'll return you a ping, for suuuure")
  pingCommand:addArgument("arg1", "player", "Player argument description")

  pingCommand:setHandler(function(player, args, baseArgs)
    print(player.identifier)
    print(args.arg1.identifier)
  end)

  pingCommand:register()
end