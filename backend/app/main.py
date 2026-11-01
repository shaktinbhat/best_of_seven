import json
import asyncio
from typing import Dict
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from app.logic.room import GameRoom
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app = FastAPI(title="Rummy Server")
rooms: Dict[str, GameRoom] = {}
connections: Dict[str, Dict[str, WebSocket]] = {}


async def broadcast_game_state(room_id: str):
    room = rooms.get(room_id)
    if not room or room_id not in connections:
        return
    for player_id, ws in list(connections[room_id].items()):
        try:
            payload = {"type": "STATE_UPDATE", "data": room.get_player_view(player_id)}
            await ws.send_text(json.dumps(payload))
        except Exception:
            pass


async def run_countdown(room_id: str):
    room = rooms.get(room_id)
    if not room:
        return
    room.game_state = "COUNTDOWN"
    for s in range(5, 0, -1):
        room.countdown_seconds = s
        await broadcast_game_state(room_id)
        await asyncio.sleep(1)

    room.start_deal()
    await broadcast_game_state(room_id)

async def broadcast_room_state(room_id: str):
    if room_id not in rooms or room_id not in connections:
        return
    room = rooms[room_id]
    for pid, ws in list(connections[room_id].items()):
        try:
            view = room.get_player_view(pid)
            await ws.send_text(json.dumps({"type": "STATE_UPDATE", "data": view}))
        except Exception as e:
            print(f"Failed to send state update to {pid}: {e}")

rooms: dict[str, GameRoom] = {}
connections: dict[str, dict[str, WebSocket]] = {}

@app.websocket("/ws/{room_id}/{player_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    room_id: str,
    player_id: str,
    player_name: str = "Player"
):
    # 1. ALWAYS accept the handshake first
    await websocket.accept()

    # 2. Track connection registry
    if room_id not in connections:
        connections[room_id] = {}
    connections[room_id][player_id] = websocket

    # 3. Create or join the GameRoom instance
    if room_id not in rooms:
        rooms[room_id] = GameRoom(room_id)

    room = rooms[room_id]

    try:
        # Register the player in the room logic
        room.add_or_reconnect_player(player_id, player_name)

        # Broadcast initial state to all connected room sockets
        await broadcast_room_state(room_id)

        # 4. Message listening loop
        while True:
            raw_text = await websocket.receive_text()
            data = json.loads(raw_text)
            action = data.get("action")
            payload = data.get("payload", {})

            if action == "CHAT_MESSAGE":
                text = payload.get("text", "").strip()
                if text:
                    chat_payload = {
                        "type": "CHAT_MESSAGE",
                        "data": {
                            "sender_id": player_id,
                            "sender_name": player_name,
                            "text": text,
                            "timestamp": payload.get("timestamp", ""),
                        },
                    }
                    if room_id in connections:
                        for pid, ws in list(connections[room_id].items()):
                            try:
                                await ws.send_text(json.dumps(chat_payload))
                            except Exception:
                                pass

            elif action == "TOGGLE_READY":
                room.toggle_ready(player_id)
                await broadcast_room_state(room_id)

            elif action == "START_GAME":
                room.start_game()
                await broadcast_room_state(room_id)

            elif action == "DRAW":
                source = payload.get("source", "STOCK")
                room.draw_card(player_id, source)
                await broadcast_room_state(room_id)

            elif action == "DISCARD":
                card_uid = payload.get("card_uid")
                room.discard_card(player_id, card_uid)
                await broadcast_room_state(room_id)

            elif action == "DECLARE":
                finish_card_uid = payload.get("finish_card_uid")
                groups = payload.get("groups", [])
                result = room.declare(player_id, finish_card_uid, groups)
                # Send declaration result specifically to the declaring client
                await websocket.send_text(json.dumps({"type": "DECLARE_RESULT", "data": result}))
                await broadcast_room_state(room_id)

            elif action == "NEXT_DEAL":
                room.next_deal()
                await broadcast_room_state(room_id)

    except WebSocketDisconnect:
        if room_id in connections and player_id in connections[room_id]:
            del connections[room_id][player_id]
            if not connections[room_id]:
                del connections[room_id]
        if room_id in rooms:
            await broadcast_room_state(room_id)
    except Exception as e:
        print(f"Error in websocket loop: {e}")