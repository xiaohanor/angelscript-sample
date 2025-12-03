struct FMeltdownBossPhaseThreeStoneBeastSpawnParams
{
	AHazePlayerCharacter FacingPlayer;
	FRotator OffsetRotation;
};

class UMeltdownBossPhaseThreeStoneBeastSpawnCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	AMeltdownBossPhaseThreeShootingFlyingStoneBeast StoneBeast;

	const float SpawnDuration = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StoneBeast = Cast<AMeltdownBossPhaseThreeShootingFlyingStoneBeast>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMeltdownBossPhaseThreeStoneBeastSpawnParams& Params) const
	{
		if (StoneBeast.ActionQueue.Start(this, Params))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > SpawnDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMeltdownBossPhaseThreeStoneBeastSpawnParams Params)
	{
		StoneBeast.LaserMesh.SetHiddenInGame(true);
		StoneBeast.WorldMesh.RelativeScale3D = StoneBeast.WorldStartScale;

		StoneBeast.PlayerToTrack = Params.FacingPlayer;
		StoneBeast.LaserOffsetRotation = Params.OffsetRotation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		StoneBeast.ActionQueue.Finish(this);
		StoneBeast.WorldMesh.RelativeScale3D = StoneBeast.WorldEndScale;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		StoneBeast.WorldMesh.RelativeScale3D = Math::Lerp(StoneBeast.WorldStartScale, StoneBeast.WorldEndScale, ActiveDuration / SpawnDuration);
		StoneBeast.SetActorRotation(
			FQuat::MakeFromX(StoneBeast.PlayerToTrack.ActorLocation - StoneBeast.ActorLocation)
			* StoneBeast.LaserOffsetRotation.Quaternion());
	}
};