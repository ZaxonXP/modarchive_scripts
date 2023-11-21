# Modarchive.org
Playback for https://modarchive.org music modules.

# Intro
- The collection of Modarchive.org modules can be played using playlists directly from the server.
- Possition of the playback is remembered, so it can be continued from the last listened music module.
- User can define which playlist will listen to (selectable by fzf menu)
- For each playlist additional playlist are created (fav.txt and rej.txt). Using additional script (menu_modules_my_favorite.sh) user can decide which modules will be Favorite and which Rejected.
- User later on can play only Favorites, Rejected or normal list.
- All the list is taken from the modarchive.org and stored locally in the paged txt files, so it is like a snapshot in time.

# Purpose of the scripts:
- menu_modules.sh - for binding to some key shortcut. Runs st terminal with the `menu_modarchive.sh` script.
- menu_modarchive.sh - contains a definition of playlist and runs the playback script
- modarchive_play_from_web.sh - play user specified playlist
- mpt_control.sh - allows remote control of the OpenMPT123 module player (can be mapped to play/next/previous media keys)
- menu_modules_my_favorite.sh - script for choosing where the currently played module should be placed (fav.txt or rej.txt)
- modarchive.conf - configuration file.

# Dependencies:
- Bash
- fzf
- wget
- lynx
- openmpt123 (at least v0.7.0-pre.22 with FIFO support)
- st (optional)

# Installing:
1) Install listed dependent programs.
2) Download the scripts in a writable directory located in the $PATH.
3) Make the scripts executable.

# Running:
a) run "menu_modarchive.sh" and select the playlist you want to listen to. 

# How to add new playlist
1) Open the https://modarchive.org website and select some playlist form Music -> Browse by / Charts or Artists menu. 
   The selected playlist URL has to contain `request` and `query` elements
   (Example: https://modarchive.org/index.php?request=view_by_license&query=publicdomain)
2) Edit `menu_modarchive.sh` and add the new entry to the bash array like (using data from above example):
```
n=14 qu[$n]=publicdomain;      req[$n]="view_by_license";     lab[$n]="Public domain"
```
3) Save the file.
