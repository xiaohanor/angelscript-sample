class UStoneBeastSegmentMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;

	AStoneBeastSegmentActor Segment;

	FVector Origin;
	FRotator StartRot;

	float Time;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Segment = Cast<AStoneBeastSegmentActor>(Owner);
		Origin = Segment.ActorLocation;
		StartRot = Segment.RotateRoot.RelativeRotation;
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
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Time += DeltaTime;
		float ZOffset = Math::Sin(Segment.VerticalStartingTime + Time * Segment.Speed) * Segment.VerticalDistance;
		float PitchOffset = Math::Sin(Segment.PitchStartingTime + Time * Segment.Speed) * Segment.PitchRange;
		Segment.ActorLocation = Origin + FVector(0,0,ZOffset);
		Segment.RotateRoot.RelativeRotation = StartRot + FRotator(PitchOffset,0,0);
	}
};