C        Generated by TAPENADE     (INRIA, Tropics team)
C  Tapenade 3.6 (r4343) - 10 Feb 2012 10:52
C
C  Differentiation of bcwall in reverse (adjoint) mode:
C   gradient     of useful results: einf vinf uinf q
C   with respect to varying inputs: einf vinf uinf q
C
C***********************************************************************
      SUBROUTINE BCWALL_BQ(q, qb, xx, xy, yx, yy, ug, vg, jd, kd, js, je
     +                     , ks, ke, idir, invsc)
      USE PARAMS_GLOBAL
      IMPLICIT NONE
      INCLUDE 'DIFFSIZES.inc'
C  Hint: ISIZE1OFuwallbINbcwall should be the value of mdim
C  Hint: ISIZE1OFvwallbINbcwall should be the value of mdim
C
C  generic solid wall boundary conditions.
C
C***********************************************************************
C***********************************************************************
C
      INTEGER jd, kd, js, je, ks, ke, idir
      LOGICAL invsc
      REAL q(jd, kd, nq)
      REAL qb(jd, kd, nq)
      REAL xx(jd, kd), xy(jd, kd), yx(jd, kd), yy(jd, kd)
C local variables
      REAL ug(jd, kd), vg(jd, kd)
      REAL uwall(mdim), vwall(mdim)
C
      INTEGER k, k1, k2, k3, kc, ihigh, j, iadd, iadir
      REAL foso, rj, us, vs, ue, ve, t, scal, rscal, ajacinv
      REAL rho1, rho2, u1, u2, v1, v2, p1, p2, press
      REAL rho1b, rho2b, u1b, u2b, v1b, v2b, p1b, p2b, pressb
      LOGICAL tmp
      REAL tmp0
      REAL tmp1
      REAL tmp2
      REAL tmp3
      INTEGER branch
      REAL temp3
      REAL temp2
      REAL temp1
      REAL temp0
      REAL temp9b0
      REAL vwallb(mdim)
      REAL tempb0
      INTRINSIC SIGN
      REAL tmp0b
      INTRINSIC ABS
      REAL tmp3b
      REAL temp12b
      REAL temp2b0
      REAL temp6b
      REAL temp12
      REAL temp11
      REAL temp10
      REAL temp9b
      REAL temp5b0
      REAL tempb
      REAL temp2b
      REAL tmp2b
      REAL temp5b
      REAL uwallb(mdim)
      REAL temp12b2
      REAL temp12b1
      REAL temp12b0
      REAL temp6b4
      REAL temp6b3
      REAL temp6b2
      REAL temp6b1
      REAL temp
      REAL temp6b0
      REAL temp9
      REAL tmp1b
      REAL temp8
      REAL temp7
      REAL temp6
      REAL temp5
      REAL temp4
C
C**** first executable statement
      iadd = SIGN(1, idir)
      IF (idir .GE. 0.) THEN
        iadir = idir
      ELSE
        iadir = -idir
      END IF
C
C...setting wind tunnel walls to be inviscid
      invisc = invsc
C
      IF (iadir .NE. 1) THEN
        IF (iadir .EQ. 2) THEN
C
          IF (idir .EQ. 2) THEN
            k = ke
          ELSE IF (idir .EQ. -2) THEN
            k = ks
          END IF
C
          k1 = k + iadd
          k2 = k1 + iadd
C
          IF (invsc) THEN
            foso = 1.0
          ELSE
            foso = 0.0
          END IF
C
C..compute surface velocities
C
          CALL BCTANY(q, uwall, vwall, xx, xy, yx, yy, ug, vg, jd, kd
     +                   , js, je, ks, ke, idir)
C
C..extrapolate pressure and density to the surface
C
          DO j=js,je
            CALL PUSHREAL8(rho1)
            rho1 = q(j, k1, 1)*q(j, k1, nq)
            CALL PUSHREAL8(rho2)
            rho2 = q(j, k2, 1)*q(j, k2, nq)
C
            p1 = gm1*(q(j, k1, 4)-0.5*(q(j, k1, 2)**2+q(j, k1, 3)**2)/q(
     +        j, k1, 1))*q(j, k1, nq)
            p2 = gm1*(q(j, k2, 4)-0.5*(q(j, k2, 2)**2+q(j, k2, 3)**2)/q(
     +        j, k2, 1))*q(j, k2, nq)
C
            tmp0 = ((1.+foso)*rho1-foso*rho2)/q(j, k, nq)
            CALL PUSHREAL8(q(j, k, 1))
            q(j, k, 1) = tmp0
            CALL PUSHREAL8(q(j, k, 2))
            q(j, k, 2) = uwall(j)*q(j, k, 1)
            CALL PUSHREAL8(q(j, k, 3))
            q(j, k, 3) = vwall(j)*q(j, k, 1)
            CALL PUSHREAL8(press)
            press = (1.+foso)*p1 - foso*p2
            tmp1 = press/(gm1*q(j, k, nq)) + 0.5*(q(j, k, 2)**2+q(j, k, 
     +        3)**2)/q(j, k, 1)
            CALL PUSHREAL8(q(j, k, 4))
            q(j, k, 4) = tmp1
          ENDDO
C
C..extrapolate everything to other halo cells
C
          DO kc=1,ke-ks
            IF (idir .EQ. 2) THEN
              CALL PUSHINTEGER4(k)
              k = ke - kc
              CALL PUSHCONTROL2B(0)
            ELSE IF (idir .EQ. -2) THEN
              CALL PUSHINTEGER4(k)
              k = ks + kc
              CALL PUSHCONTROL2B(1)
            ELSE
              CALL PUSHCONTROL2B(2)
            END IF
            CALL PUSHINTEGER4(k1)
            k1 = k + iadd
            CALL PUSHINTEGER4(k2)
            k2 = k1 + iadd
            CALL PUSHREAL8(foso)
C
            foso = 1.0
C
            DO j=js,je
              CALL PUSHREAL8(rho1)
              rho1 = q(j, k1, 1)*q(j, k1, nq)
              CALL PUSHREAL8(rho2)
              rho2 = q(j, k2, 1)*q(j, k2, nq)
              CALL PUSHREAL8(u1)
              u1 = q(j, k1, 2)/q(j, k1, 1)
              CALL PUSHREAL8(u2)
              u2 = q(j, k2, 2)/q(j, k2, 1)
              CALL PUSHREAL8(v1)
              v1 = q(j, k1, 3)/q(j, k1, 1)
              CALL PUSHREAL8(v2)
              v2 = q(j, k2, 3)/q(j, k2, 1)
              p1 = gm1*(q(j, k1, 4)-0.5*(q(j, k1, 2)**2+q(j, k1, 3)**2)/
     +          q(j, k1, 1))*q(j, k1, nq)
              p2 = gm1*(q(j, k2, 4)-0.5*(q(j, k2, 2)**2+q(j, k2, 3)**2)/
     +          q(j, k2, 1))*q(j, k2, nq)
C
              tmp2 = ((1.+foso)*rho1-foso*rho2)/q(j, k, nq)
              CALL PUSHREAL8(q(j, k, 1))
              q(j, k, 1) = tmp2
              CALL PUSHREAL8(q(j, k, 2))
              q(j, k, 2) = ((1.+foso)*u1-foso*u2)*q(j, k, 1)
              CALL PUSHREAL8(q(j, k, 3))
              q(j, k, 3) = ((1.+foso)*v1-foso*v2)*q(j, k, 1)
              CALL PUSHREAL8(press)
              press = (1.+foso)*p1 - foso*p2
              tmp3 = press/(gm1*q(j, k, nq)) + 0.5*(q(j, k, 2)**2+q(j, k
     +          , 3)**2)/q(j, k, 1)
              CALL PUSHREAL8(q(j, k, 4))
              q(j, k, 4) = tmp3
            ENDDO
          ENDDO
          DO kc=ke-ks,1,-1
            DO j=je,js,-1
              CALL POPREAL8(q(j, k, 4))
              tmp3b = qb(j, k, 4)
              qb(j, k, 4) = 0.0
              temp12 = gm1*q(j, k, nq)
              temp12b = 0.5*tmp3b/q(j, k, 1)
              pressb = tmp3b/temp12
              qb(j, k, nq) = qb(j, k, nq) - press*gm1*tmp3b/temp12**2
              qb(j, k, 2) = qb(j, k, 2) + 2*q(j, k, 2)*temp12b
              qb(j, k, 3) = qb(j, k, 3) + 2*q(j, k, 3)*temp12b
              qb(j, k, 1) = qb(j, k, 1) - (q(j, k, 2)**2+q(j, k, 3)**2)*
     +          temp12b/q(j, k, 1)
              CALL POPREAL8(press)
              p1b = (foso+1.)*pressb
              p2b = -(foso*pressb)
              CALL POPREAL8(q(j, k, 3))
              temp12b0 = q(j, k, 1)*qb(j, k, 3)
              v1b = (foso+1.)*temp12b0
              v2b = -(foso*temp12b0)
              qb(j, k, 1) = qb(j, k, 1) + ((foso+1.)*v1-foso*v2)*qb(j, k
     +          , 3)
              qb(j, k, 3) = 0.0
              CALL POPREAL8(q(j, k, 2))
              temp12b1 = q(j, k, 1)*qb(j, k, 2)
              u1b = (foso+1.)*temp12b1
              u2b = -(foso*temp12b1)
              qb(j, k, 1) = qb(j, k, 1) + ((foso+1.)*u1-foso*u2)*qb(j, k
     +          , 2)
              qb(j, k, 2) = 0.0
              CALL POPREAL8(q(j, k, 1))
              tmp2b = qb(j, k, 1)
              qb(j, k, 1) = 0.0
              temp12b2 = tmp2b/q(j, k, nq)
              rho1b = (foso+1.)*temp12b2
              rho2b = -(foso*temp12b2)
              qb(j, k, nq) = qb(j, k, nq) - ((foso+1.)*rho1-foso*rho2)*
     +          temp12b2/q(j, k, nq)
              temp11 = q(j, k2, 1)
              temp10 = q(j, k2, 2)**2 + q(j, k2, 3)**2
              temp9 = temp10/temp11
              temp9b = gm1*q(j, k2, nq)*p2b
              temp9b0 = -(0.5*temp9b/temp11)
              qb(j, k2, 4) = qb(j, k2, 4) + temp9b
              qb(j, k2, 2) = qb(j, k2, 2) + 2*q(j, k2, 2)*temp9b0
              qb(j, k2, 3) = qb(j, k2, 3) + 2*q(j, k2, 3)*temp9b0
              qb(j, k2, 1) = qb(j, k2, 1) - temp9*temp9b0
              qb(j, k2, nq) = qb(j, k2, nq) + gm1*(q(j, k2, 4)-0.5*temp9
     +          )*p2b
              temp8 = q(j, k1, 1)
              temp7 = q(j, k1, 2)**2 + q(j, k1, 3)**2
              temp6 = temp7/temp8
              temp6b = gm1*q(j, k1, nq)*p1b
              temp6b0 = -(0.5*temp6b/temp8)
              qb(j, k1, 4) = qb(j, k1, 4) + temp6b
              qb(j, k1, 2) = qb(j, k1, 2) + 2*q(j, k1, 2)*temp6b0
              qb(j, k1, 3) = qb(j, k1, 3) + 2*q(j, k1, 3)*temp6b0
              qb(j, k1, 1) = qb(j, k1, 1) - temp6*temp6b0
              qb(j, k1, nq) = qb(j, k1, nq) + gm1*(q(j, k1, 4)-0.5*temp6
     +          )*p1b
              CALL POPREAL8(v2)
              temp6b1 = v2b/q(j, k2, 1)
              qb(j, k2, 3) = qb(j, k2, 3) + temp6b1
              qb(j, k2, 1) = qb(j, k2, 1) - q(j, k2, 3)*temp6b1/q(j, k2
     +          , 1)
              CALL POPREAL8(v1)
              temp6b2 = v1b/q(j, k1, 1)
              qb(j, k1, 3) = qb(j, k1, 3) + temp6b2
              qb(j, k1, 1) = qb(j, k1, 1) - q(j, k1, 3)*temp6b2/q(j, k1
     +          , 1)
              CALL POPREAL8(u2)
              temp6b3 = u2b/q(j, k2, 1)
              qb(j, k2, 2) = qb(j, k2, 2) + temp6b3
              qb(j, k2, 1) = qb(j, k2, 1) - q(j, k2, 2)*temp6b3/q(j, k2
     +          , 1)
              CALL POPREAL8(u1)
              temp6b4 = u1b/q(j, k1, 1)
              qb(j, k1, 2) = qb(j, k1, 2) + temp6b4
              qb(j, k1, 1) = qb(j, k1, 1) - q(j, k1, 2)*temp6b4/q(j, k1
     +          , 1)
              CALL POPREAL8(rho2)
              qb(j, k2, 1) = qb(j, k2, 1) + q(j, k2, nq)*rho2b
              qb(j, k2, nq) = qb(j, k2, nq) + q(j, k2, 1)*rho2b
              CALL POPREAL8(rho1)
              qb(j, k1, 1) = qb(j, k1, 1) + q(j, k1, nq)*rho1b
              qb(j, k1, nq) = qb(j, k1, nq) + q(j, k1, 1)*rho1b
            ENDDO
            CALL POPREAL8(foso)
            CALL POPINTEGER4(k2)
            CALL POPINTEGER4(k1)
            CALL POPCONTROL2B(branch)
            IF (branch .EQ. 0) THEN
              CALL POPINTEGER4(k)
            ELSE IF (branch .EQ. 1) THEN
              CALL POPINTEGER4(k)
            END IF
          ENDDO
          uwallb = 0.0
          vwallb = 0.0
          DO j=je,js,-1
            CALL POPREAL8(q(j, k, 4))
            tmp1b = qb(j, k, 4)
            qb(j, k, 4) = 0.0
            temp5 = gm1*q(j, k, nq)
            temp5b = 0.5*tmp1b/q(j, k, 1)
            pressb = tmp1b/temp5
            qb(j, k, nq) = qb(j, k, nq) - press*gm1*tmp1b/temp5**2
            qb(j, k, 2) = qb(j, k, 2) + 2*q(j, k, 2)*temp5b
            qb(j, k, 3) = qb(j, k, 3) + 2*q(j, k, 3)*temp5b
            qb(j, k, 1) = qb(j, k, 1) - (q(j, k, 2)**2+q(j, k, 3)**2)*
     +        temp5b/q(j, k, 1)
            CALL POPREAL8(press)
            p1b = (foso+1.)*pressb
            p2b = -(foso*pressb)
            CALL POPREAL8(q(j, k, 3))
            vwallb(j) = vwallb(j) + q(j, k, 1)*qb(j, k, 3)
            qb(j, k, 1) = qb(j, k, 1) + vwall(j)*qb(j, k, 3)
            qb(j, k, 3) = 0.0
            CALL POPREAL8(q(j, k, 2))
            uwallb(j) = uwallb(j) + q(j, k, 1)*qb(j, k, 2)
            qb(j, k, 1) = qb(j, k, 1) + uwall(j)*qb(j, k, 2)
            qb(j, k, 2) = 0.0
            CALL POPREAL8(q(j, k, 1))
            tmp0b = qb(j, k, 1)
            qb(j, k, 1) = 0.0
            temp5b0 = tmp0b/q(j, k, nq)
            rho1b = (foso+1.)*temp5b0
            rho2b = -(foso*temp5b0)
            qb(j, k, nq) = qb(j, k, nq) - ((foso+1.)*rho1-foso*rho2)*
     +        temp5b0/q(j, k, nq)
            temp4 = q(j, k2, 1)
            temp3 = q(j, k2, 2)**2 + q(j, k2, 3)**2
            temp2 = temp3/temp4
            temp2b = gm1*q(j, k2, nq)*p2b
            temp2b0 = -(0.5*temp2b/temp4)
            qb(j, k2, 4) = qb(j, k2, 4) + temp2b
            qb(j, k2, 2) = qb(j, k2, 2) + 2*q(j, k2, 2)*temp2b0
            qb(j, k2, 3) = qb(j, k2, 3) + 2*q(j, k2, 3)*temp2b0
            qb(j, k2, 1) = qb(j, k2, 1) - temp2*temp2b0
            qb(j, k2, nq) = qb(j, k2, nq) + gm1*(q(j, k2, 4)-0.5*temp2)*
     +        p2b
            temp1 = q(j, k1, 1)
            temp0 = q(j, k1, 2)**2 + q(j, k1, 3)**2
            temp = temp0/temp1
            tempb = gm1*q(j, k1, nq)*p1b
            tempb0 = -(0.5*tempb/temp1)
            qb(j, k1, 4) = qb(j, k1, 4) + tempb
            qb(j, k1, 2) = qb(j, k1, 2) + 2*q(j, k1, 2)*tempb0
            qb(j, k1, 3) = qb(j, k1, 3) + 2*q(j, k1, 3)*tempb0
            qb(j, k1, 1) = qb(j, k1, 1) - temp*tempb0
            qb(j, k1, nq) = qb(j, k1, nq) + gm1*(q(j, k1, 4)-0.5*temp)*
     +        p1b
            CALL POPREAL8(rho2)
            qb(j, k2, 1) = qb(j, k2, 1) + q(j, k2, nq)*rho2b
            qb(j, k2, nq) = qb(j, k2, nq) + q(j, k2, 1)*rho2b
            CALL POPREAL8(rho1)
            qb(j, k1, 1) = qb(j, k1, 1) + q(j, k1, nq)*rho1b
            qb(j, k1, nq) = qb(j, k1, nq) + q(j, k1, 1)*rho1b
          ENDDO
          CALL BCTANY_BQ(q, qb, uwall, uwallb, vwall, vwallb, xx, xy, yx
     +                   , yy, ug, vg, jd, kd, js, je, ks, ke, idir)
        END IF
      END IF
      END