class UMoonMarketRideMothCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;
	UMoonMarketPlayerRideMothComponent RiderComp;

	AMoonMarketMoth Moth;
	AFocusCameraActor Camera;

	float LockCameraDuration = 3;
	float BlendTime = 3;
	float VerticalOffset = 150;
	float BehindOffset = 450;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
		RiderComp = UMoonMarketPlayerRideMothComponent::Get(Player);

	}
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(RiderComp.Moth == nullptr)
			return false;

		if(Time::GetGameTimeSince(RiderComp.Moth.StartRidingTime) >= LockCameraDuration)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
		bool ShouldDeactivate() const
	{
		if(RiderComp.Moth == nullptr)
			return true;

		// if(ActiveDuration > LockCameraDuration)
		// 	return true;

		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Moth = RiderComp.Moth;
		Camera = SpawnActor(AFocusCameraActor);
		Player.DeactivateCamera(Player.CurrentlyUsedCamera);
		Player.ActivateCamera(Camera, BlendTime, this);

		FHazeCameraWeightedFocusTargetInfo FocusInfo;
		FocusInfo.SetFocusToComponent(Moth.Spline.CameraFocusComponent);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DeactivateCamera(Camera, BlendTime);
		Moth = nullptr;
		Camera.DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Camera.SetActorLocation(Moth.ActorLocation + FVector::UpVector * VerticalOffset - Moth.ActorForwardVector * BehindOffset);
	}
};