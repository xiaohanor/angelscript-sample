class ASummitGenericDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent RightMeshroot;

	UPROPERTY(DefaultComponent)
	USceneComponent LeftMeshroot;

	UPROPERTY(DefaultComponent, Attach = RightMeshroot)
	UStaticMeshComponent RightMesh;

	UPROPERTY(DefaultComponent, Attach = LeftMeshroot)
	UStaticMeshComponent LeftMesh;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};