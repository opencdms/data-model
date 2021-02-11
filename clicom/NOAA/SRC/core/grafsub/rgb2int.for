$STORAGE:2

      SUBROUTINE RGB2INT(ICOLOR,JCOLOR)
C
C   ROUTINE TO TRANSLATE RGB COLOR INDEX VALUES TO THE COLOR VALUE 
C   BITS USED BY VGA/EGA BOARDS.
C
C     INPUT - ICOLOR...RGB COLOR VALUES (3 ITEM ARRAY WITH VALUES 0-3)
C    OUTPUT - JCOLOR...INTEGER COLOR VALUE(0-63) 
C
      INTEGER*2 ICOLOR(3),JCOLOR
C
      JCOLOR = 0
      DO 50 I = 1,3
         J = 4 - I
         IF (ICOLOR(J).EQ.0) THEN
            JCOLOR = IBCLR(JCOLOR,I-1)
            JCOLOR = IBCLR(JCOLOR,I+2)
         ELSE IF (ICOLOR(J).EQ.1) THEN
            JCOLOR = IBSET(JCOLOR,I+2)
            JCOLOR = IBCLR(JCOLOR,I-1)
         ELSE IF (ICOLOR(J).EQ.2) THEN
            JCOLOR = IBSET(JCOLOR,I-1)
            JCOLOR = IBCLR(JCOLOR,I+2)
         ELSE IF (ICOLOR(J).EQ.3) THEN
            JCOLOR = IBSET(JCOLOR,I-1)
            JCOLOR = IBSET(JCOLOR,I+2)
         END IF
50    CONTINUE                
      RETURN
      END
