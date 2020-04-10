VALAC = valac
NAME  = LobbyController
DIRS  = \
	source/*.vala \
	../Engine/EngineLog.vala \
	../Engine/Helper/DeltaTimers.vala \
	../Engine/Helper/Helper.vala \
	../Engine/Helper/Timers.vala \
	../Engine/Helper/Networking.vala \
	../Engine/Helper/Threading.vala \
	../Engine/Helper/RandomClass.vala \
	../Engine/Files/FileLoader.vala \
	../Engine/Properties/Animation.vala \
	../Engine/Properties/Color.vala \
	../Engine/Properties/Curve.vala \
	../Engine/Properties/DeltaArgs.vala \
	../OpenRiichi/source/Environment.vala \
	../OpenRiichi/source/Game/ServerSettings.vala \
	../OpenRiichi/source/Game/Options.vala \
	../OpenRiichi/source/Game/Logic/*.vala \
	../OpenRiichi/source/GameServer/Bots/*.vala \
	../OpenRiichi/source/GameServer/GameState/*.vala \
	../OpenRiichi/source/GameServer/Server/*.vala
PKGS  = --thread --target-glib 2.32 --pkg gio-2.0 --pkg gee-0.8 --pkg zlib --pkg win32 -X -lm
VAPI  = --vapidir=../OpenRiichi/vapi
#-w = Suppress C warnings (Since they stem from the vala code gen)
OTHER = -X -w
O     = -o bin/$(NAME)
DEBUG = -v --save-temps --enable-checking -g -X -ggdb -X -O0 -D DEBUG

all: debug

debug:
	$(VALAC) $(O) $(DIRS) $(PKGS) $(VAPI) $(OTHER) $(DEBUG) -D LINUX

release:
	$(VALAC) $(O) $(DIRS) $(PKGS) $(VAPI) $(OTHER) -D LINUX

windowsDebug:
	$(VALAC) $(O) $(DIRS) $(PKGS) $(VAPI) $(OTHER) $(DEBUG) -D WINDOWS

windowsRelease:
	$(VALAC) $(O) $(DIRS) $(PKGS) $(VAPI) $(OTHER) -D WINDOWS -X -mwindows

clean:
	rm bin/$(NAME)*
	find . -type f -name '*.c' -exec rm {} +
