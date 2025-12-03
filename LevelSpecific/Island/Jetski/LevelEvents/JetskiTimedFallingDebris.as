class AJetskiTimedFallingDebris : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	// The distance the player needs to be to trigger the final fall animation
	UPROPERTY(EditAnywhere)
	float TriggerEndLocationDistance = 4000.0;

	UPROPERTY(EditInstanceOnly)
	AHazeLevelSequenceActor FirstFallSeq;
	UPROPERTY(EditInstanceOnly)
	AHazeLevelSequenceActor SecondFallSeq;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	bool bStartedFalling = false;
	bool bStartedFallingToEndLocation = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (FVector(ActorForwardVector).DotProduct(Game::GetClosestPlayer(ActorLocation).ActorLocation - ActorLocation) < 7000.0 && !bStartedFallingToEndLocation)
		{
			bStartedFallingToEndLocation = true;
			StartFallingToEndLocation();
		}
	}

	UFUNCTION()
	void StartFalling()
	{
		if(bStartedFalling)
			return;

		SetActorTickEnabled(true);
		OnDebrisStartedFalling();
		bStartedFalling = true;
	}

	UFUNCTION(BlueprintEvent)
	void OnDebrisStartedFalling(){}

	void StartFallingToEndLocation()
	{
		SetActorTickEnabled(false);
		OnFallToEndLocation();
	}

	UFUNCTION(BlueprintEvent)
	void OnFallToEndLocation(){}
}