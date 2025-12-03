class APigSausage : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent CapsuleCollision;
	default CapsuleCollision.SetRelativeRotation(FRotator(-90, 0, 0));
	default CapsuleCollision.SetRelativeLocation(FVector::UpVector * Girth * 0.5);
	default CapsuleCollision.SetCapsuleSize(Girth * 0.5, Length * 0.5);

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeOffsetComponent MeshOffsetComponent;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	USplineMeshComponent SplineMesh;
	default SplineMesh.SetStartPosition(-FVector::ForwardVector * Length * 0.5);
	default SplineMesh.SetEndPosition(FVector::ForwardVector * Length * 0.5);
	default SplineMesh.SetMobility(EComponentMobility::Movable);

	UPROPERTY(Category = "Player Specific")
	private UMaterialInterface MioMaterial;

	UPROPERTY(Category = "Player Specific")
	private UMaterialInterface ZoeMaterial;

	UPROPERTY(Category = "Player Specific")
	UMaterialInterface MioGrillMaterial;

	UPROPERTY(Category = "Player Specific")
	UMaterialInterface ZoeGrillMaterial;

	UPROPERTY()
	UMaterialInterface BurnGrillMaterial;

	UPROPERTY()
	UMaterialInterface MaskMaterial;

	UPROPERTY()
	UMaterialInterface KetchupMaterial;

	UPROPERTY()
	UMaterialInterface MustardMaterial;


	UPROPERTY()
	private UDeathEffect DeathEffect;

	UPROPERTY(EditConst, BlueprintReadOnly)
	const float Length = 200;

	UPROPERTY(EditConst, BlueprintReadOnly)
	const float Girth = 50;

	FHazeAcceleratedVector AcceleratedStartTangent;
	FHazeAcceleratedVector AcceleratedEndTangent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcceleratedStartTangent.SnapTo(SplineMesh.StartTangent);
		AcceleratedEndTangent.SnapTo(SplineMesh.EndTangent);
	}

	UMaterialInterface GetMaterialForPlayer(AHazePlayerCharacter Player) const
	{
		return Player.IsMio() ? MioMaterial : ZoeMaterial;
	}

	FVector GetStartTangent() const
	{
		return SplineMesh.StartTangent;
	}

	FVector GetEndTangent() const
	{
		return SplineMesh.EndTangent;
	}

	void UpdateTangents()
	{
		SplineMesh.SetStartTangent(AcceleratedStartTangent.Value);
		SplineMesh.SetEndTangent(AcceleratedEndTangent.Value);
	}
}