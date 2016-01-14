public int main()
{
    Environment.init();

    uint16 port = 1337;

    print("Starting LobbyController on port: " + port.to_string() + "\n");

    LobbyController lobby = new LobbyController(port);
    if (!lobby.start())
    {
        print("main: Could not start lobby!\n");
        return -1;
    }

    lobby.work();

    return 0;
}
