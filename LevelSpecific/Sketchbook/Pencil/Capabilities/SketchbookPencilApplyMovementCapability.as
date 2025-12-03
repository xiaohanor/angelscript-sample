class USketchbookPencilApplyMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	ASketchbookPencil Pencil;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Pencil = Cast<ASketchbookPencil>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!Pencil.HasPencilMovedThisFrame())
			Pencil.SnapPencilTo(Pencil.ActorLocation, Pencil.ActorVelocity, this);

		if(!Pencil.HasPencilRotatedThisFrame())
			Pencil.RotateOffsetTowards(FQuat::Identity, 1, DeltaTime, this);

		if(!Pencil.HasTipRotatedThisFrame())
			Pencil.RotateTipOffsetTowards(FRotator::ZeroRotator, 1, DeltaTime, this);

		if(!Pencil.HasTipMovedThisFrame())
			Pencil.MoveTipOffsetAccelerateTo(FVector::ZeroVector, 1, DeltaTime, this);

		if(!Pencil.HasPivotRotatedThisFrame())
			Pencil.SetPivotRotationAlpha(0, this);
		
		Pencil.ApplyPencilMovement();
	}
};