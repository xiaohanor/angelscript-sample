class ATundraGrowingFlower : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UTundraPlayerShapeshiftingComponent ShapeshiftComp;

	float ReactRadius = 1500;

	FHazeAcceleratedFloat CurrentSize;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Game::Zoe);
		CurrentSize.SnapTo(0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(ShapeshiftComp == nullptr)
		{
			ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Game::Zoe);
			return;
		}


		float SizeTarget = 0;

		if(ShouldGrow())
			SizeTarget = 1;

		CurrentSize.SpringTo(SizeTarget, 30, 0.4, DeltaSeconds);
		CurrentSize.Value = Math::Clamp(CurrentSize.Value, 0, CurrentSize.Value);
		SetActorScale3D(FVector::OneVector * CurrentSize.Value * 2);
	}

	bool ShouldGrow() const
	{
		if(ShapeshiftComp.GetCurrentShapeType() != ETundraShapeshiftShape::Big)
			return false;

		else if(ShapeshiftComp.Owner.GetDistanceTo(this) > ReactRadius)
			return false;

		return true;
	}
};