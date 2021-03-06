C        Generated by TAPENADE     (INRIA, Tropics team)
C  Tapenade 3.6 (r4343) - 10 Feb 2012 10:52
C
C  Differentiation of tridag in reverse (adjoint) mode:
C   gradient     of useful results: f z
C   with respect to varying inputs: f z
C
C***********************************************************************
      SUBROUTINE TRIDAG_BQ(a, b, c, f, fb, z, zb, ni, nl)
      IMPLICIT NONE
C***********************************************************************
      INTEGER jd, ni, nl
      PARAMETER (jd=1001)
C local variables
      REAL a(jd), b(jd), c(jd), f(jd), z(jd)
      REAL fb(jd), zb(jd)
C
      REAL w(jd), g(jd)
      REAL gb(jd)
C
      INTEGER nipl, j, nd, j1
      REAL d, rd
      INTEGER ii1
C
C
      w(ni) = c(ni)/b(ni)
      nipl = ni + 1
      DO j=nipl,nl
        d = b(j) - a(j)*w(j-1)
        CALL PUSHREAL8(rd)
        rd = 1.0/d
        w(j) = c(j)*rd
      ENDDO
      nd = nl - ni
      DO ii1=1,jd
        gb(ii1) = 0.0
      ENDDO
      DO j1=nd,1,-1
        j = nl - j1
        gb(j) = gb(j) + zb(j)
        zb(j+1) = zb(j+1) - w(j)*zb(j)
        zb(j) = 0.0
      ENDDO
      gb(nl) = gb(nl) + zb(nl)
      zb(nl) = 0.0
      DO j=nl,nipl,-1
        fb(j) = fb(j) + rd*gb(j)
        gb(j-1) = gb(j-1) - rd*a(j)*gb(j)
        gb(j) = 0.0
        CALL POPREAL8(rd)
      ENDDO
      fb(ni) = fb(ni) + gb(ni)/b(ni)
      END
