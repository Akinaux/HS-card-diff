# Hearthstone - Card-diff

## Purpose

This repository contains a script to compare the difference between the Hearthstone Patches.
It will compare all cards to check the NEW and MODIFIED cards. The script does not display the cards removed from the previous version.

## How to interpret the data:

### Example of a new card
~~~
{
  "artist": "MAR Studio",
  "cardClass": "DEMONHUNTER",
  "collectible": true,
  "cost": 1,
  "dbfId": 61939,
  "flavor": "\"Don't read texts and drive.\"",
  "id": "YOP_001",
  "mechanics": [
    "DISCOVER"
  ],
  "name": "Illidari Studies",
  "rarity": "COMMON",
  "referencedTags": [
    "OUTCAST"
  ],
  "set": "DARKMOON_FAIRE",
  "text": "<b>Discover</b> an <b>Outcast</b> card. Your next one costs (1) less.",
  "type": "SPELL"
}
New entry
~~~
The "New Entry" value at the buttom of the data indicates that this card is new.

### Example of a modified card
~~~
{
  "artist": "Hideaki Takamura",
  "attack": 2,
  "cardClass": "NEUTRAL",
  "collectible": true,
  "cost": 2,
  "dbfId": 61622,
  "flavor": "He's just making sure they're real. Authentic tickets taste like strawberry.",
  "health": 3,
  "id": "DMF_067",
  "mechanics": [
    "BATTLECRY"
  ],
  "name": "Prize Vendor",
  "race": "MURLOC",
  "rarity": "COMMON",
  "set": "DARKMOON_FAIRE",
  "text": "<b>Battlecry:</b> Each player draws a card.",
  "type": "MINION"
}
------------------------
<   "text": "<b>Battlecry:</b> Each player draws a card.",
>   "text": "<b>Battlecry:</b> Both players draw a card.",
~~~
The value below the "------------------------" are the values changed.
Values starting with "<" are present in the new version.
Values starting with ">" are present in the previous version.

In some cases, values may have been added "<" or removed ">" between version. In this case the comparaison value will be missing.

~~~
{
  "artist": "Todd Lockwood",
  "attack": 4,
  "battlegroundsPremiumDbfId": 60403,
  "cardClass": "WARLOCK",
  "collectible": true,
  "cost": 5,
  "dbfId": 2068,
  "flavor": "\"Evil Eye Watcher of Doom\" was the original name, but marketing felt it was a bit too aggressive.",
  "health": 4,
  "id": "GVG_100",
  "mechanics": [
    "TRIGGER_VISUAL"
  ],
  "name": "Floating Watcher",
  "race": "DEMON",
  "rarity": "COMMON",
  "set": "GVG",
  "text": "Whenever your hero takes damage on your turn, gain +2/+2.",
  "type": "MINION"
}
------------------------
>   "techLevel": 4,
~~~
In this case, the field "techLevel" has been removed from the card.
## How to use the script

To run the script you must know the previous and latest version of the Patches that you want to compare.
Please refer to https://api.hearthstonejson.com/v1/ for the available versions.

Once you have both previous and latest versions, you can run the command using the following syntaxe:
~~~
Usage: cards_diff.sh -l <latest> -p <previous> [-d|-n] [-L <LANG>] [-F <folder>]
    -l: Latest version
    -p: Previous version
    -d: Display only the modified cards
    -n: Display only the new cards
    -L: Define the langage of the collections (Default: enUS)
    -F: Set the folder to download the collections (Default: /tmp)
~~~

Because the script analyses some rangs of **dbfId** from the file, and Blizzard does not use continuous **dbfIds**, the script may "pause" for a couple of seconds to find new cards to compare.

### Examples

### Download the json files in the default directory (/tmp) and display all new and modified cards
~~~
./cards_diff.sh -l 71603 -p 70986
~~~

#### Download the French json files in the current directory (.) and display only the modified cards
~~~
./cards_diff.sh -l 71603 -p 70986 -F . -d -L frFR
~~~
