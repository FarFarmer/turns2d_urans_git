C        Generated by TAPENADE     (INRIA, Tropics team)
C  Tapenade 3.6 (r4343) - 10 Feb 2012 10:52
C
C  Differentiation of source in reverse (adjoint) mode:
C   gradient     of useful results: rey q vmul sjmat vort
C   with respect to varying inputs: rey q vmul sjmat vort
C
C***********************************************************************
      SUBROUTINE SOURCE_BQ(q, qb, sn, u, v, sjmat, sjmatb, vmul, vmulb, 
     +                     vort, vortb, xx, xy, yx, yy, aj, bj, cj, ak, 
     +                     bk, ck, jd, kd, js, je, ks, ke)
      USE PARAMS_GLOBAL
      USE PARAMS_SENSITIVITY
      IMPLICIT NONE
C***********************************************************************
      INTEGER jd, kd, js, je, ks, ke
      REAL q(jd, kd, nq), sjmat(jd, kd)
      REAL qb(jd, kd, nq), sjmatb(jd, kd)
      REAL xx(jd, kd), xy(jd, kd), yx(jd, kd), yy(jd, kd)
      REAL aj(jd, kd), bj(jd, kd), cj(jd, kd)
      REAL ak(jd, kd), bk(jd, kd), ck(jd, kd)
      REAL vmul(jd, kd), sn(jd, kd), vort(jd, kd)
      REAL vmulb(jd, kd), vortb(jd, kd)
      REAL u(jd, kd), v(jd, kd)
C
      !am REAL chp(jd, kd), dnuhp(jd, kd)
      !am REAL dmxh(jd, kd), dmyh(jd, kd)
      REAL rcv2, d2min, rmax, stilim, fturf
      REAL vnul, chi, d, fv1, fv2, fv3, ft2, dchi
      REAL vnulb, chib, fv1b, fv2b, fv3b, ft2b
      REAL dfv1, dfv2, dfv3, dft2, d2, stilda, r, g, fw
      REAL stildab, rb, gb, fwb
      REAL dstild, dr, dg, dfw, pro, des, prod, dest, dpro, ddes
      REAL prodb, destb
      REAL tk1, tk2
      INTEGER j, k, isour
      INTEGER branch
      REAL temp3
      REAL temp2
      REAL temp1
      REAL temp0
      REAL temp7b
      INTRINSIC EXP
      REAL min1
      INTRINSIC MAX
      REAL temp3b
      REAL min1b
      REAL x1
      REAL temp7b0
      REAL temp2b1
      REAL temp2b0
      REAL tempb
      REAL temp2b
      REAL x1b
      INTRINSIC MIN
      REAL temp1b
      REAL temp
      REAL temp9
      REAL temp8
      REAL temp7
      REAL temp6
      REAL temp5
      REAL temp4
      INCLUDE 'sadata.h'
C
C**   first executable statement
C
      rcv2 = 1./5.
      d2min = 1.e-12
      rmax = 10.0
      stilim = 1.e-12
      fturf = 0.0
      isour = 0
      DO k=ks,ke
        DO j=js,je
          vnul = vmul(j, k)/q(j, k, 1)/q(j, k, nq)
          chi = q(j, k, nmv+1)/vnul
          d = sn(j, k)
          IF (chi .LT. 1.e-12) THEN
            chi = 1.e-12
            CALL PUSHCONTROL1B(0)
          ELSE
            CALL PUSHCONTROL1B(1)
            chi = chi
          END IF
          fv1 = chi**3/(chi**3+cv1**3)
C
          IF (isour .EQ. 0) THEN
            fv2 = 1. - chi/(1.+chi*fv1)
            fv3 = 1.0
            ft2 = fturf*ct3*EXP(-(1.*ct4*chi*chi))
            CALL PUSHCONTROL1B(1)
          ELSE
            fv2 = 1./(1.+chi*rcv2)
            CALL PUSHREAL8(fv2)
            fv2 = fv2**3
            fv3 = (1.+chi*fv1)*(1.-fv2)/chi
            ft2 = fturf*ct3*EXP(-(1.*ct4*chi*chi))
            CALL PUSHCONTROL1B(0)
          END IF
C
          IF (d**2 .LT. d2min) THEN
            d2 = d2min
          ELSE
            d2 = d**2
          END IF
C
C....for new definition of s_{tilda}, refer aiaa-95-0312
C
          stilda = vort(j, k)*fv3 + vnul/(d2*akt*akt*rey)*chi*fv2
          IF (stilda .LT. stilim) THEN
            stilda = stilim
            CALL PUSHCONTROL1B(0)
          ELSE
            CALL PUSHCONTROL1B(1)
            stilda = stilda
          END IF
C
          r = q(j, k, nmv+1)/(d2*akt*akt*rey)/stilda
          IF (r .GT. rmax) THEN
            r = rmax
            CALL PUSHCONTROL1B(0)
          ELSE
            CALL PUSHCONTROL1B(1)
            r = r
          END IF
          g = r + cw2*(r**6-r)
          fw = (1.+cw3**6)/(g**6+cw3**6)
          CALL PUSHREAL8(fw)
          fw = g*fw**(1./6.)
C
C
          prod = cb1*stilda*(1.-ft2)*q(j, k, nmv+1)
          dest = (cw1*fw-cb1/(akt*akt)*ft2)*q(j, k, nmv+1)*q(j, k, nmv+1
     +      )/d2/rey
C
C
C...modification for transition model
C
          IF (itrans .EQ. 1) THEN
            IF (q(j, k, nmv+nturb+1) .LT. 0.1) THEN
              CALL PUSHCONTROL1B(0)
              x1 = 0.1
            ELSE
              x1 = q(j, k, nmv+nturb+1)
              CALL PUSHCONTROL1B(1)
            END IF
            IF (x1 .GT. 1.0) THEN
              min1 = 1.0
              CALL PUSHCONTROL1B(0)
            ELSE
              min1 = x1
              CALL PUSHCONTROL1B(1)
            END IF
            CALL PUSHCONTROL1B(1)
          ELSE
            CALL PUSHCONTROL1B(0)
          END IF
          prodb = sjmatb(j, k)
          destb = -sjmatb(j, k)
          CALL POPCONTROL1B(branch)
          IF (branch .NE. 0) THEN
            min1b = dest*destb
            destb = min1*destb
            CALL POPCONTROL1B(branch)
            IF (branch .EQ. 0) THEN
              x1b = 0.0
            ELSE
              x1b = min1b
            END IF
            CALL POPCONTROL1B(branch)
            IF (branch .NE. 0) qb(j, k, nmv+nturb+1) = qb(j, k, nmv+
     +          nturb+1) + x1b
            qb(j, k, nmv+nturb+1) = qb(j, k, nmv+nturb+1) + prod*prodb
            prodb = q(j, k, nmv+nturb+1)*prodb
          END IF
          temp7b0 = cb1*q(j, k, nmv+1)*prodb
          temp9 = d2*rey
          temp8 = q(j, k, nmv+1)
          temp7 = temp8**2/temp9
          temp7b = (cw1*fw-cb1*(ft2/akt**2))*destb/temp9
          fwb = temp7*cw1*destb
          ft2b = -(stilda*temp7b0) - cb1*temp7*destb/akt**2
          qb(j, k, nmv+1) = qb(j, k, nmv+1) + cb1*stilda*(1.-ft2)*prodb 
     +      + 2*temp8*temp7b
          reyb = reyb - temp7*d2*temp7b
          stildab = (1.-ft2)*temp7b0
          CALL POPREAL8(fw)
          temp6 = 1.0/6.
          gb = fw**temp6*fwb
          IF (fw .LE. 0.0 .AND. (temp6 .EQ. 0.0 .OR. temp6 .NE. INT(
     +        temp6))) THEN
            fwb = 0.0
          ELSE
            fwb = g*temp6*fw**(temp6-1)*fwb
          END IF
          temp5 = cw3**6 + g**6
          gb = gb - (cw3**6+1.)*6*g**5*fwb/temp5**2
          rb = (cw2*6*r**5-cw2+1.0)*gb
          CALL POPCONTROL1B(branch)
          IF (branch .EQ. 0) rb = 0.0
          temp4 = d2*akt**2
          temp3 = temp4*rey*stilda
          temp3b = -(q(j, k, nmv+1)*temp4*rb/temp3**2)
          qb(j, k, nmv+1) = qb(j, k, nmv+1) + rb/temp3
          reyb = reyb + stilda*temp3b
          stildab = stildab + rey*temp3b
          CALL POPCONTROL1B(branch)
          IF (branch .EQ. 0) stildab = 0.0
          temp2 = d2*akt**2
          temp2b1 = stildab/(temp2*rey)
          vortb(j, k) = vortb(j, k) + fv3*stildab
          fv3b = vort(j, k)*stildab
          vnulb = fv2*chi*temp2b1
          chib = fv2*vnul*temp2b1
          fv2b = vnul*chi*temp2b1
          reyb = reyb - vnul*chi*fv2*temp2b1/rey
          CALL POPCONTROL1B(branch)
          IF (branch .EQ. 0) THEN
            temp1 = (-fv2+1.)/chi
            temp1b = (chi*fv1+1.)*fv3b/chi
            fv2b = fv2b - temp1b
            CALL POPREAL8(fv2)
            fv2b = 3*fv2**2*fv2b
            chib = chib + temp1*fv1*fv3b - temp1*temp1b - rcv2*fv2b/(
     +        rcv2*chi+1.)**2 - ct4*EXP(-(ct4*chi**2))*fturf*ct3*2*chi*
     +        ft2b
            fv1b = temp1*chi*fv3b
          ELSE
            temp2b = -(fv2b/(chi*fv1+1.))
            temp2b0 = -(chi*temp2b/(chi*fv1+1.))
            chib = chib + temp2b + fv1*temp2b0 - ct4*EXP(-(ct4*chi**2))*
     +        fturf*ct3*2*chi*ft2b
            fv1b = chi*temp2b0
          END IF
          temp0 = cv1**3 + chi**3
          chib = chib + (3*chi**2/temp0-chi**5*3/temp0**2)*fv1b
          CALL POPCONTROL1B(branch)
          IF (branch .EQ. 0) chib = 0.0
          qb(j, k, nmv+1) = qb(j, k, nmv+1) + chib/vnul
          vnulb = vnulb - q(j, k, nmv+1)*chib/vnul**2
          temp = q(j, k, 1)*q(j, k, nq)
          tempb = -(vmul(j, k)*vnulb/temp**2)
          vmulb(j, k) = vmulb(j, k) + vnulb/temp
          qb(j, k, 1) = qb(j, k, 1) + q(j, k, nq)*tempb
          qb(j, k, nq) = qb(j, k, nq) + q(j, k, 1)*tempb
        ENDDO
      ENDDO
      END
