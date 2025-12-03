class AStormDragonSummit : AHazeCharacter
{
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"StormDragonSummitFlameCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"StormDragonSummitWindCapability");

	UPROPERTY(EditAnywhere, Category = "Setup | Entrance")
	AActor LandLocation;

	UPROPERTY(EditAnywhere, Category = "Setup | Entrance")
	ASplineActor SplineActor;

	bool bStartedStormDragon;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorHiddenInGame(true);
	}

	UFUNCTION()
	void ActivateStormDragon()
	{
		bStartedStormDragon = true;
		SetActorHiddenInGame(false);
	}
	
	AHazePlayerCharacter GetClosestPlayer()
	{
		return GetDistanceTo(Game::Mio) < GetDistanceTo(Game::Zoe) ? Game::Mio : Game::Zoe;
	}
}