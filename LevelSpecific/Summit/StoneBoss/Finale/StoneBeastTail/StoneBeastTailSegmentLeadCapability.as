class UStoneBeastTailSegmentLeadCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;
	//default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AStoneBeastTailSegment TailSegment;

	float TimeWhenSwitchedDirection;
	float AverageSpeed;

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

		if (TailSegment.TargetTailSegment != nullptr)
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

		if (TailSegment.TargetTailSegment != nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float CurrentTime = Math::Lerp(0, ActiveDuration, Math::Saturate(ActiveDuration * 0.2));
		float Pitch = Math::Sin(CurrentTime * TailSegment.PitchRotationFrequency) * TailSegment.PitchRotationAmplitude;
		float Yaw = Math::Sin(CurrentTime * TailSegment.YawRotationFrequency) * TailSegment.YawRotationAmplitude;
		float Roll = Math::Sin(CurrentTime * TailSegment.RollRotationFrequency) * TailSegment.RollRotationAmplitude;
		TailSegment.SetSegmentLocationAndRotation(TailSegment.SegmentTransform.Location, FRotator(Pitch, Yaw, Roll));
	}
};