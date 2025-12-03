class ASummitLaunchTrebuchet : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BaseMeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TrebuchetArmMeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TrebuchetChainLocation;
	
	UPROPERTY(EditAnywhere)
	ANightQueenMetal Chain;

	UPROPERTY(EditAnywhere)
	ASummitRollingWheel RollingWheel;

	UPROPERTY()
	FRotator TrebuchetStartRot;

	UPROPERTY()
	FVector ChainStartLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TrebuchetStartRot = TrebuchetArmMeshRoot.RelativeRotation;
		ChainStartLocation = Chain.ActorLocation;
	}

};