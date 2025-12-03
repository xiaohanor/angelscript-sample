class ASplitTraversalWaterableTable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FantasyRoot;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent FantasyWaterableRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SciFiRoot;

	UPROPERTY(DefaultComponent, Attach = SciFiRoot)
	USceneComponent SciFiWaterableRoot;

	UPROPERTY(EditAnywhere)
	float WateringHeight = 1000.0;

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
		SciFiWaterableRoot.SetRelativeLocation(FVector::UpVector * AcceleratedProgress.Value * WateringHeight);
		FantasyWaterableRoot.SetRelativeLocation(FVector::UpVector * AcceleratedProgress.Value * WateringHeight);
	}
};