class USketchbookDarkCaveCutoutComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	float Radius = 200;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TListedActors<ASketchbookDarkCaveShader>().Single.AddCutoutComponent(this);
	}
	};