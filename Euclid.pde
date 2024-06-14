/**
 * @file: Euclid.pde
 *
 * @summary: MetaSquares-like board game with AI written in Java for the Processing environment
 * @author:  trent m. wyatt
 * @date:    August-2010
 *
 */

import java.util.Comparator;
import processing.sound.*;

Board    board  = null;
Point    cursor = null;
int      DebugLevel = 1;

// ------------------------------------------------------------------------------------------
// Board class definition
// 
public class Board {
    public static final int GS_RUNNING    = 0;
    public static final int GS_PLAYER1WIN = 1;
    public static final int GS_PLAYER2WIN = 2;
    public static final int GS_TIE        = 3;

    public static final int PS_OFFENSIVE = 1;
    public static final int PS_DEFENSIVE = 2;
    public static final int PS_BEGINNER  = 3;

    public static final int WIDTH       =  8;
    public static final int HEIGHT      =  8;
    public static final int CELL_WIDTH  = 40;
    public static final int CELL_HEIGHT = 40;
    public static final int xOffset     = 45;
    public static final int yOffset     = 70;
    public        final int radius      = int(float(CELL_WIDTH) * 0.38);

    // UX Assets:
    SoundFile          m_moveSnd;
    SoundFile          m_niceMoveSnd;
    SoundFile          m_squaresSnd;

    // Game State:
    int[]              m_board;
    Player[]           m_players;
    int                m_turn;
    ArrayList<Point>   m_history;
    boolean            m_displayed_game_over;


    // Game Preferences:
    boolean            m_playSounds;
    boolean            m_onlyShowLastSquares;
    boolean            m_createRandomizedRangeOrder;
    boolean            m_stopAt150;

    Point              m_last;
    int                m_lastPoints;

    // ------------------------------------------------------------------------------------------
    // Construct and initialize a new instance of a Board object 
    // ------------------------------------------------------------------------------------------
    Board(final SoundFile[] sounds, Player p1, Player p2) {
        // Load the runtime game assets
        m_moveSnd     = sounds[0];
        m_niceMoveSnd = sounds[1];
        m_squaresSnd  = sounds[2];

        // Create two players, each with options for playing style
        m_players = new Player[2];
        m_players[0] = p1;
        m_players[1] = p2;

        // Configure the game options
        m_onlyShowLastSquares = false;
        m_createRandomizedRangeOrder = true;
        m_playSounds = true;
        m_stopAt150  = false;
        m_displayed_game_over = false;

        // Initialize the board contents
        initGame();
    }


    // ------------------------------------------------------------------------------------------
    // @name:      initGame
    // @summary:   Initialize the board for a new game 
    // @returns:   void
    // ------------------------------------------------------------------------------------------
    void initGame() {
        m_board      = new int[WIDTH * HEIGHT];
        m_history    = new ArrayList();
        m_turn       = 0;
        m_lastPoints = 0;
        m_displayed_game_over = false;
        m_last = pointAt(-1, -1);
        cursor = pointAt(-1, -1);

        m_players[0].initGame();
        m_players[1].initGame();
    } // Board::initGame


    // ------------------------------------------------------------------------------------------
    // @name:       dot
    // @summary:    draw a colored dot on the board at a given x, y cell
    // 
    // ------------------------------------------------------------------------------------------
    void drawGameCell(final Point pt, final int red, final int green, final int blue) {
        stroke(0, 0, 0);
        fill(red, green, blue);
        circle(Board.xOffset + pt.x * Board.CELL_WIDTH + Board.CELL_WIDTH/2, Board.yOffset + pt.y * Board.CELL_HEIGHT + Board.yOffset/2, radius);
        noFill();
        noStroke();
    }


    // ------------------------------------------------------------------------------------------
    // Draw the board
    // ------------------------------------------------------------------------------------------
    void drawBoard() {
        background(128, 128, 128);

        stroke(255, 255, 255);
        fill(224, 224, 224);
        rect(0, 0, width - 1, Board.yOffset);
        noFill();

        textSize(24);

        fill(0, 0, 255);
        Point score1Loc = pointAt(Board.xOffset/3 + ((Board.WIDTH * Board.CELL_WIDTH) / 4) - Board.CELL_WIDTH * 2, Board.yOffset/2);
        text(String.format("Player 1: %5d%c %c", m_players[0].m_score, (m_turn == 0 ? '*' : ' '), m_players[0].m_computer == true ? 'C' : 'H'), score1Loc.x, score1Loc.y);

        fill(255, 0, 0);
        Point score2Loc = pointAt(Board.xOffset/2 + ((Board.WIDTH * Board.CELL_WIDTH) / 2) + Board.CELL_WIDTH * 1, Board.yOffset/2);
        text(String.format("Player 2: %5d%c %c", m_players[1].m_score, (m_turn == 1 ? '*' : ' '), m_players[1].m_computer == true ? 'C' : 'H'), score2Loc.x, score2Loc.y);

        textSize(12);
        fill(255, 255, 255);
        text(String.format("Squares: Last: %2d, Total: %3d ", m_players[0].m_lastNumSquares, m_players[0].m_squares.size()), score1Loc.x, score1Loc.y + 25);
        fill(0, 0, 0);
        text(String.format("Squares: Last: %2d, Total: %3d ", m_players[0].m_lastNumSquares, m_players[0].m_squares.size()), score1Loc.x + 1, score1Loc.y + 25 + 1);

        fill(255, 255, 255);
        text(String.format("Squares: Last: %2d, Total: %3d ", m_players[1].m_lastNumSquares, m_players[1].m_squares.size()), score2Loc.x, score2Loc.y + 25);
        fill(0, 0, 0);
        text(String.format("Squares: Last: %2d, Total: %3d ", m_players[1].m_lastNumSquares, m_players[1].m_squares.size()), score2Loc.x + 1, score2Loc.y + 25 + 1);
        
        textSize(10);
        fill(255, 255, 255);
        text(String.format("Comp (%s) vs Comp (%s), turn: %d ", 
            (m_players[0].m_playStyle == PS_DEFENSIVE ? "Def" : m_players[0].m_playStyle == PS_OFFENSIVE ? "Off" : "Noob"), 
            (m_players[1].m_playStyle == PS_DEFENSIVE ? "Def" : m_players[1].m_playStyle == PS_OFFENSIVE ? "Off" : "Noob"), 
            board.m_turn), score1Loc.x + 1, score1Loc.y - 23 + 1);
        fill(0, 0, 0);
        text(String.format("Comp (%s) vs Comp (%s), turn: %d ", 
            (m_players[0].m_playStyle == PS_DEFENSIVE ? "Def" : m_players[0].m_playStyle == PS_OFFENSIVE ? "Off" : "Noob"), 
            (m_players[1].m_playStyle == PS_DEFENSIVE ? "Def" : m_players[1].m_playStyle == PS_OFFENSIVE ? "Off" : "Noob"), 
            board.m_turn), score1Loc.x, score1Loc.y - 23);

        noFill();

        for (final Square s : m_players[0].m_squares) drawSquare(s, 0, 0, 255);
        for (final Square s : m_players[1].m_squares) drawSquare(s, 255, 0, 0);

        for (int index=0; index < WIDTH * HEIGHT; ++index) {
            final int x = index % WIDTH;
            final int y = index / WIDTH;
            int red=255, green=255, blue=255;

            if (m_last.index == index) {
                // highlight the last move in yellow
                green = 192;
                blue  = 0;
            } else {
                if (1 == m_board[index]) {
                    red   = 0;
                    green = 0;
                } else 
                if (2 == m_board[index]) {
                    green = 0;
                    blue  = 0;
                }
            }
            drawGameCell(pointAt(x, y), red, green, blue);
        }
    } // Board::drawBoard


    // ------------------------------------------------------------------------------------------
    // Draw a completed square on the board to show its contents
    // ------------------------------------------------------------------------------------------
    void drawSquare(final Square s, int red, int green, int blue) {
        final int xOff = xOffset + Board.CELL_WIDTH  / 2;
        final int yOff = yOffset + Board.yOffset / 2;
        final int x1 = s.p1.x;
        final int y1 = s.p1.y;
        final int x2 = s.p2.x;
        final int y2 = s.p2.y;
        final int x3 = s.p3.x;
        final int y3 = s.p3.y;
        final int x4 = s.p4.x;
        final int y4 = s.p4.y;

        int w1 = 2;
        int w2 = 2;

        if (red == 255 && green == 0 && blue == 0) {
            stroke(red, 75, 75);
        } else if (red == 0 && green == 0 && blue == 255) {
            stroke(108, 108, blue);
        }

        boolean lastSquares = false;
        if ((m_last.x == x1 && m_last.y == y1) || (m_last.x == x2 && m_last.y == y2) || (m_last.x == x3 && m_last.y == y3) || (m_last.x == x4 && m_last.y == y4)) {
            w1 = 4;
            w2 = 3;
            lastSquares = true;
            stroke(red, green, blue);
        }

        if (!m_onlyShowLastSquares || lastSquares) {
            if (x1 == x2 || y1 == y2) strokeWeight(w1); 
            else strokeWeight(w2);
            line((xOff + x1 * Board.CELL_WIDTH), (yOff + y1 * Board.CELL_HEIGHT), 
                (xOff + x2 * Board.CELL_WIDTH), (yOff + y2 * Board.CELL_HEIGHT));

            if (x2 == x3 || y2 == y3) strokeWeight(w1); 
            else strokeWeight(w2);
            line((xOff + x2 * Board.CELL_WIDTH), (yOff + y2 * Board.CELL_HEIGHT), 
                (xOff + x3 * Board.CELL_WIDTH), (yOff + y3 * Board.CELL_HEIGHT));

            if (x3 == x4 || y3 == y4) strokeWeight(w1); 
            else strokeWeight(w2);
            line((xOff + x3 * Board.CELL_WIDTH), (yOff + y3 * Board.CELL_HEIGHT), 
                (xOff + x4 * Board.CELL_WIDTH), (yOff + y4 * Board.CELL_HEIGHT));

            if (x4 == x1 || y4 == y1) strokeWeight(w1); 
            else strokeWeight(w2);
            line((xOff + x4 * Board.CELL_WIDTH), (yOff + y4 * Board.CELL_HEIGHT), 
                (xOff + x1 * Board.CELL_WIDTH), (yOff + y1 * Board.CELL_HEIGHT));
        }

        strokeWeight(1);
    } // Board::drawSquare


    // ------------------------------------------------------------------------------------------
    // Advance the turn to the next player
    // ------------------------------------------------------------------------------------------
    void advanceTurn() {
        m_turn = (m_turn + 1) % 2;
    } // end Board::advanceTurn


    // ------------------------------------------------------------------------------------------
    // @name:     createRandomizedRange
    // 
    // @summary:  Create an array of ordinal numbers starting with 0 and then randomize
    //            their order.  This is used to randomize the order that various loops examine the
    //            board's contents so that it minimizes noticeable or predictable patterns from emerging
    //            such as those that would be noticeable if we always examined the board from left
    //            to right and top to bottom.
    // 
    // @param:    size - the size of the array to create
    //
    // @returns:  new array of randomized index values  
    // ------------------------------------------------------------------------------------------
    int[] createRandomizedRange(final int size) {
        // Create and initialize the array of sequential integers:
        int[] numbers = new int[size];
        for (int i=0; i < size; ++i) { numbers[i] = i; }

        if (m_createRandomizedRangeOrder) {
            // Randomize the numbers so that, just like in a for-loop, each
            // number occurs once but unlike a for-loop they now occur in
            // a random order:
            for (int passes=0; passes < size * size; ++passes) {
                // exchange two random array members:
                final int r1 = int(random(size - 1));
                final int r2 = int(random(size - 1));
                if (r1 != r2) {
                    final int tmp = numbers[r1];
                    numbers[r1] = numbers[r2];
                    numbers[r2] = tmp;
                }
            }
        }

        return numbers;
    } // Board::createRandomizedRange


    // ------------------------------------------------------------------------------------------
    // @name:     analyze
    // 
    // @summary:  Analyze the board and produce a list of all completed and
    //            potential squares that can be made for the specified color
    //            (side) that involves the specified x,y point for one of the
    //            corners. 
    //            - The potential square list is placed in 'potential'.
    //            - The completed square list is placed in 'm_squares' for the player.
    //            - The number of squares created by this move is stored in 
    //              'm_lastNumSquares1' or 'm_lastNumSquares2'.
    //
    //            This method is usually called just after modifying the contents of
    //            the board when a player has made a move to determine the effects of
    //            the last move.
    // 
    // @param:    move        the point of the move just made by the current color
    // @param:    potential   a list of potential squares we could make
    //
    // @returns:  the score for the specified side (color)
    // ------------------------------------------------------------------------------------------
    int analyze(final Point move, ArrayList<Square> potential) {
        int total = 0;
        
        final int x = move.x;
        final int y = move.y;
        final int clr = m_turn + 1;

        if (null != potential) {
            potential.clear();
        }

        // determine the other players color
        m_players[m_turn].m_lastNumSquares = 0;
        int other = (clr == 1) ? 2 : 1;
        
        // Instead of using a sequential for-loop for iterating over the
        // ordinal row and column numbers we want to examine we instead
        // set up two arrays for the row and column numbers we need to go
        // through (0 thru WIDTH/HEIGHT).  Then we createRandomizedRange the order of
        // these two arrays.  Then we do our for-loops and use the indexed
        // values for the x and y values.  That way we remove any deterministic
        // (and thus predictable by humans) patterns influenced by always
        // approaching and examining from the lower numbered rows and columns
        // first as would happen in simple nested x and y for-loops.
        int[] rows = createRandomizedRange(WIDTH);
        int[] columns = createRandomizedRange(HEIGHT);

        for (int index=0; index < WIDTH * HEIGHT; ++index) {
            final int row =    rows[index / WIDTH];
            final int col = columns[index % WIDTH];

            // (x, y) and (col, row) are the first two corners.
            // Calculate the other two corners:
            final int dx = col - x;   // delta x
            final int dy = row - y;   // delta y

            final int x1 = x - dy;    // corner 3
            final int y1 = y + dx;

            final int x2 = col - dy;  // corner 4
            final int y2 = row + dx;

            // Make sure all corners for this square are on the board
            // and make sure this (col, row) spot isn't the same spot as (x, y)
            if (x1 < 0 || x1 >= Board.WIDTH  || 
                y1 < 0 || y1 >= Board.HEIGHT || 
                x2 < 0 || x2 >= Board.WIDTH  || 
                y2 < 0 || y2 >= Board.HEIGHT || 
                (col == x && row == y) )
                continue;

            // Get the values on the board for all four corners
            final int value1 = m_board[  y * Board.WIDTH +   x];
            final int value2 = m_board[row * Board.WIDTH + col];
            final int value3 = m_board[ y1 * Board.WIDTH +  x1];
            final int value4 = m_board[ y2 * Board.WIDTH +  x2];

            // Make sure the other player doesn't already have a piece in any corner:
            if (value1 == other || value2 == other || value3 == other || value4 == other)
                continue;

            // Calculate how many empty corners remain:
            final int remain = 
                (value1 == 0 ? 1 : 0) +
                (value2 == 0 ? 1 : 0) +
                (value3 == 0 ? 1 : 0) +
                (value4 == 0 ? 1 : 0);

            // Calculate the left, top, right, and bottom cartesian edges,
            // and then the width and height of that area in order to get
            // the score value.  

            // Since in the current form of the game we know this is always a
            // square there's no real need to calc the top, bottom, or height
            // but I do in case we want to support rectangles some day.
            final int left   = min(min(min(x, col), x1), x2);
            final int top    = min(min(min(y, row), y1), y2);
            final int right  = max(max(max(x, col), x1), x2);
            final int bottom = max(max(max(y, row), y1), y2);

            // Calculate the score value if this square was completed
            final int score = ((right - left) + 1) * ((bottom - top) + 1);

            // Create an object to represent this square
            final Square square = new Square(col, row, x, y, x1, y1, x2, y2, clr, score, remain);

            // See if this square is complete
            if (remain == 0) {
                // Add its value to our running total
                total += score;

                // Add it to our list of completed squares if it is not already in the list
                if (!m_players[m_turn].m_squares.contains(square)) {
                    m_players[m_turn].m_squares.add(square);
                    m_players[m_turn].m_lastNumSquares++;
                }
            } else {
                // Uncompleted Square:
                if (null != potential) {
                    // Add it to our list of potential squares if it's not already in there
                    if (!potential.contains(square)) {
                        potential.add(square);
                    }
                }
            }
        }

        return total;
    } // Board::analyze


    // ------------------------------------------------------------------------------------------
    // @name:     findBestMove
    // 
    // @summary:  Find the best move available for the given color.
    //            This is mainly called to make the next move when
    //            playing for the computer side.
    // 
    // @param:    none
    // 
    // @returns:  The Point for the best move available
    // ------------------------------------------------------------------------------------------
    Point findBestMove() {
        final int clr = m_turn + 1;

        if (DebugLevel >= 2) {
            System.out.println("entering findBestMove()");
            System.out.println("finding for color: " + clr);
            System.out.println("Board m_turn: " + board.m_turn);
        }

        // Make a random move if we're configured to make occassional
        // mistakes or if we're in beginner mode
        if (m_players[m_turn].m_goofs || m_players[m_turn].m_playStyle == PS_BEGINNER) {
            if (int(random((m_players[m_turn].m_playStyle == PS_BEGINNER) ? 4 : 12)) == 1) {
                int x = -1, y = -1;
                while (x < 0 || m_board[y * Board.WIDTH + x] > 0) {
                    x = int(random(Board.WIDTH - 1));
                    y = int(random(Board.HEIGHT - 1));
                }
                if (DebugLevel >= 2) { 
                    System.out.println("exiting findBestMove() - made beginner (random) move");
                }
                return pointAt(x, y);
            }
        }

        // Produce a list of all uncompleted squares that can be made
        int total = 0;
        int[] rows = createRandomizedRange(WIDTH);
        int[] columns = createRandomizedRange(HEIGHT);
        ArrayList<Square> all_incomplete = new ArrayList();
        for (int index=0; index < WIDTH * HEIGHT; ++index) {
            ArrayList<Square> cur_incomplete = new ArrayList();
            Point move = pointAt(columns[index % WIDTH], rows[index / WIDTH]);
            analyze(move, cur_incomplete);
            for (Square s : cur_incomplete) { 
                if (!all_incomplete.contains(s)) {
                    all_incomplete.add(s);
                    total++;
                }
            }
        }

        if (DebugLevel >= 2) { 
            System.out.println("findBestMove() - total: " + total);
        }

        assert(total == all_incomplete.size());

        // If no good moves exist, pick any empty spot
        if (total == 0) {
            for (int index=0; index < WIDTH * HEIGHT; ++index) {
                if (m_board[index] == 0) {
                    m_lastPoints = 0;
                    if (DebugLevel >= 2) { 
                        System.out.println("exiting findBestMove() - no good moves exist - making random move");
                    }
                    return pointAt(index);
                }
            }
        }

        // Sort the possible squares by their point values in descending order
        all_incomplete.sort(new Comparator<Square>() {
            @Override
            public int compare(Square s1, Square s2) {
                return s2.points - s1.points;
            }
        });    

        // At this point, the squares with the highest point value are at the top
        int best = 0;
        int highest = 0;

        // See if we are one move away from completing a square
        for (int k=0; k < total; k++) {
            if (all_incomplete.get(k).remain == 1 && all_incomplete.get(k).points > highest) {
                highest = all_incomplete.get(k).points;
                best = k;
            }
        }

        if (DebugLevel >= 2) { 
            System.out.println("findBestMove() - highest: " + highest + " best: " + best);
        }

        // Limit the moves considered to those at the top with the same point value
        int same = 0;
        int delta = Board.WIDTH;

        for (same=0; same < total - 1; same++)
            if (all_incomplete.get(same).points != all_incomplete.get(same + 1).points)
                break;

        if (DebugLevel >= 2) { 
            System.out.println("findBestMove() - same: " + same);
        }

        if (highest < (m_players[m_turn].m_playStyle == PS_BEGINNER ? 36 : 4)) {
            // the highest available square within one move yields a low 
            // point value. Find the next square with a larger point value...
            if (m_players[m_turn].m_playStyle == PS_DEFENSIVE) {
                // favor odd-angled diagonal squares over non-diagonal squares. They are
                // harder to see visually.
                if (DebugLevel >= 2) { 
                    System.out.println("findBestMove() - defensive style");
                }
                int oldBest = best;
                best = 0;

                for (int loop=0; loop < same; loop++) {
                    int tmpDelta = abs(((all_incomplete.get(loop).p1.x - all_incomplete.get(loop).p2.x) - 2));
                    if (tmpDelta < delta) {
                        best = loop;
                        delta = tmpDelta;
                    }
                }

                if (best < all_incomplete.size() && all_incomplete.get(best).remain > 2)
                    best = oldBest;
            }
        }

        // Find the remaining spots needed for the best incomplete square.  We pick one of the remaining
        // corners randomly to help eliminate patterns in the move making that the user may pick up on.
        Square s = all_incomplete.get(best);

        if (DebugLevel >= 2) { 
            System.out.println("findBestMove() - working on square: " + s.toString());
        }

        ArrayList<Point> remaining = new ArrayList();
        if (m_board[s.p1.index] == 0)
            remaining.add(s.p1);
        if (m_board[s.p2.index] == 0)
            remaining.add(s.p2);
        if (m_board[s.p3.index] == 0)
            remaining.add(s.p3);
        if (m_board[s.p4.index] == 0)
            remaining.add(s.p4);

        int pick = int(random(remaining.size() - 1));

        return remaining.get(pick);
    } // Board::findBestMove


    // ------------------------------------------------------------------------------------------
    // Name:       makeMove
    // Purpose:    Make a move for the current side
    // ------------------------------------------------------------------------------------------
    Point makeMove() {
        // Find our best move
        final Point us = pointAt(findBestMove());
        final int ourPoints = m_lastPoints;

        Point move = us;

        if (m_players[m_turn].m_playStyle == PS_DEFENSIVE) {
            advanceTurn();  // advance to our opponents turn

            // Find our opponents best offensive move
            final int origStyle = m_players[m_turn].m_playStyle;

            m_players[m_turn].m_playStyle = PS_OFFENSIVE;
            final Point them = pointAt(findBestMove());
            final int theirPoints = m_lastPoints;
            m_players[m_turn].m_playStyle = origStyle;

            advanceTurn();  // advance back to our turn

            // At this point:
            // Our       best move points are in 'ourPoints' moving to Point 'us'.
            // Opponents best move points are in 'theirPoints' moving to Point 'them'.
            // 
            // Block his move if it makes as many or more points than our move:
            move = (theirPoints >= ourPoints) ? them : us;
        }

        placePiece(move);

        return move;
    } // Board::makeMove


    // ------------------------------------------------------------------------------------------
    // @name:       placePiece
    // @summary:    Place the specified color piece at the specified location on the board
    //              for the current player in 'm_turn'.
    // 
    // @param:      x   - the column of the move
    // @param:      y   - the row    of the move
    // 
    // @returns:    score points made for any completed square(s) from this move
    // ------------------------------------------------------------------------------------------
    int placePiece(final Point pt) {
        if (!pt.valid()) { 
            System.out.println("Error: placePiece(" + pt.x + ", " + pt.y + ") is out of bounds.");
            assert(false); 
            return 0;
        } 

        if (m_board[pt.index] > 0) {
            System.out.println("Error: placePiece(" + pt.x + ", " + pt.y + 
                ") is occupied (" + pt.index + ") := " + m_board[pt.index]);
            assert(false); 
            return 0;
        }

        // Place the piece on the board
        m_board[pt.index] = m_turn + 1;
        m_history.add(pt);
        m_last = pointAt(pt);

        // Get the score points resulting from this move
        int points = analyze(pt, null);

        if (points > 0) {
            if (m_playSounds) {
                if (points >= 25 && m_turn == 0) {
                    m_niceMoveSnd.stop();
                    m_niceMoveSnd.play();
                } else {
                    m_squaresSnd.stop();
                    m_squaresSnd.play();
                }
            }
        } else {
            if (m_playSounds)
                m_moveSnd.stop();
                m_moveSnd.play();
        }

        // Update the appropriate score with any points made
        m_players[m_turn].m_score += points;

        return points;
    } // Board::placePiece


    // ------------------------------------------------------------------------------------------
    // @name:       checkGameOver
    // @summary:    See if the game has been won, is tied, or still running
    // 
    // @param:      
    // 
    // @returns:    GS_RUNNING if game is not over (still playing)    
    //              GS_PLAYER1WINS if player 1 has won
    //              GS_PLAYER2WINS if player 2 has won
    //              GS_TIE if game has ended with a tie
    // ------------------------------------------------------------------------------------------
    int checkGameOver() {
        int gameOver = 0;
        String reason = "";

        if (m_stopAt150) {
            if (m_players[0].m_score >= 150) {
                reason = "Player reached 150.";            
                gameOver = 1;
            } else if (m_players[1].m_score >= 150) {
                reason = "Player reached 150.";            
                gameOver = 2;
            }
        } else {
            // see if there are any empty spots
            gameOver = 1;
            reason = "All spots are used.";
            for (int contents : m_board) {
                if (0 == contents) {
                    gameOver = 0;
                    break;
                }
            }
        }

        // See if the board has room for more moves:
        if (gameOver != 0) {
            // Decide who won or lost this game or if it is a draw
            if (DebugLevel >= 1) {
                String winner;
                if (m_players[0].m_score == m_players[1].m_score) {
                    winner = "Tie Game!";
                } else {
                    if (m_players[0].m_score > m_players[1].m_score) {
                        gameOver = 1;
                    } else {
                        gameOver = 2;
                    }
                    winner = String.format("Player %d wins: %d to %d", gameOver, m_players[0].m_score, m_players[1].m_score);
                }
                
                if (m_displayed_game_over == false) {
                    System.out.println(reason + " " + winner);
                    m_displayed_game_over = true;
                }
            }
        }

        return gameOver;
    } // Board::checkGameOver

} // end of Board class definition


// ------------------------------------------------------------------------------------------
// Player class definition
// 
class Player {
    // Player State:
    ArrayList<Square>  m_squares;
    int                m_score;
    int                m_lastNumSquares;

    // Player Prefs:
    int                m_playStyle;
    boolean            m_goofs;
    boolean            m_computer;

    public Player() {
        //m_playStyle  = PS_BEGINNER;
        //m_playStyle  = PS_OFFENSIVE;
        m_playStyle  = Board.PS_DEFENSIVE;
        m_goofs      = false;
        m_computer   = false;
    }

    void initGame() {
        m_squares = new ArrayList<Square>();
        m_lastNumSquares = 0;
        m_score = 0;
    }

} // end of Player class definition


// ------------------------------------------------------------------------------------------
// The Point class is used to hold a cartesian coordinate
// that is convertible to/from a sequential index
// ------------------------------------------------------------------------------------------
class Point {
    int index, x, y;

    
    Point(final Point that) {
        this.index = that.index;
        this.x = that.x;
        this.y = that.y;
    }

    
    Point(final int x, final int y) {
        this.x = x;
        this.y = y;
        this.index = y * Board.WIDTH + x;
    }

    
    Point(final int index) {
        this.x = index % Board.WIDTH;
        this.y = index / Board.WIDTH;
        this.index = index;
    }
    

    boolean valid() {
        return (x >= 0) && (x < Board.WIDTH) && (y >= 0) && (y < Board.HEIGHT);
    }


    @Override
    public boolean equals(final Object obj) {
        if (obj == null)
            return false;
        final Point p = (Point) obj;
        if (p == this)
            return true;
        return p.index == index;
    }


    @Override
    public String toString() {
        return String.format("(%d,%d)", x, y);
    }

} // class Point


// ------------------------------------------------------------------------------------------
// Point construction helper functions
// 
public Point pointAt(final int x, final int y) {
    return new Point(x, y);
}

public Point pointAt(final int index) {
    return new Point(index);
}

public Point pointAt(final Point at) {
    return new Point(at);
}


// ------------------------------------------------------------------------------------------
// The Square class is used to keep track of
// completed and work in progress squares
// ------------------------------------------------------------------------------------------
class Square {
    Point p1, p2, p3, p4;
    int   points;
    int   remain;
    int   clr;

    Square(final Square that) {
        this.p1 = pointAt(that.p1);
        this.p2 = pointAt(that.p2);
        this.p3 = pointAt(that.p3);
        this.p4 = pointAt(that.p4);
        this.points = that.points;
        this.remain = that.remain;
        this.clr = that.clr;

        normalize();
    }


    Square(final int x1, final int y1, 
        final int x2, final int y2, 
        final int x3, final int y3, 
        final int x4, final int y4) {
        p1 = pointAt(x1, y1);
        p2 = pointAt(x2, y2);
        p3 = pointAt(x3, y3);
        p4 = pointAt(x4, y4);
        points = 0;
        remain = 4;
        clr = 0;

        normalize();
    }

    
    Square(final int x1, final int y1, 
        final int x2, final int y2, 
        final int x3, final int y3, 
        final int x4, final int y4, 
        final int clr, 
        final int points, 
        final int remain) {
        p1 = pointAt(x1, y1);
        p2 = pointAt(x2, y2);
        p3 = pointAt(x3, y3);
        p4 = pointAt(x4, y4);
        this.points = points;
        this.remain = remain;
        this.clr = clr;

        normalize();
    }


    // ------------------------------------------------------------------------------------------
    // @name:       normalize  
    // @summary:    Normalize a square's definition to start at the top left and
    //              and go clockwise. 
    // 
    // @param:      none
    // 
    // @returns:    void
    // ------------------------------------------------------------------------------------------
    void  normalize() {
        Point[] pts = new Point[4];

        pts[0] = p1;
        pts[1] = p2;
        pts[2] = p3;
        pts[3] = p4;

        boolean bChanged = true;
        while (bChanged) {
            bChanged = false;
            for (int k=0; k < 3; k++) {
                if (pts[k].y > pts[k + 1].y) {
                    Point tmp = pointAt(pts[k]);
                    pts[k] = pts[k + 1];
                    pts[k + 1] = tmp;
                    bChanged = true;
                }
            }
        }

        if (pts[0].y != pts[1].y) {
            // diagonal square, normalize the two center points
            if (pts[1].x > pts[2].x) {
                Point tmp = pointAt(pts[1]);
                pts[1] = pts[2];
                pts[2] = tmp;
            }
        } else {
            // non-diagonal square, normalize the first and second pairs
            if (pts[0].x < pts[1].x) {
                Point tmp = pointAt(pts[0]);
                pts[0] = pts[1];
                pts[1] = tmp;
            }

            if (pts[2].x < pts[3].x) {
                Point tmp = pointAt(pts[2]);
                pts[2] = pts[3];
                pts[3] = tmp;
            }
        }
    } // Square::normalize


    @Override
    public boolean equals(Object obj) {
        if (obj == null) return false;
        Square square = (Square) obj;
        if (square == this) return true;

        return square.p1.equals(p1) && 
               square.p2.equals(p2) && 
               square.p3.equals(p3) && 
               square.p4.equals(p4) && 
               square.points == points && 
               square.remain == remain && 
               square.clr == clr;
    } // Square::equals


    @Override
    public String toString() {
        return String.format("Square: p1(%d,%d) p2(%d,%d), p3(%d,%d), p4(%d,%d), color: %d, points: %d, remain: %d", 
            p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, p4.x, p4.y, clr, points, remain);
    } // Squares::toString

} // class Square


// ------------------------------------------------------------------------------------------
// @name:       newGame
// @summary:    Set up two instances of Board in order to evaluate
//              them by competing against each other
// @param:              
// @returns:              
// ------------------------------------------------------------------------------------------
void newGame() {
    // load the game sounds
    SoundFile[] sounds = new SoundFile[3];
    sounds[0] = new SoundFile(this, "move.wav");
    sounds[1] = new SoundFile(this, "squares.wav");
    sounds[2] = new SoundFile(this, "nicemove.wav");

    // Make two Player instances and a Board:
    Player p1 = new Player();
    p1.m_playStyle = Board.PS_DEFENSIVE;
    p1.m_goofs = false;
    p1.m_computer = false;

    Player p2 = new Player();
    p2.m_playStyle = Board.PS_OFFENSIVE;
    p2.m_goofs = false;
    p2.m_computer = true;
    
    board = new Board(sounds, p1, p2);
    board.initGame();
    board.m_playSounds = true;
    board.m_onlyShowLastSquares = false;
    board.m_createRandomizedRangeOrder = true;
    board.m_stopAt150 = true;
}


// ------------------------------------------------------------------------------------------
// @name:       settings
// @summary:    Called once at start of program (before setup) by the Processing framework.
//              If defined this function allows setting the window size to be calculated
//              dynamically using variable values (that is not allowed in the setup() function) 
// ------------------------------------------------------------------------------------------
void settings() {
    int w = Board.xOffset * 2 + Board.WIDTH * Board.CELL_WIDTH;
    int h = Board.yOffset * 2 + (Board.HEIGHT - 1) * Board.CELL_HEIGHT;
    size(w, h);

    if (DebugLevel >= 1) {
        System.out.println("Window Width: " + w + " Height: " + h);
    }
}


// ------------------------------------------------------------------------------------------
// @name:       evaluate
// 
// @summary:    Test function to set up a loop to run a certain number of games.  
//              Evaluate what percentage was won by player 1.
// ------------------------------------------------------------------------------------------
void evaluate() {
    int totalPasses = 50;
    int passNumber = 0;
    int p1Wins = 0;

    for (passNumber=0; passNumber < totalPasses; ++passNumber) {
        newGame();
        board.drawBoard();
        while (0 == board.checkGameOver()) {
            board.makeMove();
            board.advanceTurn();
        }
        if (board.checkGameOver() == 1) {
            p1Wins++;
        }
    }
    
    System.out.println(String.format("Player 1 won %4.1f%% of the time", ((float)p1Wins / (float)totalPasses) * 100.0));
}


// =========================================================================================
// @name:       setup
// 
// @summary:    Called once at start of program (after calling the settings() function if it
//              exists).
// =========================================================================================
void setup() {
    background(128, 128, 128);
    randomSeed(System.nanoTime());
    
    cursor = pointAt(-1, -1);

    newGame();

    // for debugging
    if ((false)) {
        evaluate();
        exit();
    }

    board.drawBoard();

    if (board.m_players[board.m_turn].m_computer == true) {
        board.makeMove();
        board.advanceTurn();
        board.drawBoard();
    }
}


// =========================================================================================
// @name:       track_human_move
// 
// @summary:    Called to display and track the mouse cursor while
//              the human player is selecting their next move.
// =========================================================================================
void track_human_move() {
    int x = (pmouseX - Board.xOffset) / Board.CELL_WIDTH; 
    int y = (pmouseY - Board.yOffset) / Board.CELL_HEIGHT;

    // See if the mouse is over an empty spot
    Point pt = pointAt(x, y);

    if (pt.valid() && board.m_board[pt.index] == 0) {
        if (!pt.equals(cursor)) {
            int red=0, green=0, blue=0;
            if (cursor.valid()) 
                board.drawGameCell(cursor, 255, 255, 255);

            if (0 == board.m_turn) 
                blue = 255; 
            else 
                red = 255;

            board.drawGameCell(pt, red, green, blue);
            cursor = pt;
        }
    } else {
        if (cursor.valid()) { 
            board.drawGameCell(cursor, 255, 255, 255);
        }
        cursor = pointAt(-1, -1);
    }
}


// =========================================================================================
// @name:       draw
// 
// @summary:    Called continuously after setup() is called
// =========================================================================================
void draw() {
    // See if the current player is set to be a computer or human
    if (board.m_players[board.m_turn].m_computer == false) {
        track_human_move();
    } else {
        if (0 == board.checkGameOver()) {
            board.makeMove();
            board.advanceTurn();
            board.drawBoard();
        }
    }
}


// ------------------------------------------------------------------------------------------
// @name:       mouseClicked
// @summary:    Called when any button on the mouse is clicked
// 
// @returns:    void
// ------------------------------------------------------------------------------------------
void mouseClicked() {
    if (0 != board.checkGameOver()) {
        background(128, 128, 128);
        newGame();
        board.drawBoard();
        return;
    }

    int x = (mouseX - Board.xOffset) / Board.CELL_WIDTH; 
    int y = (mouseY - Board.yOffset) / Board.CELL_HEIGHT;

    Point move = pointAt(x, y);

    if (!move.valid() || board.m_board[move.index] > 0) {
        return;
    }

    board.placePiece(move);
    board.advanceTurn();
    board.drawBoard();

    cursor = pointAt(-1, -1);
}


// ------------------------------------------------------------------------------------------
// @name:       keyPressed
// @summary:    Called when a key is pressed on the keyboard
// 
// @returns:    void
// ------------------------------------------------------------------------------------------
void keyPressed() {
    // Press Q to exit the program
    if ('q' == key || 'Q' == key) {
        exit();
    }

    // Press C to toggle the current player
    // between Computer and Human mode
    if ('c' == key || 'C' == key) {
        board.m_players[board.m_turn].m_computer = !(board.m_players[board.m_turn].m_computer);
        board.drawBoard();
        return;
    }

    // Press N for a New Game
    if ('n' == key || 'N' == key) {
        newGame();
        board.drawBoard();
        return;
    } 

    // Press T to toggle whose turn it is
    if ('t' == key || 'T' == key) {
        board.advanceTurn();
        board.drawBoard();
        return;
    }

    // Press P to select playing style
    if ('p' == key || 'P' == key) {
        board.m_players[0].m_playStyle = ((board.m_players[0].m_playStyle + 1) % 3) + 1;
        board.drawBoard();
        return;
    }

    // Press U to undo the last move
    if ('u' == key || 'U' == key) {
        if (!board.m_history.isEmpty()) {
            ArrayList<Point> list = new ArrayList();
            list.addAll(board.m_history);
            list.remove(list.size() - 1);
            newGame();
            for (final Point move : list) {
                board.placePiece(move);
                board.advanceTurn();
                cursor = pointAt(-1, -1);
            }
            board.drawBoard();
        }
        return;
    }

    // Press spacebar to have the AI make a move for the current player 
    if (' ' == key) {
        if (0 != board.checkGameOver()) {
            background(128, 128, 128);
            newGame();
            board.drawBoard();
            return;
        }

        board.makeMove();
        board.advanceTurn();
        board.drawBoard();
        return;
    }

} // keyPressed()
