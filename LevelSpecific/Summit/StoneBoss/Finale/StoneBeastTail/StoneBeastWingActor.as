class AStoneBeastWingActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent MoveAudioComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};