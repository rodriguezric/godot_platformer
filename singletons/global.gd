extends Node

# Global singleton is mostly for handling constants

const TILESIZE := 16

enum Direction {
    LEFT = -1,
    RIGHT = 1,
}

enum songs {
    LEVEL,
}
const SONG_MAP := {
    songs.LEVEL: preload("res://music/8bit_adventur.ogg")
}
