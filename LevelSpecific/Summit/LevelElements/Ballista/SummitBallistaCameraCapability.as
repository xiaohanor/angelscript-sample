class USummitBallistaCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitBallista Ballista;

	FQuat StartRootWorldRotation;
	FQuat EndRootWorldRotation;

	float BlendTime = 2.0;
	float CurrentBlendTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ballista = Cast<ASummitBallista>(Owner);
		EndRootWorldRotation = Ballista.CameraRoot.WorldRotation.Quaternion();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Ballista.ZoeInVolume.IsSet())
			return false;

		if (!Ballista.bIsHeld)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Ballista.ZoeInVolume.IsSet())
			return true;

		if (!Ballista.bIsHeld)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FVector PlayerToCamRoot = (Game::Zoe.ViewLocation - Ballista.CameraRoot.WorldLocation);
		FVector ConstrainedForwardDir = PlayerToCamRoot.ConstrainToPlane(Ballista.CameraRoot.UpVector);
		StartRootWorldRotation = ConstrainedForwardDir.ToOrientationQuat();
		CurrentBlendTime = (1 - (Math::Abs(StartRootWorldRotation.Rotator().Yaw) / 180.0)) * BlendTime;
		CurrentBlendTime = Math::Clamp(CurrentBlendTime, 1.0, 100);
		Ballista.CameraRoot.WorldRotation = StartRootWorldRotation.Rotator();
		Game::Zoe.ActivateCamera(Ballista.CameraComp, CurrentBlendTime * 0.8, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Game::Zoe.DeactivateCamera(Ballista.CameraComp, 2.0);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Ballista.CameraBlendCurve.GetFloatValue(Math::Saturate(ActiveDuration / CurrentBlendTime));
		Ballista.CameraRoot.WorldRotation = FQuat::Slerp(StartRootWorldRotation, EndRootWorldRotation, Alpha).Rotator();
	}
};