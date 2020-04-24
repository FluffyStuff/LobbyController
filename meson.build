project('LobbyController', 'vala', 'c')

engine_vapi_dir = meson.current_source_dir() / 'OpenRiichi' / 'Engine' / 'vapi'
add_project_arguments(['--vapidir', engine_vapi_dir], language: 'vala')
add_project_arguments('-D', get_option('buildtype').to_upper(), language: 'vala')
add_project_arguments('-D', target_machine.system().to_upper(), language: 'vala')

cc = meson.get_compiler('c')
valac = meson.get_compiler('vala')
dependencies = [
    dependency('glib-2.0', version: '>=2.54'),
    dependency('gobject-2.0'),
    dependency('gio-2.0'),
    dependency('gee-0.8'),
    dependency('zlib'),
    cc.find_library('m', required : false),
    valac.find_library('os', dirs: meson.current_source_dir() / 'OpenRiichi' / 'vapi', required: false)
]

sources = files(
    'source/LobbyController.vala',
    'source/LobbyGameServerController.vala',
    'source/main.vala',
    'OpenRiichi/source/Environment.vala',
    'OpenRiichi/source/Game/ServerSettings.vala',
    'OpenRiichi/source/Game/Options.vala',
    'OpenRiichi/source/Game/Logic/AnimationTimings.vala',
    'OpenRiichi/source/Game/Logic/ClientAction.vala',
    'OpenRiichi/source/Game/Logic/ClientMessage.vala',
    'OpenRiichi/source/Game/Logic/ClientRoundState.vala',
    'OpenRiichi/source/Game/Logic/GameLog.vala',
    'OpenRiichi/source/Game/Logic/GamePlayer.vala',
    'OpenRiichi/source/Game/Logic/GameStartInfo.vala',
    'OpenRiichi/source/Game/Logic/GameState.vala',
    'OpenRiichi/source/Game/Logic/IGameConnection.vala',
    'OpenRiichi/source/Game/Logic/LobbyMessages.vala',
    'OpenRiichi/source/Game/Logic/RoundLog.vala',
    'OpenRiichi/source/Game/Logic/RoundState.vala',
    'OpenRiichi/source/Game/Logic/ServerAction.vala',
    'OpenRiichi/source/Game/Logic/ServerMessage.vala',
    'OpenRiichi/source/Game/Logic/Tile.vala',
    'OpenRiichi/source/Game/Logic/TileRules.vala',
    'OpenRiichi/source/Game/Logic/TimeStamp.vala',
    'OpenRiichi/source/Game/Logic/VersionInfo.vala',
    'OpenRiichi/source/GameServer/Bots/Bot.vala',
    'OpenRiichi/source/GameServer/Bots/BotConnection.vala',
    'OpenRiichi/source/GameServer/Bots/NullBot.vala',
    'OpenRiichi/source/GameServer/Bots/SimpleBot.vala',
    'OpenRiichi/source/GameServer/GameState/ServerRoundState.vala',
    'OpenRiichi/source/GameServer/GameState/ServerRoundStatePlayer.vala',
    'OpenRiichi/source/GameServer/GameState/ServerRoundStateValidator.vala',
    'OpenRiichi/source/GameServer/Server/Server.vala',
    'OpenRiichi/source/GameServer/Server/ServerController.vala',
    'OpenRiichi/source/GameServer/Server/ServerGameRound.vala',
    'OpenRiichi/source/GameServer/Server/ServerMenu.vala',
    'OpenRiichi/source/GameServer/Server/ServerNetworking.vala',
    'OpenRiichi/source/GameServer/Server/ServerPlayer.vala',
    'OpenRiichi/Engine/EngineLog.vala',
    'OpenRiichi/Engine/Helper/DeltaTimers.vala',
    'OpenRiichi/Engine/Helper/Helper.vala',
    'OpenRiichi/Engine/Helper/Timers.vala',
    'OpenRiichi/Engine/Helper/Networking.vala',
    'OpenRiichi/Engine/Helper/Threading.vala',
    'OpenRiichi/Engine/Helper/RandomClass.vala',
    'OpenRiichi/Engine/Files/FileLoader.vala',
    'OpenRiichi/Engine/Properties/Animation.vala',
    'OpenRiichi/Engine/Properties/Color.vala',
    'OpenRiichi/Engine/Properties/Curve.vala',
    'OpenRiichi/Engine/Properties/DeltaArgs.vala',
    'OpenRiichi/Engine/Properties/ScreenTypeEnum.vala',
)

executable('LobbyController', sources,
    dependencies: dependencies,
    install: true
)