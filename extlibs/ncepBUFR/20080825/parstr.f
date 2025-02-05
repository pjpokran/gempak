      SUBROUTINE PARSTR(STR,TAGS,MTAG,NTAG,SEP,LIMIT80)

C$$$  SUBPROGRAM DOCUMENTATION BLOCK
C
C SUBPROGRAM:    PARSTR
C   PRGMMR: J. ATOR          ORG: NP12       DATE: 2007-01-19
C
C ABSTRACT: THIS SUBROUTINE PARSES A STRING CONTAINING ONE OR MORE
C   SUBSTRINGS INTO AN ARRAY OF SUBSTRINGS.  THE SEPARATOR FOR THE
C   SUBSTRINGS IS SPECIFIED DURING INPUT, AND MULTIPLE ADJACENT
C   OCCURRENCES OF THIS CHARACTER WILL BE TREATED AS A SINGLE
C   OCCURRENCE WHEN THE STRING IS ACTUALLY PARSED.
C
C PROGRAM HISTORY LOG:
C 2007-01-19  J. ATOR    -- BASED UPON SUBROUTINE PARSEQ
C
C USAGE:    CALL PARSTR (STR, TAGS, MTAG, NTAG, SEP, LIMIT80)
C   INPUT ARGUMENT LIST:
C     STR      - CHARACTER*(*): STRING
C     MTAG     - INTEGER: MAXIMUM NUMBER OF SUBSTRINGS TO BE PARSED
C                FROM STRING
C     SEP      - CHARACTER*1: SEPARATOR CHARACTER FOR SUBSTRINGS
C     LIMIT80  - LOGICAL: .TRUE. IF AN ABORT SHOULD OCCUR WHEN STR IS
C                LONGER THAN 80 CHARACTERS; INCLUDED FOR HISTORICAL
C                CONSISTENCY WITH OLD SUBROUTINE PARSEQ
C
C   OUTPUT ARGUMENT LIST:
C     TAGS     - CHARACTER*(*): MTAG-WORD ARRAY OF SUBSTRINGS (FIRST
C                NTAG WORDS FILLED)
C     NTAG     - INTEGER: NUMBER OF SUBSTRINGS RETURNED
C
C REMARKS:
C    THIS ROUTINE CALLS:        BORT2
C    THIS ROUTINE IS CALLED BY: GETNTBE  GETTBH   PARUSR   READLC
C                               SEQSDX   SNTBBE   UFBSEQ   UFBTAB
C                               UFBTAM   WRITLC
C                               Normally not called by any application
C                               programs but it could be.
C
C ATTRIBUTES:
C   LANGUAGE: FORTRAN 77
C   MACHINE:  PORTABLE TO ALL PLATFORMS
C
C$$$

      CHARACTER*(*) STR,TAGS(MTAG)
      CHARACTER*128 BORT_STR1,BORT_STR2
      CHARACTER*1   SEP
      LOGICAL       SUBSTR,LIMIT80

C-----------------------------------------------------------------------
C-----------------------------------------------------------------------

      LSTR = LEN(STR)
      LTAG = LEN(TAGS(1))
      IF( LIMIT80 .AND. (LSTR.GT.80) ) GOTO 900
      NTAG = 0
      NCHR = 0
      SUBSTR = .FALSE.

      DO I=1,LSTR

      IF( .NOT.SUBSTR .AND. (STR(I:I).NE.SEP) ) THEN
         NTAG = NTAG+1
         IF(NTAG.GT.MTAG) GOTO 901
         TAGS(NTAG) = ' '
      ENDIF

      IF( SUBSTR .AND. (STR(I:I).EQ.SEP) ) NCHR = 0
      SUBSTR = STR(I:I).NE.SEP

      IF(SUBSTR) THEN
         NCHR = NCHR+1
         IF(NCHR.GT.LTAG) GOTO 902
         TAGS(NTAG)(NCHR:NCHR) = STR(I:I)
      ENDIF

      ENDDO

C  EXITS
C  -----

      RETURN
900   WRITE(BORT_STR1,'("BUFRLIB: PARSTR - INPUT STRING (",A,") HAS ")')
     . STR
      WRITE(BORT_STR2,'(18X,"LENGTH (",I4,"), > LIMIT OF 80 CHAR.")')
     . LSTR
      CALL BORT2(BORT_STR1,BORT_STR2)
901   WRITE(BORT_STR1,'("BUFRLIB: PARSTR - INPUT STRING (",A,") '//
     . 'CONTAINS",I4)') STR,NTAG
      WRITE(BORT_STR2,'(18X,"SUBSTRINGS, EXCEEDING THE LIMIT {",I4,'//
     . '" - THIRD (INPUT) ARGUMENT}")') MTAG
      CALL BORT2(BORT_STR1,BORT_STR2)
902   WRITE(BORT_STR1,'("BUFRLIB: PARSTR - INPUT STRING (",A,") ")') STR
      WRITE(BORT_STR2,'(18X,"CONTAINS A PARSED SUBSTRING WITH LENGTH '//
     . 'EXCEEDING THE MAXIMUM OF",I4," CHARACTERS")') LTAG
      CALL BORT2(BORT_STR1,BORT_STR2)
      END
