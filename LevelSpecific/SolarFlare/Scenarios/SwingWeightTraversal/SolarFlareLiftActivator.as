class ASolarFlareLiftActivator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere)
	AOneShotInteractionActor OneShotInteractActor;

	UPROPERTY(EditAnywhere)
	AActor Platform;

	UPROPERTY(EditAnywhere)
	float ZOffsetTarget = -780.0;
	float Target;

	float CurrentOffset;

	FVector StartLoc;

	bool bLiftOn;
	bool bIsMoving;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OneShotInteractActor.OnOneShotActivated.AddUFunction(this, n"OnOneShotActivated");
		StartLoc = Platform.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Target = 0.0;

		if (bLiftOn)
			Target = ZOffsetTarget;

		CurrentOffset = Math::FInterpConstantTo(CurrentOffset, Target, DeltaSeconds, 800.0);
		Platform.ActorLocation = StartLoc + FVector::UpVector  * CurrentOffset;
	
		if (CurrentOffset == Target && bIsMoving)
		{
			bIsMoving = false; 
		}
	}

	UFUNCTION()
	private void OnOneShotActivated(AHazePlayerCharacter Player, AOneShotInteractionActor Interaction)
	{
		if (bIsMoving)
			return;

		bLiftOn = !bLiftOn;
		bIsMoving = true;

		FSolarFlareLiftActivatorParams Params;
		Params.Location = Platform.ActorLocation;
		USolarFlareLiftActivatorEffectHandler::Trigger_OnLiftStarted(this, Params);
	}
}