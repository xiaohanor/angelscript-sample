class USketchbookPencilDeactiveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 110;

	ASketchbookPencil Pencil;

	FHazeAcceleratedVector AccOffsetFromTarget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Pencil = Cast<ASketchbookPencil>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Pencil.bIsActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Pencil.bIsActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccOffsetFromTarget.SnapTo(Pencil.ActorLocation - Pencil.GetOutOfViewLocation(), Pencil.ActorVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccOffsetFromTarget.AccelerateTo(FVector::ZeroVector, 3.0, DeltaTime);

		const FVector OutOfViewLocation = Pencil.GetOutOfViewLocation();

		FVector Location = OutOfViewLocation + AccOffsetFromTarget.Value;
		FVector Velocity = (Location - Pencil.ActorLocation) / DeltaTime;

		Pencil.SnapPencilTo(Location, Velocity, this);

		FVector TipOffset = OutOfViewLocation - Sketchbook::ProjectWorldLocationToPagePlane(OutOfViewLocation);
		Pencil.MoveTipOffsetAccelerateTo(TipOffset, 2, DeltaTime, this);
	}
};