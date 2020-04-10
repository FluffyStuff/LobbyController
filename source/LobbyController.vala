using Gee;
using Lobby;
using GameServer;
using Engine;

public class LobbyController
{
    private Networking net = new Networking();
    private int lobby_IDs = 0;
    private int user_IDs = 0;
    private ArrayList<ServerLobby> lobbies = new ArrayList<ServerLobby>();
    private ArrayList<ServerLobbyUser> users = new ArrayList<ServerLobbyUser>();
    private ArrayList<LobbyConnection> new_connections = new ArrayList<LobbyConnection>();
    private Mutex mutex = Mutex();

    public LobbyController(uint16 port)
    {
        this.port = port;
        create_lobby("English test lobby");
        create_lobby("日本テストロビー");
    }

    ~LobbyController()
    {
        net.close();
    }

    public bool start()
    {
        net.connected.connect(client_connected);
        return net.host(port);
    }

    public void work()
    {
        while (true)
        {
            process_connections();

            Thread.usleep(10 * 1000);
        }
    }

    private void create_lobby(string name)
    {
        ServerLobby lobby = new ServerLobby(lobby_IDs++, name);
        lobby.user_left_lobby.connect(user_left_lobby);
        lobbies.add(lobby);
    }

    private void process_connections()
    {
        mutex.lock();
        for (int i = 0; i < new_connections.size; i++)
        {
            LobbyConnection connection = new_connections[i];

            if (connection.disconnected)
            {
                new_connections.remove_at(i--);
                continue;
            }

            ClientLobbyMessage? message;
            while ((message = connection.dequeue_message()) != null)
            {
                if (message is ClientLobbyMessageVersionInfo)
                {
                    ClientLobbyMessageVersionInfo msg = message as ClientLobbyMessageVersionInfo;

                    if (!Environment.compatible(msg.version_info))
                    {
                        connection.send(new ServerLobbyMessageVersionMismatch(true));
                        connection.disconnect();
                        break;
                    }

                    connection.version_info = msg.version_info;
                    connection.send(new ServerLobbyMessageVersionInfo(Environment.version_info));
                }
                else if (message is ClientLobbyMessageAuthenticate)
                {
                    if (connection.version_info == null)
                    {
                        connection.disconnect();
                        break;
                    }

                    ClientLobbyMessageAuthenticate msg = message as ClientLobbyMessageAuthenticate;
                    if (authentication_request(connection, msg))
                    {
                        connection.send(new ServerLobbyMessageAuthenticationResult(true, null));
                        users.add(new ServerLobbyUser(user_IDs++, msg.username, connection));

                        new_connections.remove_at(i--);
                        break;
                    }
                    else
                        connection.send(new ServerLobbyMessageAuthenticationResult(false, "Authentication problem"));
                }
                else if (message is ClientLobbyMessageGetLobbies)
                {
                    if (connection.version_info == null)
                    {
                        connection.disconnect();
                        break;
                    }

                    get_lobbies_request(connection);
                }
            }

        }
        mutex.unlock();

        for (int i = 0; i < users.size; i++)
        {
            ServerLobbyUser user = users[i];

            if (user.disconnected)
            {
                users.remove_at(i--);
                continue;
            }

            ClientLobbyMessage? message;
            while ((message = user.dequeue_message()) != null)
            {
                if (message is ClientLobbyMessageAuthenticate)
                    user.send(new ServerLobbyMessageAuthenticationResult(false, "Already authenticated"));
                else if (message is ClientLobbyMessageGetLobbies)
                    get_lobbies_request(user.connection);
                else if (message is ClientLobbyMessageEnterLobby)
                {
                    if (enter_lobby_request(user, message as ClientLobbyMessageEnterLobby))
                    {
                        users.remove_at(i--);
                        break;
                    }
                }
            }
        }

        foreach (ServerLobby lobby in lobbies)
            lobby.process();
    }

    private bool authentication_request(LobbyConnection connection, ClientLobbyMessageAuthenticate message)
    {
        return Environment.is_valid_name(message.username);
    }

    private void get_lobbies_request(LobbyConnection connection)
    {
        LobbyInformation[] info = new LobbyInformation[lobbies.size];

        for (int i = 0; i < info.length; i++)
        {
            ServerLobby lobby = lobbies[i];
            info[i] = new LobbyInformation(lobby.ID, lobby.name, lobby.users.size);
        }

        connection.send(new ServerLobbyMessageLobbyEnumerationResult(true, info));
    }

    private bool enter_lobby_request(ServerLobbyUser user, ClientLobbyMessageEnterLobby request)
    {
        foreach (ServerLobby lobby in lobbies)
        {
            if (lobby.ID == request.ID)
                return lobby.add_user(user);
        }

        return false;
    }

    private void client_connected(Connection connection)
    {
        LobbyConnection con = new LobbyConnection(connection);
        mutex.lock();
        new_connections.add(con);
        mutex.unlock();
    }

    private void user_left_lobby(ServerLobby lobby, ServerLobbyUser user)
    {
        mutex.lock();
        new_connections.add(user.connection);
        mutex.unlock();
    }

    public uint16 port { get; private set; }
}

public class LobbyConnection
{
    private Mutex mutex = Mutex();
    private Mutex send_mutex = Mutex();
    private ArrayList<ClientLobbyMessage> messages = new ArrayList<ClientLobbyMessage>();

    public signal void tunnel_disconnected(LobbyConnection connection);

    public LobbyConnection(Connection connection)
    {
        this.connection = connection;
        connection.closed.connect(do_disconnected);
        connection.message_received.connect(message_received);
        tunneled_connection = new ServerPlayerTunneledConnection();
        tunneled_connection.send_message_request.connect(send_message_request);
        tunneled_connection.close_connection_request.connect(close_connection_request);

        version_info = null;
    }

    ~LobbyConnection()
    {
        connection.closed.disconnect(do_disconnected);
        connection.message_received.disconnect(message_received);
        tunneled_connection.send_message_request.disconnect(send_message_request);
        tunneled_connection.close_connection_request.disconnect(close_connection_request);
    }

    public void send(ServerLobbyMessage message)
    {
        send_mutex.lock();
        connection.send(new Message(message.serialize()));
        send_mutex.unlock();
    }

    public ClientLobbyMessage? dequeue_message()
    {
        ClientLobbyMessage? message = null;
        mutex.lock();
        if (messages.size > 0)
            message = messages.remove_at(0);
        mutex.unlock();

        return message;
    }

    public void disconnect()
    {
        connection.close();
    }

    private void send_message_request(ServerPlayerTunneledConnection connection, ServerMessage message)
    {
        send_mutex.lock();
        this.connection.send(new Message(message.serialize()));
        send_mutex.unlock();
    }

    private void close_connection_request()
    {
        send(new ServerLobbyMessageCloseTunnel());
        tunnel_disconnected(this);
    }

    private void message_received(Connection connection, Message msg)
    {
        Serializable? m = Serializable.deserialize(msg.get_message());

        if (m == null || !(m.get_type().is_a(typeof(ClientLobbyMessage)) || m.get_type().is_a(typeof(ClientMessage))))
        {
            Environment.log(LogType.DEBUG, "LobbyConnection", "Server discarding invalid client lobby message");
            return;
        }

        if (m.get_type().is_a(typeof(ClientMessage)))
        {
            tunneled_connection.receive_message(m as ClientMessage);
            return;
        }

        if (m is ClientLobbyMessageCloseTunnel)
        {
            tunneled_connection.disconnected();
            tunnel_disconnected(this);
            return;
        }

        ClientLobbyMessage? message = m as ClientLobbyMessage;
        mutex.lock();
        messages.add(message);
        mutex.unlock();
    }

    private void do_disconnected()
    {
        disconnected = true;
        tunneled_connection.disconnected();
    }

    private Connection connection { get; private set; }
    public ServerPlayerTunneledConnection tunneled_connection { get; private set; }
    public bool disconnected { get; private set; }
    public VersionInfo? version_info { get; set; }
}

public class ServerLobby
{
    private int game_IDs = 0;
    private Mutex mutex = Mutex();
    private Mutex game_mutex = Mutex();

    public signal void user_left_lobby(ServerLobby lobby, ServerLobbyUser user);

    public ServerLobby(int ID, string name)
    {
        this.ID = ID;
        this.name = name;
        users = new ArrayList<ServerLobbyUser>();
        games = new ArrayList<ServerLobbyGame>();
        active_games = new ArrayList<ServerLobbyGame>();
    }

    public bool add_user(ServerLobbyUser user)
    {
        mutex.lock();

        Environment.log(LogType.INFO, "ServerLobby", "User " + user.username + " entered lobby " + name);
        ServerLobbyMessageUserEnteredLobby msg = new ServerLobbyMessageUserEnteredLobby(new LobbyUser(user.ID, user.username));
        foreach (ServerLobbyUser u in users)
            u.send(msg);

        users.add(user);

        LobbyUser[] u = new LobbyUser[users.size];
        for (int i = 0; i < users.size; i++)
            u[i] = new LobbyUser(users[i].ID, users[i].username);

        LobbyGame[] g = new LobbyGame[games.size];
        for (int i = 0; i < games.size; i++)
        {
            ServerLobbyGame game = games[i];
            LobbyUser[] s = new LobbyUser[game.users.size];
            for (int j = 0; j < game.users.size; j++)
                s[j] = new LobbyUser(game.users[j].ID, game.users[j].username);
            g[i] = new LobbyGame(game.ID, s);
        }

        user.send(new ServerLobbyMessageEnterLobbyResult(true, name, u, g));
        mutex.unlock();
        return true;
    }

    public void process()
    {
        mutex.lock();
        for (int i = 0; i < users.size; i++)
        {
            ServerLobbyUser user = users[i];

            if (user.disconnected)
            {
                users.remove_at(i--);
                user_leave_game(user);

                ServerLobbyMessageUserLeftLobby msg = new ServerLobbyMessageUserLeftLobby(user.ID);
                foreach (ServerLobbyUser u in users)
                    u.send(msg);
                continue;
            }

            if (user.tunnel_disconnected)
            {
                user.tunnel_disconnected = false;
                if (user.current_game != null && user.current_game.running)
                    user.current_game = null;
            }

            ClientLobbyMessage? message;
            while ((message = user.dequeue_message()) != null)
            {
                if (message is ClientLobbyMessageCreateGame)
                    create_game_request(user, message as ClientLobbyMessageCreateGame);
                else if (message is ClientLobbyMessageEnterGame)
                    enter_game_request(user, message as ClientLobbyMessageEnterGame);
                else if (message is ClientLobbyMessageLeaveGame)
                    leave_game_request(user, message as ClientLobbyMessageLeaveGame);
                else if(message is ClientLobbyMessageLeaveLobby)
                {
                    users.remove_at(i--);
                    user_leave_game(user);

                    ServerLobbyMessageUserLeftLobby msg = new ServerLobbyMessageUserLeftLobby(user.ID);
                    foreach (ServerLobbyUser u in users)
                        u.send(msg);

                    Environment.log(LogType.INFO, "ServerLobby", "User " + user.username + " left lobby " + name);
                    user_left_lobby(this, user);
                    break;
                }
            }
        }

        game_mutex.lock();
        for (int i = 0; i < games.size; i++)
        {
            ServerLobbyGame game = games[i];
            if (game.should_start)
            {
                game.finished.connect(game_finished);
                game.start();
                ServerLobbyMessageGameRemoved msg = new ServerLobbyMessageGameRemoved(game.ID, true);
                foreach (ServerLobbyUser u in users)
                    u.send(msg);
                active_games.add(game);
                games.remove_at(i--);
                Environment.log(LogType.INFO, "ServerLobby", "Game " + game.ID.to_string() + " started in lobby " + name);
            }
        }
        game_mutex.unlock();

        mutex.unlock();
    }

    private void create_game_request(ServerLobbyUser user, ClientLobbyMessageCreateGame request)
    {
        if (user.current_game != null)
        {
            user.send(new ServerLobbyMessageCreateGameResult(false, -1));
            return;
        }

        ServerLobbyGame game = new ServerLobbyGame(game_IDs++);
        Environment.log(LogType.INFO, "ServerLobby", "User " + user.username + " created game " + game.ID.to_string());

        games.add(game);

        ServerLobbyMessageGameAdded game_msg = new ServerLobbyMessageGameAdded(new LobbyGame(game.ID, new LobbyUser[0]));
        ServerLobbyMessageUserEnteredGame user_msg = new ServerLobbyMessageUserEnteredGame(game.ID, user.ID);
        foreach (ServerLobbyUser u in users)
        {
            u.send(game_msg);
            u.send(user_msg);
        }

        game.add_user(user);
        user.current_game = game;

        user.send(new ServerLobbyMessageCreateGameResult(true, game.ID));
    }

    private void enter_game_request(ServerLobbyUser user, ClientLobbyMessageEnterGame request)
    {
        if (user.current_game == null)
        {
            foreach (ServerLobbyGame game in games)
            {
                if (game.ID == request.ID)
                {
                    if (game.users.size >= 4 || !game.add_user(user))
                        break;

                    user.send(new ServerLobbyMessageEnterGameResult(true, game.ID));

                    ServerLobbyMessageUserEnteredGame msg = new ServerLobbyMessageUserEnteredGame(game.ID, user.ID);
                    foreach (ServerLobbyUser u in users)
                        u.send(msg);

                    user.current_game = game;

                    Environment.log(LogType.INFO, "ServerLobby", "User " + user.username + " entered game " + game.ID.to_string());
                    return;
                }
            }
        }

        user.send(new ServerLobbyMessageEnterGameResult(false, -1));
    }

    private void leave_game_request(ServerLobbyUser user, ClientLobbyMessageLeaveGame request)
    {
        user_leave_game(user);
        user.send(new ServerLobbyMessageLeaveGameResult(user.current_game != null));
    }

    private void user_leave_game(ServerLobbyUser user)
    {
        if (user.current_game == null)
            return;

        ServerLobbyGame game = user.current_game;
        Environment.log(LogType.INFO, "ServerLobby", "User " + user.username + " left game " + game.ID.to_string());

        ServerLobbyMessageUserLeftGame msg = new ServerLobbyMessageUserLeftGame(user.ID, game.ID);
        foreach (ServerLobbyUser u in users)
            u.send(msg);

        if (game.users[0] == user)
        {
            ServerLobbyMessageGameRemoved m = new ServerLobbyMessageGameRemoved(game.ID, false);
            foreach (ServerLobbyUser u in users)
                u.send(m);

            foreach (ServerLobbyUser u in game.users)
                u.current_game = null;
            games.remove(game);
            Environment.log(LogType.INFO, "ServerLobby", "Game " + game.ID.to_string() + " removed in lobby " + name);
        }
        else
            game.remove_user(user);

        user.current_game = null;
    }

    private void game_finished(ServerLobbyGame game)
    {
        game_mutex.lock();
        active_games.remove(game);
        Environment.log(LogType.INFO, "ServerLobby", "Game " + game.ID.to_string() + " finished in lobby " + name);
        game_mutex.unlock();
    }

    public int ID { get; private set; }
    public string name { get; private set; }
    public ArrayList<ServerLobbyUser> users { get; private set; }
    public ArrayList<ServerLobbyGame> games { get; private set; }
    public ArrayList<ServerLobbyGame> active_games { get; private set; }
}

public class ServerLobbyUser
{
    public ServerLobbyUser(int ID, string username, LobbyConnection connection)
    {
        this.ID = ID;
        this.username = username;
        this.connection = connection;
        connection.tunnel_disconnected.connect(do_tunnel_disconnected);
    }

    public void send(ServerLobbyMessage message)
    {
        connection.send(message);
    }

    public ClientLobbyMessage? dequeue_message()
    {
        return connection.dequeue_message();
    }

    private void do_tunnel_disconnected()
    {
        tunnel_disconnected = true;
    }

    public int ID { get; private set; }
    public string username { get; private set; }
    public bool disconnected { get { return connection.disconnected; } }
    public bool tunnel_disconnected { get; set; }
    public ServerLobbyGame? current_game { get; set; }
    public LobbyConnection connection { get; private set; }
}

public class ServerLobbyGame
{
    private ServerMenu? menu = new ServerMenu();
    private LobbyGameServerController controller;
    private GameStartInfo start_info;
    private ServerSettings settings;
    private ArrayList<UserPlayer> players;

    public signal void finished(ServerLobbyGame game);

    public ServerLobbyGame(int ID)
    {
        this.ID = ID;
        users = new ArrayList<ServerLobbyUser>();
        players = new ArrayList<UserPlayer>();
        menu.game_start.connect(menu_start);
    }

    public bool add_user(ServerLobbyUser user)
    {
        ServerHumanPlayer player = new ServerHumanPlayer(user.connection.tunneled_connection, user.username);
        if (!menu.player_connected(player))
            return false;

        users.add(user);
        players.add(new UserPlayer(user, player));
        user.current_game = this;
        return true;
    }

    public void remove_user(ServerLobbyUser user)
    {
        for (int i = 0; i < players.size; i++)
        {
            UserPlayer player = players[i];
            if (player.user == user)
            {
                if (menu != null)
                    menu.player_disconnected(player.player);
                players.remove_at(i);
                break;
            }
        }
        users.remove(user);

        user.current_game = this;
    }

    public void start()
    {
        should_start = false;
        running = true;
        controller = new LobbyGameServerController(menu.players, menu.observers);
        controller.finished.connect(on_finished);
        menu = null;
        controller.start(start_info, settings);
    }

    private void menu_start(GameStartInfo start_info)
    {
        this.start_info = start_info;
        settings = menu.settings;
        should_start = true;
    }

    private void on_finished()
    {
        finished(this);
    }

    public int ID { get; private set; }
    public ArrayList<ServerLobbyUser> users { get; private set; }
    public bool should_start { get; private set; }
    public bool running { get; private set; }

    private class UserPlayer
    {
        public UserPlayer(ServerLobbyUser user, ServerHumanPlayer player)
        {
            this.user = user;
            this.player = player;
        }

        public ServerLobbyUser user { get; private set; }
        public ServerHumanPlayer player { get; private set; }
    }
}
