class UAdultDragonGapFlyingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"AdultDragon");
	default CapabilityTags.Add(n"AdultDragonStrafing");
	default CapabilityTags.Add(n"AdultDragonStrafeCapability");

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 110;

	default DebugCategory = n"AdultDragon";

	UPlayerAdultDragonComponent DragonComp;
	FHazeAcceleratedRotator AccelRootRotation;

	bool bFinishTransition;
	bool bTransitionOut;
	// bool bSideFlyingMode;

	float TransitionOutDuration = 1.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!DragonComp.bGapFlying)
			return false;

		if (DragonComp.GapFlyingData.Value.bUseGapFlyMovement)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Time::GetGameTimeSince(DragonComp.TimeStoppedGapFlying) > TransitionOutDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bTransitionOut = false;
		bFinishTransition = false;
		Player.ApplyCameraSettings(DragonComp.SideFlyingCameraSettings, 2.5, this);
		Player.PlayCameraShake(DragonComp.ClosingGapCameraShake, this);
		AccelRootRotation.SnapTo(DragonComp.GetAdultDragon().MeshOffsetComponent.RelativeRotation);
		DragonComp.AimingInstigators.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this);
		DragonComp.GetAdultDragon().MeshOffsetComponent.RelativeRotation = FRotator(0);
		DragonComp.bGapFlying = false;
		DragonComp.AimingInstigators.RemoveSingleSwap(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (DragonComp.bGapFlying)
		{
			//AccelRootRotation.AccelerateTo(FRotator(0, 0, DragonComp.GapFlyingData.Value.RollAmount[Player]), 2.0, DeltaTime);

			if (DragonComp.bNewGapFlyingDataSet)
			{
				DragonComp.bNewGapFlyingDataSet = false;
				Player.ApplyCameraSettings(DragonComp.SideFlyingCameraSettings, DragonComp.GapFlyingData.Value.CameraSettingsBlendTime, this);
			}
		} // if side flying true from OnActivated but have left side flying volume, transition roll first then deactivate
		else
		{
			//AccelRootRotation.AccelerateTo(FRotator(0, 0, 0), TransitionOutDuration, DeltaTime);

			if (!bTransitionOut)
			{
				bTransitionOut = true;
				//Player.ClearCameraSettingsByInstigator(this, 3.0);
				Player.StopCameraShakeByInstigator(this);
			}
		}

		//DragonComp.GetAdultDragon().MeshOffsetComponent.RelativeRotation = AccelRootRotation.Value;
	}
};