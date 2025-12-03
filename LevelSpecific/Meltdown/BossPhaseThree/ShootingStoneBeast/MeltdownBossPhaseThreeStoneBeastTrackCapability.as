struct FMeltdownBossPhaseThreeStoneBeastTrackParams
{
	AHazePlayerCharacter Player;
	FRotator OffsetRotation;
};

class UMeltdownBossPhaseThreeStoneBeastTrackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	AMeltdownBossPhaseThreeShootingFlyingStoneBeast StoneBeast;
	AMeltdownBoss Rader;
	FHazeAcceleratedQuat AccRotation;

	const float TrackAccelerationDuration = 0.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StoneBeast = Cast<AMeltdownBossPhaseThreeShootingFlyingStoneBeast>(Owner);
		Rader = Cast<AMeltdownBoss>(Owner.AttachParentActor);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMeltdownBossPhaseThreeStoneBeastTrackParams& Params) const
	{
		if (StoneBeast.ActionQueue.Start(this, Params))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (AccRotation.Value.Equals(StoneBeast.LaserOffsetRotation.Quaternion(), KINDA_SMALL_NUMBER))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMeltdownBossPhaseThreeStoneBeastTrackParams Params)
	{
		StoneBeast.PlayerToTrack = Params.Player;
		AHazePlayerCharacter RaderTarget = Params.Player;
		Rader.SetLookTarget(RaderTarget);
		StoneBeast.LaserOffsetRotation = Params.OffsetRotation;

		FQuat RotationToPlayer = FQuat::MakeFromX(StoneBeast.PlayerToTrack.ActorLocation - StoneBeast.ActorLocation);
		FQuat CurrentRelativeRotation = RotationToPlayer.Inverse() * StoneBeast.ActorQuat;

		AccRotation.SnapTo(CurrentRelativeRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		StoneBeast.ActionQueue.Finish(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccRotation.AccelerateTo(StoneBeast.LaserOffsetRotation.Quaternion(), TrackAccelerationDuration, DeltaTime);

		FQuat RotationToPlayer = FQuat::MakeFromX(StoneBeast.PlayerToTrack.ActorLocation - StoneBeast.ActorLocation);
		StoneBeast.SetActorRotation(RotationToPlayer * AccRotation.Value);
	}
};