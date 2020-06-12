!################################################################
!################################################################
!################################################################
!################################################################
subroutine make_boundary_hydro(ilevel)
  use amr_commons
  use hydro_commons
  use poisson_parameters
  implicit none
  integer::ilevel
  ! -------------------------------------------------------------------
  ! This routine set up boundary conditions for fine levels.
  ! -------------------------------------------------------------------
  integer::ibound,boundary_dir,idim,inbor=1
  integer::i,ncache,ivar,igrid,ngrid,ind, id, ip
  integer::iskip,iskip_ref,gdim=1,nx_loc,ix,iy,iz
  integer,dimension(1:8)::ind_ref,alt
  integer,dimension(1:nvector),save::ind_grid,ind_grid_ref
  integer,dimension(1:nvector),save::ind_cell,ind_cell_ref

  real(dp)::switch,dx,dx_loc,scale,ekin,d,v,pert
  real(dp),dimension(1:3)::gs,skip_loc
  real(dp),dimension(1:twotondim,1:3)::xc
  real(dp),dimension(1:nvector,1:ndim),save::xx
  real(dp),dimension(1:nvector,1:nvar),save::uu
  real(dp)::poly_gamma, T_T0

  if(.not. simple_boundary)return
  if(verbose)write(*,111)ilevel

  ! Mesh size at level ilevel
  dx=0.5D0**ilevel

  ! Rescaling factors
  nx_loc=(icoarse_max-icoarse_min+1)
  skip_loc=(/0.0d0,0.0d0,0.0d0/)
  if(ndim>0)skip_loc(1)=dble(icoarse_min)
  if(ndim>1)skip_loc(2)=dble(jcoarse_min)
  if(ndim>2)skip_loc(3)=dble(kcoarse_min)
  scale=boxlen/dble(nx_loc)
  dx_loc=dx*scale

  ! Set position of cell centers relative to grid center
  do ind=1,twotondim
     iz=(ind-1)/4
     iy=(ind-1-4*iz)/2
     ix=(ind-1-2*iy-4*iz)
     if(ndim>0)xc(ind,1)=(dble(ix)-0.5D0)*dx
     if(ndim>1)xc(ind,2)=(dble(iy)-0.5D0)*dx
     if(ndim>2)xc(ind,3)=(dble(iz)-0.5D0)*dx
  end do

  ! Loop over boundaries
  do ibound=1,nboundary

     ! Compute direction of reference neighbors
     boundary_dir=boundary_type(ibound)-10*(boundary_type(ibound)/10)
     if(boundary_dir==1)inbor=2
     if(boundary_dir==2)inbor=1
     if(boundary_dir==3)inbor=4
     if(boundary_dir==4)inbor=3
     if(boundary_dir==5)inbor=6
     if(boundary_dir==6)inbor=5

     ! Compute index of reference cells
     ! Reflexive boundary
     if(boundary_type(ibound)== 1)ind_ref(1:8)=(/2,1,4,3,6,5,8,7/)
     if(boundary_type(ibound)== 2)ind_ref(1:8)=(/2,1,4,3,6,5,8,7/)
     if(boundary_type(ibound)== 3)ind_ref(1:8)=(/3,4,1,2,7,8,5,6/)
     if(boundary_type(ibound)== 4)ind_ref(1:8)=(/3,4,1,2,7,8,5,6/)
     if(boundary_type(ibound)== 5)ind_ref(1:8)=(/5,6,7,8,1,2,3,4/)
     if(boundary_type(ibound)== 6)ind_ref(1:8)=(/5,6,7,8,1,2,3,4/)
     ! Free boundary
     if(boundary_type(ibound)==11)ind_ref(1:8)=(/1,1,3,3,5,5,7,7/)
     if(boundary_type(ibound)==12)ind_ref(1:8)=(/2,2,4,4,6,6,8,8/)
     if(boundary_type(ibound)==13)ind_ref(1:8)=(/1,2,1,2,5,6,5,6/)
     if(boundary_type(ibound)==14)ind_ref(1:8)=(/3,4,3,4,7,8,7,8/)
     if(boundary_type(ibound)==15)ind_ref(1:8)=(/1,2,3,4,1,2,3,4/)
     if(boundary_type(ibound)==16)ind_ref(1:8)=(/5,6,7,8,5,6,7,8/)
     ! Imposed boundary (used only for flag1)
     if(boundary_type(ibound)==21)ind_ref(1:8)=(/1,1,3,3,5,5,7,7/)
     if(boundary_type(ibound)==22)ind_ref(1:8)=(/2,2,4,4,6,6,8,8/)
     if(boundary_type(ibound)==23)ind_ref(1:8)=(/1,2,1,2,5,6,5,6/)
     if(boundary_type(ibound)==24)ind_ref(1:8)=(/3,4,3,4,7,8,7,8/)
     if(boundary_type(ibound)==25)ind_ref(1:8)=(/1,2,3,4,1,2,3,4/)
     if(boundary_type(ibound)==26)ind_ref(1:8)=(/5,6,7,8,5,6,7,8/)

     ! Velocity sign switch for reflexive boundary conditions
     gs=(/1,1,1/)
     if(boundary_type(ibound)==1.or.boundary_type(ibound)==2)gs(1)=-1
     if(boundary_type(ibound)==3.or.boundary_type(ibound)==4)gs(2)=-1
     if(boundary_type(ibound)==5.or.boundary_type(ibound)==6)gs(3)=-1

     ! Direction of gravity vector for hydrostatic equilibrium
     if(boundary_dir==1.or.boundary_dir==2)gdim=1
     if(boundary_dir==3.or.boundary_dir==4)gdim=2
     if(boundary_dir==5.or.boundary_dir==6)gdim=3

     ! Altitude for hydrostatic equilibrium
     ! Reflexive boundary
     if(boundary_type(ibound)==1)alt(1:8)=-(/3,1,3,1,3,1,3,1/)
     if(boundary_type(ibound)==2)alt(1:8)=+(/1,3,1,3,1,3,1,3/)
     if(boundary_type(ibound)==3)alt(1:8)=-(/1,1,3,3,1,1,3,3/)
     if(boundary_type(ibound)==4)alt(1:8)=+(/3,3,1,1,3,3,1,1/)
     if(boundary_type(ibound)==5)alt(1:8)=-(/1,1,1,1,3,3,3,3/)
     if(boundary_type(ibound)==6)alt(1:8)=+(/3,3,3,3,1,1,1,1/)
     ! Free boundary
     if(boundary_type(ibound)==11)alt(1:8)=-(/2,1,2,1,2,1,2,1/)
     if(boundary_type(ibound)==12)alt(1:8)=+(/1,2,1,2,1,2,1,2/)
     if(boundary_type(ibound)==13)alt(1:8)=-(/1,1,2,2,1,1,2,2/)
     if(boundary_type(ibound)==14)alt(1:8)=+(/2,2,1,1,2,2,1,1/)
     if(boundary_type(ibound)==15)alt(1:8)=-(/1,1,1,1,2,2,2,2/)
     if(boundary_type(ibound)==16)alt(1:8)=+(/2,2,2,2,1,1,1,1/)

     ! Loop over grids by vector sweeps
     ncache=boundary(ibound,ilevel)%ngrid
     do igrid=1,ncache,nvector
        ngrid=MIN(nvector,ncache-igrid+1)
        do i=1,ngrid
           ind_grid(i)=boundary(ibound,ilevel)%igrid(igrid+i-1)
        end do

        ! Gather neighboring reference grid
        do i=1,ngrid
           ind_grid_ref(i)=son(nbor(ind_grid(i),inbor))
        end do

        ! Loop over cells
        do ind=1,twotondim
           iskip=ncoarse+(ind-1)*ngridmax
           do i=1,ngrid
              ind_cell(i)=iskip+ind_grid(i)
           end do

           ! Gather neighboring reference cell
           iskip_ref=ncoarse+(ind_ref(ind)-1)*ngridmax
           do i=1,ngrid
              ind_cell_ref(i)=iskip_ref+ind_grid_ref(i)
           end do

           ! Wall boundary conditions
           if((boundary_type(ibound)/10).eq.0)then

              ! Gather reference hydro variables
              do ivar=1,nvar
                 do i=1,ngrid
                    uu(i,ivar)=uold(ind_cell_ref(i),ivar)
                 end do
              end do

              ! Scatter to boundary region
              do ivar=1,nvar
                 switch=1
                 if(ivar>1.and.ivar<ndim+2)switch=gs(ivar-1)
                 do i=1,ngrid
                    uold(ind_cell(i),ivar)=uu(i,ivar)*switch
                 end do
              end do

           ! Free boundary conditions
           else if((boundary_type(ibound)/10).eq.1)then

              ! Gather reference hydro variables
              do ivar=1,nvar
                 do i=1,ngrid
                    uu(i,ivar)=uold(ind_cell_ref(i),ivar)
                 end do
              end do

              ! Remove kinetic energy
              do i=1,ngrid
                 ekin = 0d0
                 d    = max(uu(i,1),smallr)
                 do idim=1,ndim
                    v = uu(i,idim+1)/d
                    ekin = ekin+0.5d0*d*v**2
                 end do
                 uu(i,ndim+2) = uu(i,ndim+2)-ekin
              end do

              ! Scatter to boundary region
              do ivar=1,nvar
                 do i=1,ngrid
                    uold(ind_cell(i),ivar)=uu(i,ivar)
                 end do
              end do

              ! Prevent inflow back into the box
              if(no_inflow) then
                 ivar = gdim+1
                 if((boundary_dir.eq.1).or.(boundary_dir.eq.3).or.(boundary_dir.eq.5)) then
                    do i=1,ngrid
                       uold(ind_cell(i),ivar) = min(0d0,uold(ind_cell(i),ivar))
                    end do
                 endif
                 if((boundary_dir.eq.2).or.(boundary_dir.eq.4).or.(boundary_dir.eq.6)) then
                    do i=1,ngrid
                       uold(ind_cell(i),ivar) = max(0d0,uold(ind_cell(i),ivar))
                    end do
                 endif
              endif

              ! Add back kinetic energy
              do i=1,ngrid
                 ekin = 0d0
                 d    = max(uold(ind_cell(i),1),smallr)
                 do idim=1,ndim
                    v = uold(ind_cell(i),idim+1)/d
                    ekin = ekin+0.5d0*d*v**2
                 end do
                 uold(ind_cell(i),ndim+2) = uold(ind_cell(i),ndim+2)+ekin
              end do
              ! -------------------------------------
              ! JRCC --------------------------------

              ! We force hydrostatic equilibrium
              ! with the given polytropic profile
              if(poisson.and.gravity_type==1)then
                !ivar=ndim+2
                id = 1 ! density
                ip = ndim+2 ! pressure

                do i=1,ngrid
                  uu(i,id)=uold(ind_cell_ref(i),id)
                  uu(i,ip)=uold(ind_cell_ref(i),ip)*(gamma-1.0d0) ! Pressure
                end do
                ! set value of poly_gamma based on boundary
                if (ibound==1) then
                  poly_gamma = gamma_region(1)
                else if (ibound==2) then
                  poly_gamma = gamma_region(3)
                end if 

                ! update density in boundaries
                do i=1,ngrid
                  ! ! 1st order approximation
                  ! uold(ind_cell(i),id)= uu(i,id) - &
                  !     & abs(gravity_params(gdim))*uu(i,id)*uu(i,id)*dx_loc*alt(ind)/ &
                  !     & (poly_gamma*uu(i,ip))

                  ! exact solution
                  T_T0 = 1. - ((poly_gamma - 1.0d0)/poly_gamma)* &
                          & abs(gravity_params(gdim))*(uu(i,id)/uu(i,ip))* &
                          & dx_loc*alt(ind)
                  uold(ind_cell(i),id) = uu(i,id)*(T_T0**(1./(poly_gamma-1.0d0)))
                end do

                ! update energy in boundaries
                do i=1,ngrid
                  ! ! 1st order approximation
                  ! uold(ind_cell(i),ip)=uu(i,ip)/(gamma-1.0d0) - &
                  !       & uu(i,id)*abs(gravity_params(gdim))* &
                  !       & dx_loc*alt(ind)/(gamma-1.0d0)

                  ! exact solution
                  T_T0 = 1.d0 - ((poly_gamma - 1.0d0)/poly_gamma)* &
                          & abs(gravity_params(gdim))*(uu(i,id)/uu(i,ip))* &
                          & dx_loc*alt(ind)
                  uold(ind_cell(i), ip) = uu(i,ip)*(T_T0**(poly_gamma/(poly_gamma-1.0d0)))/(gamma-1.0d0)
                end do
                ! -------------------------------------
                ! -------------------------------------
              
              end if


           ! Imposed boundary conditions
           else

              ! Compute cell center in code units
              do idim=1,ndim
                 do i=1,ngrid
                    xx(i,idim)=xg(ind_grid(i),idim)+xc(ind,idim)
                 end do
              end do

              ! Rescale position from code units to user units
              do idim=1,ndim
                 do i=1,ngrid
                    xx(i,idim)=(xx(i,idim)-skip_loc(idim))*scale
                 end do
              end do

              call boundana(xx,uu,dx_loc,ibound,ngrid)

              ! Scatter variables
              do ivar=1,nvar
                 do i=1,ngrid
                    uold(ind_cell(i),ivar)=uu(i,ivar)
                 end do
              end do

           end if

           if(strict_equilibrium>0)then

            ! Compute cell center in code units
            do idim=1,ndim
               do i=1,ngrid
                  xx(i,idim)=xg(ind_grid(i),idim)+xc(ind,idim)
               end do
            end do

            ! Rescale position from code units to user units
            do idim=1,ndim
               do i=1,ngrid
                  xx(i,idim)=(xx(i,idim)-skip_loc(idim))*scale
               end do
            end do
            
            pert=0.0
            call condinit(xx,uu,dx_loc,pert,ngrid)

            ! Scatter variables
            do i=1,ngrid
               rho_eq(ind_cell(i))=uu(i,1)
               p_eq(ind_cell(i))=uu(i,ndim+2)*(gamma-1.0D0)
            end do

          end if      

        end do
        ! End loop over cells

     end do
     ! End loop over grids

  end do
  ! End loop over boundaries

111 format('   Entering make_boundary_hydro for level ',I2)

end subroutine make_boundary_hydro
