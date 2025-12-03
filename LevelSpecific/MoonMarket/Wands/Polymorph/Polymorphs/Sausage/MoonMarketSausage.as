class AMoonMarketSausage : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

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

	UPROPERTY()
	UMaterialInterface MaskMaterial;

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