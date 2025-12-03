class USummitKillAreaSphereComponent : USphereComponent
{
	private bool bCanKillPlayer = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
		// OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");
	}

	void EnableKill()
	{
		if (bCanKillPlayer)
			return;

		TArray<AActor> OverlappingActors;
		bCanKillPlayer = true;
		GetOverlappingActors(OverlappingActors);

		for (AActor OtherActor : OverlappingActors)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

			if (Player != nullptr)
			{
				Player.KillPlayer();
			}
		}
	}

	void DisableKill()
	{
		if (!bCanKillPlayer)
			return;

		bCanKillPlayer = false;
	}

	bool CanKillPlayer()
	{
		return bCanKillPlayer;
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
		if (!bCanKillPlayer)
			return;
		
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
		{
			Player.KillPlayer();
		}
    }
}