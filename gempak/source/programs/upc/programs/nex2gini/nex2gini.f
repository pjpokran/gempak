	PROGRAM NEX2GINI
C************************************************************************
C* NEX2GINI								*
C*									*
C* This program creates a GINI format RADAR mosaic from NEXRAD products.*
C**									*
C* Log:									*
C* Chiz/Unidata         3/01	Initial coding				*
C* Chiz/Unidata         2/02	Modified from GDRADR to write GINI 	*
C*				format images with optional compression.*
C* M. James/Unidata     6/10    Added bin mins & mstrct to CTB_DTGET    * 
C************************************************************************
	INCLUDE		'GEMPRM.PRM'
	INCLUDE		'IMGDEF.CMN'
	INCLUDE		'ERROR.PRM'
	INCLUDE		'nex2gini.cmn'
C*
	CHARACTER*(LLMXLN)	device, satfil, radtim, raddur, radfrq,
     +				stnfil, cpyfil, cpytmp, proj, gdarea, 
     +				kxky, filnam, cpyf(2), gfunc, filpath,
     +				outstr, templ, newfil, gemfil, anlyss,
     +				radmode
C*
	CHARACTER	curtim*15, stid*8, stnnam*32, coun*2, stat*2, 
     +			tbchars*20, gname*20, cprj*10, errstr*24,
     +			headerid*30, radproj*10, radarea*10, ttim*20
C*
	CHARACTER	imgfls*(256), nextfile*(4096),
     +			tpath*(256), tplate*(80), ctmpl*(10)
                       
C*
	INTEGER		kx, ky, ignhdr(135), idtarr(5)
C*
	LOGICAL		gsflag, respnd, done, exist, proces, viewable,
     +			opmode, compress
C*	
	REAL		rltln(4), rnvblk(LLNNAV), anlblk(LLNANL),
     +			grid(GINISZ), envblk(LLNNAV), rarr(256)
C
C-----------------------------------------------------------------------
C*	Initialize user interface and graphics.
C
	CALL IP_INIT  ( respnd, iperr )
	IF  ( iperr .ne. 0 )  THEN
	    CALL ER_WMSG  ( 'NEX2GINI', -1, ' ', ier )
	    CALL SS_EXIT
	END IF
C
C*	Initialize graphics.
C
	CALL GG_INIT  ( 1, iret )
	IF  ( iret .eq. 0 )  THEN
	    done = .false.
	  ELSE 
	    CALL ER_WMSG  ( 'NEX2GINI', -3, ' ', ier )
	    done = .true.
	END IF
	CALL IP_IDNT ( 'NEX2GINI', ier )
C
C*	Find NEXRIII template
C
	ctmpl = 'NEXRIII'
	CALL ST_NULL ( ctmpl, ctmpl, lens, ier )
	tpath = ' '
	tplate = ' '
	CALL CTB_DTGET ( ctmpl, tpath, tplate, ic, is, if, ir, ii, ion, 
     +			ihb, mnb, iha, mna, mstrct, idtmch, ier )
C
	IF ( ier .ne. 0 )  THEN
	   tpath = '$RAD/NIDS/%SITE%/%PROD%'
	   tplate = '%PROD%_YYYYMMDD_HHNN'
	   CALL ER_WMSG  ( 'NEX2GINI', 2, tpath, ier )
	ELSE
	   CALL ST_RNUL ( tpath, tpath, lens, ier )
           CALL ST_RNUL ( tplate, tplate, lens, ier )
	END IF
C
	DO i=1,LLNNAV
	   envblk(i) = RMISSD
	END DO
C
C	
	DO  WHILE  ( .not. done )
C
C*	    Initialize grid
C
	    DO i=1,GINISZ
	       grid(i) = RMISSD
	    END DO
C
	    proces = .true.
C
C*	    Get input parameters.
C
	    CALL GPINP  ( proj, gdarea, kxky, gfunc, satfil, radtim,
     +                    raddur, radfrq, cpyfil, stnfil, 
     +			  radmode, compress, iperr )	

	    CALL ST_LCUC (gfunc, gfunc, ier)
C*
	    CALL ST_C2I (radfrq, 1, iwaitper, inum, ier)
            IF (inum .ne. 1) iwaitper = 0
C*
	    CALL ST_C2I (raddur, 1, iraddur, inum, ier)
            IF (inum .ne. 1) iraddur = 30
C*
	    IF (stnfil .eq. ' ') THEN
		stnfil = 'nexrad.tbl'
		CALL ER_WMSG  ( 'NEX2GINI', 3, stnfil, ier )
	    END IF

	    CALL ST_LCUC ( radmode, radmode, ier )
	    icair_mode = INDEX ( radmode, 'C')
	    iprcp_mode = INDEX ( radmode, 'P')
	    imntn_mode = INDEX ( radmode, 'M')
	    IF ( icair_mode + iprcp_mode + imntn_mode .eq. 0 ) THEN
		icair_mode = 1
		iprcp_mode = 1
		imntn_mode = 1
	    END IF

	    IF  ( iperr .eq. 0 )  THEN
C
C*		Get current system time
C
		CALL ST_UCLC(radtim, radtim, ier)
		IF ( radtim(1:1) .eq. 'c') THEN
		   itype = 1
		   CALL CSS_GTIM ( itype, curtim, ier )
		   CALL ST_RNUL ( curtim, curtim, lens, ier)
		ELSE
		   curtim = radtim(1:15)
		END IF
C
C*		Set device and projection.
C
		device = 'gif|/dev/null'
		CALL GG_SDEV  ( device, ier )
		IF  ( ier .ne. 0 )  proces = .false.
		IF  ( proces )  THEN
C
C*		  Set Grid projection
C		  
		  CALL ST_CLST ( cpyfil, '|', ' ', 2, cpyf, num, ier )
                  cpytmp = cpyf(1)
C
C*          	  CASE 1: Build new navigation block from user input.
C
		  IF (cpytmp .eq. ' ') THEN
		     CALL GDCNAV  ( proj, kxky, gdarea, cprj, kx, ky,
     +                         rltln, rnvblk, ier )
                     IF  ( ier .eq. 0 )  THEN
			anlyss = ' '
                        CALL GDCANL ( anlyss, rnvblk, anlblk, ier )
                     END IF
C
C*            CASE 2: Build new navigation and analysis blocks from grid
C*            navigation table input.
C
                  ELSE IF  ( cpytmp(1:1) .eq. '#') THEN
                     CALL GDCTBL (cpytmp, gname, cprj, kx, ky, rltln, 
     +                  rnvblk, anlblk, ier)
C
C*            CASE 3: Get the navigation and analysis blocks from the
C*            existing file.
C
		  ELSE
		     CALL FL_MFIL ( cpytmp, ' ', filnam, ier )
		     IF ( ier .eq. 0) THEN
		        CALL GD_OPNF ( filnam, .false., iflno, inav, rnvblk,
     +                             ianl,  anlblk, ihd, maxg, ier )
			IF ( ier .eq. 0) THEN
			   CALL GD_CLOS  ( iflno, ier )
			   CALL GR_RNAV  ( rnvblk, cprj, kx, ky, ier )
			END IF
		     END IF
		  END IF

                  IF (ier .ne. 0) THEN
		     CALL ER_WMSG  ( 'NEX2GINI', -4, cpyfil, ier )
                     proces = .false.
		  ELSE
		     CALL FL_MNAM(curtim, satfil, gemfil, ier)
		     CALL FL_INQR (gemfil, exist, newfil, ier)
C
C*		     We have a nav block.... if not the same as our existing
C*		     nav block, we need to initialize the bounds locations.
C
		     CALL GR_CNAV (rnvblk, envblk, LLNNAV, gsflag, iret)
		     IF (.not. gsflag) CALL radar_boundsinit()

		     CALL GR_SNAV(LLNNAV,rnvblk,ier)
C
C*		     Save rnvblk to envblk
C
		     DO i=1,LLNNAV
                        envblk(i) = rnvblk(i)
                     END DO
                  END IF
C
C*		  Make sure KX*KY <= GINISZ
		  IF ( kx*ky .gt. GINISZ ) THEN
		     write(*,*) 'Error: requested inages size ',kx*kx,
     +			' is larger than maximum image size ',GINISZ
		     proces = .false.
		  END IF

C
C*		  Start loop over input image files.
C
		  IF  ( proces )  THEN

		     CALL FL_TBOP(stnfil,'stns', ilun, ierf)
		     IF (ierf .ne. 0) THEN
			CALL ER_WMSG  ( 'NEX2GINI', -8, stnfil, ier )
		     END IF
                     DO WHILE (ierf.eq.0)	
			CALL TB_RSTN(ilun,stid,stnnam, istnm, stat, 
     +			   coun, slat, slon, selv, ispri, tbchars, 
     +			   ierf )
                        IF (ierf.eq.0) THEN
		           viewable = .true.
			   ifile = 1
			  
			   CALL ST_RPST(tpath,'%SITE%',stid,ipos,
     +					outstr, ier)
			   CALL ST_RPST(outstr,'%PROD%',gfunc,ipos,
     +					filpath, ier)

			   CALL ST_NULL(filpath, filpath, ilen, ier)
	
			   CALL ST_RPST(tplate,'%SITE%',stid,ipos,
     +					outstr, ier)
			   CALL ST_RPST(outstr,'%PROD%',gfunc,ipos,
     +					templ, ier)
			   CALL ST_NULL(templ, templ, ilen, ier)
	
			   CALL ST_NULL(curtim, ttim, ilen, ier)
			   CALL next_radar (filpath, templ, ttim, 
     +				nextfile, numc, idelt, ier)

                           IF (ier .eq. 0) THEN
                              imgfls = nextfile(1:numc)
	   		      CALL ST_RNUL ( imgfls, imgfls, lens, ier )
                           ELSE
			      viewable = .false.
                           END IF

C
C*			check if radar is within grid
C
		           IF (viewable) THEN
C
C*			      Reset the projection for each image.
C
			      radproj = 'RAD|D'
			      radarea = 'dset'
                              CALL GG_MAPS ( radproj, radarea, imgfls,
     +          			    idrpfl, ier )
C
C*			       Clear the screen (not needed)
C
			      CALL GCLEAR ( iret)
C
C*			       Display satellite image
C
			      CALL IM_DROP ( iret )
C
			      IF ( ( iret .ne. 0 ) .or. 
     +				( imldat .eq. 0 ) ) THEN
				 viewable = .false.
			      ELSE
			         CALL radar_bounds(istnm, kx, ky, ier)
		                 IF (ier .ne. 0) viewable = .false.
			      END IF
			      IF (idelt .gt. iraddur) THEN
				 CALL ER_WMSG  ( 'NEX2GINI', 1, imgfls, ier )
				 viewable = .false.
			      END IF
			   END IF
C
			   IF  ( viewable )  THEN
C
C*			       Determine if radar mode is acceptable
C
			       opmode = .false.
			       IF ( ( immode .eq. 2 ) .and. 
     +				  ( iprcp_mode .gt. 0 ) ) opmode = .true.
			       IF ( ( immode .eq. 1 ) .and. 
     +				  ( icair_mode .gt. 0 ) ) opmode = .true.
			       IF ( ( immode .eq. 0 ) .and. 
     +				  ( imntn_mode .gt. 0 ) ) opmode = .true.
C                               opmode = .true.
			       IF ( opmode ) THEN
			          CALL ER_WMSG  ( 'NEX2GINI', 0, imgfls, ier )
			          DO i=1,imndlv
			             CALL ST_C2R(cmblev(i),1,rarr(i),num,ier)
			             IF ( (ier .ne. 0 ) .or. 
     +				        ( i .eq. 1 ) ) rarr(i) = RMISSD
			          END DO
C                               Need a flag for radar_grid function
C                               (HHC,DVL, other high-res products)
C##      138     DSP (High-Res Digital Storm Total Precipitation)
C##      81      DPA (High-Res Hourly Digital Precipitation Array)
C##      177     HHC (Hybrid Scan Hydrometeor Classification)
                                  SELECT CASE (imtype)
                                    CASE (81,177,138)
			              CALL radar_grid(0,kx,ky,grid,rarr)
C##      32      DHR (Digital Hybrid Scan Reflectivity)
C##      94      N0Q (High-Res Base Reflectivity, 0.5)
C##      134     DVL (High-Res Digital Vertically Integrated Liquid)
C##      170     DAA (Digital Accum Array)
C##      135     EET (High-Res Enhanced Echo Tops)
                                    CASE DEFAULT
			              CALL radar_grid(1,kx,ky,grid,rarr)
                                  END SELECT
			       ELSE
				  WRITE (errstr,1000) stid,immode
1000				  FORMAT (A,1x,I1)
				  CALL ER_WMSG  ( 'NEX2GINI', 5, errstr, ier )
			       END IF
C
C*			       Flush the graphics buffer.
C
			       CALL GEPLOT  ( iret)
			   END IF
		        END IF
		      END DO
		      IF (ilun .gt. 0) CALL FL_CLOS(ilun, iret)
		      CALL ER_WMSG  ( 'NEX2GINI', 4, curtim, ier )
                      CALL TI_CTOI (curtim, idtarr, ier)
		      write(headerid,2000) 'TICZ99 CHIZ',
     +			((idtarr(3)*100)+idtarr(4))*100+idtarr(5)
2000		      FORMAT(A,1x,I6)
C
C*		      Check for leading zero in time
C
		      iF (headerid(13:13) .eq. ' ')
     +			  headerid(13:13) = '0'
C
                      CALL ST_LSTR(headerid, lens, ier)
                      CALL ST_LSTR(gfunc, lenf, ier)
C
		      IF ( compress ) THEN
		         icompress = 128
		      ELSE
			 icompress = 0
		      END IF
C
                      CALL gdhgin ( ignhdr, gfunc, lenf, idtarr, 
     +                   icompress, ier)
C
                      IF ( ier .ne. 0) THEN
                          write(*,*) 'Failed to create GINI header ',ier
                      ELSE

                         CALL ST_LSTR  ( gemfil, len2, ier )
                         ihdlen = 21
                         iofset = ihdlen + 512
                         lendat = kx * ky
                         CALL gdlgin ( grid, kx, ky, icompress, 
     +					ilen, ier)
                         CALL IM_GM2GI ( gemfil, ignhdr, rnvblk, ier )
			 IF ( ier .ne. 0 ) THEN
                            write(*,*) 'Error writing header: ',ier
			    call freeimg()
			 ELSE
                            CALL IM_WGIN  ( gemfil, len2, iofset, 
     +					ilen, ier ) 
		            IF ( ier .ne. 0) THEN
			       IF ( ier .eq. NIMGFL ) call freeimg ()
                               write(*,*) 'Failed to write image [',
     +				ier,'] ',gemfil
                            END IF
			 END IF
                      END IF

C
C
		  END IF
		END IF
	      END IF
C
C*	    Call the dynamic tutor.
C
	    IF (iwaitper .ne. 0) CALL wait_time(iwaitper, iret)
            IF ((iwaitper .eq. 0).or.(iret .ne. 0))
     + 		CALL IP_DYNM ( done, iret )
	END DO
C*
	IF  ( iperr .ne. 0 )  
     +		CALL ER_WMSG  ( 'NEX2GINI', iperr, ' ', ier )
	CALL GENDP   ( 0, iret )
	CALL IP_EXIT ( iret )
C*
	END
