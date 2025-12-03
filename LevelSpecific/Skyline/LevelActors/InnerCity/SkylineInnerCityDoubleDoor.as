class ASkylineInnerCityDoubleDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot1;

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot2;

	UPROPERTY(DefaultComponent, Attach = Pivot1)
	UStaticMeshComponent DoorMesh;
	

	UPROPERTY(EditAnywhere)
	ADoubleInteractionActor DoubleInteract;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike Animation;

	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Animation.BindUpdate(this, n"AnimationUpdate");
		DoubleInteract.OnDoubleInteractionCompleted.AddUFunction(this, n"HandleDoubleInteractCompleted");
	}

	UFUNCTION()
	private void AnimationUpdate(float CurrentValue)
	{
		Pivot1.RelativeScale3D = FVector(1.0, 1.0, 1.0 - CurrentValue);
		Pivot2.RelativeScale3D = FVector(1.0, 1.0, 1.0 - CurrentValue);
	}

	UFUNCTION()
	private void HandleDoubleInteractCompleted()
	{
		Animation.Play();
	}
};