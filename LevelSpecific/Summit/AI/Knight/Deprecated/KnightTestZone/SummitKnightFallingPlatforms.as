class ASummitKnightFallingPlatforms : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USummitObjectShakeComponent ShakeRoot;

	UPROPERTY(DefaultComponent, Attach = ShakeRoot)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent FloorTile;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent FloorTileTarget;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UNiagaraComponent ImpactVFX;

	UPROPERTY(EditAnywhere)
	float DelayTime;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION()
	void TriggerFallingTiles()
	{
		BP_FallingTile();
	}

	UFUNCTION(BlueprintEvent)
	void BP_FallingTile()
	{

	}
	
};