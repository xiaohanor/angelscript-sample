class ASplitTraversalRevealingStaircaseFantasyChunk : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent VFXComp;

	UPROPERTY(EditAnywhere)
	float Force = 100.0;

	UPROPERTY(EditAnywhere)
	float Delay = 1.0;

	UPROPERTY(EditInstanceOnly)
	bool bRetract = true;

	ASplitTraversalRevealingStaircase StairCaseActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StairCaseActor = Cast<ASplitTraversalRevealingStaircase>(AttachParentActor);

		if (StairCaseActor != nullptr)
			StairCaseActor.OnStairsRevealed.AddUFunction(this, n"HandleStairsRevealed");
	}

	UFUNCTION()
	private void HandleStairsRevealed()
	{
		if (Delay > 0.0)
			Timer::SetTimer(this, n"Activate", Delay);
		else
			Activate();
	}

	UFUNCTION()
	private void Activate()
	{
		ForceComp.Force = FVector::UpVector * Force;
		VFXComp.Activate();
		
		if (bRetract)
		{
			Timer::SetTimer(this, n"DelayedDeactivate", 0.5);
			RotateComp.SpringStrength = 2.0;
		}
	}

	UFUNCTION()
	private void DelayedDeactivate()
	{
		ForceComp.Force = FVector::ZeroVector;
	}
};