class ASummitKnightRegeningPlatforms : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USummitObjectShakeComponent Shake;

	UPROPERTY(DefaultComponent, Attach = Shake)
	UStaticMeshComponent FloorTile;
	
	UPROPERTY(DefaultComponent, Attach = Shake)
	UStaticMeshComponent FloorTileTarget;

	UPROPERTY(DefaultComponent, Attach = Shake)
	UNiagaraComponent ImpactVFX;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike FallingAnim;
	default FallingAnim.Duration = 3.0;
	default FallingAnim.Curve.AddDefaultKey(0.0, 0.0);
	default FallingAnim.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	float DownTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void RemoveTiles()
	{
		BP_DestroyTile();
	}

	UFUNCTION(BlueprintEvent)
	void BP_DestroyTile()
	{

	}
};