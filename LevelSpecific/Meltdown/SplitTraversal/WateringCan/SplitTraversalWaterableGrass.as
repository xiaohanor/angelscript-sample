class ASplitTraversalWaterableGrass : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FantasyRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SciFiRoot;

	UPROPERTY(DefaultComponent)
	USplitTraversalWateringCanResponseComponent ResposeComp;

	UPROPERTY()
	FHazeAcceleratedFloat AcceleratedProgress;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		SciFiRoot.SetWorldLocation(FantasyRoot.WorldLocation + FVector::ForwardVector * 500000.0);
		SciFiRoot.SetWorldRotation(FantasyRoot.WorldRotation);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AcceleratedProgress.AccelerateTo(ResposeComp.Progress, 1.0, DeltaSeconds);
		FVector Scale = FVector(1.0, 1.0, 1.0 + AcceleratedProgress.Value * 4);
		FantasyRoot.SetRelativeScale3D(Scale);
		SciFiRoot.SetRelativeScale3D(Scale);
	}
};