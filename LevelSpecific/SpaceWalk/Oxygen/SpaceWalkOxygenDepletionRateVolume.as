class ASpaceWalkOxygenDepletionRateVolume : AVolume
{
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");

	// Target point to calculate oxygen depletion rate from
	UPROPERTY(EditAnywhere, Category = "Oxygen Depletion")
	AActor TargetPoint;

	// When the furthest player is within this distance of the target point, oxygen depletes fast
	UPROPERTY(EditAnywhere, Category = "Oxygen Depletion")
	float DistanceForFastDepletion = 5000.0;

	// When the furthest player is further than this distance of the target point, oxygen depletes normally
	UPROPERTY(EditAnywhere, Category = "Oxygen Depletion")
	float DistanceForNormalDepletion = 20000.0;

	// How much faster the oxygen depletes when the players are both closest
	UPROPERTY(EditAnywhere, Category = "Oxygen Depletion")
	float MaxFastDepletionRate = 2.0;

	private bool bEnabled = true;

	// Disable this volume's modification of any player oxygen depletion rates
	UFUNCTION()
	void DisableOxygenDepletionRate()
	{
		bEnabled = false;
		for (AHazePlayerCharacter Player : Game::Players)
		{
			auto OxygenComp = USpaceWalkOxygenPlayerComponent::Get(Player);
			OxygenComp.OxygenDepletionRate.Clear(this);
		}
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!IsValid(TargetPoint))
			return;

		// Don't do anything unless both players are inside the volume
		FVector TargetLocation = TargetPoint.ActorLocation;
		bool bBothPlayersInVolume = true;
		float FurthestDistance = 0.0;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!IsOverlappingActor(Player))
				bBothPlayersInVolume = false;

			float Distance = TargetLocation.Distance(Player.ActorLocation);
			if (Distance > FurthestDistance)
				FurthestDistance = Distance;
		}

		// Update oxygen depletion rates
		for (AHazePlayerCharacter Player : Game::Players)
		{
			auto OxygenComp = USpaceWalkOxygenPlayerComponent::Get(Player);
			if (bBothPlayersInVolume && bEnabled)
			{
				float Rate = Math::GetMappedRangeValueClamped(
					FVector2D(DistanceForFastDepletion, DistanceForNormalDepletion),
					FVector2D(MaxFastDepletionRate, 1.0),
					FurthestDistance,
				);
				OxygenComp.OxygenDepletionRate.Apply(Rate, this);
			}
			else
			{
				OxygenComp.OxygenDepletionRate.Clear(this);
			}
		}
	}
};