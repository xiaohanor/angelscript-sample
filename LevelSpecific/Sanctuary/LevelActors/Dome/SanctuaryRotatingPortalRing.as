class ASanctuaryRotatingPortalRing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHierarchicalInstancedStaticMeshComponent HISM;

	UPROPERTY(EditAnywhere)
	float RotationSpeed = 4.0;

	UPROPERTY(EditAnywhere)
	float Radius = 2000.0;

	UPROPERTY(EditAnywhere)
	float TargetOffset = 80.0;

	UPROPERTY(EditAnywhere)
	float MeshScale = 1.0;

	UPROPERTY(EditAnywhere)
	float BoxSize = 300.0;

	UPROPERTY(EditAnywhere)
	int Instances = 10;

	UPROPERTY(EditAnywhere)
	UStaticMesh Mesh;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		HISM.ClearInstances();
		HISM.SetStaticMesh(Mesh);
		float AngleStep = TWO_PI / Instances;

		for (int i = 0; i < Instances; i++)
		{
			FTransform InstanceTransform;
			FVector Location = FVector(Math::Cos(i * AngleStep) * Radius, Math::Sin(i * AngleStep) * Radius, 0.0);

			InstanceTransform.Scale3D = FVector(0.25, 1.0, 1.0) * MeshScale;
			InstanceTransform.Location = Location;
			InstanceTransform.Rotation = Location.ToOrientationQuat();
			HISM.AddInstance(InstanceTransform);
			auto AutoPlacementComp = UDarkPortalAutoPlacementComponent::Create(this, FName("AutoPlacementComp" + i));
			AutoPlacementComp.RelativeTransform = InstanceTransform;
			AutoPlacementComp.RelativeLocation += AutoPlacementComp.ForwardVector * TargetOffset;
			AutoPlacementComp.bOnlyWhenPlacedInShape = true;
			AutoPlacementComp.PlacementShape.Type = EHazeShapeType::Box;
			AutoPlacementComp.PlacementShape.BoxExtents = FVector(300.0, BoxSize + 30.0, BoxSize + 30.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorRotation = FRotator(0.0, Time::PredictedGlobalCrumbTrailTime * RotationSpeed, 0.0);
	}
};