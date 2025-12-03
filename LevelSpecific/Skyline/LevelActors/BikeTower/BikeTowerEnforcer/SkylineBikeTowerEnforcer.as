class ASkylineBikeTowerEnforcer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase SkeletalMeshComp;

	FVector2D AimSpace;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};