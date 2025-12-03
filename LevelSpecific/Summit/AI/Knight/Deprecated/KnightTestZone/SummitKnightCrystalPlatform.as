class ASummitKnightCrystalPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent TileMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent CrystalMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent CrystalMeshTarget;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent ShockwaveMesh;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UNiagaraComponent DestroyVFX;

	UPROPERTY()
	FVector StartScale;

	UPROPERTY()
	FVector TargetScale;

	UPROPERTY()
	FVector Startlocation;

	UPROPERTY()
	FVector TargetLocation;

	UPROPERTY()
	FVector StartColor;

	UPROPERTY()
	FVector TargetColor;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike StartAnim;
	default StartAnim.Duration = 3.0;
	default StartAnim.Curve.AddDefaultKey(0.0, 0.0);
	default StartAnim.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	FHazeTimeLike AttackAnim;
	default AttackAnim.Duration = 5.0;
	default AttackAnim.Curve.AddDefaultKey(0.0, 0.0);
	default AttackAnim.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	FHazeTimeLike ShockwaveAnim;
	default ShockwaveAnim.Duration = 5.0;
	default ShockwaveAnim.Curve.AddDefaultKey(0.0, 0.0);
	default ShockwaveAnim.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	float StartDelay;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		 Startlocation = CrystalMesh.RelativeLocation;
		 TargetLocation = CrystalMeshTarget.RelativeLocation;

		 StartScale = ShockwaveMesh.RelativeScale3D;

		 TargetScale = FVector(15.0,15.0,11.0);
	}

	UFUNCTION()
	void TriggerCrystalTiles()
	{
		BP_StartCrystalTile();
	}

	UFUNCTION()
	void CrystalTileAttack()
	{
		BP_CrystalTileAttack();
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartCrystalTile()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_ReverseCrystalTR()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_CrystalTileAttack()
	{
	}
};