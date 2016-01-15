using Gee;
using GameServer;

public class LobbyGameServerController
{
    private Server server;
    private ClientMessageParser parser = new ClientMessageParser();
    private ArrayList<ServerPlayer> players;
    private ArrayList<ServerPlayer> observers;
    private bool finish = false;
    private Mutex mutex = Mutex();

    public signal void finished(LobbyGameServerController server);

    public LobbyGameServerController(ArrayList<ServerPlayer> players, ArrayList<ServerPlayer> observers)
    {
        this.players = players;
        this.observers = observers;
    }

    public void start(GameStartInfo info)
    {
        foreach (ServerPlayer player in players)
        {
            player.receive_message.connect(message_received);
            player.disconnected.connect(player_disconnected);
        }

        Threading.start3(server_worker, players, observers, info);
    }

    private void server_worker(Object players_obj, Object observers_obj, Object start_info_obj)
    {
        ArrayList<ServerPlayer> players = players_obj as ArrayList<ServerPlayer>;
        ArrayList<ServerPlayer> observers = observers_obj as ArrayList<ServerPlayer>;
        GameStartInfo info = (GameStartInfo)start_info_obj;
        Rand rnd = new Rand();

        server = new Server(players, observers, rnd, info);
        Timer timer = new Timer();

        while (!finish && !server.finished)
        {
            mutex.lock();
            process_messages();
            server.process((float)timer.elapsed());
            mutex.unlock();
            sleep();
        }

        die(players, observers);
        finished(this);
    }

    private void sleep()
    {
        Thread.usleep(10000); // Server is not cpu intensive at all (can save cycles)
    }

    private void process_messages()
    {
        ClientMessageParser.ClientMessageTuple? message;
        while ((message = parser.dequeue()) != null)
            server.message_received(message.player, message.message);
    }

    private void message_received(ServerPlayer player, ClientMessage message)
    {
        parser.add(player, message);
    }

    private void player_disconnected(ServerPlayer player)
    {
        bool all_disconnected = true;
        player.is_disconnected = true;

        mutex.lock();
        server.player_disconnected(player);

        foreach (ServerPlayer p in players)
            if (!p.bot && !p.is_disconnected)
                all_disconnected = false;

        foreach (ServerPlayer p in observers)
            if (!p.bot && !p.is_disconnected)
                all_disconnected = false;

        mutex.unlock();

        if (all_disconnected)
            finish = true;
    }

    private void die(ArrayList<ServerPlayer> players, ArrayList<ServerPlayer> observers)
    {
        foreach (ServerPlayer player in players)
        {
            player.disconnected.disconnect(player_disconnected);
            player.receive_message.disconnect(message_received);
            player.close();
        }

        foreach (ServerPlayer player in observers)
        {
            player.disconnected.disconnect(player_disconnected);
            player.receive_message.disconnect(message_received);
            player.close();
        }
    }
}
