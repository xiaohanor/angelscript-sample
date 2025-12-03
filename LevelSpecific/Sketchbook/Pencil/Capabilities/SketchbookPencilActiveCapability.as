class USketchbookPencilActiveCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ASketchbookPencil Pencil;
	FQuat Rotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Pencil = Cast<ASketchbookPencil>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Pencil.HasValidRequestInQueue())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Pencil.CurrentRequest.IsSet())
			return false;

		if(!Pencil.HasValidRequestInQueue())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Pencil.bIsActive = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Pencil.bIsActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float HorizontalVelocity = Pencil.ActorVelocity.Y;
		float TiltFactor = Math::Saturate(HorizontalVelocity * Sketchbook::MoveTiltFactor);
		FQuat TargetRotation = FQuat(FVector::ForwardVector, TiltFactor * Sketchbook::MoveMaxTiltRad);
		Pencil.RotateOffsetTowards(TargetRotation, 1, DeltaTime, this);
	}
};