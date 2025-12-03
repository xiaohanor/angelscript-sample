class UCrystalGrowthKillComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	float Radius = 150.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (PlayerInRange(Player))
			{
				PrintToScreen("IN RANGE: " + Player);
			}
		}

		// Debug::DrawDebugSphere(WorldLocation, Radius * WorldScale.Size(), 12, FLinearColor::Red, 10.0);
	}

	bool PlayerInRange(AHazePlayerCharacter Player)
	{
		float TrueRadius = Radius * WorldScale.Size();
		return Player.GetDistanceTo(Owner) < TrueRadius;
	}
};