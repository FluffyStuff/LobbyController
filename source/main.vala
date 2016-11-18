private static bool debug =
#if DEBUG
    true
#else
    false
#endif
;

public int main()
{
    Environment.init(debug);

    uint16 port = Environment.LOBBY_PORT;

    Environment.log(LogType.INFO, "Main", "Starting LobbyController on port " + port.to_string());

    LobbyController lobby = new LobbyController(port);
    if (!lobby.start())
    {
        Environment.log(LogType.ERROR, "Main", "Could not start lobby");
        return -1;
    }

    lobby.work();

    return 0;
}
