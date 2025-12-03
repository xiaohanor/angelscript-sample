class UPrisonBeamElevatorPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UPrisonBeamElevatorPlayerComponent PlayerComp;
	APrisonBeamElevator CurrentElevator;

	bool bReachedEnd = false;

	FVector StartLoc;
	FVector EndLoc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UPrisonBeamElevatorPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PlayerComp.CurrentElevator == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PlayerComp.CurrentElevator == nullptr)
			return true;

		if (bReachedEnd)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bReachedEnd = false;
		CurrentElevator = PlayerComp.CurrentElevator;

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CameraTags::CameraControl, this);

		Player.ApplyCameraSettings(PlayerComp.CurrentElevator.CamSettings, 0.5, this, EHazeCameraPriority::High);

		Player.PlaySlotAnimation(Animation = PlayerComp.Anim, bLoop = true);

		StartLoc = Player.ActorLocation;
		FVector DirToPlayer = (CurrentElevator.ActorLocation - Player.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();

		UCapsuleComponent TargetTrigger = PlayerComp.bGoingUp ? CurrentElevator.TopTrigger : CurrentElevator.BottomTrigger;
		EndLoc = TargetTrigger.WorldLocation + (DirToPlayer * 300.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CameraTags::CameraControl, this);

		Player.ClearCameraSettingsByInstigator(this, 0.5);

		Player.StopSlotAnimation();

		PlayerComp.CurrentElevator = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float VerticalLoc = Math::Lerp(StartLoc.Z, EndLoc.Z, PlayerComp.VerticalCurve.GetFloatValue(ActiveDuration));
		FVector HorizontalLoc = Math::Lerp(StartLoc, EndLoc, PlayerComp.HorizontalCurve.GetFloatValue(ActiveDuration));

		Player.SetActorLocation(FVector(HorizontalLoc.X, HorizontalLoc.Y, VerticalLoc));

		if (ActiveDuration >= 2.0)
			bReachedEnd = true;
	}
}