class ASummitDoubleChainedBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp )
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere)
	float FirstDropAngle;

	UPROPERTY(EditAnywhere)
	float FinalDropAngle;

	UPROPERTY(EditAnywhere)
	TArray<ANightQueenMetal> Chains;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UFauxPhysicsWeightComponent WeightComp;

	int MetalCount = 2;

	FRotator StartRot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WeightComp.AddDisabler(this);	

		for (ANightQueenMetal Chain : Chains)
		{
			Chain.OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
		}
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		MetalCount--;

		if (MetalCount <= 0)
		{
			WeightComp.RemoveDisabler(this);
		}
	}
}