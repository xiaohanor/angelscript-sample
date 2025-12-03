class UCentipedeBodyGravityModifierCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::LastMovement;

	ACentipede Centipede;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Centipede = Cast<ACentipede>(Owner);
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
	void OnDeactivated()
	{
		if (Centipede.HasActorBegunPlay())
			Centipede.ClearGravityDirectionOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Read players' up vectors
		FVector GravityOverride;
		for (auto Player : Game::Players)
			GravityOverride -= Centipede.GetPlayerWorldUp(Player);

		GravityOverride = GravityOverride.GetSafeNormal() * Centipede::BodyGravityMagnitude;
		Centipede.ApplyGravityOverride(GravityOverride, this);

		// Print("GO "+ GravityOverride, 0);
	}
}