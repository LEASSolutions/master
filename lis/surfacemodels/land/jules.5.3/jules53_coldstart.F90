!-----------------------BEGIN NOTICE -- DO NOT EDIT-----------------------
! NASA Goddard Space Flight Center
! Land Information System Framework (LISF)
! Version 7.5
!
! Copyright (c) 2024 United States Government as represented by the
! Administrator of the National Aeronautics and Space Administration.
! All Rights Reserved.
!-------------------------END NOTICE -- DO NOT EDIT-----------------------
#include "LIS_misc.h"
!BOP
!
! !ROUTINE: jules53_coldstart
! \label{jules53_coldstart}
!
! !REVISION HISTORY:
! 16 May 2016; Shugong Wang; initial implementation for JULES 4.3
! 01 Feb 2018; Shugong Wang; updated for JULES 5.0 
! 28 Nov 2018; Shugong Wang; updated for JULES 5.2 
! 12 Dec 2018; Shugong Wang; updated for JULES 5.3 
!
! !INTERFACE:
subroutine jules53_coldstart(mtype)
   ! !USES:
   use LIS_coreMod,            only: LIS_rc, LIS_domain, LIS_surface
   use LIS_logMod,             only: LIS_logunit
   use LIS_timeMgrMod,         only: LIS_date2time
   use jules53_lsmMod
   use initial_conditions_mod, only: init_ic
   use init_params_mod,        only: init_params
   use p_s_parms,              only: smvcst_soilt  , &   
                                     smvccl_soilt  , &   
                                     smvcwt_soilt  , &   
                                     bexp_soilt    , &   
                                     sathh_soilt   , &   
                                     hcap_soilt    , &   
                                     hcon_soilt    , &   
                                     satcon_soilt  , &   
                                     sthu_min_soilt, &
                                     albsoil_soilt 
   use prognostics,            only: sice_surft       , &
                                     sliq_surft       , &
                                     snowdepth_surft  , &
                                     tsnow_surft      , &
                                     ds_surft         
   use ancil_info,             only: land_pts, lice_pts, soil_pts,     &
                                     lice_index, soil_index,           &
                                     l_lice_point, l_soil_point,       &
                                     land_mask, frac_surft, surft_pts, &
                                     surft_index

   use top_pdm, only : fexp_soilt,       &
                       ti_mean_soilt, & 
                       ti_sig_soilt 
   use init_parms_mod, only: init_parms 
   use jules_surface_mod,      only: l_aggregate
!
! !DESCRIPTION:
!
!  This routine initializes the jules53 state variables with some
!  predefined values constantly for the entire domain. 
!
!EOP

   implicit none
   integer :: mtype
   integer :: t, n, j, k
   integer :: c, r
   integer :: pft
   integer :: gid, cur_grid, start_k, end_k

   do n=1, LIS_rc%nnest
      if (trim(LIS_rc%startcode) .eq. "coldstart") then
         write(LIS_logunit,*) "MSG: jules53_coldstart -- cold-starting jules53"
         k = 1
         do
            if ( k > LIS_rc%npatch(n,LIS_rc%lsm_index) ) then
               exit
            endif

            ! Find all tiles in current grid
            cur_grid = LIS_surface(n,LIS_rc%lsm_index)%tile(k)%index
            start_k = k
            end_k = jules53_struc(n)%jules53(start_k)%end_k 
            k = end_k + 1
            
            !!! the following code are for packing parameters for a grid   
            frac_surft(1,:)  = 0.0 
            surft_pts(:)     = 0 
            surft_index(1,:) = 0 
            land_mask(1,1)   = .true. 
            
            !deal with un-initialized variables in JULES
            ds_surft(1,1,:)    = 0.0
            sliq_surft(1,1,:)  = 0.0
            sice_surft(1,1,:)  = 0.0
            tsnow_surft(1,1,:) = 0.0  ! unreasonalbe, but try to be the same as offline JULES 
            
            ! start_k is the number ID of the first tile in the grid 
            ! end_k is the number ID of the last tile in the grid
            do t=start_k, end_k
               pft = jules53_struc(n)%jules53(t)%pft 
               jules53_struc(n)%jules53(t)%frac(pft) = LIS_surface(n,LIS_rc%lsm_index)%tile(t)%fgrd 
               jules53_struc(n)%jules53(t)%land_mask = .true.  
               jules53_struc(n)%jules53(t)%z1_tq = jules53_struc(n)%z1_tq
               jules53_struc(n)%jules53(t)%z1_uv = jules53_struc(n)%z1_uv
               
               ! copy soil parameters
               bexp_soilt(1,1,:)   = jules53_struc(n)%jules53(t)%b
               sathh_soilt(1,1,:)  = jules53_struc(n)%jules53(t)%sathh
               satcon_soilt(1,1,:) = jules53_struc(n)%jules53(t)%satcon
               smvcst_soilt(1,1,:) = jules53_struc(n)%jules53(t)%sm_sat
               smvccl_soilt(1,1,:) = jules53_struc(n)%jules53(t)%sm_crit
               smvcwt_soilt(1,1,:) = jules53_struc(n)%jules53(t)%sm_wilt
               hcap_soilt(1,1,:)   = jules53_struc(n)%jules53(t)%hcap
               hcon_soilt(1,1,:)   = jules53_struc(n)%jules53(t)%hcon
               albsoil_soilt(1,1)  = jules53_struc(n)%jules53(t)%albsoil 
               fexp_soilt(1,1)     = jules53_struc(n)%jules53(t)%fexp           ! Decay factor in Sat. Conductivity in water table layer
               ti_mean_soilt(1,1)  = jules53_struc(n)%jules53(t)%ti_mean        ! Mean topographic index
               ti_sig_soilt(1,1)   = jules53_struc(n)%jules53(t)%ti_sig         ! Standard dev. of topographic index
              
               if(l_aggregate) then
                  do j=1, jules53_struc(n)%ntype
                     if(jules53_struc(n)%jules53(t)%surft_frac(j)>0.0) then
                       surft_pts(j)     = 1
                       surft_index(1,j) = 1
                       frac_surft(1,j)  = jules53_struc(n)%jules53(t)%surft_frac(j)
                     endif
                  enddo
               else
                  pft = jules53_struc(n)%jules53(t)%pft
                  surft_pts(pft)     = 1
                  surft_index(1,pft) = 1
                  frac_surft(1, pft) = jules53_struc(n)%jules53(t)%frac(pft)
               endif
            enddo


            ! intialize grid by grid 
            call init_ic(jules53_struc(n)%namelist_dir) 
            call init_params(jules53_struc(n)%namelist_dir)
            call init_parms()

            do t=start_k, end_k
               pft = jules53_struc(n)%jules53(t)%pft 
               call ps_to_tile(n, t, pft)
               call prog_to_tile(n, t, pft)
               call ancil_to_tile(n, t, pft) 
               call trifctl_to_tile(n,t, pft)
               call bvoc_vars_to_tile(n, t, pft)
               call top_pdm_to_tile(n, t, pft)
               call jules_internal_to_tile(n, t, pft) 
               call fluxes_to_tile(n, t, pft) 
            enddo
         enddo
      endif

      LIS_rc%yr = LIS_rc%syr
      LIS_rc%mo = LIS_rc%smo
      LIS_rc%da = LIS_rc%sda
      LIS_rc%hr = LIS_rc%shr
      LIS_rc%mn = LIS_rc%smn
      LIS_rc%ss = LIS_rc%sss

      call LIS_date2time(LIS_rc%time, LIS_rc%doy, LIS_rc%gmt, LIS_rc%yr, &
                         LIS_rc%mo, LIS_rc%da, LIS_rc%hr, LIS_rc%mn, LIS_rc%ss)
      write(LIS_logunit,*) "MSG: jules53_coldstart -- ", &
                           "Using the specified start time ", LIS_rc%time
      write(LIS_logunit,*) "year: ",LIS_rc%yr, " month: ", LIS_rc%mo, &
                           " day: ", LIS_rc%da, " hour: ", LIS_rc%hr 
   enddo
end subroutine jules53_coldstart
