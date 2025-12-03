class ASanctuaryBossInsideStatue : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent StatueMesh;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdRespComp;

	UPROPERTY(DefaultComponent)
	USceneComponent SwordRoot;

	UPROPERTY(DefaultComponent, Attach = SwordRoot)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = SwordRoot)
	UStaticMeshComponent SwordMesh;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LightBirdRespComp.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
	}

	UFUNCTION(BlueprintEvent)
	private void HandleIlluminated()
	{
	}
};