class ASummitClimbableCounterweightLever : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailClimbableComponent ClimbComp;

	UPROPERTY(EditAnywhere)
	float TargetDistance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}


};