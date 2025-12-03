class ASummitMetalPlatformLinebana : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere)
	ANightQueenMetal Metal;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UFauxPhysicsWeightComponent WeightComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WeightComp.AddDisabler(this);	
		Metal.OnNightQueenMetalMelted.AddUFunction(this,n"OnMetalMelted");
	}

	UFUNCTION()
	private void OnMetalMelted()
	{
		WeightComp.RemoveDisabler(this);
	}
};