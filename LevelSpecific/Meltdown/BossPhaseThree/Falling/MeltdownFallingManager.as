class AMeltdownFallingManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike MovePlayers;
	default MovePlayers.Duration = 5.0;
	default MovePlayers.UseSmoothCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	APlayerTrigger Ptrigger;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovePlayers.BindUpdate(this, n"MoveUpdate");
		Ptrigger.OnActorBeginOverlap.AddUFunction(this, n"StartMoving");
	}

	UFUNCTION()
	private void StartMoving(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter OverlapPlayer = Cast<AHazePlayerCharacter>(OtherActor);

		if(OverlapPlayer != nullptr)
			MovePlayers.Play();
	}

	UFUNCTION()
	private void MoveUpdate(float CurrentValue)
	{
		for(AHazePlayerCharacter Player : Game::GetPlayers())
		{
			UMeltdownSkydiveSettings::SetFallingVelocity(Player,Math::Lerp(5500, 60000, CurrentValue), this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		 
	}
};