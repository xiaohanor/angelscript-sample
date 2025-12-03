class ASkylineInnerCitySunBader : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(EditAnywhere)
	ASkylineInnerCitySunbedRoof SunBed;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintEvent)
	void StartCooking()
	{

	}
};