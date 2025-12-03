class ASanctuaryFloodGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UStaticMeshComponent Gate;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike TimeLike;

	//UPROPERTY(DefaultComponent)
	//LightBirdResponseComponent BirdRespComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent WheelMesh;

	UPROPERTY(DefaultComponent, Attach = WheelMesh)
	UThreeShotInteractionComponent InteractionComp;
		

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
		TimeLike.BindUpdate(this, n"AnimUpdate");
		//BirdRespComp.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
		//BirdRespComp.OnUnilluminated.AddUFunction(this, n"HandleIlluminated");
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"HandleInteractionStarted");
		InteractionComp.OnInteractionStopped.AddUFunction(this, n"HandleInteractionStopped");
	}



	UFUNCTION()
	private void HandleInteractionStopped(UInteractionComponent InteractionComponent,
	                                      AHazePlayerCharacter Player)
	{
		
		TimeLike.Reverse();
	}

	UFUNCTION()
	private void HandleInteractionStarted(UInteractionComponent InteractionComponent,
	                                      AHazePlayerCharacter Player)
	{
		
		TimeLike.PlayWithAcceleration(1.0);
	}


	/*UFUNCTION()
	private void HandleIlluminated(ALightBird Bird)
	{
		TimeLike.SetPlayRate(1.0);
		TimeLike.PlayWithAcceleration(1.0);
	}

	UFUNCTION()
	private void HandleUnilluminated(ALightBird Bird)
	{
		TimeLike.SetPlayRate(0.6);
		TimeLike.Reverse();
	}*/

	UFUNCTION()
	private void AnimUpdate(float CurrentValue)
	{
		Pivot.RelativeLocation = FVector(0.0, 0.0, CurrentValue * -800.0);
	}
};