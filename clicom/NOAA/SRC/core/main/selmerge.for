$STORAGE:2
C     PROGRAM SELMERGE
C
C   ROUTINE SELECTS DATA FROM THE FILENAME PASSED IN THE COMMAND
C   LINE USING SELECTION CRITERIA IN FILE P:\DATA\SELECT.CMD.  RESULTS
C   ARE WRITTEN TO FILE0001.TMP ON FIRST PASS, FILE002.TMP ON NEXT, ETC.
C   THIS PROGRAM HAS BEEN MODIFIED TO WORK WITH EITHER DATAEASE VERSION
C   2.5 OR DATAEASE VERSION 4.0
C
      INTERFACE TO SUBROUTINE CMDLIN(ADDRES,LENGTH,RESULT)
      INTEGER*4 ADDRES[VALUE],LENGTH[VALUE]
      CHARACTER*1 RESULT
      END
C----------------------------------------------------------------------
      PROGRAM SELMERGE
      CHARACTER*1 RTNCODE,FLAG1(100),EMAXFLG,EMINFLG
      CHARACTER*3 RECTYPE,TYPDEF(8),ELEM
      CHARACTER*4 MAXYR,MINYR
      CHARACTER*7 OUTCNT(2)
      CHARACTER*6 FLAGS
      CHARACTER*8 BEGSTN,ENDSTN,STNID,BEGDATE,ENDDATE,PERIOD
      CHARACTER*14 INFILE, OUTFILE 
      CHARACTER*22 FILNAME
      CHARACTER*24 FRMNAM(8)
      CHARACTER*64 RESULT
      INTEGER*2  DDSID,IELEM,YEAR,MONTH,DAY,HOUR,NUMLVL,LVLNUM
     +           ,NMLTYP,NORMFLG,BITVAL(30)
      INTEGER*4 PSP,PSPNCHR,OFFSET,IREC,YRMON,BYRMON,EYRMON,
     +          RECCOUNT,NRECCOUNT,NREC,NUMREC
      REAL*4 VALUE(100),PRESSURE,HEIGHT,TEMP,DEWPTDEP,WNDDIR,WNDSPEED,
     +       NORMAL,SDEV,EXTMAX,EXTMIN,MLYMAXMN,MLYMINMN,SDMAX,
     +       SDMIN,PQM(5),PQX(5),PQN(5)

C
      DATA TYPDEF /'MLY','10D','DLY','SYN','HLY','15M','U-A','NML'/
      DATA FRMNAM /'MONTHLY DATA','TEN DAY DATA','DAILY DATA'
     +   ,'SYNOPTIC DATA','HOURLY DATA','FIFTEEN MINUTE DATA'
     +   ,'UPPER-AIR DATA','NORMALS'/
      DATA OUTCNT/'       ','       '/
      
      OUTCNT(2) = CHAR(0)
C
C   LOCATE SEGMENTED ADDRESS OF THE BEGINNING OF THIS PROGRAM
C
      OFFSET = #00100000
      PSP = LOCFAR(SELMERGE)
C
C   COMPUTE THE BEGINNING OF THE PROGRAM SEGMENT PREFIX (PSP)
C
      PSP = (PSP - MOD(PSP,#10000)) - OFFSET 
C
C   LOCATE POSITION OF COMMAND PARAMTERS WITHIN THE PSP
C
      PSPNCHR = PSP + #80
      PSP = PSP + #81
C
C   PASS THE ADDRESS OF THE COMMAND PARAMETERS TO CMDLIN WHICH DECODES
C      THE COMMAND AND RETURNS IT AS RESULT.
C
      CALL CMDLIN(PSP,PSPNCHR,RESULT)
C
C   PULL THE INPUT FILENAME OUT OF THE RESULT
C
      INFILE = ' '
      INFILE = RESULT(1:14)
      IF (INFILE.EQ.' ') THEN
         STOP 2
      END IF
C
C   READ THE SELECTION PARAMETERS AND OTHER CONTROL INFORMATION
C   THEN WRITE THE INFO BACK WITH THE UPDATED CONTROL INFO.
C
      OPEN(63,FILE='P:\DATA\SELECT.CMD',STATUS='OLD'
     +          ,FORM='UNFORMATTED')
      READ(63) RECTYPE,BEGSTN,ENDSTN,BEGDATE,ENDDATE,IMERGE
      WRITE(OUTFILE,'(A9,I1,A4)')  'Q:FILE000',IMERGE,'.TMP'
      IMERGE = IMERGE + 1
      REWIND 63 
      WRITE(63) RECTYPE,BEGSTN,ENDSTN,BEGDATE,ENDDATE,IMERGE
      CLOSE(63)
      READ(BEGDATE,'(I6,2X)') BYRMON
      READ(ENDDATE,'(I6,2X)') EYRMON
C
C   FIND THE RELATIVE NUMBER OF THE DATATYPE WANTED TO INDEX INTO THE
C   FRMNAM ARRAY
C
      DO 20 I = 1,8
         IF (RECTYPE.EQ.TYPDEF(I)) THEN
            ITYPE = I
            GO TO 30
         END IF
20    CONTINUE
      STOP 2
30    CONTINUE
C
C   OPEN THE INPUT AND OUTPUT FILES
C
50    CONTINUE
      OPEN (25,FILE=INFILE,STATUS='OLD',FORM='BINARY',SHARE='DENYWR'
     +       ,MODE='READ',IOSTAT=IOCHK)
      IF (IOCHK.NE.0) THEN
         CALL OPENMSG(INFILE,'SELMERGE    ',IOCHK)
         GO TO 50
      END IF
      OPEN (51,FILE=OUTFILE,STATUS='UNKNOWN',FORM='BINARY')
C
C  WRITE THE RUNNING TOTAL LINE
C
      CALL CLRMSG(2)
      CALL CLRMSG(1)
      CALL LOCATE(23,0,IERR) 
      CALL WRTSTR('Output file = ',14,14,0)
      CALL WRTSTR(OUTFILE,14,14,0)
      CALL LOCATE(24,0,IERR)
      CALL WRTSTR('Records Read -          Records processed - '
     +             ,44,14,0)
C
C   READ THE INPUT FILE AND SELECT THE DATA WANTED
C
      DO 500 IREC=1,999999  
$INCLUDE:'READAREC.INC'
         NRECCOUNT = NRECCOUNT + INT4(1)
         CALL LOCATE(24,15,IERR)
         WRITE(OUTCNT,'(I7)') NRECCOUNT
         CALL CWRITE(OUTCNT,12,IERR)
         IF (RTNCODE.EQ.'1'.OR.STNID.GT.ENDSTN.OR.
     +         (STNID.EQ.ENDSTN.AND.YRMON.GT.EYRMON)) THEN
            GO TO 501
         ELSE IF (STNID.LT.BEGSTN.OR.YRMON.LT.BYRMON.OR.
     +        YRMON.GT.EYRMON)THEN
            GO TO 500
         END IF
         RECCOUNT = RECCOUNT + INT4(1)
         CALL LOCATE(24,44,IERR)
         WRITE(OUTCNT,'(I7)') RECCOUNT
         CALL CWRITE(OUTCNT,12,IERR)
C
C     WRITE THE CURRENT RECORD TO THE OUTPUT FILE 
C
         IF (RECTYPE.EQ.'DLY') THEN
            CALL WRTDLY(DDSID,STNID,IELEM,YEAR,MONTH,VALUE,FLAG1)
         ELSE IF (RECTYPE.EQ.'MLY') THEN
            CALL WRTMLY(DDSID,STNID,IELEM,YEAR,VALUE,FLAG1)
         ELSE IF (RECTYPE.EQ.'10D') THEN
            CALL WRT10D(DDSID,STNID,IELEM,YEAR,VALUE,FLAG1)
         ELSE IF (RECTYPE.EQ.'SYN') THEN
            CALL WRTSYN(DDSID,STNID,IELEM,YEAR,MONTH,DAY,VALUE,FLAG1)
         ELSE IF (RECTYPE.EQ.'HLY') THEN
            CALL WRTHLY(DDSID,STNID,IELEM,YEAR,MONTH,DAY,VALUE,FLAG1)
         ELSE IF (RECTYPE.EQ.'15M') THEN
            CALL WRT15M(DDSID,STNID,IELEM,YEAR,MONTH,DAY,VALUE,FLAG1)
         ELSE IF (RECTYPE.EQ.'U-A') THEN
            VALUE(1) = PRESSURE
            VALUE(2) = HEIGHT
            VALUE(3) = TEMP
            VALUE(4) = DEWPTDEP
            VALUE(5) = WNDDIR
            VALUE(6) = WNDSPEED
            CALL WRTUA(DDSID,STNID,YEAR,MONTH,DAY,HOUR,NUMLVL,LVLNUM
     +          ,VALUE,FLAGS)
         ELSE IF (RECTYPE.EQ.'NML') THEN
             CALL WRTNML(STNID,PERIOD,MONTH,ELEM,NORMAL,NMLTYP,
     +                   NORMFLG,SDEV,EXTMAX,EMAXFLG,MAXYR,
     +                   EXTMIN,EMINFLG,MINYR,MLYMAXMN,SDMAX,
     +                   MLYMINMN,SDMIN,PQM,PQX,PQN,BITVAL)
         END IF
500   CONTINUE
501   CONTINUE
C
C   CLOSE INPUT AND OUTPUT FILES THEN UPDATE THE NUMBER OF TOTAL 
C   RECORDS IN THE FDN FILE FOR THIS DATATYPE
C
      CLOSE(25)
      CLOSE(51)
      NREC = 0
      CALL FNDFIL(FRMNAM(ITYPE),FILNAME,NUMREC)
      FILNAME(12:14) = 'FDN'
      IF (IMERGE.GT.2) THEN
         OPEN (72,FILE=FILNAME,STATUS='OLD',FORM='FORMATTED')
         READ(72,'(2I6)') NREC, NDEL
         REWIND 72
      ELSE  
         OPEN (72,FILE=FILNAME,STATUS='UNKNOWN',FORM='FORMATTED')
      END IF               
      NDEL = 0
      NREC = NREC + RECCOUNT
      WRITE(72,'(2I6)') NREC,NDEL
      CLOSE(72)
      CALL LOCATE(24,0,IERR)
      STOP ' '
      END
$PAGE
************************************************************************
      SUBROUTINE WRTMLY(IDDSID,STNID,IELEM,IYEAR,VALUE,FLAG1)
C
C  THIS SUBROUTINE WRITES A MLY FORMAT DATAEASE RECORD.  

C  LOCAL VARIABLES
      CHARACTER*8 LOCALID
      CHARACTER*4 YEAR
      CHARACTER*3 ELEM,DDSID
      CHARACTER*1 OUTREC(84) 
      INTEGER*2 HEADER(2)
*  PASSED VARIABLES
      CHARACTER*8 STNID
      CHARACTER*1 FLAG1(100)
      INTEGER*2 IDDSID,IELEM,IYEAR
      REAL*4  VALUE(100)
C
C  EQUIVALENCE THE INPUT VARIABLES TO THE OUTPUT RECORD STRING 
C
      EQUIVALENCE (HEADER,OUTREC(1)),(DDSID,OUTREC(7)), 
     +            (LOCALID,OUTREC(10)),
     +            (ELEM,OUTREC(18)),(YEAR,OUTREC(21)) 

      RTNCODE = '0'
   10 CONTINUE
C
C  WRITE THE INFORMATION INTO THE DATEASE RECORD HEADER  
C
      HEADER(1) = 12
      HEADER(2) = 0
      LOCALID = STNID
      WRITE(DDSID ,'(I3.3)') IDDSID
      WRITE(ELEM ,'(I3.3)') IELEM
      WRITE(YEAR ,'(I4.4)') IYEAR
C
C  WRITE THE DATA VALUES INTO THE DATEASE FORMAT OUTPUT RECORD  
C
      DO 200 I=1,12
         IPOS = 25 + (I-1)*5
         CALL MOVBYT(4,VALUE(I),1,OUTREC,IPOS)
         OUTREC(IPOS+4) = FLAG1(I)
200   CONTINUE
      WRITE(51) OUTREC
300   CONTINUE
      RETURN
      END
$PAGE
      SUBROUTINE WRT10D(IDDSID,STNID,IELEM,IYEAR,VALUE,FLAG1)
C
C  THIS SUBROUTINE WRITES A 10 DAY FORMAT DATAEASE RECORD.  

C  LOCAL VARIABLES
      CHARACTER*8 LOCALID
      CHARACTER*4 YEAR
      CHARACTER*3 ELEM,DDSID
      CHARACTER*1 OUTREC(210) 
      INTEGER*2 HEADER(6)
*  PASSED VARIABLES
      CHARACTER*8 STNID
      CHARACTER*1 FLAG1(100)
      INTEGER*2 IDDSID,IELEM,IYEAR
      REAL*4  VALUE(100)
C
C  EQUIVALENCE THE INPUT VARIABLES TO THE OUTPUT RECORD STRING 
C
      EQUIVALENCE (HEADER,OUTREC(1)),(DDSID,OUTREC(13)), 
     +            (LOCALID,OUTREC(16)),
     +            (ELEM,OUTREC(24)),(YEAR,OUTREC(27)) 

      RTNCODE = '0'
   10 CONTINUE
C
C  WRITE THE INFORMATION INTO THE DATEASE RECORD HEADER  
C
      HEADER(1) = 12
      HEADER(2) = 0
      HEADER(3) = 0
      HEADER(4) = 0
      HEADER(5) = 0
      HEADER(6) = 0
      LOCALID = STNID
      WRITE(DDSID ,'(I3.3)') IDDSID
      WRITE(ELEM ,'(I3.3)') IELEM
      WRITE(YEAR ,'(I4.4)') IYEAR
C
C  WRITE THE DATA VALUES INTO THE DATEASE FORMAT OUTPUT RECORD  
C
      DO 200 I=1,36
         IPOS = 31 + (I-1)*5
         CALL MOVBYT(4,VALUE(I),1,OUTREC,IPOS)
         OUTREC(IPOS+4) = FLAG1(I)
200   CONTINUE
      WRITE(51) OUTREC
300   CONTINUE
      RETURN
      END
$PAGE
      SUBROUTINE WRTDLY(IDDSID,STNID,IELEM,IYEAR,IMON,VALUE,FLAG1)
C
C  THIS SUBROUTINE WRITES A DAILY FORMAT DATAEASE RECORD.  

C  LOCAL VARIABLES
      CHARACTER*8 LOCALID
      CHARACTER*6 YRMON
      CHARACTER*3 ELEM,DDSID
      CHARACTER*1 OUTREC(186) 
      INTEGER*2 HEADER(5)
*  PASSED VARIABLES
      CHARACTER*8 STNID
      CHARACTER*1 FLAG1(100)
      INTEGER*2 IDDSID,IELEM,IYEAR,IMON
      REAL*4  VALUE(100)
C
C  EQUIVALENCE THE INPUT VARIABLES TO THE OUTPUT RECORD STRING 
C
      EQUIVALENCE (HEADER,OUTREC(1)),(DDSID,OUTREC(12)), 
     +            (LOCALID,OUTREC(15)),
     +            (ELEM,OUTREC(23)),(YRMON,OUTREC(26)) 

      RTNCODE = '0'
   10 CONTINUE
C
C  WRITE THE INFORMATION INTO THE DATEASE RECORD HEADER  
C
      HEADER(1) = 12
      HEADER(2) = 0
      HEADER(3) = 0
      HEADER(4) = 0
      HEADER(5) = 0
      LOCALID = STNID
      WRITE(DDSID ,'(I3.3)') IDDSID
      WRITE(ELEM ,'(I3.3)') IELEM
      WRITE(YRMON ,'(I4.4,I2.2)') IYEAR,IMON
C
C  WRITE THE DATA VALUES INTO THE DATEASE FORMAT OUTPUT RECORD  
C
      DO 200 I=1,31
         IPOS = 32 + (I-1)*5
         CALL MOVBYT(4,VALUE(I),1,OUTREC,IPOS)
         OUTREC(IPOS+4) = FLAG1(I)
200   CONTINUE
      WRITE(51) OUTREC
300   CONTINUE
      RETURN
      END
$PAGE
      SUBROUTINE WRTSYN(IDDSID,STNID,IELEM,IYEAR,IMON,IDAY,VALUE,FLAG1)
C
C  THIS SUBROUTINE WRITES A 3-HOURLY FORMAT DATAEASE RECORD.  

C  LOCAL VARIABLES
      CHARACTER*8 LOCALID
      CHARACTER*8 DATE
      CHARACTER*3 ELEM,DDSID
      CHARACTER*1 OUTREC(67) 
      INTEGER*2 HEADER(2)
*  PASSED VARIABLES
      CHARACTER*8 STNID
      CHARACTER*1 FLAG1(100)
      INTEGER*2 IDDSID,IELEM,IYEAR,IMON,IDAY
      REAL*4  VALUE(100)
C
C  EQUIVALENCE THE INPUT VARIABLES TO THE OUTPUT RECORD STRING 
C
      EQUIVALENCE (HEADER,OUTREC(1)),(DDSID,OUTREC(6)), 
     +            (LOCALID,OUTREC(9)),
     +            (ELEM,OUTREC(17)),(DATE,OUTREC(20)) 

      RTNCODE = '0'
   10 CONTINUE
C
C  WRITE THE INFORMATION INTO THE DATEASE RECORD HEADER  
C
      HEADER(1) = 12
      HEADER(2) = 0
      LOCALID = STNID
      WRITE(DDSID ,'(I3.3)') IDDSID
      WRITE(ELEM ,'(I3.3)') IELEM
      WRITE(DATE ,'(I4.4,2I2.2)') IYEAR,IMON,IDAY
C
C  WRITE THE DATA VALUES INTO THE DATEASE FORMAT OUTPUT RECORD  
C
      DO 200 I=1,8
         IPOS = 28 + (I-1)*5
         CALL MOVBYT(4,VALUE(I),1,OUTREC,IPOS)
         OUTREC(IPOS+4) = FLAG1(I)
200   CONTINUE
      WRITE(51) OUTREC
300   CONTINUE
      RETURN
      END
$PAGE
      SUBROUTINE WRTHLY(IDDSID,STNID,IELEM,IYEAR,IMON,IDAY,VALUE,FLAG1)
C
C  THIS SUBROUTINE WRITES AN HOURLY FORMAT DATAEASE RECORD.  

C  LOCAL VARIABLES
      CHARACTER*8 LOCALID
      CHARACTER*8 DATE
      CHARACTER*3 ELEM,DDSID
      CHARACTER*1 OUTREC(151) 
      INTEGER*2 HEADER(4)
*  PASSED VARIABLES
      CHARACTER*8 STNID
      CHARACTER*1 FLAG1(100)
      INTEGER*2 IDDSID,IELEM,IYEAR,IMON,IDAY
      REAL*4  VALUE(100)
C
C  EQUIVALENCE THE INPUT VARIABLES TO THE OUTPUT RECORD STRING 
C
      EQUIVALENCE (HEADER,OUTREC(1)),(DDSID,OUTREC(10)), 
     +            (LOCALID,OUTREC(13)),
     +            (ELEM,OUTREC(21)),(DATE,OUTREC(24)) 

      RTNCODE = '0'
   10 CONTINUE
C
C  WRITE THE INFORMATION INTO THE DATEASE RECORD HEADER  
C
      HEADER(1) = 12
      HEADER(2) = 0
      HEADER(3) = 0
      HEADER(4) = 0
      LOCALID = STNID
      WRITE(DDSID ,'(I3.3)') IDDSID
      WRITE(ELEM ,'(I3.3)') IELEM
      WRITE(DATE ,'(I4.4,2I2.2)') IYEAR,IMON,IDAY
C
C  WRITE THE DATA VALUES INTO THE DATEASE FORMAT OUTPUT RECORD  
C
      DO 200 I=1,24
         IPOS = 32 + (I-1)*5
         CALL MOVBYT(4,VALUE(I),1,OUTREC,IPOS)
         OUTREC(IPOS+4) = FLAG1(I)
200   CONTINUE
      WRITE(51) OUTREC
300   CONTINUE
      RETURN
      END
$PAGE
      SUBROUTINE WRT15M(IDDSID,STNID,IELEM,IYEAR,IMON,IDAY,VALUE,FLAG1)
C
C  THIS SUBROUTINE WRITES A 15 MINUTE FORMAT DATAEASE RECORD.  

C  LOCAL VARIABLES
      CHARACTER*8 LOCALID
      CHARACTER*8 DATE
      CHARACTER*3 ELEM,DDSID
      CHARACTER*1 OUTREC(529) 
      INTEGER*2 HEADER(13)
*  PASSED VARIABLES
      CHARACTER*8 STNID
      CHARACTER*1 FLAG1(100)
      INTEGER*2 IDDSID,IELEM,IYEAR,IMON,IDAY
      REAL*4  VALUE(100)
C
C  EQUIVALENCE THE INPUT VARIABLES TO THE OUTPUT RECORD STRING 
C
      EQUIVALENCE (HEADER,OUTREC(1)),(DDSID,OUTREC(28)), 
     +            (LOCALID,OUTREC(31)),
     +            (ELEM,OUTREC(39)),(DATE,OUTREC(42)) 

      RTNCODE = '0'
   10 CONTINUE
C
C  WRITE THE INFORMATION INTO THE DATEASE RECORD HEADER  
C
      HEADER(1) = 12
      DO 20 I1 = 2,13
         HEADER(I1) = 0
20    CONTINUE
      LOCALID = STNID
      WRITE(DDSID ,'(I3.3)') IDDSID
      WRITE(ELEM ,'(I3.3)') IELEM
      WRITE(DATE ,'(I4.4,2I2.2)') IYEAR,IMON,IDAY
C
C  WRITE THE DATA VALUES INTO THE DATEASE FORMAT OUTPUT RECORD  
C
      DO 200 I=1,96
         IPOS = 49 + (I-1)*5
         CALL MOVBYT(4,VALUE(I),1,OUTREC,IPOS)
         OUTREC(IPOS+4) = FLAG1(I)
200   CONTINUE
      WRITE(51) OUTREC
300   CONTINUE
      RETURN
      END
$PAGE
      SUBROUTINE WRTUA(IDDSID,STNID,IYEAR,IMON,IDAY,IHOUR,INUMLVL
     +        ,ILVLNUM,VALUE,IFLAGS)
C
C  THIS SUBROUTINE WRITES AN UPPER AIR FORMAT DATAEASE RECORD.  
C
C  LOCAL VARIABLES
      CHARACTER*8 LOCALID, DATE
      CHARACTER*6 FLAGS
      CHARACTER*3 DDSID,NUMLVL,LVLNUM
      CHARACTER*2 HOUR
      CHARACTER*1 OUTREC(62) 
      INTEGER*2 HEADER(2)
*  PASSED VARIABLES
      INTEGER*2 IDDSID,IYEAR,IMON,IDAY,IHOUR,INUMLVL,ILVLNUM
      REAL*4    VALUE(6)
      CHARACTER*8 STNID
      CHARACTER*6 IFLAGS
C
C  EQUIVALENCE THE INPUT VARIABLES TO THE OUTPUT RECORD STRING 
C
      EQUIVALENCE (HEADER,OUTREC(1)),(DDSID,OUTREC(6)), 
     +            (LOCALID,OUTREC(9)),(DATE,OUTREC(17)),
     +            (HOUR,OUTREC(25)),(NUMLVL,OUTREC(27)),
     +            (LVLNUM,OUTREC(30)),(FLAGS,OUTREC(57))

      RTNCODE = '0'
   10 CONTINUE
C
C  WRITE THE INFORMATION INTO THE DATEASE RECORD HEADER  
C
      HEADER(1) = 12
      HEADER(2) = 0
      LOCALID = STNID
      WRITE(DDSID ,'(I3.3)') IDDSID
      WRITE(DATE ,'(I4.4,2I2.2)') IYEAR,IMON,IDAY
      WRITE(HOUR,'(I2.2)') IHOUR
      WRITE(NUMLVL,'(I3.3)') INUMLVL
      WRITE(LVLNUM,'(I3.3)') ILVLNUM
      FLAGS = IFLAGS
C
C  WRITE THE DATA VALUES INTO THE DATEASE FORMAT OUTPUT RECORD  
C
      DO 200 I=1,6
         IPOS = 33 + (I-1)*4
         CALL MOVBYT(4,VALUE(I),1,OUTREC,IPOS)
200   CONTINUE
      WRITE(51) OUTREC
300   CONTINUE
      RETURN
      END
************************************************************************
$page
      SUBROUTINE WRTNML(ID,PERIOD,MONTH,ELEMENT,NORMAL,NMLTYP,
     +                   NORMFLG,SDEV,EXTMAX,EMAXFLG,MAXYR,
     +                   EXTMIN,EMINFLG,MINYR,MLYMAXMN,SDMAX,
     +                   MLYMINMN,SDMIN,PQM,PQX,PQN,BITVAL)
C
C   THIS ROUTINE WRITES A NML FORMAT DATAEASE RECORD AS A BINARY FILE.
C   THE VARIABLES WITHIN THE RECORD ARE EQUIVALENCED TO THE APPROPRIATE
C   POSITION WITHIN OUTREC.                      
C
      CHARACTER*8 ID,PERIOD
      CHARACTER*4 MAXYR,MINYR
      CHARACTER*3 ELEMENT
      CHARACTER*1 EMAXFLG,EMINFLG
      INTEGER*2   MONTH,NMLTYP,NORMFLG,BITVAL(30)
      REAL*4 NORMAL,SDEV,EXTMAX,EXTMIN,MLYMAXMN,MLYMINMN,SDMAX,
     +       SDMIN,PQM(5),PQX(5),PQN(5)
C
      CHARACTER*1 OUTREC(165)
C
      CHARACTER*8 STNID
      CHARACTER*4 YEAR1,YEAR2,MXYR,MNYR
      CHARACTER*3 ELEM
      CHARACTER*2 OMONTH
      CHARACTER*1 EMAXFG,EMINFG
      REAL*4 NORM,MEAN,EMAX,EMIN,MYMX,MYMN,SDEMAX,SDEMIN
     +       ,P1(5),P2(5),P3(5)
      INTEGER*2 HEADER(2)
      INTEGER*1 TYPNML,NMLFG
C
C  EQUIVALENCE THE INPUT VARIABLES TO THE INPUT RECORD STRING        
C
      EQUIVALENCE (HEADER,OUTREC(1)),(STNID,OUTREC(11)),
     +         (YEAR1,OUTREC(19)),(YEAR2,OUTREC(23)),
     +         (OMONTH,OUTREC(27)),(ELEM,OUTREC(29)),
     +         (NORM,OUTREC(32)),(TYPNML,OUTREC(36)),
     +         (NMLFG,OUTREC(37)),(MEAN,OUTREC(38)),
     +         (EMAX,OUTREC(42)),(EMAXFG,OUTREC(46)),
     +         (MXYR,OUTREC(47)),(EMIN,OUTREC(51)),
     +         (EMINFG,OUTREC(55)),(MNYR,OUTREC(56)),  (P1,OUTREC(60)),
     +         (MYMX,OUTREC(80)),(SDEMAX,OUTREC(84)),  (P2,OUTREC(88)),
     +         (MYMN,OUTREC(108)),(SDEMIN,OUTREC(112)),(P3,OUTREC(116))
C
C   WRITE THE INFORMATION INTO THE DATEASE RECORD HEADER AND THEN
C   WRITE THE VALUES INTO THE DATAEASE RECORD             
C
      HEADER(1) = 12
      HEADER(2) = 0
      STNID = ID
      YEAR1 = PERIOD(1:4)
      YEAR2 = PERIOD(5:8)
      WRITE(OMONTH,'(I2)') MONTH
      ELEM = ELEMENT
      NORM = NORMAL
      TYPNML = INT1(NMLTYP)
      NMLFG = INT1(NORMFLG)
      MEAN = SDEV
      EMAX = EXTMAX 
      EMAXFG = EMAXFLG 
      MXYR = MAXYR
      EMIN = EXTMIN
      EMINFG = EMINFLG
      MNYR = MINYR 
      MYMX = MLYMAXMN
      SDEMAX = SDMAX
      MYMN = MLYMINMN
      SDEMIN = SDMIN
C
      DO 50 I=1,5
          P1(I) = PQM(I)
          P2(I) = PQX(I)
          P3(I) = PQN(I)
   50 CONTINUE
C
      DO 75 I=1,30
         IPOS = 136 + (I-1)
         OUTREC(IPOS) = BITVAL(I) 
   75 CONTINUE

      WRITE(51) OUTREC
      RETURN
      END
         