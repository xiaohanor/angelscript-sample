class ASummitChainedBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp )
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere)
	ANightQueenMetal Chain;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UFauxPhysicsWeightComponent WeightComp;

	int MetalCount;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WeightComp.AddDisabler(this);	
		Chain.OnNightQueenMetalMelted.AddUFunction(this, n"OnMetalMelted");					 
	}

	UFUNCTION()
	private void OnMetalMelted()
	{
		WeightComp.RemoveDisabler(this);
	}
}