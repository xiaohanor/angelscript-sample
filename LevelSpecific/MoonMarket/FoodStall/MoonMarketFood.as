class AMoonMarketFood : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent FoodMeshComp;

	UPROPERTY(EditAnywhere)
	UStaticMesh FoodMesh;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetMesh();
	}

	UFUNCTION(CallInEditor)
	void SetMesh()
	{
		if (FoodMesh != nullptr && FoodMeshComp.StaticMesh != FoodMesh)
		{
			FoodMeshComp.StaticMesh = FoodMesh;
		}
	}
};