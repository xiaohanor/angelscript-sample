class ASpaceWalkSplineEscapeShip : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Ship;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	UHazeSplineComponent Spline;

	FHazeAcceleratedFloat AccSpeed;

	UPROPERTY(EditAnywhere)
	float RubberbandMaxSpeed = 300.0;

	UPROPERTY(EditAnywhere)
	float RubberbandMinSpeed = 150.0;

	UPROPERTY(EditAnywhere)
	float RubberbandMinDistanceToPlayer = 400;

	UPROPERTY(EditAnywhere)
	float RubberbandMaxDistanceToPlayer = 1000;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spline = SplineActor.Spline;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AHazePlayerCharacter CurrentClosestPlayer;
		float MinDistanceToPlayer = MAX_flt;
		for (AHazePlayerCharacter Player: Game::Players)
		{
			if(Player.IsPlayerDead())
				continue;
			
		}



		float TargetSpeed = Math::GetMappedRangeValueClamped(FVector2D(RubberbandMinDistanceToPlayer, RubberbandMaxDistanceToPlayer),FVector2D(RubberbandMinSpeed,RubberbandMaxSpeed),MinDistanceToPlayer);	
	}
};