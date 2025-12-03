struct FMeltdownBossPhaseThreeStoneBeastFireParams
{
};

class UMeltdownBossPhaseThreeStoneBeastFireCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	AMeltdownBossPhaseThreeShootingFlyingStoneBeast StoneBeast;

	const float FireDuration = 1.0;

	FQuat StartRotation;
	FQuat EndRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StoneBeast = Cast<AMeltdownBossPhaseThreeShootingFlyingStoneBeast>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMeltdownBossPhaseThreeStoneBeastFireParams& Params) const
	{
		if (StoneBeast.ActionQueue.Start(this, Params))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > FireDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMeltdownBossPhaseThreeStoneBeastFireParams Params)
	{
		StoneBeast.LaserMesh.SetHiddenInGame(false);

		StartRotation = StoneBeast.ActorQuat;
		EndRotation = StartRotation * (StoneBeast.LaserOffsetRotation * -2.0).Quaternion();
	}


	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		StoneBeast.ActionQueue.Finish(this);
		StoneBeast.LaserMesh.SetHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		StoneBeast.SetActorRotation(
			FQuat::Slerp(
				StartRotation, EndRotation,
				ActiveDuration / FireDuration
			)
		);
	}
};