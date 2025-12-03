class ASkylineSwingSign : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Sign;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent WallGrabMesh;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike TimeLike;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};