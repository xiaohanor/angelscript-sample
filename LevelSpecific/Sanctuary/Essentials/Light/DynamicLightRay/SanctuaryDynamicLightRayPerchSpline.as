class ASanctuaryDynamicLightRayPerchSpline : APerchSpline
{
	default bAllowGrappleToPoint = false;
	default bValidatePlayerSplineDistanceAndSplineLength = true;

	USanctuaryDynamicLightRayMeshComponent Mesh;

	UPROPERTY(EditAnywhere)
	float Height = 500.0;

	TArray<FInstigator> DisableInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		Mesh = USanctuaryDynamicLightRayMeshComponent::Get(this);
		UpdateHeight(Height);
	}

	UFUNCTION(BlueprintCallable)
	void UpdateHeight(float InHeight)
	{
		Height = InHeight;

		if (Mesh == nullptr)
			return;

		float HeightFraction = InHeight / 100.0;
		Mesh.RelativeScale3D = FVector(
			Mesh.RelativeScale3D.X,
			Mesh.RelativeScale3D.Y,
			HeightFraction
		);
	}

	void Disable(FInstigator Instigator)
	{
		if (DisableInstigators.Num() == 0)
		{
			DisablePerchSpline(this);
			Mesh.Disable();
		}

		DisableInstigators.Add(Instigator);
	}

	void RemoveDisable(FInstigator Instigator)
	{
		if (DisableInstigators.Remove(Instigator) != 0 && DisableInstigators.Num() == 0)
		{
			EnablePerchSpline(this);
			Mesh.Enable();
		}
	}
}