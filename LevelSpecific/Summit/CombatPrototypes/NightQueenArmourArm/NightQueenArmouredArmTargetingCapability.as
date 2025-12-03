class UNightQueenArmouredArmTargetingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"NightQueenArmouredArmTargetingCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ANightQueenArmouredArm ArmouredArm;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ArmouredArm = Cast<ANightQueenArmouredArm>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (ArmouredArm.bIsPose)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ArmouredArm.bIsPose)
			return true;

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
		for (AHazePlayerCharacter Player : Game::Players)
		{
			float Distance = (Player.ActorLocation - ArmouredArm.ActorLocation).Size();

			if (Distance < ArmouredArm.AggressionDistance && !ArmouredArm.TargetPlayers.Contains(Player))
				ArmouredArm.SetNewTarget(Player);
			else if (Distance > ArmouredArm.AggressionDistance && ArmouredArm.TargetPlayers.Contains(Player))
				ArmouredArm.TargetPlayers.Remove(Player);
		}
	}
}