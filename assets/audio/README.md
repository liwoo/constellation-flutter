# Audio Assets

This directory contains sound effects for the Constellation game.

## Required Sound Files

Download CC0/royalty-free sounds and save them here with these exact names:

### Tier 1 (Essential)
| File | Description | Suggested Duration |
|------|-------------|-------------------|
| `select_pop.wav` | Soft click when letter is selected | ~50ms |
| `success_chime.wav` | Positive chime for correct word | ~500ms |
| `error_buzz.wav` | Buzzer for incorrect word | ~300ms |
| `wheel_land.wav` | Impact when wheel stops | ~200ms |
| `victory.wav` | Fanfare for winning game | ~2s |
| `game_over.wav` | Sound for losing game | ~1.5s |

### Tier 2 (Polish)
| File | Description | Suggested Duration |
|------|-------------|-------------------|
| `wheel_spin.wav` | Looping whoosh during spin | ~1s (loopable) |
| `jackpot_reveal.wav` | Slot machine ding | ~500ms |
| `button_click.wav` | Generic button tap | ~50ms |
| `time_warning.wav` | Alert for low time | ~200ms |
| `round_complete.wav` | Level up sound | ~1s |

## Recommended Sources (CC0/Royalty-Free)

1. **Kenney.nl** - https://kenney.nl/assets
   - [UI Audio](https://kenney.nl/assets/ui-audio)
   - [Impact Sounds](https://kenney.nl/assets/impact-sounds)
   - [Casino Audio](https://kenney.nl/assets/casino-audio)

2. **itch.io CC0 SFX** - https://itch.io/game-assets/assets-cc0/tag-sound-effects
   - Interface SFX Pack 1
   - 200 Free SFX

3. **Pixabay** - https://pixabay.com/sound-effects/

4. **ZapSplat CC0** - https://www.zapsplat.com/license-type/cc0-1-0-universal/

## File Format Guidelines

- **Short SFX (<1s)**: Use `.wav` for lowest latency
- **Longer sounds (>1s)**: Use `.ogg` for smaller file size
- **Target size**: <100KB per file for mobile performance
- **Sample rate**: 44.1kHz or 48kHz
- **Bit depth**: 16-bit

## Quick Start

1. Visit https://kenney.nl/assets/ui-audio
2. Download the pack
3. Copy relevant sounds to this folder
4. Rename to match the filenames above
