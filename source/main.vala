public int main()
{
    fix_reflection_bug();

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

private void fix_reflection_bug()
{
    typeof(Lobby.ClientLobbyMessage).class_ref();
    typeof(Lobby.ClientLobbyMessageCloseTunnel).class_ref();
    typeof(Lobby.ClientLobbyMessageGetLobbies).class_ref();
    typeof(Lobby.ClientLobbyMessageAuthenticate).class_ref();
    typeof(Lobby.ClientLobbyMessageEnterLobby).class_ref();
    typeof(Lobby.ClientLobbyMessageLeaveLobby).class_ref();
    typeof(Lobby.ClientLobbyMessageEnterGame).class_ref();
    typeof(Lobby.ClientLobbyMessageLeaveGame).class_ref();
    typeof(Lobby.ClientLobbyMessageCreateGame).class_ref();

    typeof(NullBot).class_ref();
    typeof(SimpleBot).class_ref();
}
