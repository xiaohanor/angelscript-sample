class UMagnetDroneAimCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDrone);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneAim);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttached);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileChainJumping);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

    UMagnetDroneComponent DroneComp;
	UMagnetDroneAttractAimComponent AttractAimComp;
	UPlayerAimingComponent PlayerAimingComp;
	UPlayerTargetablesComponent PlayerTargetablesComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
        DroneComp = UMagnetDroneComponent::Get(Player);
		AttractAimComp = UMagnetDroneAttractAimComponent::Get(Player);
		PlayerAimingComp = UPlayerAimingComponent::Get(Player);
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
        if(PlayerAimingComp.IsAiming(AttractAimComp))
            return false;

		if(DroneComp.Settings.bUse2DTargeting)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(DroneComp.Settings.bUse2DTargeting)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
        PlayerAimingComp.StartAiming(AttractAimComp, DroneComp.Settings.AimSettings);
	}

    UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
        PlayerAimingComp.StopAiming(AttractAimComp);
		AttractAimComp.AimVisualProgress = 0;
		AttractAimComp.AimData.Invalidate(n"AimData", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Reset early in the frame
		AttractAimComp.AimVisualProgress = 0;

		FAimingResult AutoAimResult = AttractAimComp.PerformAutoAiming();
		if(AutoAimResult.AutoAimTarget != nullptr)
		{
			auto AutoAimComp = Cast<UMagnetDroneAutoAimComponent>(AutoAimResult.AutoAimTarget);
			AttractAimComp.AimData = FMagnetDroneTargetData::MakeFromAutoAim(AutoAimComp, AutoAimResult.AutoAimTargetPoint);
			if(AttractAimComp.AimData.IsValidTarget())
			{
				AttractAimComp.AimVisualProgress = 1;

				if(AttractAimComp.AimData.IsSurface())
				{
					// If the target is a surface, we must sweep down to find the actual ground, and set a new target point from that
					FHazeTraceSettings TraceSettings = Trace::InitFromPlayer(Player);
					const FVector Normal = AttractAimComp.AimData.GetTargetImpactNormal();
					const FVector Offset = Normal * MagnetDrone::Radius;
					const FVector StartLocation = AttractAimComp.AimData.GetTargetLocation() + Offset;
					const FVector EndLocation = AttractAimComp.AimData.GetTargetLocation() - Offset;
					const FHitResult Hit = TraceSettings.QueryTraceSingle(StartLocation, EndLocation);

					if(Hit.IsValidBlockingHit())
					{
						AttractAimComp.AimData = FMagnetDroneTargetData::MakeFromAutoAim(AutoAimComp, Hit.Location - Offset);
					}
				}

				return;	// We found a valid auto aim target, no need to trace aiming
			}
		}
		else
		{
			UTargetableComponent VisibleTarget;
			FTargetableResult TargetableResult;
			PlayerTargetablesComp.GetMostVisibleTargetAndResult(MagnetDroneTags::MagnetDroneTarget, VisibleTarget, TargetableResult);

			if(VisibleTarget != nullptr)
			{
				AttractAimComp.AimVisualProgress = TargetableResult.VisualProgress;
			}
		}

		AttractAimComp.AimData.Invalidate(n"AimData Failed", this);
	}
}