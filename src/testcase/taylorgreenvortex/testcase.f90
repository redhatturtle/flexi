!=================================================================================================================================
! Copyright (c) 2010-2016  Prof. Claus-Dieter Munz 
! This file is part of FLEXI, a high-order accurate framework for numerically solving PDEs with discontinuous Galerkin methods.
! For more information see https://www.flexi-project.org and https://nrg.iag.uni-stuttgart.de/
!
! FLEXI is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
! as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
!
! FLEXI is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
! of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License v3.0 for more details.
!
! You should have received a copy of the GNU General Public License along with FLEXI. If not, see <http://www.gnu.org/licenses/>.
!=================================================================================================================================
#include "flexi.h"

#if FV_ENABLED
#error "This testcase is not tested with FV"
#endif

!==================================================================================================================================
!> Subroutines defining the Taylor-Green isentropic vortex testcase
!==================================================================================================================================
MODULE MOD_Testcase
! MODULES
IMPLICIT NONE
PRIVATE
!----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES

INTERFACE DefineParametersTestcase
  MODULE PROCEDURE DefineParametersTestcase
End INTERFACE

INTERFACE InitTestcase
  MODULE PROCEDURE InitTestcase
END INTERFACE

INTERFACE FinalizeTestcase
  MODULE PROCEDURE FinalizeTestcase
END INTERFACE

INTERFACE ExactFuncTestcase
  MODULE PROCEDURE ExactFuncTestcase
END INTERFACE

INTERFACE CalcForcing
  MODULE PROCEDURE DO_NOTHING
END INTERFACE

!INTERFACE TestcaseSource
!  MODULE PROCEDURE TestcaseSource
!END INTERFACE

INTERFACE AnalyzeTestCase
  MODULE PROCEDURE AnalyzeTestCase
END INTERFACE

INTERFACE GetBoundaryFluxTestcase
  MODULE PROCEDURE GetBoundaryFluxTestcase
END INTERFACE

INTERFACE GetBoundaryFVgradientTestcase
  MODULE PROCEDURE GetBoundaryFVgradientTestcase
END INTERFACE

INTERFACE Lifting_GetBoundaryFluxTestcase
  MODULE PROCEDURE Lifting_GetBoundaryFluxTestcase
END INTERFACE

PUBLIC:: DefineParametersTestcase
PUBLIC:: InitTestcase
PUBLIC:: FinalizeTestcase
PUBLIC:: ExactFuncTestcase
PUBLIC:: TestcaseSource
PUBLIC:: CalcForcing
PUBLIC:: AnalyzeTestCase
PUBLIC:: GetBoundaryFluxTestcase
PUBLIC:: GetBoundaryFVgradientTestcase
PUBLIC:: Lifting_GetBoundaryFluxTestcase

CONTAINS

!==================================================================================================================================
!> Define parameters
!==================================================================================================================================
SUBROUTINE DefineParametersTestcase()
! MODULES
USE MOD_Globals
USE MOD_ReadInTools ,ONLY: prms
IMPLICIT NONE
!==================================================================================================================================
CALL prms%SetSection("Testcase")
CALL prms%CreateIntOption('nWriteStats', "Write testcase statistics to file at every n-th AnalyzeTestcase step.", '100')
CALL prms%CreateIntOption('nAnalyzeTestCase', "Call testcase specific analysis routines every n-th timestep. "//&
                                              "(Note: always called at global analyze level)", '10')
END SUBROUTINE DefineParametersTestcase


!==================================================================================================================================
!> Initialize testcase variables
!==================================================================================================================================
SUBROUTINE InitTestcase()
! MODULES
USE MOD_Globals
USE MOD_ReadInTools,    ONLY: GETINT
USE MOD_Output_Vars,    ONLY: ProjectName
USE MOD_TestCase_Vars
USE MOD_Output,         ONLY: InitOutputToFile
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
CHARACTER(LEN=31)        :: varnames(nTGVVars)
!==================================================================================================================================
SWRITE(UNIT_StdOut,'(132("-"))')
SWRITE(UNIT_stdOut,'(A)') ' INIT TESTCASE TAYLOR-GREEN VORTEX...'

#if FV_ENABLED
CALL CollectiveStop(__STAMP__, &
  'The testcase has not been implemented for FV yet!')
#endif

! Length of Buffer for TGV output
nWriteStats      = GETINT( 'nWriteStats','100')
nAnalyzeTestCase = GETINT( 'nAnalyzeTestCase','10')

IF(MPIRoot)THEN
  ALLOCATE(Time(nWriteStats))
  ALLOCATE(writeBuf(nTGVvars,nWriteStats))
  Filename = TRIM(ProjectName)//'_TGVAnalysis'

  varnames(1) ="Dissipation Rate Incompressible"
  varnames(2) ="Dissipation Rate Compressible"
  varnames(3) ="Ekin incomp"
  varnames(4) ="Ekin comp"
  varnames(5) ="Enstrophy comp"
  varnames(6) ="DR_u"
  varnames(7) ="DR_S"
  varnames(8) ="DR_Sd"
  varnames(9) ="DR_p"
  varnames(10)="Maximum Vorticity"
  varnames(11)="Mean Temperature"
  varnames(12)="uprime"
  CALL InitOutputToFile(FileName,'Taylor-Green Vortex Analysis Data',nTGVVars,varnames)
END IF

SWRITE(UNIT_stdOut,'(A)')' INIT TESTCASE TAYLOR-GREEN VORTEX DONE!'
SWRITE(UNIT_StdOut,'(132("-"))')
END SUBROUTINE InitTestcase


!==================================================================================================================================
!> Specifies all the initial conditions.
!==================================================================================================================================
SUBROUTINE ExactFuncTestcase(tIn,x,Resu,Resu_t,Resu_tt)
! MODULES
USE MOD_Globals,      ONLY: Abort
USE MOD_EOS_Vars,     ONLY: kappa
USE MOD_EOS,          ONLY: PrimToCons
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
REAL,INTENT(IN)                 :: x(3)        !< position in physical coordinates
REAL,INTENT(IN)                 :: tIn         !< current simulation time
REAL,INTENT(OUT)                :: Resu(5)     !< exact fuction evaluated at tIn, returning state in conservative variables
REAL,INTENT(OUT)                :: Resu_t(5)   !< first time deriv of exact fuction
REAL,INTENT(OUT)                :: Resu_tt(5)  !< second time deriv of exact fuction
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
REAL                            :: A,Ms,prim(PP_nVarPrim)
!==================================================================================================================================
A=1.    ! magnitude of speed
Ms=0.1  ! maximum Mach number
prim(1)=1.
prim(2)= A*SIN(x(1))*COS(x(2))*COS(x(3))
prim(3)=-A*COS(x(1))*SIN(x(2))*COS(x(3))
prim(4)=0.
prim(5)=(A/Ms*A/Ms/Kappa*prim(1))  ! scaling to get Ms
prim(5)=prim(5)+1./16.*A*A*prim(1)*(COS(2*x(1))*COS(2.*x(3)) + 2.*COS(2.*x(2)) +2.*COS(2.*x(1)) +COS(2*x(2))*COS(2.*x(3)))
prim(6)=0. ! T does not matter for prim to cons
CALL PrimToCons(prim,Resu)
Resu_t =0.
Resu_tt=0.
END SUBROUTINE ExactFuncTestcase


!==================================================================================================================================
!> Add testcases source term to solution time derivative
!==================================================================================================================================
SUBROUTINE TestcaseSource(Ut)
! MODULES
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
REAL,DIMENSION(*),INTENT(IN) :: Ut                        !< solution time derivative
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!==================================================================================================================================
END SUBROUTINE TestcaseSource


!==================================================================================================================================
!> Perform TGV-specific analysis: compute dissipation rates, kinetic energy and enstrophy
!==================================================================================================================================
SUBROUTINE AnalyzeTestcase(t)
! MODULES
USE MOD_PreProc
USE MOD_Globals
USE MOD_TestCase_Vars
USE MOD_DG_Vars,        ONLY: U
USE MOD_Lifting_Vars,   ONLY: GradUx,GradUy,GradUz
USE MOD_Analyze_Vars,   ONLY: NAnalyze,Vdm_GaussN_NAnalyze,wGPVolAnalyze
USE MOD_EOS_Vars,       ONLY: KappaM1,mu0,R
USE MOD_Mesh_Vars,      ONLY: sJ
USE MOD_ChangeBasis,    ONLY: ChangeBasis3D
USE MOD_Mesh_Vars,      ONLY: nElems
#if USE_MPI
USE MOD_MPI_Vars
#endif
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
REAL,INTENT(IN)                 :: t                      !< simulation time
!----------------------------------------------------------------------------------------------------------------------------------
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                         :: ii,i,j,k,p,q
REAL                            :: Vel(1:3),GradVel(1:3,1:3),Volume,Ekin,uprime
REAL                            :: U_NAnalyze(1:PP_nVar, 0:NAnalyze, 0:NAnalyze, 0:NAnalyze)
REAL                            :: sJ_NAnalyze(1, 0:NAnalyze, 0:NAnalyze, 0:NAnalyze)
REAL                            :: GradUx_NAnalyze(1:PP_nVar, 0:NAnalyze, 0:NAnalyze, 0:NAnalyze)
REAL                            :: GradUy_NAnalyze(1:PP_nVar, 0:NAnalyze, 0:NAnalyze, 0:NAnalyze)
REAL                            :: GradUz_NAnalyze(1:PP_nVar, 0:NAnalyze, 0:NAnalyze, 0:NAnalyze)
REAL                            :: Vorticity(1:3),max_Vorticity,mean_temperature, temperature
!REAL                            :: lambda,nu,tnu,Rlambda
REAL                            :: S(1:3,1:3)                    ! Strain rate tensor S (symmetric)
REAL                            :: Sd(1:3,1:3)                   ! Deviatoric part of the strain rate tensor S
REAL                            :: divU                          ! Divergence of velocity vector
REAL                            :: E,E_comp                      ! Integrands: 0.5*v*v, 0.5*rho*v*v
REAL                            :: ens                           ! Integrand: 0.5*rho*omega*omega
REAL                            :: eps3                          ! Integrand: p*(div u)
REAL                            :: u_tens, s_tens, sd_tens       ! matrix : matrix product, integrands of Gradvel, S, Sd
REAL                            :: Intfactor                     ! Integrationweights and Jacobian
REAL                            :: Ekin_comp,Enstrophy_comp
REAL                            :: DR_u,DR_S,DR_Sd,DR_p           ! Contributions to dissipation rate
REAL                            :: Pressure,rho0
#if USE_MPI
REAL                            :: DR_u_Glob,Volume_Glob,Ekin_glob,max_Vorticity_glob,mean_temperature_glob,DR_S_glob
REAL                            :: DR_Sd_Glob,DR_p_Glob,Enstrophy_comp_glob,Ekin_comp_glob
#  endif
REAL                            :: sJ_N(1, 0:PP_N, 0:PP_N, 0:PP_N) ! local array for sJ
!==================================================================================================================================
Volume=0.
Ekin=0.
Ekin_comp=0.
Enstrophy_comp=0.

DR_u=0.;DR_S=0.;DR_Sd=0.;DR_p=0.
max_Vorticity=-1.
mean_Temperature=0.

DO ii=1,nElems

  !Interpolate the gradient of the velocity to the analyze grid
  CALL ChangeBasis3D(PP_nVar, PP_N, NAnalyze, Vdm_GaussN_NAnalyze, GradUx(1:PP_nVar,:,:,:,ii), GradUx_NAnalyze(1:PP_nVar,:,:,:))
  CALL ChangeBasis3D(PP_nVar, PP_N, NAnalyze, Vdm_GaussN_NAnalyze, GradUy(1:PP_nVar,:,:,:,ii), GradUy_NAnalyze(1:PP_nVar,:,:,:))
  CALL ChangeBasis3D(PP_nVar, PP_N, NAnalyze, Vdm_GaussN_NAnalyze, GradUz(1:PP_nVar,:,:,:,ii), GradUz_NAnalyze(1:PP_nVar,:,:,:))
  !Interpolate the jacobian to the analyze grid
  sJ_N(1,:,:,:)=sJ(:,:,:,ii,0)
  CALL ChangeBasis3D(1, PP_N, NAnalyze, Vdm_GaussN_NAnalyze, sJ_N(1:1,0:PP_N,0:PP_N,0:PP_N), sJ_NAnalyze(1:1,:,:,:))
  !Interpolate the solution to the analyze grid
  CALL ChangeBasis3D(PP_nVar, PP_N, NAnalyze, Vdm_GaussN_NAnalyze, U(1:PP_nVar,:,:,:,ii), U_NAnalyze(1:PP_nVar,:,:,:))

  DO k=0,NAnalyze
    DO j=0,NAnalyze
      DO i=0,NAnalyze
        ! compute primitive gradients (of u,v,w) at each GP
        Vel(1:3)=U_NAnalyze(2:4,i,j,k)/U_NAnalyze(1,i,j,k)
        GradVel(:,1)=1./(U_NAnalyze(1,i,j,k))*(GradUx_NAnalyze(2:4,i,j,k)-Vel(1:3)*GradUx_NAnalyze(1,i,j,k))
        GradVel(:,2)=1./(U_NAnalyze(1,i,j,k))*(GradUy_NAnalyze(2:4,i,j,k)-Vel(1:3)*GradUy_NAnalyze(1,i,j,k))
        GradVel(:,3)=1./(U_NAnalyze(1,i,j,k))*(GradUz_NAnalyze(2:4,i,j,k)-Vel(1:3)*GradUz_NAnalyze(1,i,j,k))
        ! Pressure
        Pressure=KappaM1*(U_NAnalyze(5,i,j,k)-0.5*SUM(U_NAnalyze(2:4,i,j,k)*Vel(1:3)))
        ! compute divergence of velocity
        divU=GradVel(1,1)+GradVel(2,2)+GradVel(3,3)
        ! compute tensor of velocity gradients
        S=0.5*(Gradvel+TRANSPOSE(GradVel))
        ! deviatoric part of strain tensor
        Sd=S
        DO p=1,3
          Sd(p,p)=Sd(p,p)-1./3.*divU
        END DO
        ! compute kinetic energy integrand (incomp)
        E=0.5*SUM(Vel(1:3)*Vel(1:3))
        ! compute kinetic energy integrand (compr)
        E_comp=U_NAnalyze(1,i,j,k)*E
        ! compute vorticity and max(vorticity)
        Vorticity(1)=GradVel(3,2) - GradVel(2,3)
        Vorticity(2)=GradVel(1,3) - GradVel(3,1)
        Vorticity(3)=GradVel(2,1) - GradVel(1,2)
        max_Vorticity=MAX(max_Vorticity,SQRT(SUM(Vorticity(:)*Vorticity(:))))
        ! compute enstrophy integrand
        ens=0.5*U_NAnalyze(1,i,j,k)*SUM(Vorticity(1:3)*Vorticity(1:3))
        ! compute integrand for epsilon3, pressure contribution to dissipation (compressiblity effect)
        eps3=Pressure*divU
        ! Matrix : Matrix product for velocity gradient tensor, S:S and Sd:Sd
        u_tens=0.;s_tens=0.;sd_tens=0.
        DO p=1,3
          DO q=1,3
            u_tens=u_tens+GradVel(p,q)*GradVel(p,q)
            s_tens=s_tens+S(p,q)*S(p,q)
            sd_tens=sd_tens+Sd(p,q)*Sd(p,q)
          END DO
        END DO
        Intfactor=wGPVolAnalyze(i,j,k)/sJ_NAnalyze(1,i,j,k)
        ! compute cell volume (total volumen of domain on proc)
        Volume=Volume+Intfactor
        ! compute integrals:
          ! Kinetic Energy incompressible
        Ekin=Ekin+E*Intfactor
          ! Kinetic Energy compressible
        Ekin_comp=Ekin_comp+E_comp*IntFactor
          ! Enstrophy compressible
        Enstrophy_comp=Enstrophy_comp+ens*IntFactor
          ! dissipation rate epsilon incomp from velocity gradient tensor (Diss Fauconnier)
        DR_u=DR_u+u_tens*IntFactor
          ! dissipation rate epsilon incomp from strain rate tensor (incomp) (Sagaut)
        DR_S=DR_S+S_tens*IntFactor
          ! dissipation rate epsilon 1 from deviatoric part of strain rate tensor Sd (compressible)
        DR_SD=DR_SD+sd_tens*Intfactor
          ! dissipation rate epsilon 3 from pressure times div u (compressible)
        DR_p=DR_p+eps3*Intfactor

        ! compute mean temperature
        Temperature=KappaM1/R*(U_NAnalyze(5,i,j,k)/U_NAnalyze(1,i,j,k)-E)
        mean_temperature=mean_temperature+Temperature*Intfactor
      END DO
    END DO
  END DO
END DO

#if USE_MPI
! MPI case: globalize Volume, Dissipation Rate and Kinetic Energy
! maximum of vorticity
CALL MPI_REDUCE(max_Vorticity,max_vorticity_Glob,1,MPI_DOUBLE_PRECISION,MPI_MAX,0,MPI_COMM_WORLD,iError)
! add volume of domain on all procs
CALL MPI_REDUCE(Volume,Volume_Glob,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,MPI_COMM_WORLD,iError)
! add Dissrates on all procs
CALL MPI_REDUCE(DR_u,DR_u_Glob,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,MPI_COMM_WORLD,iError)
CALL MPI_REDUCE(DR_S,DR_S_Glob,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,MPI_COMM_WORLD,iError)
CALL MPI_REDUCE(DR_Sd,DR_Sd_Glob,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,MPI_COMM_WORLD,iError)
CALL MPI_REDUCE(DR_p,DR_p_Glob,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,MPI_COMM_WORLD,iError)
CALL MPI_REDUCE(Ekin,Ekin_Glob,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,MPI_COMM_WORLD,iError)
CALL MPI_REDUCE(Ekin_comp,Ekin_comp_Glob,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,MPI_COMM_WORLD,iError)
CALL MPI_REDUCE(Enstrophy_comp,Enstrophy_comp_Glob,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,MPI_COMM_WORLD,iError)
CALL MPI_REDUCE(mean_temperature,mean_temperature_Glob,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,MPI_COMM_WORLD,iError)
Volume=Volume_Glob
DR_u=DR_u_Glob
DR_S=DR_S_Glob
DR_Sd=DR_SD_Glob
DR_p=DR_p_Glob
Ekin=Ekin_Glob
Ekin_comp=Ekin_comp_Glob
Enstrophy_comp=Enstrophy_comp_glob
max_Vorticity=max_Vorticity_glob
mean_temperature=mean_temperature_Glob
IF(.NOT.MPIRoot) RETURN
#  endif

! some turbulent quantities
uprime=SQRT(Ekin/Volume*2./3.)
! for TGV = nu = mu, since rho = 1 = const
!lambda=SQRT(15*mu0*uprime**2/(DR_u*mu0/(Volume)))
!nu=(mu0**3./((DR_u*mu0/Volume)))**0.25
!tnu=SQRT(mu0/(DR_u*mu0/Volume))
!Rlambda=uprime*lambda/mu0

! now do the normalization of integrals
! warning, rho0=1 for the TGV runs, not in general case!
rho0=1.
Ekin=Ekin/Volume
Ekin_comp=Ekin_comp/(rho0*Volume)

Enstrophy_comp=Enstrophy_comp/(rho0*Volume)

DR_u=DR_u*mu0/Volume
DR_S=DR_S*2.*mu0/(rho0*Volume)
DR_SD=DR_SD*2.*mu0/(rho0*Volume)
DR_p=-DR_p/(rho0*Volume)

mean_temperature=mean_temperature/Volume

IF(MPIRoot)THEN
  ioCounter=ioCounter+1
  Time(ioCounter)                = t
  writeBuf(1:nTGVvars,ioCounter) = (/DR_S,DR_Sd+DR_p,Ekin,Ekin_comp,Enstrophy_comp,DR_u,DR_S,DR_Sd,DR_p,&
                                     max_Vorticity,mean_temperature,uprime/)
  IF(ioCounter.EQ.nWriteStats)THEN
    CALL WriteStats()
    ioCounter=0
  END IF
END IF

END SUBROUTINE AnalyzeTestCase


!==================================================================================================================================
!> Write TGV Analysis Data to File
!==================================================================================================================================
SUBROUTINE WriteStats()
! MODULES
USE MOD_TestCase_Vars
USE MOD_Output,        ONLY: OutputToFile
IMPLICIT NONE
!==================================================================================================================================
CALL OutputToFile(FileName,Time(1:ioCounter),(/nTGVvars,ioCounter/),&
                           RESHAPE(writeBuf(:,1:ioCounter),(/nTGVVars*ioCounter/)))
END SUBROUTINE WriteStats


!==================================================================================================================================
!> Flushes Buffer to File, Deallocation
!==================================================================================================================================
SUBROUTINE FinalizeTestcase()
! MODULES
USE MOD_Globals      ,ONLY:MPIRoot
USE MOD_TestCase_Vars,ONLY:writeBuf,Time
IMPLICIT NONE
!==================================================================================================================================
IF(MPIRoot)THEN
  CALL WriteStats()
  DEALLOCATE(Time)
  DEALLOCATE(writeBuf)
END IF
END SUBROUTINE


SUBROUTINE DO_NOTHING(optionalREAL,optionalREAL2)
IMPLICIT NONE
REAL, OPTIONAL,INTENT(IN) :: optionalREAL,optionalREAL2
END SUBROUTINE DO_NOTHING


SUBROUTINE GetBoundaryFluxTestcase(SideID,t,Nloc,Flux,UPrim_master,                   &
#if PARABOLIC
                           gradUx_master,gradUy_master,gradUz_master,&
#endif
                           NormVec,TangVec1,TangVec2,Face_xGP)
! MODULES
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT / OUTPUT VARIABLES
INTEGER,INTENT(IN)   :: SideID  
REAL,INTENT(IN)      :: t       !< current time (provided by time integration scheme)
INTEGER,INTENT(IN)   :: Nloc    !< polynomial degree
REAL,INTENT(IN)      :: UPrim_master( PP_nVarPrim,0:Nloc,0:Nloc) !< inner surface solution
#if PARABOLIC
                                                           !> inner surface solution gradients in x/y/z-direction
REAL,INTENT(IN)      :: gradUx_master(PP_nVarPrim,0:Nloc,0:Nloc)
REAL,INTENT(IN)      :: gradUy_master(PP_nVarPrim,0:Nloc,0:Nloc)
REAL,INTENT(IN)      :: gradUz_master(PP_nVarPrim,0:Nloc,0:Nloc)
#endif /*PARABOLIC*/
                                                           !> normal and tangential vectors on surfaces
REAL,INTENT(IN)      :: NormVec (3,0:Nloc,0:Nloc)
REAL,INTENT(IN)      :: TangVec1(3,0:Nloc,0:Nloc)
REAL,INTENT(IN)      :: TangVec2(3,0:Nloc,0:Nloc)
REAL,INTENT(IN)      :: Face_xGP(3,0:Nloc,0:Nloc)    !< positions of surface flux points
REAL,INTENT(OUT)     :: Flux(PP_nVar,0:Nloc,0:Nloc)  !< resulting boundary fluxes
!==================================================================================================================================
END SUBROUTINE GetBoundaryFluxTestcase


SUBROUTINE GetBoundaryFVgradientTestcase(SideID,t,gradU,UPrim_master)
USE MOD_PreProc
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT / OUTPUT VARIABLES
INTEGER,INTENT(IN) :: SideID
REAL,INTENT(IN)    :: t                                       !< current time (provided by time integration scheme)
REAL,INTENT(IN)    :: UPrim_master(PP_nVarPrim,0:PP_N,0:PP_N) !< primitive solution from the inside
REAL,INTENT(OUT)   :: gradU       (PP_nVarPrim,0:PP_N,0:PP_N) !< FV boundary gradient
!==================================================================================================================================
END SUBROUTINE GetBoundaryFVgradientTestcase


SUBROUTINE Lifting_GetBoundaryFluxTestcase(SideID,t,UPrim_master,Flux)
USE MOD_PreProc
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT / OUTPUT VARIABLES
INTEGER,INTENT(IN) :: SideID
REAL,INTENT(IN)    :: t                                       !< current time (provided by time integration scheme)
REAL,INTENT(IN)    :: UPrim_master(PP_nVarPrim,0:PP_N,0:PP_N) !< primitive solution from the inside
REAL,INTENT(OUT)   :: Flux(        PP_nVarPrim,0:PP_N,0:PP_N) !< lifting boundary flux
!==================================================================================================================================
END SUBROUTINE Lifting_GetBoundaryFluxTestcase

END MODULE MOD_Testcase

