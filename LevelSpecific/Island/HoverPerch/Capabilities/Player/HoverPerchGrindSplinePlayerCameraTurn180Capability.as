class UHoverPerchGrindSplinePlayerCameraTurn180Capability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(n"HoverPerchCamera");
	default BlockExclusionTags.Add(n"HoverPerchCameraTurn180");

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 75;

	UCameraUserComponent CameraUser;
	UHoverPerchPlayerComponent HoverPerchComp;

	FHazeAcceleratedFloat AcceleratedDegreesLeft;

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

		if(!HoverPerch.CurrentGrind.bRotateCameraWithSpline)
			return false;

		if(!HoverPerch.FrameOfSwitchGrindDirection.IsSet())
			return false;

		if(HoverPerch.FrameOfSwitchGrindDirection.Value != Time::FrameNumber)
			return false;

		if(Player.IsPlayerDead())
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

		if(!HoverPerch.CurrentGrind.bRotateCameraWithSpline)
			return true;

		if(Math::IsNearlyZero(AcceleratedDegreesLeft.Value))
			return true;

		if(Player.IsPlayerDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		float TotalDegreeDelta = 180.0;

		if(HoverPerch.GrindSplinePos.CurrentSpline.IsClosedLoop())
		{
			float Angle = HoverPerch.GrindSplinePos.WorldRightVector.GetAngleDegreesTo(CameraUser.GetDesiredRotation().ForwardVector.GetSafeNormal2D());
			TotalDegreeDelta = Angle * 2.0;

			if(HoverPerch.GrindSplinePos.IsForwardOnSpline())
				TotalDegreeDelta -= 360.0;
		}

		AcceleratedDegreesLeft.SnapTo(TotalDegreeDelta);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float PreviousDegreesLeft = AcceleratedDegreesLeft.Value;
		AcceleratedDegreesLeft.AccelerateTo(0.0, 2.0, DeltaTime);
		FRotator DeltaRotation = FRotator(0.0, AcceleratedDegreesLeft.Value - PreviousDegreesLeft, 0.0);
		CameraUser.AddDesiredRotation(DeltaRotation, this);
	}

	AHoverPerchActor GetHoverPerch() const property
	{
		return HoverPerchComp.PerchActor;
	}
}