
Board board = new Board();

void setup() {
  size(500, 500);
  background(128, 128, 128);
  board.drawBoard();
}

int lastX = -1;
int lastY = -1;
void draw() {
  int x = (pmouseX - Board.xOffset) / Board.CELL_WIDTH; 
  int y = (pmouseY - Board.yOffset) / Board.CELL_HEIGHT;
  if (x >= 0 && x < Board.WIDTH && y >= 0 && y < Board.HEIGHT && board.board[x + y * Board.WIDTH] == 0) {
    if (x != lastX || y != lastY) {
      if (lastX != -1 && lastY != -1) {
        stroke(0, 0, 0);
        fill(255,255,255);
        circle(Board.xOffset + lastX * Board.CELL_WIDTH + Board.CELL_WIDTH/2, Board.yOffset + lastY * Board.CELL_HEIGHT + Board.CELL_HEIGHT/2, Board.radius);
        noFill();
      }
      lastX = x;
      lastY = y;

      if (board.turn == 0)
        fill(255,0,0);
      else
        fill(0,0,255);
      circle(Board.xOffset + x * Board.CELL_WIDTH + Board.CELL_WIDTH/2, Board.yOffset + y * Board.CELL_HEIGHT + Board.CELL_HEIGHT/2, Board.radius);
      noFill();
    }
  } else {
    if (lastX != -1 && lastY != -1) {
      stroke(0, 0, 0);
      fill(255,255,255);
      circle(Board.xOffset + lastX * Board.CELL_WIDTH + Board.CELL_WIDTH/2, Board.yOffset + lastY * Board.CELL_HEIGHT + Board.CELL_HEIGHT/2, Board.radius);
      noFill();
    }
    lastX = lastY = -1;
  }
}

class Board {
  public static final int WIDTH       = 10;
  public static final int HEIGHT      = 10;
  public static final int CELL_WIDTH  = 40;
  public static final int CELL_HEIGHT = 40;
  public static final int xOffset     = 45;
  public static final int yOffset     = 70;
  public static final int radius      = 20;

  int[] board;
  ArrayList<Integer> pieces1;
  ArrayList<Integer> pieces2;
  ArrayList<Square> squares1;
  ArrayList<Square> squares2;
  int score1;
  int score2;
  int turn = 0;
  
  Board() {
    board = new int[WIDTH * HEIGHT];
    pieces1 = new ArrayList();
    pieces2 = new ArrayList();
    squares1 = new ArrayList();
    squares2 = new ArrayList();
    score1 = 0;
    score2 = 0;
  }

  void drawBoard() {
    fill(255,255,255);
    stroke(255,255,255);
    rect(0, 0, 500, Board.CELL_WIDTH);
    noFill();
    stroke(0,0,0);

    textSize(24);
    fill(0,0,0);
    Point score1Loc = new Point(Board.xOffset/2 + ((Board.WIDTH * Board.CELL_WIDTH) / 4) - Board.CELL_WIDTH, Board.yOffset/2);
    Point score2Loc = new Point(Board.xOffset   + ((Board.WIDTH * Board.CELL_WIDTH) / 2) + Board.CELL_WIDTH, Board.yOffset/2);
    text(String.format("Score 1: %5d", score1), score1Loc.x, score1Loc.y);
    text(String.format("Score 2: %5d", score2), score2Loc.x, score2Loc.y);
    noFill();

    for (int y=0; y < Board.HEIGHT; y++) {
      for (int x=0; x < Board.WIDTH; x++) {
        int red = 0;
        int green = 0;
        int blue = 0;
        switch(board[x + y * Board.WIDTH]) {
          default:
            red   = 255;
            green = 255;
            blue  = 255;
            break;
          case 1:
            red = 255;
            break;
          case 2:
            blue = 255;
            break;
        }
        stroke(0,0,0);
        fill(red, green, blue);
        circle(Board.xOffset + x * Board.CELL_WIDTH + Board.CELL_WIDTH/2, Board.yOffset + y * Board.CELL_HEIGHT + Board.CELL_HEIGHT/2, Board.radius);
        noFill();
        noStroke();

        for (Square s : squares1) {
          drawSquare(s, 255, 0, 0);
        }
        for (Square s : squares2) {
          drawSquare(s, 0, 0, 255);
        }
      }
    }
  }

  void drawSquare(Square s, int r, int g, int b) {
    stroke(r,g,b);
    int x1 = s.p1.x;
    int y1 = s.p1.y;
    int x2 = s.p2.x;
    int y2 = s.p2.y;
    int x3 = s.p3.x;
    int y3 = s.p3.y;
    int x4 = s.p4.x;
    int y4 = s.p4.y;
    if (x1 == x2 || y1 == y2) strokeWeight(2); else strokeWeight(1);
    line(
      xOffset + x1 * Board.CELL_WIDTH + Board.CELL_WIDTH/2, Board.yOffset + y1 * Board.CELL_HEIGHT + Board.CELL_HEIGHT/2,
      xOffset + x2 * Board.CELL_WIDTH + Board.CELL_WIDTH/2, Board.yOffset + y2 * Board.CELL_HEIGHT + Board.CELL_HEIGHT/2);
    if (x3 == x4 || y3 == y4) strokeWeight(2); else strokeWeight(1);
    line(
      xOffset + x3 * Board.CELL_WIDTH + Board.CELL_WIDTH/2, Board.yOffset + y3 * Board.CELL_HEIGHT + Board.CELL_HEIGHT/2,
      xOffset + x4 * Board.CELL_WIDTH + Board.CELL_WIDTH/2, Board.yOffset + y4 * Board.CELL_HEIGHT + Board.CELL_HEIGHT/2);
    if (x1 == x3 || y1 == y3) strokeWeight(2); else strokeWeight(1);
    line(
      xOffset + x1 * Board.CELL_WIDTH + Board.CELL_WIDTH/2, Board.yOffset + y1 * Board.CELL_HEIGHT + Board.CELL_HEIGHT/2,
      xOffset + x3 * Board.CELL_WIDTH + Board.CELL_WIDTH/2, Board.yOffset + y3 * Board.CELL_HEIGHT + Board.CELL_HEIGHT/2);
    if (x2 == x4 || y2 == y4) strokeWeight(2); else strokeWeight(1);
    line(
      xOffset + x2 * Board.CELL_WIDTH + Board.CELL_WIDTH/2, Board.yOffset + y2 * Board.CELL_HEIGHT + Board.CELL_HEIGHT/2,
      xOffset + x4 * Board.CELL_WIDTH + Board.CELL_WIDTH/2, Board.yOffset + y4 * Board.CELL_HEIGHT + Board.CELL_HEIGHT/2);
    strokeWeight(1);
}

  void addMove(int x, int y) {
    int index = x + y * Board.WIDTH;
    if (board[index] != 0) return;
    if (turn == 0) {
      pieces1.add(index);
    } else {
      pieces2.add(index);
    }
    board[index] = turn + 1;
    turn = (turn + 1) % 2; 
  }

  void calcSquares() {
    for (int y1=0; y1 < Board.HEIGHT; y1++) {
      for (int x1=0; x1 < Board.WIDTH; x1++) {
        int p1 = board[x1 + y1 * Board.WIDTH];
        if (p1 == 0) continue;
        for (int y2=0; y2 < Board.HEIGHT; y2++) {
          for (int x2=0; x2 < Board.WIDTH; x2++) {
            if (!isSquare(this, x1, y1, x2, y2)) continue;
            int dx12 = abs(x1-x2);
            int dy12 = abs(y1-y2);
            if (dx12 == 0 && dy12 == 0) continue;
            int x3 = x1 - dy12;
            int y3 = y1 + dx12;
            int x4 = x2 - dy12;
            int y4 = y2 + dx12;
            Square s1 = new Square(x1, y1, x2, y2, x3, y3, x4, y4);
            if (p1 == 1) {
              if (!contains(squares1, s1)) {
                //System.out.print("squares1: ");
                //for (Square s : squares1) {
                //  System.out.print(s.toString() + ", ");
                //}
                //System.out.println();
                //System.out.println(s1.toString());
                squares1.add(s1);
                score1 += (abs(x2 - x1) + 1) * (abs(y3 - y1) + 1);

                //System.out.print("squares1: ");
                //for (Square s : squares1) {
                //  System.out.print(s.toString() + ", ");
                //}
                //System.out.println();
              }
            } else {
              if (!contains(squares2, s1)) {
                //System.out.print("squares2: ");
                //for (Square s : squares2) {
                //  System.out.print(s.toString() + ", ");
                //}
                //System.out.println();
                //System.out.println(s1.toString());
                squares2.add(s1);
                score2 += (abs(x2 - x1) + 1) * (abs(y3 - y1) + 1);

                //System.out.print("squares2: ");
                //for (Square s : squares2) {
                //  System.out.print(s.toString() + ", ");
                //}
                //System.out.println();
              }
            }
          }
        }
      }
    }
  }
}

boolean contains(ArrayList<Square> squares, Square s1) {
  if (s1.p2.equals(s1.p3) || s1.p1.equals(s1.p4)) return true;
  Square s2 = new Square(s1.p2.x, s1.p2.y, s1.p1.x, s1.p1.y, s1.p4.x, s1.p4.y, s1.p3.x, s1.p3.y);
  Square s3 = new Square(s1.p4.x, s1.p4.y, s1.p2.x, s1.p2.y, s1.p3.x, s1.p3.y, s1.p1.x, s1.p1.y);
  Square s4 = new Square(s1.p3.x, s1.p3.y, s1.p1.x, s1.p1.y, s1.p4.x, s1.p4.y, s1.p2.x, s1.p2.y);
  for (Square s : squares) {
    if (s.equals(s1) || 
        s.equals(s2) || 
        s.equals(s3) || 
        s.equals(s4)) return true;
  }
  return false;
}

class Point {
  int x, y;

  Point(int x, int y) {
    this.x = x;
    this.y = y;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj == null) return false;
    Point p = (Point) obj;
    if (p == this) return true;
    return (p.x == x) && (p.y == y);
  }
}

class Square {
  Point p1, p2, p3, p4;
  Square(int x1, int y1, int x2, int y2, int x3, int y3, int x4, int y4) {
    p1 = new Point(x1,y1);
    p2 = new Point(x2,y2);
    p3 = new Point(x3,y3);
    p4 = new Point(x4,y4);
  }
  
  @Override
  public boolean equals(Object obj) {
    if (obj == null) return false;
    Square s = (Square) obj;
    if (s == this) return true;
    return (s.p1.equals(p1) && s.p2.equals(p2) && s.p3.equals(p3) && s.p4.equals(p4));
  }
  
  @Override
  public String toString() {
    return String.format("Square(%d,%d %d,%d, %d,%d, %d,%d",
      p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, p4.x, p4.y);
  }
}

static boolean isSquare(Board b, int x1, int y1, int x2, int y2) {
  int dx12 = abs(x1-x2);
  int dy12 = abs(y1-y2);
  if (dx12 == 0 && dy12 == 0) return false;
  int x3 = x1 - dy12;
  int y3 = y1 + dx12;
  int x4 = x2 - dy12;
  int y4 = y2 + dx12;
  if (x1 < 0 || x1 >= Board.WIDTH || y1 < 0 || y1 >= Board.HEIGHT) return false;
  if (x2 < 0 || x2 >= Board.WIDTH || y2 < 0 || y2 >= Board.HEIGHT) return false;
  if (x3 < 0 || x3 >= Board.WIDTH || y3 < 0 || y3 >= Board.HEIGHT) return false;
  if (x4 < 0 || x4 >= Board.WIDTH || y4 < 0 || y4 >= Board.HEIGHT) return false;
  int c = b.board[x1 + y1 * Board.WIDTH];
  if (c == 0) return false;
  if (c != b.board[x2 + y2 * Board.WIDTH]) return false;
  if (c != b.board[x3 + y3 * Board.WIDTH]) return false;
  if (c != b.board[x4 + y4 * Board.WIDTH]) return false;
  return true;
}

void mouseClicked() {
  int x = (mouseX - Board.xOffset) / Board.CELL_WIDTH; 
  int y = (mouseY - Board.yOffset) / Board.CELL_HEIGHT;
  if (x < 0 || x >= Board.WIDTH || y < 0 || y >= Board.HEIGHT) return;
  board.addMove(x, y);
  board.calcSquares();
  board.drawBoard();
  lastX = lastY = -1;

  // debounce
  //try {
  //  Thread.sleep(50);
  //} catch (InterruptedException e) {
  //}
}
