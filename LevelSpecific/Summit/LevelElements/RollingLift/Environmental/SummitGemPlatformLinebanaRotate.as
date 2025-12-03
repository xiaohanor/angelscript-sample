class ASummitGemPlatformLinebanaRotate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere)
	ASummitNightQueenGem Gem;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UFauxPhysicsWeightComponent WeightComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WeightComp.AddDisabler(this);	
		Gem.OnSummitGemDestroyed.AddUFunction(this, n"OnGemDestroyed");	
	}

	UFUNCTION()
	private void OnGemDestroyed(ASummitNightQueenGem CrystalDestroyed)
	{
		WeightComp.RemoveDisabler(this);
	}
};