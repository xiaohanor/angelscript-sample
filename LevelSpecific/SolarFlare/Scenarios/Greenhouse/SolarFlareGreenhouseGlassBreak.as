class ASolarFlareGreenhouseGlassBreak : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent NormalGlassMesh;
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BrokenGlassMesh;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	
};