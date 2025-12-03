class ASplitTraversalRevealingStaircaseStep : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY()
	float Force = 100.0;

	UPROPERTY(EditAnywhere)
	bool bForceFeedback = false;

	ASplitTraversalRevealingStaircase StairCaseActor;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		TranslateComp.MaxZ = ActorRelativeLocation.X * 0.5;
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StairCaseActor = Cast<ASplitTraversalRevealingStaircase>(AttachParentActor);

		if (StairCaseActor != nullptr)
			StairCaseActor.OnStairsRevealed.AddUFunction(this, n"HandleStairsRevealed");

		TranslateComp.OnConstraintHit.AddUFunction(this, n"HandleConstraintHit");
	}

	UFUNCTION()
	private void HandleConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if (bForceFeedback)
		{
			BP_ForceFeedback();
			bForceFeedback = false;
		}
	}

	UFUNCTION(BlueprintEvent)
	private void BP_ForceFeedback(){}

	UFUNCTION()
	private void HandleStairsRevealed()
	{
		ForceComp.Force = FVector::UpVector * Force;
	}
};