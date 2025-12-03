class UIslandOverseerDoorEyeFollowCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AAIIslandOverseer Overseer;
	UIslandOverseerPhaseComponent PhaseComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Overseer = Cast<AAIIslandOverseer>(Owner);
		PhaseComp = UIslandOverseerPhaseComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PhaseComp.Phase == EIslandOverseerPhase::Door)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PhaseComp.Phase == EIslandOverseerPhase::Door)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Location = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) / 2;
		Overseer.EyeLeft.WorldRotation = (Location - Overseer.EyeLeft.WorldLocation).Rotation();
		Overseer.EyeRight.WorldRotation = (Location - Overseer.EyeRight.WorldLocation).Rotation();
	}
}