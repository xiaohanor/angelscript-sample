class UHoverPerchGrindSplinePlayerCameraCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(n"HoverPerchCamera");

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 75;

	UCameraUserComponent CameraUser;
	UHoverPerchPlayerComponent HoverPerchComp;

	FHazeAcceleratedRotator AcceleratedRotationLeft;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CameraUser = UCameraUserComponent::Get(Player);
		HoverPerchComp = UHoverPerchPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HoverPerch == nullptr)
			return false;

		if(HoverPerch.CurrentGrind == nullptr)
			return false;

		if(Player.IsPlayerDead())
			return false;

		if(!HoverPerch.CurrentGrind.bRotateCameraWithSpline)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(HoverPerch == nullptr)
			return true;

		if(HoverPerch.CurrentGrind == nullptr)
			return true;

		if(Player.IsPlayerDead())
			return true;

		if(!HoverPerch.CurrentGrind.bRotateCameraWithSpline)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AcceleratedRotationLeft.SnapTo(FRotator::ZeroRotator);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FRotator DeltaRotation = HoverPerch.GrindSplinePos.WorldRotation.Rotator() - HoverPerch.PreviousGrindSplinePos.WorldRotation.Rotator();
		DeltaRotation.Pitch = 0.0;
		DeltaRotation.Roll = 0.0;
		AcceleratedRotationLeft.Value += DeltaRotation;

		FRotator Previous = AcceleratedRotationLeft.Value;
		AcceleratedRotationLeft.AccelerateTo(FRotator::ZeroRotator, 2, DeltaTime);
		FRotator Delta = Previous - AcceleratedRotationLeft.Value;
		CameraUser.AddDesiredRotation(Delta, this);
	}

	AHoverPerchActor GetHoverPerch() const property
	{
		return HoverPerchComp.PerchActor;
	}
}