!-----------------------BEGIN NOTICE -- DO NOT EDIT-----------------------
! NASA Goddard Space Flight Center
! Land Information System Framework (LISF)
! Version 7.5
!
! Copyright (c) 2024 United States Government as represented by the
! Administrator of the National Aeronautics and Space Administration.
! All Rights Reserved.
!-------------------------END NOTICE -- DO NOT EDIT-----------------------
!BOP
! !ROUTINE: noah39_descale_snodep
! \label{noah39_descale_snodep}
!
! !REVISION HISTORY:
! 27Feb2005: Sujay Kumar; Initial Specification
! 25Jun2006: Sujay Kumar: Updated for the ESMF design
!  02 Mar 2010: Sujay Kumar; Modified for Noah 3.1
!  16 Apr 2019: Eric Kemp; Modified for Noah 3.9
!
! !INTERFACE:
subroutine noah39_descale_snodep(n, LSM_State, LSM_Incr_State)

! !USES:
  use ESMF
  use noah39_lsmMod

  implicit none
! !ARGUMENTS: 
  integer, intent(in)    :: n
  type(ESMF_State)       :: LSM_State
  type(ESMF_State)       :: LSM_Incr_State
!
! !DESCRIPTION:
!
!  Returns the snow related state prognostic variables for
!  data assimilation
! 
!  The arguments are: 
!  \begin{description}
!  \item[n] index of the nest \newline
!  \item[LSM\_State] ESMF State container for LSM state variables \newline
!  \end{description}
!EOP

end subroutine noah39_descale_snodep

