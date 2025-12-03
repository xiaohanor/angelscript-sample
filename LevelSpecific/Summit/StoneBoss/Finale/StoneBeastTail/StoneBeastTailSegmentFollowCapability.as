class UStoneBeastTailSegmentFollowCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;
	//default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	AStoneBeastTailSegment TailSegment;

	FHazeAcceleratedTransform AccTransform;

	FVector StartRelativeLocation;
	FRotator StartRelativeRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TailSegment = Cast<AStoneBeastTailSegment>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Game::Mio.bIsParticipatingInCutscene)
			return false;

		if (!TailSegment.bIsControllingActor)
			return false;

		if (TailSegment.TargetTailSegment == nullptr)
			return false;

		if (!TailSegment.bIsActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!TailSegment.bIsActive)
			return true;

		if (TailSegment.TargetTailSegment == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccTransform.SnapTo(TailSegment.TargetTailSegment.SegmentTransform);
		StartRelativeLocation = AccTransform.Value.InverseTransformPosition(TailSegment.SegmentTransform.Location);
		StartRelativeRotation = AccTransform.Value.InverseTransformRotation(TailSegment.SegmentTransform.Rotator());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Follow the previous segment, then apply rotation additively to that
		AccTransform.AccelerateTo(TailSegment.TargetTailSegment.SegmentTransform, TailSegment.FollowTransformDelay, DeltaTime);
		FVector NewWorldLocation = AccTransform.Value.TransformPosition(StartRelativeLocation);

		float CurrentTime = Math::Lerp(0, ActiveDuration, Math::Saturate(ActiveDuration * 0.2));
		float Pitch = Math::Sin(CurrentTime * TailSegment.PitchRotationFrequency) * TailSegment.PitchRotationAmplitude;
		float Yaw = Math::Sin(CurrentTime * TailSegment.YawRotationFrequency) * TailSegment.YawRotationAmplitude;
		float Roll = Math::Sin(CurrentTime * TailSegment.RollRotationFrequency) * TailSegment.RollRotationAmplitude;
		FRotator NewLocalRotation = FRotator(Pitch, Yaw, Roll);
		FRotator NewWorldRotation = AccTransform.Value.TransformRotation(StartRelativeRotation + NewLocalRotation);

		TailSegment.SetSegmentLocationAndRotation(NewWorldLocation, NewWorldRotation);
	}
};