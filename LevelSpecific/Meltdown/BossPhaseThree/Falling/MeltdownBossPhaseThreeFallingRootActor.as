class AMeltdownBossPhaseThreeFallingRootActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Icon;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Game::Mio;
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintCallable)
	void StartFalling()
	{
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintCallable)
	void StopFalling()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	}
};