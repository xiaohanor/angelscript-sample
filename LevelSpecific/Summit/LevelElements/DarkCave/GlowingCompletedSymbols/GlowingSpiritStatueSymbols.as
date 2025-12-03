class AGlowingSpiritStatueSymbols : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance EmissiveMat;

	UPROPERTY(EditInstanceOnly)
	ADarkCaveSpiritStatue SpiritStatue;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpiritStatue.OnSummitGemDestroyed.AddUFunction(this, n"OnSummitGemDestroyed");
	}

	UFUNCTION()
	private void OnSummitGemDestroyed(ASummitNightQueenGem CrystalDestroyed)
	{
		MeshComp.SetMaterial(0, EmissiveMat);
	}
};