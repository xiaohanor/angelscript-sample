class AStormFallDragonSplineMover : AHazeCharacter
{
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"StormFallDragonSplineMovementCapability");

	UPROPERTY(EditAnywhere)
	ASplineActor Spline;

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 9500.0;

	UPROPERTY(EditAnywhere)
	bool bActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorHiddenInGame(true);
	}

	UFUNCTION()
	void ActivateDragon()
	{
		bActive = true;	
		SetActorHiddenInGame(false);
	}
}