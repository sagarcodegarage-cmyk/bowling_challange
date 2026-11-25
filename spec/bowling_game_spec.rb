# frozen_string_literal: true

require_relative "../lib/bowling_game"

RSpec.describe BowlingGame do
  def score(text)
    described_class.from_text(text).score
  end

  describe "#score" do
    context "with the examples from the assessment" do
      it "scores a partial game with a strike and a spare as 38" do
        expect(score("5 3\n10\n4 6")).to eq(38)
      end

      it "scores the complete reference game as 140" do
        game = <<~GAME
          5 3
          10
          4 6
          0 0
          8 1
          10
          10
          6 3
          7 2
          10 10 10
        GAME

        expect(score(game)).to eq(140)
      end
    end

    context "with complete games" do
      it "scores a gutter game as 0" do
        expect(score("0 0\n" * 10)).to eq(0)
      end

      it "scores a game with no strikes or spares as the sum of pins" do
        expect(score("3 4\n" * 10)).to eq(70)
      end

      it "scores a perfect game as 300" do
        expect(score("10\n" * 9 + "10 10 10")).to eq(300)
      end

      it "scores a game of all 5-spares as 150" do
        expect(score("5 5\n" * 9 + "5 5 5")).to eq(150)
      end

      it "adds the next two rolls to a strike" do
        expect(score("10\n3 4\n" + "0 0\n" * 8)).to eq(24)
      end

      it "adds the next roll to a spare" do
        expect(score("6 4\n3 0\n" + "0 0\n" * 8)).to eq(16)
      end

      it "adds two following strikes as a strike's bonus" do
        expect(score("10\n10\n10\n" + "0 0\n" * 7)).to eq(60)
      end
    end

    context "with the 10th frame" do
      let(:nine_open_frames) { "0 0\n" * 9 }

      it "scores an open 10th frame with only two rolls" do
        expect(score(nine_open_frames + "4 5")).to eq(9)
      end

      it "counts the bonus roll after a spare in the 10th frame" do
        expect(score(nine_open_frames + "7 3 8")).to eq(18)
      end

      it "counts both bonus rolls after a strike in the 10th frame" do
        expect(score(nine_open_frames + "10 4 5")).to eq(19)
      end

      it "allows a spare made from the two bonus rolls after a strike" do
        expect(score(nine_open_frames + "10 4 6")).to eq(20)
      end

      it "uses the 10th frame's first two rolls as the bonus for a 9th-frame strike" do
        expect(score("0 0\n" * 8 + "10\n10 10 10")).to eq(60)
      end
    end

    context "with games in progress" do
      it "scores an empty game as 0" do
        expect(score("")).to eq(0)
      end

      it "counts a strike without its bonus rolls yet as 10" do
        expect(score("10")).to eq(10)
      end

      it "counts the one bonus roll available after a strike" do
        expect(score("10\n10")).to eq(30)
      end
    end

    context "with frames given as arrays" do
      it "scores the same as the text input" do
        expect(described_class.new([[5, 3], [10], [4, 6]]).score).to eq(38)
      end
    end
  end

  describe ".from_text" do
    it "ignores blank lines and surrounding whitespace" do
      expect(score("\n  5 3  \n\n10\n   4   6\n\n")).to eq(38)
    end

    it "rejects input that is not a string" do
      expect { described_class.from_text(nil) }
        .to raise_error(BowlingGame::InvalidGameError, /must be a string/)
    end

    it "rejects rolls that are not whole numbers" do
      expect { score("5 x") }.to raise_error(BowlingGame::InvalidGameError, /invalid roll "x"/)
      expect { score("5 2.5") }.to raise_error(BowlingGame::InvalidGameError, /invalid roll "2.5"/)
    end
  end

  describe "validation" do
    def expect_invalid(text, message)
      expect { score(text) }.to raise_error(BowlingGame::InvalidGameError, message)
    end

    it "rejects more than 10 frames" do
      expect_invalid("0 0\n" * 11, /at most 10 frames, got 11/)
    end

    it "rejects negative rolls" do
      expect_invalid("-1 3", /invalid roll -1/)
    end

    it "rejects rolls above 10" do
      expect_invalid("11", /invalid roll 11/)
    end

    it "rejects a regular frame that knocks down more than 10 pins" do
      expect_invalid("7 5", /frame 1 knocks down more than 10 pins/)
    end

    it "rejects a strike followed by another roll in the same frame" do
      expect_invalid("10 0", /frame 1 is a strike and must have only one roll/)
    end

    it "rejects a regular frame with a single non-strike roll" do
      expect_invalid("5 3\n4", /frame 2 must have two rolls/)
    end

    it "rejects a regular frame with three rolls" do
      expect_invalid("1 2 3", /frame 1 must have two rolls/)
    end

    it "rejects frames that are not arrays of integers" do
      expect { described_class.new([[5, "3"]]) }
        .to raise_error(BowlingGame::InvalidGameError, /invalid roll "3"/)
      expect { described_class.new([[]]) }
        .to raise_error(BowlingGame::InvalidGameError, /frame 1 must be a non-empty list/)
      expect { described_class.new("5 3") }
        .to raise_error(BowlingGame::InvalidGameError, /frames must be an array/)
    end

    context "in the 10th frame" do
      let(:nine_open_frames) { "0 0\n" * 9 }

      it "rejects a bonus roll after an open frame" do
        expect_invalid(nine_open_frames + "3 4 5", /frame 10 must have 2 rolls, got 3/)
      end

      it "rejects a missing bonus roll after a spare" do
        expect_invalid(nine_open_frames + "3 7", /frame 10 must have 3 rolls, got 2/)
      end

      it "rejects missing bonus rolls after a strike" do
        expect_invalid(nine_open_frames + "10 10", /frame 10 must have 3 rolls, got 2/)
      end

      it "rejects two rolls on the same rack that exceed 10 pins" do
        expect_invalid(nine_open_frames + "6 6", /frame 10 knocks down more than 10 pins/)
      end

      it "rejects bonus rolls after a strike that exceed 10 pins on the same rack" do
        expect_invalid(nine_open_frames + "10 6 6", /more than 10 pins with its bonus rolls/)
      end
    end
  end
end
