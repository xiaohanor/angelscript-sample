class UMagnetDroneTopDownAimCapability : UHazePlayerCapability
{
	// Hopefully we always sync UMagnetDroneSettings::bUse2DTargeting...
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDrone);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneAim);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttached);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileChainJumping);

	default TickGroup = EHazeTickGroup::AfterGameplay;
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

		if(!DroneComp.Settings.bUse2DTargeting)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!DroneComp.Settings.bUse2DTargeting)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerTargetablesComp.TargetingMode.Apply(EPlayerTargetingMode::TopDown, this, EInstigatePriority::High);

        PlayerAimingComp.StartAiming(AttractAimComp, DroneComp.Settings.AimSettings);
	}

    UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerTargetablesComp.TargetingMode.Clear(this);
		
        PlayerAimingComp.StopAiming(AttractAimComp);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FAimingResult AimResult = AttractAimComp.PerformAutoAiming();
		if(AimResult.AutoAimTarget != nullptr)
		{
			AttractAimComp.AimData = FMagnetDroneTargetData::MakeFromAutoAim(Cast<UMagnetDroneAutoAimComponent>(AimResult.AutoAimTarget), AimResult.AutoAimTargetPoint);
		}
		else
		{
			AttractAimComp.AimData.Invalidate(n"AimData TopDownAim Failed", this);
		}
	}
}