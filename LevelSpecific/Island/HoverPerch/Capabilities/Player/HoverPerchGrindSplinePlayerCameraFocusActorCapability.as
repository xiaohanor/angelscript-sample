class UHoverPerchGrindSplinePlayerCameraFocusActorCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(n"HoverPerchCamera");

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 50;

	UCameraUserComponent CameraUser;
	UHoverPerchPlayerComponent HoverPerchComp;

	FHazeAcceleratedRotator AcceleratedRotationLeft;
	AActor CurrentFocusActor;
	FRotator PreviousFacingRotation;

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

		if(HoverPerch.InstigatedCameraFocusActor.Get() == nullptr)
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

		if(HoverPerch.InstigatedCameraFocusActor.Get() == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(n"HoverPerchCamera", this);
		AcceleratedRotationLeft.SnapTo(FRotator::ZeroRotator);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(n"HoverPerchCamera", this);
		CurrentFocusActor = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HoverPerch.InstigatedCameraFocusActor.Get() != CurrentFocusActor)
		{
			CurrentFocusActor = HoverPerch.InstigatedCameraFocusActor.Get();
			PreviousFacingRotation = CurrentFacingRotation;
		}

		FRotator DeltaRotation = CurrentFacingRotation - PreviousFacingRotation;
		DeltaRotation.Pitch = 0.0;
		DeltaRotation.Roll = 0.0;
		AcceleratedRotationLeft.Value += DeltaRotation;

		FRotator Previous = AcceleratedRotationLeft.Value;
		AcceleratedRotationLeft.AccelerateTo(FRotator::ZeroRotator, 2, DeltaTime);
		FRotator Delta = Previous - AcceleratedRotationLeft.Value;
		CameraUser.AddDesiredRotation(Delta, this);
		PreviousFacingRotation = CurrentFacingRotation;
	}

	AHoverPerchActor GetHoverPerch() const property
	{
		return HoverPerchComp.PerchActor;
	}

	FRotator GetCurrentFacingRotation() const property
	{
		return FRotator::MakeFromZX(FVector::UpVector, CurrentFocusActor.ActorLocation - Player.ActorLocation);
	}
}