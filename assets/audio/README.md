# Audio Assets

Every file in this folder is synthesized by [`tool/generate_audio.py`](../../tool/generate_audio.py)
— no third-party samples, so no licensing concerns. To tweak a sound, edit its
`sfx_*` function and regenerate:

```sh
brew install sox lame          # one-time
python3 tool/generate_audio.py # all sounds
python3 tool/generate_audio.py --only magnet_snap.wav music_ambient.mp3
```

Short, latency-critical sounds are **WAV** (no decoder delay). Longer ones are
**MP3** to keep the web bundle small.

| File | Used for |
|------|----------|
| `magnet_snap.wav` | Letter connects (pitch climbs a pentatonic ladder per letter) |
| `connect_fail.wav` | Practice: connected a letter that doesn't fit the target word |
| `delete.wav` | DEL / swipe-to-remove |
| `button_tap.wav` | Menu buttons, space, wheel spin start |
| `bubbles_rise.mp3` | Word won — bubbles fizzing up |
| `word_correct.mp3` | Word won — whimsical chime layered over the bubbles |
| `pure_connection.mp3` | Word built in a single drag — harp glissando |
| `word_wrong.wav` | Wrong word submitted |
| `wheel_tick.wav` | Spinning wheel / category reel ratchet |
| `wheel_land.mp3` | Wheel lands on a letter |
| `jackpot_reveal.mp3` | Category revealed |
| `time_warning.wav` | Clock tick in the final 10 seconds |
| `counter_tick.wav` | Score/time counters counting up (pitch rises) |
| `hint.mp3` | Hint used |
| `mystery_activate.mp3` / `mystery_reward.mp3` / `mystery_penalty.wav` | Mystery orbs |
| `star_earned.mp3` | Star earned / final round hype |
| `round_complete.mp3` | Letter complete, practice session complete |
| `game_win.mp3` / `game_lose.mp3` | Game over |
| `music_ambient.mp3` | Soothing background loop (see below) |

## Music loop

`music_ambient.mp3` is a 16-bar loop at 70 BPM (54.857 s) with a 2 s pre-roll
and post-roll copied from the loop's own tail and head. `AudioService` loops the
region `[2 s, 2 s + 54.857 s]`, which stays seamless on every decoder whether or
not it strips MP3 encoder delay. If you change `MUSIC_BPM`, `MUSIC_BARS` or
`MUSIC_PREROLL_S` in the generator, update `_musicLoopStart` / `_musicLoopEnd`
in `lib/shared/services/audio_service.dart` to match.
