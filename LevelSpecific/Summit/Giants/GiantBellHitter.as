class AGiantBellHitter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BellHitterMesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent RightLock;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LeftLock;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}
};