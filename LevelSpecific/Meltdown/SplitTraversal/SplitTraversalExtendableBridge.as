class ASplitTraversalExtendableBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	USceneComponent FantasyRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SciFiRoot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SciFiRoot.SetWorldLocation(FantasyRoot.WorldLocation + FVector::ForwardVector * 500000.0);
		SciFiRoot.SetWorldRotation(FantasyRoot.WorldRotation);
	}

	UFUNCTION()
	void Activate()
	{
		ForceComp.Force = FVector::ForwardVector * 3000.0;
	}
};