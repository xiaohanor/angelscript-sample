class AWalkingWitchHouse : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkeletalMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UPlayerInheritMovementComponent InheritMovement;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMoonMarketFollowSplineComp FollowSplineComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void StartWitchHouse()
	{
		FollowSplineComp.ActivateSplineFollow();
	}
};