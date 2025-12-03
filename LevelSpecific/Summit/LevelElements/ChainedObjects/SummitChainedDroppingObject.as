class ASummitChainedDroppingObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root )
	UFauxPhysicsTranslateComponent FauxTranslate;

	UPROPERTY(DefaultComponent, Attach = FauxTranslate)
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere)
	ANightQueenChain Chain;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UFauxPhysicsWeightComponent FauxWeight;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FauxWeight.AddDisabler(this);
		Chain.OnNightQueenMetalMelted.AddUFunction(this, n"OnMetalMelted");
	}

	UFUNCTION()
	private void OnMetalMelted()
	{
		FauxWeight.RemoveDisabler(this);
	}
}