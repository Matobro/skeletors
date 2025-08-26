extends Node

func host_game(port: int = 9000, max_players: int = 8):
    var peer = ENetMultiplayerPeer.new()
    peer.create_server(port, max_players)
    multiplayer.multiplayer_peer = peer
    print("Hosting game on port", port)

func join_game(ip: String, port: int = 9000):
    var peer = ENetMultiplayerPeer.new()
    peer.create_client(ip, port)
    multiplayer.multiplayer_peer = peer
    print("Joining server: ", ip, ":", port)

func start_singleplayer():
    var peer = ENetMultiplayerPeer.new()
    peer.create_server(0, 1)
    multiplayer.multiplayer_peer = peer
    print("Starting singleplayer")

@rpc("any_peer")
func register_player(player_id: int, hero: UnitData):
    if not multiplayer.is_server():
        return
    for p in PlayerManager.players_to_spawn:
        if p.id == player_id:
            p.hero = hero
            return

    PlayerManager.players_to_spawn.append({
        "id": player_id,
        "is_ai": false,
        "hero": hero
    })
