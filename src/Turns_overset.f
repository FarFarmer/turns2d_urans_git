c********1*********2*********3*********4*********5*********6*********7**
      program umturns2d
c                                                                      c
c  the code was cleaned-up primarily by j. sitaraman to f90 type 
c  constructs and  options for oversetting and other good stuff to work
c
c  last modified 09/05/2005 by karthik.
c
c  j.d baeder did previously claim to have cleaned it up in 1991 :)    c
c  to structure, vectorize and streamline to make all options working. c
c                                                                      c
c  many new limiters etc. added in 1996, along with better metrics     c
c                                                                      c
c**********************************************************************c
c
c
c     note: b.c. elements must be configured for each new grid topology
c           (currently c-grid)
c     note: mdim must be .ge. jdim and kdim
c
c         tape1:    grid (input)
c         tape3:    restart file (input)
c         tape5:    input file
c         tape6:    output file of summary data
c         tape7:    output file of run norms
c         tape8:    restart file (output - suitable for plot3d)
c         tape9:    grid (output)
c         tape11:   output file of cl,cd,cmp
c         tape17:   file of alpha(t) (input)
c 
c*********************************************************************** 
c 
c   input variable to airfoil in namelist inputs:
c   
c     iread  = tells whether to read in a restart file from unit 3
c            = 1 => restart
c            = 0 => initial run with no restart
c     jmax   = points in wrap around direction
c     kmax   = points in normal direction
c     jtail1 = j location of beginning airfoil (at tail on underside)
c     half   = symmetrical airfoil?
c            = 0 no symmetry assumed, 
c                        jtail2 = jmax-jtail1+1 & jle =(jmax+1)/2
c            = 1 symmetry assumed, jtail2 = jmax-1 & jle = jmax-1
c   
c   
c     npnorm = output residual to fort.7 every npnorm iterations
c              output force to fort.11 every npnorm its.
c              output spanwise forces to fort.12 every npnorm its. (rotor only)
c     nrest  = write out restart to fort.8 every nrest iterations
c     nsteps = total number of steps at end of this run
c              (typically 200-2000 larger than last run)
c   
c   
c     fsmach = free stream mach number (0 for hover)
c     alfa   = angle of attack for freestream (collective set by grid)
c     rey    = reynolds number
c     invisc = euler or navier-stokes
c            = .false. => navier-stokes
c            = .true. => euler
c     lamin  = is the flow laminar
c            = .true. => laminar
c            = .false. => fully turbulent
c   
c   
c     iunst  = type of unsteady flow
c            = 0 => steady
c            = 1 => unsteady pitching oscillation
c            = 2 => unsteady pitching ramp
c                         (need to input grid motion)
c            = 3 => prescribed pitching
c     ntac   = temporal order of accuracy
c            = 1 => first order
c            = 2 => second order
c            = 3 => third order 
c     itnmax = number of newton iterations per time step
c     dt     = time step size, should be less than 0.10 for time accuracy
c              (typically 50.0 if steady, 0.05 for time-accurate)
c     timeac = how does dt vary in space
c            = 1. => constant time step everywhere
c            otherwise space-varying dt
c     totime = total time for unsteady calculation (reset from restart file)
c   
c   
c     ilhs   = left hand side scheme
c            = 1 => LU-SGS algorithm
c            = 2 => ARC-2D with second and fourth order dissipation
c            = 3 => ARC-2D with upwind
c    iprecon = use low Mach preconditioning or not
c            = .true. => use preconditioning
c            = .false. => no preconditioning
c     Mp    = low Mach preconditioning factor
c     epse   = dissipation for implicit side (usually 0.01)
c     irhsy  = spatial order of accuracy
c            = -1 => 1st order
c            = -2 => 2nd order
c            = -3 => 3rd order
c     ilim   = type of limiting
c            =  0 => no limiting at all (muscl scheme)
c            <  0 => no limiting in k-direction (muscl scheme)
c            >  0 => limiting in both directions
c abs(ilim)  =  1 => differentiable limiter for 3rd order (koren's)
c            =  2 => differentiable limiter for 2nd order (van albada)
c            =  3 => chakravarthy-osher minmod
c            =  4 => sonic-a scheme of hyunh et al.
c            =  5 => sonic extension of chakravarthy-osher minmod
c            =  7 => cubic interpolation with no limiting
c            =  8 => quartic interpolation with no limiting
c            =  9 => quadratic reconstruction with no limiting (pade' scheme)
c    
c
c     jint   = calculate solution on only every jint points in j-direction (1)
c     kint   = calculate solution on only every kint points in k-direction (1)
c    
c     rf     = reduced frequency or time for unsteady motion
c     angmax = maximum change in angle of attack
c 
c************end prologue ********************************************
      use params_global
      use ihc
c*********************************************************************
      implicit none
c*********************************************************************
      ! allocatable arrays

      real, allocatable :: s(:),q(:),qtn(:),qtnm1(:),qnewt(:)
      real, allocatable :: x(:),y(:),xv(:),yv(:)
      real, allocatable :: tscale(:),bt(:)
      integer, allocatable :: iblank(:)
      real, allocatable :: xx(:),xy(:),yx(:),yy(:)
      real, allocatable :: ug(:),vg(:),ugv(:),vgv(:),turmu(:)
      real, allocatable :: xole(:),yole(:),xold(:),yold(:)
      integer, allocatable :: jgmx(:),kgmx(:),jgmxv(:),kgmxv(:)
      integer, allocatable :: ipointer(:,:)

      real,allocatable :: tspec(:),Ds(:,:)

      ! arrays for overset meshing

      integer              :: Nj,Nk,idsize,j,k
      integer,allocatable  :: ndonor(:,:),nfringe(:,:)
      integer,allocatable  :: iisptr(:,:),iieptr(:,:)
      integer, allocatable :: imesh(:,:,:,:),idonor(:,:,:,:)
      integer, allocatable :: ibc(:,:,:)
      real, allocatable    :: frac(:,:,:,:)
      real, allocatable    :: xgl(:,:,:),ygl(:,:,:)
      real, allocatable    :: xglv(:,:,:),yglv(:,:,:),volg(:,:,:)
      integer, allocatable :: ibgl(:,:,:)
      character*40,allocatable :: ihcbcfile(:)
      !am
      integer              :: maxjd,maxkd

      ! local scalar variables
      
      integer ig,igq,igs,igv,igb
      integer nmesh,jd,kd,im,nsp
      integer nrc2,ii,mstop
      character*40 bcfile,fprefix,integer_string

      real cfx_tot,cfy_tot,cm_tot,cl_tot,cd_tot,cpower_tot
      real opt_obj

c** first executable statement

      write(6,*) ' '
      write(6,*) ' welcome to maryland overset turns-2d '
      write(6,*) '  this research code should help you with all your',
     <            ' airfoil problems :). '
      write(6,*) '  overset version : 04/13/2005 (jaina)'
      write(6,*)

      nmesh=6
      allocate(jgmx(nmesh),kgmx(nmesh)) ! allocate mesh pointers with 
      allocate(jgmxv(nmesh),kgmxv(nmesh)) ! dummy number of meshes to start

      !initialize to avoid bugs !asitav
      jgmx = 0; kgmx = 0
      jgmxv = 0; kgmxv = 0

c..  initialize data and read inputs

      bcfile = "bc.inp"
      fprefix = "fort"
      call read_inputs(jgmx,kgmx,nmesh,bcfile)

c..  compute time-spectral coefficients 

      allocate(tspec(nspec),Ds(nspec,nspec))
      call computeTScoefs(nspec,Ds)

c*************** memory allocation for multiple mesh pointers ***********

      allocate(ipointer(nmesh,5))
      call determine_size(jgmx,kgmx,nspec,nq,nv,ipointer,nmesh,
     &     igrd,igrdv,igrdb,iqdim,isdim,mdim,nadd)

c***************** memory allocation block for flow variables**********

      allocate(s(isdim),q(iqdim),qtn(isdim),qtnm1(isdim),qnewt(isdim))
      allocate(x(igrd),y(igrd),xv(igrdv),yv(igrdv))
      allocate(tscale(igrd),bt(igrd))
      allocate(iblank(igrd))
      allocate(xx(igrd),xy(igrd),yx(igrd),yy(igrd))
      allocate(ug(igrd),vg(igrd),turmu(igrd))
      allocate(ugv(igrdv),vgv(igrdv))
      allocate(xole(igrdv),yole(igrdv))
      allocate(xold(igrdv),yold(igrdv))

c***************** memory allocation block for connectivity variables**********

      if(num_grids.gt.1) then

        Nj=jgmx(1); Nk=kgmx(1); idsize=jgmx(1)*kgmx(1)
        do im=2,nmesh
          if(Nj.le.jgmx(im)) Nj=jgmx(im)
          if(Nk.le.kgmx(im)) Nk=kgmx(im)
          if(idsize.le.jgmx(im)*kgmx(im)) idsize=jgmx(im)*kgmx(im)
        end do

        allocate(xgl(Nj,Nk,nmesh),ygl(Nj,Nk,nmesh),volg(Nj,Nk,nmesh))
        allocate(ibgl(Nj,Nk,nmesh))

        allocate(imesh(idsize,2,nmesh,nspec),idonor(idsize,2,nmesh,nspec))
        allocate(frac(idsize,2,nmesh,nspec),ibc(idsize,nmesh,nspec))
        allocate(nfringe(nmesh,nspec),ndonor(nmesh,nspec))
        allocate(iisptr(nmesh,nspec),iieptr(nmesh,nspec))
        allocate(ihcbcfile(nmesh))
         
        Nj=jgmx(1)-nadd; Nk=kgmx(1)-nadd
        do im=2,nmesh
          if(Nj.le.jgmx(im)-nadd) Nj=jgmx(im)-nadd
          if(Nk.le.kgmx(im)-nadd) Nk=kgmx(im)-nadd
        end do

        allocate(xglv(Nj,Nk,nmesh),yglv(Nj,Nk,nmesh))

      endif
         
c********* end memory allocation block *******************************

      do im=1,nmesh
         call set_pointers_globals(im,ipointer,ig,
     &        igq,igs,igv,igb,jd,kd,jgmx,kgmx,nmesh)
         call initia(q(igq),s(igs),x(ig),y(ig),xv(igv),yv(igv),xx(ig),xy(ig),yx(ig),
     &        yy(ig),ug(ig),vg(ig),ugv(igv),vgv(igv),turmu(ig),
     &        xold(igv),yold(igv),xole(igv),yole(igv),iblank(ig),tspec,im,jd,kd)

         if (num_grids.gt.1) then
          jgmxv(im) = jmax
          kgmxv(im) = kmax

          write(integer_string,*) im-1
          integer_string = adjustl(integer_string)
          ihcbcfile(im) = 'ihcbc.'//trim(integer_string)
         endif

      enddo

      do im=1,nmesh
        call set_pointers_globals(im,ipointer,ig,
     &       igq,igs,igv,igb,jd,kd,jgmx,kgmx,nmesh)
!        call movie(q(igq),x(ig),y(ig),iblank(ig),ug(ig),
!     <             vg(ig),jd,kd,1,19+100*im,18+100*im)

        !am if(if_obj .and. bodyflag(im)) then
        if(if_obj .and. im.eq.1) then
           call obj_setup(jd,kd)
        end if
      enddo

      !allocate and read beta
      !----------------------
      if(if_obj) then
        maxjd = jgmx(1)
        maxkd = kgmx(1)

        do im=2,nmesh
          if(maxjd.le.jgmx(im)) maxjd = jgmx(im)
          if(maxkd.le.kgmx(im)) maxkd = kgmx(im)
        end do
        allocate(obj_coeff_prod(maxjd,maxkd,nmesh))

        !read beta
        open(2211,file='beta.opt',form='formatted')
        do im=1,nmesh
          read(2211,*)((obj_coeff_prod(j,k,im),j=1,jgmx(im)),k=1,kgmx(im)) 
        end do
      end if
      !----------------------

      call astore(x,y,iblank,q,iturb,itrans,jgmx,kgmx,nmesh,ipointer,
     &     igrd,iqdim,jd,kd,istep0,timespectral,nspec)

c...find connectivity

      if(num_grids.gt.1) then

!!!$OMP PARALLEL IF (NSPEC > 1)
!!!$OMP DO
!!!$OMP& PRIVATE(im,j,k,ig,igq,igs,igv,igb,jd,kd,jmax,kmax)
!!!$OMP& FIRSTPRIVATE(xgl,ygl,ibgl,volg,xglv,yglv)
        spectralloop1: do nsp = 1,nspec

c.....collect grids
        do im=1,nmesh
          call set_pointers_globals(im,ipointer,ig,
     &         igq,igs,igv,igb,jd,kd,jgmx,kgmx,nmesh)
          do k=1,kd
            do j=1,jd
              xgl(j,k,im)=x(ig-1 + jd*kd*(nsp-1) + jd*(k-1) + j)
              ygl(j,k,im)=y(ig-1 + jd*kd*(nsp-1) + jd*(k-1) + j)
              volg(j,k,im)=1./q(igq - 1 + jd*kd*nspec*(nq-1) + 
     &                                    jd*kd*(nsp-1) + jd*(k-1) + j)
            enddo
          enddo

          do k=1,kmax
            do j=1,jmax
              xglv(j,k,im)=xv(igv-1 + jmax*kmax*(nsp-1)+jmax*(k-1)+j)
              yglv(j,k,im)=yv(igv-1 + jmax*kmax*(nsp-1)+jmax*(k-1)+j)
            enddo
          enddo
        enddo

c......call connectivity now

        call connect2d(xglv,yglv,xgl,ygl,volg,ibgl,
     &        idonor(:,:,:,nsp),frac(:,:,:,nsp),imesh(:,:,:,nsp),
     &        ibc(:,:,nsp),iisptr(:,nsp),iieptr(:,nsp),ndonor(:,nsp),
     &        nfringe(:,nsp),jgmxv,kgmxv,nhalo,nmesh,ihcbcfile)
        
c......connectivity info to all meshes
        do im=1,nmesh
          call set_pointers_globals(im,ipointer,ig,
     &         igq,igs,igv,igb,jd,kd,jgmx,kgmx,nmesh)
          do k=1,kd
            do j=1,jd
              iblank(ig-1 + jd*kd*(nsp-1) + jd*(k-1) + j) = ibgl(j,k,im)
            enddo
          enddo
        enddo 

        enddo spectralloop1
!!!$OMP END DO
!!!$OMP END PARALLEL

        do im=1,nmesh
          call set_pointers_globals(im,ipointer,ig,
     &         igq,igs,igv,igb,jd,kd,jgmx,kgmx,nmesh)
          call update_halo_iblanks(iblank(ig),jd,kd)
        enddo 

      endif

c..now perform the flow solution for each iteration or time step 

      nrc2 = nsteps - istep0

	totime=0.0
      do 10 istep = 1,nrc2

c..update time and move the grid if unsteady problem

        istep0 = istep0 + 1
        if(iunst.ne.0) totime = totime + dt

        do ii=1,nmesh
           
           call set_pointers_globals(ii,ipointer,ig,
     &          igq,igs,igv,igb,jd,kd,jgmx,kgmx,nmesh)
           
           if (iunst.gt.0) then
              if (motiontype.eq.1 .and. ii.eq.1) then
!am?                theta_col=alfa + angmax*sin(rotf*istep*dt)
!am?                call move_new(0,x(ig),y(ig),xv(igv),yv(igv),
!am?     &                   xold(igv),yold(igv),xole(igv),yole(igv),
!am?     &                   ug(ig),vg(ig),jd,kd)
                theta_col=alfa + angmax*(1.-cos(rotf*istep*dt)) !asitav
                call pitch(0,x(ig),y(ig),xv(igv),yv(igv),
     &                   xold(igv),yold(igv),xole(igv),yole(igv),
     &                   ug(ig),vg(ig),jd,kd)
              elseif (motiontype.eq.2) then
                call move_cyclo(0,x(ig),y(ig),xv(igv),yv(igv),
     &                   xold(igv),yold(igv),xole(igv),yole(igv),
     &                   ug(ig),vg(ig),jd,kd,ii)
              elseif (motiontype.eq.3.and.ii.eq.1) then
                call move_tef(0,x(ig),y(ig),xv(igv),yv(igv),
     &                   xold(igv),yold(igv),xole(igv),yole(igv),
     &                   ug(ig),vg(ig),jd,kd,ii)
              elseif(ii.eq.1) then
                stop 'Error: Unknown motion type'
	      endif
              call metfv(q(igq),x(ig),y(ig),xv(igv),yv(igv),
     &                   xx(ig),xy(ig),yx(ig),yy(ig),jd,kd,ii)

              if (iunst.eq.2) call rotateq(q(igq),qtn(igs),qtnm1(igs),jd,kd)

 7         endif


           if (itnmax.gt.1) then
             call stqol(q(igq),qtn(igs),qtnm1(igs),qnewt(igs),jd,kd)
           endif

           if( mod(istep,npnorm).eq.0)
     <                      write(6,101) istep,theta_col,totime
 101       format(/,' istep,angle,time =',x,i5,2(x,f10.5))

        enddo

c..    recalculate connectivity

        if(num_grids.gt.1.and.iunst.gt.0.and..not.static_conn) then

!!!$OMP PARALLEL IF (NSPEC > 1)
!!!$OMP DO
!!!$OMP& PRIVATE(im,j,k)
!!!$OMP& FIRSTPRIVATE(xgl,ygl,ibgl,volg,xglv,yglv)
          spectralloop2: do nsp = 1,nspec

c.....collect grids
          do im=1,nmesh
            call set_pointers_globals(im,ipointer,ig,
     &           igq,igs,igv,igb,jd,kd,jgmx,kgmx,nmesh)
            do k=1,kd
              do j=1,jd
                xgl(j,k,im)=x(ig-1 + jd*kd*(nsp-1) + jd*(k-1) + j)
                ygl(j,k,im)=y(ig-1 + jd*kd*(nsp-1) + jd*(k-1) + j)
                volg(j,k,im)=1./q(igq - 1 + jd*kd*nspec*(nq-1) + 
     &                                      jd*kd*(nsp-1) + jd*(k-1) + j)
              enddo
            enddo

            do k=1,kmax
              do j=1,jmax
                xglv(j,k,im)=xv(igv-1 + jmax*kmax*(nsp-1) + jmax*(k-1) + j)
                yglv(j,k,im)=yv(igv-1 + jmax*kmax*(nsp-1) + jmax*(k-1) + j)
              enddo
            enddo
          enddo

c......call connectivity now

          call connect2d(xglv,yglv,xgl,ygl,volg,ibgl,
     &          idonor(:,:,:,nsp),frac(:,:,:,nsp),imesh(:,:,:,nsp),
     &          ibc(:,:,nsp),iisptr(:,nsp),iieptr(:,nsp),ndonor(:,nsp),
     &          nfringe(:,nsp),jgmxv,kgmxv,nhalo,nmesh,ihcbcfile)
        
c......connectivity info to all meshes
          do im=1,nmesh
            call set_pointers_globals(im,ipointer,ig,
     &           igq,igs,igv,igb,jd,kd,jgmx,kgmx,nmesh)
            do k=1,kd
              do j=1,jd
                 iblank(ig-1 + jd*kd*(nsp-1) + jd*(k-1) + j)=ibgl(j,k,im)
              enddo
            enddo
          enddo 

          enddo spectralloop2
!!!$OMP END DO
!!!$OMP END PARALLEL

          do im=1,nmesh
            call set_pointers_globals(im,ipointer,ig,
     &           igq,igs,igv,igb,jd,kd,jgmx,kgmx,nmesh)
            call update_halo_iblanks(iblank(ig),jd,kd)
          enddo 
         
        endif

c..perform the step depending on number of newton iterations
c..stop if negative speed of sound

        do 999 itn = 1,itnmax
           
           do im=1,nmesh
              call set_pointers_globals(im,ipointer,ig,
     &        igq,igs,igv,igb,jd,kd,jgmx,kgmx,nmesh)
           
              if (.not. iprecon) Mp = 1.0

              dualtime = dtpseudo(itn)
              call time_step(q(igq),xx(ig),xy(ig),yx(ig),yy(ig),
     <               ug(ig),vg(ig),tscale(ig),bt(ig),iblank(ig),jd,kd)

              call step(q(igq),qtn(igs),qtnm1(igs),qnewt(igs),s(igs),! q (at time steps)
     &             x(ig),y(ig),xv(igv),yv(igv),iblank(ig),           ! grid
     &             xx(ig),xy(ig),yx(ig),yy(ig),                      ! metrics
     &             ug(ig),vg(ig),ugv(igv),vgv(igv),                  ! grid velocities
     &             xold(igv),yold(igv),xole(igv),yole(igv),          ! fine mesh 
     &             turmu(ig),                                        ! eddy viscosity
     &             tscale(ig),bt(ig),Ds,im,jd,kd) ! timestep, dimensions

              call monitor(mstop,q(igq),jd,kd)
              
              if(mstop .gt. 0 ) go to 19
           enddo
           
           if (nmesh.gt.1) then
             call do_interpolations(q,jgmx,kgmx,ibc,imesh,idonor,frac,
     >              nfringe,ndonor,iisptr,iieptr,idsize,iqdim,nmesh)
           endif

  999   continue
  901   continue

c..   write restart files

        if (mod(istep0,nrest).eq.0.or.istep0.eq.2) 
     <     call astore(x,y,iblank,q,iturb,itrans,jgmx,kgmx,nmesh,
     <       ipointer,igrd,iqdim,jd,kd,istep0,timespectral,nspec)
        
c...call force and moment routine

        if( mod(istep,npnorm).eq.0 ) then
          do im=1,nmesh
            call set_pointers_globals(im,ipointer,ig,
     &         igq,igs,igv,igb,jd,kd,jgmx,kgmx,nmesh)

            !am if (bodyflag(im)) then
            if (bodyflag(im) .and. im.eq.1) then !not for wt wall
               call compute_forces(jd,kd,x(ig),y(ig),xv(igv),yv(igv),
     >          q(igq),xx(ig),xy(ig),yx(ig),yy(ig),
     >          cfx_tot,cfy_tot,cm_tot,cl_tot,cd_tot,cpower_tot,im,fprefix)
               !am call write_reystress(q(igq),turmu(ig), x(ig),y(ig),xx(ig),xy(ig),yx(ig),yy(ig),jd,kd)

               !asitav write out opt objective value
               !------------------------------------
               if(if_obj .and. if_objtot) then
                 if(obj_ftype.eq.obj_ftype_cltot) then
                   opt_obj = cl_tot
                 elseif(obj_ftype.eq.obj_ftype_cdtot) then
                   opt_obj = cd_tot
                 elseif(obj_ftype.eq.obj_ftype_cmtot) then
                   opt_obj = cm_tot
                 else
                   print '(A,I7,x,A)','OBJ TYPE: ',obj_ftype,
     >                                ' not supported '
                   stop
                 end if
                 write(747,*)opt_obj
               end if
               !------------------------------------

            endif
            !am call write_reystress(q(igq),turmu(ig), x(ig),y(ig),xx(ig),xy(ig),yx(ig),yy(ig),jd,kd,im)
            !am if(if_obj .and. bodyflag(im) .and. .not.if_objtot) then
            if(if_obj .and. im.eq.1 .and. .not.if_objtot) then
              !am call  objectivef(jd,kd,x(ig),y(ig),xv(igv),yv(igv),q(igq),xx(ig),xy(ig),yx(ig),yy(ig),opt_obj,im)
              call  objectivef_ts(jd,kd,q(igq),opt_obj,im)
            end if
          enddo
        endif
          
!	 if(mod(istep,nmovie).eq.0) then
!          do im=1,nmesh
!            call set_pointers_globals(im,ipointer,ig,
!     &         igq,igs,igv,igb,jd,kd,jgmx,kgmx,nmesh)
!
!            if (istep.lt.isin) goto 10
!            write(1819,*) istep,theta_col
!            call movie(q(igq),x(ig),y(ig),iblank(ig),
!     <	          ug(ig),vg(ig),jd,kd,0,19+100*im,18+100*im)
!          enddo
!        endif

   10 continue
   19 continue

c..finished iterations or time-steps
c..write restart files

      write(6,*) 'finished iterations, storing solution files now..'
      call astore(x,y,iblank,q,iturb,itrans,jgmx,kgmx,nmesh,ipointer,
     &     igrd,iqdim,jd,kd,istep0,timespectral,nspec)

      stop 'umturns2d completed successfully'
      end

c*************************************************************************
