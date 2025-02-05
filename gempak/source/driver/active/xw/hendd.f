	SUBROUTINE HENDD  ( ieop, iret )
C************************************************************************
C* HENDD - XW								*
C*									*
C* This subroutine must be the last subroutine called by any program 	*
C* that uses GEMPLT.  It will flush internal buffers if necessary in	*
C* the device driver.  The DEVICE subprocess may be retained so that	*
C* the current definitions are available in later programs.		*
C*									*
C* HENDD  ( IEOP, IRET )						*
C*									*
C* Input parameters:							*
C*	IEOP		INTEGER		End plotting flag		*
C*					  0 = retain subprocess		*
C*					  1 = stop subprocess		*
C*									*
C* Output parameters:							*
C*	IRET		INTEGER		Return code			*
C**									*
C* Log:                                                                 *
C* M. desJardins/NMC	01/92	Close window when plotting is done	*
C* S. Jacobs/NMC	 7/94	General clean up			*
C* S. Maxwell/GSC        6/97   Documentation changes                   *
C************************************************************************
C------------------------------------------------------------------------
C*	Check for plotting done.
C
	IF  ( ieop .eq. 1 )  CALL XENDD ( iret )
C*
	RETURN
	END
