module sink_feedback_parameters
  use amr_parameters,only:dp,ndim

  ! namelist parameters SINK_FEEDBACK_PARAMS

  logical::sn_feedback_sink = .false. !SN feedback emanates from the sink

  real(dp):: sn_e_ref=1.d51      ! SN energy for forcing by sinks [erg]
  real(dp):: sn_p_ref=4.d43      ! SN momentum [g cm/s]
  real(dp):: sn_mass_ref=2.e33   ! SN mass [g]

  real(dp):: Tsat=1.d99   ! maximum temperature in SN remnants
  real(dp):: Vsat=1.d99   ! maximum velocity in SN remnants
  real(dp):: sn_r_sat=0.  ! minimum radius for SN remnant

  real(dp):: Vdisp=1.     ! dispersion velocity of the stellar objects [km/s] 
                          ! determines how far SN can explode from the sink

  ! Use the supernova module?
  logical::FB_on = .false.

  !series of supernovae specified by "hand"
  ! Number of supernovae (max limit and number active in namelist)
  integer,parameter::NSNMAX=1000
  integer::FB_nsource=0

  ! Feedback start and end times (NOTE: supernova ignores FB_end)
  real(dp),dimension(1:NSNMAX)::FB_start = 1d10
  real(dp),dimension(1:NSNMAX)::FB_end = 1d10
  
  ! Source position in units from 0 to 1
  real(dp),dimension(1:NSNMAX)::FB_pos_x = 0.5d0
  real(dp),dimension(1:NSNMAX)::FB_pos_y = 0.5d0
  real(dp),dimension(1:NSNMAX)::FB_pos_z = 0.5d0

  real(dp),dimension(1:NSNMAX)::FB_mejecta = 1.d0   ! Ejecta mass in solar masses (/year for winds)
  real(dp),dimension(1:NSNMAX)::FB_energy = 1.d51   ! Energy of source in ergs (/year for winds)

  ! Use a thermal dump? (Otherwise add kinetic energy)
  ! Note that if FB_radius is 0 it's thermal anyway
  logical,dimension(1:NSNMAX)::FB_thermal = .false.

  ! Radius to deposit energy inside in number of cells (at highest level)
  real(dp),dimension(1:NSNMAX)::FB_radius = 12d0

  ! Timestep to ensure winds are deposited properly
  ! NOT A USER-SETTABLE PARAMETER
  real(dp),dimension(1:NSNMAX)::FB_dtnew = 0d0


  ! namelist parameters STELLAR_PARAMS

  ! Stellar object related arrays, those parameters are read in  read_stellar_params 
  logical:: sn_direct = .false.        ! explode immediately instead of after lifetime
  character(LEN=100)::stellar_strategy='local' ! local: create stellar particles from each sink
                                               ! global: create when the total mass in sinks exceeds stellar_msink_th
  integer:: nstellarmax ! maximum number of stellar objects
  real(dp):: imf_index, imf_low, imf_high ! power-law IMF model: PDF index, lower and higher mass bounds (Msun)
  real(dp):: lt_t0, lt_m0, lt_a, lt_b ! Stellar lifetime model: t(M) = lt_t0 * exp(lt_a * (log(lt_m0 / M))**lt_b)

!  real(dp):: stf_K, stf_m0, stf_a, stf_b, stf_c 
  ! Stellar ionizing flux model: S(M) = stf_K * (M / stf_m0)**stf_a / (1 + (M / stf_m0)**stf_b)**stf_c
  ! This is a fit from Vacca et al. 1996
  ! Corresponding routine : vaccafit
  real(dp)::stf_K=9.634642584812752d48 ! s**(-1) then normalised in code units in read_stellar
  real(dp)::stf_m0=2.728098824280431d1 ! Msun then normalised in code units in read_stellar
  real(dp)::stf_a=6.840015602892084d0
  real(dp)::stf_b=4.353614230584390d0
  real(dp)::stf_c=1.142166657042991d0 

  !     hii_t: fiducial HII region lifetime, it is normalised in code units in read_stellar 
  real(dp):: hii_t
  real(dp):: stellar_msink_th ! sink mass threshold for stellar object creation (Msun)

  ! Allow users to pre-set stellar mass selection for physics comparison runs, etc
  ! Every time mstellar is added to, instead of a random value, use mstellarini
  integer,parameter::nstellarini=5000
  real(dp),dimension(nstellarini)::mstellarini ! List of stellar masses to use

  ! commons

  ! stellar object arrays
  integer:: nstellar = 0 ! current number of stellar objects
  real(dp), allocatable, dimension(:, :):: xstellar                   ! position
  real(dp), allocatable, dimension(:):: mstellar, tstellar, ltstellar ! mass, birth time, life time
  real(dp), allocatable, dimension(:):: time_remaining                ! time before explosion (for outputting only) 
  integer, allocatable, dimension(:):: id_stellar, idstellar_sort     !the id  of the sink to which it belongs

  ! TODO
  ! Why store position? Where does it explode?
  ! sink_id != position in array if merging=true
  ! take care of stellar particles when sinks are merged!

end module sink_feedback_parameters

