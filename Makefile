VALAC = valac
NAME  = LobbyController
DIRS  = \
	source/*.vala \
	../RiichiMahjong/source/Environment.vala \
	../Engine/EngineLog.vala \
	../Engine/Helper/Helper.vala \
	../Engine/Helper/DelayTimer.vala \
	../Engine/Helper/Networking.vala \
	../Engine/Helper/Threading.vala \
	../Engine/Files/FileLoader.vala \
	../Engine/Properties/Color.vala \
	../RiichiMahjong/source/Game/ServerSettings.vala \
	../RiichiMahjong/source/Game/Options.vala \
	../RiichiMahjong/source/Game/Logic/*.vala \
	../RiichiMahjong/source/GameServer/Bots/*.vala \
	../RiichiMahjong/source/GameServer/GameState/*.vala \
	../RiichiMahjong/source/GameServer/Server/*.vala
PKGS  = --thread --target-glib 2.32 --pkg gio-2.0 --pkg gee-0.8
WLIBS = -X ../RiichiMahjong/lib/GEE/libgee.dll.a
LLIBS = -X -lm
VAPI  = --vapidir=../RiichiMahjong/vapi
#-w = Suppress C warnings (Since they stem from the vala code gen)
OTHER = -X -w
O     = -o bin/$(NAME)
DEBUG = --save-temps --enable-checking -g -X -ggdb -X -O0 -D DEBUG

all: debug

debug:
	$(VALAC) $(O) $(DIRS) $(PKGS) $(LLIBS) $(VAPI) $(OTHER) $(DEBUG)

release:
	$(VALAC) $(O) $(DIRS) $(PKGS) $(LLIBS) $(VAPI) $(OTHER)

clean:
	rm bin/$(NAME)
	rm -r *.c

WindowsDebug:
	$(eval SHELL = C:/Windows/System32/cmd.exe)
	$(VALAC) $(O) $(DIRS) $(PKGS) $(WLIBS) $(VAPI) $(OTHER) $(DEBUG)

WindowsRelease:
	$(eval SHELL = C:/Windows/System32/cmd.exe)
	$(VALAC) $(O) $(DIRS) $(PKGS) $(WLIBS) $(VAPI) $(OTHER) -X -mwindows

cleanWindowsDebug: cleanWindows

cleanWindowsRelease: cleanWindows

cleanWindows:
	rm bin $(NAME).exe
	rm . *.c
	rm source *.c
