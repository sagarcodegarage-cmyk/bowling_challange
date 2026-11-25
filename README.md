# Bowling Score Calculator

A small, plain Ruby program that scores a game of ten-pin bowling.

## Requirements

- Ruby 3.0 or newer
- Bundler

## Setup

```sh
bundle install
```

## Input format

Each line of input is one frame, with the pins knocked down per roll separated by spaces.
A regular frame has 1 roll (a strike) or 2 rolls. The 10th frame can have up to 3.

```text
5 3
10
4 6
```

This is 3 frames, with a strike in the second and a spare in the third. It scores 38.

## Usage

### Command line

Score a file. `sample_game.txt` is the complete 140-point game from the assessment:

```sh
bin/bowling sample_game.txt
```

Pipe a game in through stdin. This prints `38`:

```sh
printf '5 3\n10\n4 6\n' | bin/bowling
```

Or type or paste the game yourself. Run `bin/bowling` with no arguments, enter one frame per
line, then press **Ctrl-D** on a new line to finish:

```sh
bin/bowling
```

When the input is invalid, the script prints the problem and exits with status 1:

```text
$ echo "7 5" | bin/bowling
Invalid game: frame 1 knocks down more than 10 pins

$ bin/bowling missing.txt
File not found: missing.txt
```

### Ruby

```ruby
require_relative "lib/bowling_game"

BowlingGame.from_text("5 3\n10\n4 6").score   # => 38
BowlingGame.new([[5, 3], [10], [4, 6]]).score # => 38
```

`BowlingGame.from_text` reads the text format above. `BowlingGame.new` takes the frames as
arrays of integers. Both validate the game when it is created and raise
`BowlingGame::InvalidGameError` with a message naming the problem.

## Scoring rules

- **Open frame:** the number of pins knocked down.
- **Strike** (all 10 pins on the first roll): 10 plus the next two rolls.
- **Spare** (all 10 pins over two rolls): 10 plus the next roll.
- **10th frame:** a strike or spare earns extra rolls, up to three rolls in all. The frame
  scores the total pins of its rolls. The extra rolls are its bonus, so nothing more is added.

### Worked example

The reference game from the assessment scores 140:

| Frame | Rolls    | Type                                   | Frame score | Running total |
|-------|----------|----------------------------------------|-------------|---------------|
| 1     | 5 3      | open                                   | 8           | 8             |
| 2     | 10       | strike: 10 + next two rolls (4, 6)     | 20          | 28            |
| 3     | 4 6      | spare: 10 + next roll (0)              | 10          | 38            |
| 4     | 0 0      | open                                   | 0           | 38            |
| 5     | 8 1      | open                                   | 9           | 47            |
| 6     | 10       | strike: 10 + next two rolls (10, 6)    | 26          | 73            |
| 7     | 10       | strike: 10 + next two rolls (6, 3)     | 19          | 92            |
| 8     | 6 3      | open                                   | 9           | 101           |
| 9     | 7 2      | open                                   | 9           | 110           |
| 10    | 10 10 10 | strike plus two extra rolls            | 30          | **140**       |

A strike's bonus can reach past the next frame. Frame 7 is a single roll, so frame 6's second
bonus roll is the first roll of frame 8.

## How it works

All the logic is in `lib/bowling_game.rb`.

`#score` flattens every roll into one list, then goes through the frames in order, keeping
track of where each frame starts in that list. Each frame scores its own pins plus a bonus:

- a strike adds the next two rolls in the list
- a spare adds the next roll
- an open frame and the 10th frame add nothing

A bonus roll that doesn't exist yet counts as 0.

## Validation

The game is rejected with `BowlingGame::InvalidGameError` if:

- it has more than 10 frames
- a roll isn't a whole number from 0 to 10
- a strike in frames 1 to 9 has a second roll
- a non-strike frame in frames 1 to 9 doesn't have exactly two rolls
- two rolls on the same set of pins add up to more than 10
- the 10th frame doesn't have 3 rolls after a strike or spare, or 2 rolls otherwise

## Assumptions

The assessment doesn't settle these cases, so this is how they are handled:

- **Games in progress are scored.** The 38-point example is a 3-frame game, so fewer than
  10 frames is valid. A bonus that hasn't been rolled yet counts as 0, and an empty input
  scores 0.
- **Frames are complete.** In frames 1 to 9, a frame with a single roll must be a strike (`10`).
  A frame with only one non-strike roll, such as an unfinished last frame, is rejected.
- **The 10th frame must be finished.** If a game has 10 frames, the last one needs all of
  its rolls.

## Tests

```sh
bundle exec rspec
```

The specs cover both examples from the assessment, perfect, gutter and all-spare games,
strike and spare bonuses, the 10th frame, games in progress, and every validation rule.

## Project layout

```text
lib/bowling_game.rb        Parsing, validation and scoring
spec/bowling_game_spec.rb  RSpec specs
bin/bowling                Command-line script
sample_game.txt            Example input (scores 140)
Gemfile                    Dependencies (RSpec only)
.rspec                     RSpec output options
```

## Troubleshooting

- **Strange errors such as `cannot load such file -- #`, or a new file named after a number.**
  Your shell is treating a `#` comment on a command line as arguments. By default, zsh doesn't
  recognise comments in commands you type. Run the commands without trailing comments, or add
  `setopt interactive_comments` to your `~/.zshrc`.
- **`bin/bowling: require_relative: command not found`.** The first line of `bin/bowling` must
  be `#!/usr/bin/env ruby`. It looks like a comment but it tells the system to run the file
  with Ruby, so it can't be removed. You can also run the script as `ruby bin/bowling`.
- **`Permission denied` when running `bin/bowling`.** Make it executable with
  `chmod +x bin/bowling`.
- **A version manager warns that a Ruby version is missing.** This project doesn't pin a Ruby
  version. Any Ruby 3.0 or newer on your `PATH` will work.
