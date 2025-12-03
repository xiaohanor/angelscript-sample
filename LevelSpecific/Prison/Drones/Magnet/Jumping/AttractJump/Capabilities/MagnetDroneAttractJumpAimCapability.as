struct FMagnetDroneAttractJumpAimDeactivateParams
{
	bool bDetached = false;
};

class UMagnetDroneAttractJumpAimCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttraction);

	default TickGroup = MagnetDrone::StartAttractTickGroup;
	default TickGroupOrder = MagnetDrone::StartAttractTickGroupOrder;
	default TickGroupSubPlacement = 60;

	UMagnetDroneComponent DroneComp;
	UMagnetDroneAttractJumpComponent AttractJumpComp;
	UMagnetDroneAttractAimComponent AttractAimComp;
	UMagnetDroneAttachedComponent AttachedComp;
	UPlayerMovementComponent MoveComp;
	UPlayerAimingComponent PlayerAimingComp;
	//UPlayerTargetablesComponent TargetablesComp;

	FMagnetDroneTargetData SweepTargetData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UMagnetDroneComponent::Get(Player);
		AttractJumpComp = UMagnetDroneAttractJumpComponent::Get(Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		PlayerAimingComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!DroneComp.Settings.bAllowJumpingWhileMagneticallyAttached)
			return false;

		if(!DroneComp.Settings.bAttractWhenJumpingFromMagneticSurfaces)
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!AttachedComp.IsAttached())
			return false;

		if(AttachedComp.AttachedData.IsSurface())
		{
			if(!MoveComp.IsOnAnyGround())
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FMagnetDroneAttractJumpAimDeactivateParams& Params) const
	{
		if(!AttachedComp.IsAttached())
		{
			Params.bDetached = true;
			return true;
		}

		if(AttachedComp.AttachedData.IsSurface())
		{
			if(!MoveComp.IsOnAnyGround())
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
        PlayerAimingComp.StartAiming(AttractJumpComp, DroneComp.Settings.AimSettings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FMagnetDroneAttractJumpAimDeactivateParams Params)
	{
        PlayerAimingComp.StopAiming(AttractJumpComp);

		if(!Params.bDetached)
		{
			// If we did not detach, invalidate immediately
			// If we detached, let PreTick invalidate the jump aim data after a short duration
			AttractJumpComp.JumpAimData.Invalidate(n"JumpAimData", this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!IsActive() && DeactiveDuration > MagnetDrone::JumpAttractBufferTime && AttractJumpComp.JumpAimData.IsValidTarget())
		{
			// Wait a while with invalidating the jump aim data, allowing the magnet drone to use it
			InvalidateJumpAimData();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			if(!ensure(AttachedComp.AttachedData.IsValid()))
				return;
		}
		else
		{
			if(!AttachedComp.AttachedData.IsValid())
				return;
		}
		
		AttractJumpComp.JumpAimData = GetJumpAimData();
	}

	FMagnetDroneTargetData GetJumpAimData() const
	{
		// Try to find a surface to jump to
		const FHitResult Hit = SweepForSurface();
		if(MagnetDrone::IsHitMagnetic(Hit, false))
		{
			// Ignore sockets, since we want to get those with aiming instead
			FMagnetDroneTargetData SurfaceAimData = FMagnetDroneTargetData::MakeFromHit(Hit, false, true);
			if(SurfaceAimData.IsValidTarget())
				return SurfaceAimData;
		}

		// Find a socket to jump to
		FMagnetDroneTargetData SocketAimData = GetSocketAimData();
		if(SocketAimData.IsValidTarget())
			return SocketAimData;

		return FMagnetDroneTargetData();
	}

	FHitResult SweepForSurface() const
	{
		const FVector GroundNormal = AttractJumpComp.GetJumpDirection();

		if(GroundNormal.IsNearlyZero())
			return FHitResult();

		FHitResult Hit;

		if(AttachedComp.AttachedData.CanAttach())
		{
			UDroneMagneticSurfaceComponent SurfaceComp = AttachedComp.AttachedData.GetSurfaceComp();
			if(SurfaceComp != nullptr && SurfaceComp.bAttractJumpInheritVelocity)
			{
				FVector InheritVelocityDirection = GroundNormal;
				const FVector VelocityDirection = MoveComp.Velocity / AttachedComp.Settings.MaxHorizontalSpeed;
				InheritVelocityDirection += VelocityDirection * SurfaceComp.AttractJumpInheritVelocityFactor;
				InheritVelocityDirection.Normalize();
				const FVector End = Player.ActorLocation + InheritVelocityDirection * DroneComp.Settings.AttractWhenJumpingFromMagneticSurfacesDistance;

				FHazeTraceSettings TraceSettings = Trace::InitFromPlayer(Player, n"AttractJumpVelocityDir");
				Hit = TraceSettings.QueryTraceSingle(Player.ActorLocation, End);

#if !RELEASE
				TEMPORAL_LOG(AttractJumpComp).HitResults("AttractJumpVelocityDir", Hit, TraceSettings.Shape, TraceSettings.ShapeWorldOffset);
#endif

				if(Hit.IsValidBlockingHit())
					return Hit;
			}
		}

		const FVector End = Player.ActorLocation + GroundNormal * DroneComp.Settings.AttractWhenJumpingFromMagneticSurfacesDistance;
		TArray<AActor> IgnoredActors;
		if(AttachedComp.AttachedData.CanAttach() && AttachedComp.AttachedData.IsSocket())
			IgnoredActors.Add(AttachedComp.AttachedData.GetSocketComp().Owner);
		
		FHazeTraceSettings TraceSettings = Trace::InitFromPlayer(Player, n"AttractJump");
		TraceSettings.IgnoreActors(IgnoredActors);
		TraceSettings.TraceWithChannel(ECollisionChannel::PlayerAiming);
		Hit = TraceSettings.QueryTraceSingle(Player.ActorLocation, End);

#if !RELEASE
			TEMPORAL_LOG(AttractJumpComp).HitResults("AttractJump", Hit, TraceSettings.Shape, TraceSettings.ShapeWorldOffset);
#endif

		return Hit;
	}

	FMagnetDroneTargetData GetSocketAimData() const
	{
		FAimingResult AimResult = PlayerAimingComp.GetAimingTarget(AttractJumpComp);
		if(AimResult.AutoAimTarget == nullptr)
			return FMagnetDroneTargetData();

		return FMagnetDroneTargetData::MakeFromAutoAim(Cast<UDroneMagneticSocketComponent>(AimResult.AutoAimTarget), AimResult.AutoAimTargetPoint);
	}

	void InvalidateJumpAimData()
	{
		AttractJumpComp.JumpAimData.Invalidate(n"JumpAimData", this);
	}
}