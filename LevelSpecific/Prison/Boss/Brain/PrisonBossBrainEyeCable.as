class UPrisonMovableSplineMeshComponent : USplineMeshComponent
{
	default Mobility = EComponentMobility::Movable;
}

class APrisonBossBrainEyeCable : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostUpdateWork;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	USceneComponent CableRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent CableAttachComp;

	UPROPERTY(EditInstanceOnly)
	ASplineActor FollowSpline;

	FHazeRuntimeSpline RuntimeSpline;

	UPROPERTY(EditAnywhere)
	UStaticMesh Mesh;

	UPROPERTY(EditAnywhere)
	float DesiredMeshLength = 900.0;

	UPROPERTY(EditAnywhere)
	float MeshScale = 0.85;

	UPROPERTY(EditInstanceOnly)
	APrisonBossBrainEye Eye;
	TArray<USplineMeshComponent> SplineMeshComponents;

	int NumOfMeshes;
	float MeshLength;
	FVector FootLocation;
	FRotator FootRotation;

	bool bSagging = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UpdateSpline();

		SplineMeshComponents.Reset();
		CreateSplineMeshes();
		UpdateSplineMeshes();
	}

	UFUNCTION()
	void StartSagging()
	{
		bSagging = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdateSpline();
		UpdateSplineMeshes();
	}

	void UpdateSpline()
	{
		TArray<FVector> Points;
		Points.Add(CableAttachComp.WorldLocation);

		float DistanceToEye = ActorLocation.Distance(Eye.CableRoot.WorldLocation);

		float DistanceAlpha = Math::GetMappedRangeValueClamped(FVector2D(4000.0, 1500.0), FVector2D(1.0, 0.0), DistanceToEye);
		float SecondPointOffset = Math::Lerp(100.0, 300.0, DistanceAlpha);
		FVector SecondPoint = CableAttachComp.WorldLocation + (ActorForwardVector * SecondPointOffset);

		Points.Add(SecondPoint);
		if (bSagging)
		{
			FVector MidLoc = Eye.CableRoot.WorldLocation - (Eye.CableRoot.ForwardVector * 600.0);
			MidLoc -= Eye.CableRoot.RightVector * 1200.0;
			Points.Add(MidLoc);
		}

		FVector HalfwayPoint = (SecondPoint + Eye.CableRoot.WorldLocation)/2.0;
		float HalfwayPointHeight = Math::Lerp(400.0, 1200.0, DistanceAlpha);
		HalfwayPoint += FVector::UpVector * HalfwayPointHeight;
		Points.Add(HalfwayPoint);

		float SecondaryEyePointOffset = Math::Lerp(400.0, 800.0, DistanceAlpha);
		float SecondaryEyePointHeightOffset = Math::Lerp(250.0, 800.0, DistanceAlpha);
		Points.Add(Eye.CableRoot.WorldLocation + (Eye.CableRoot.ForwardVector * -SecondaryEyePointOffset) + (FVector::UpVector * SecondaryEyePointHeightOffset));
		Points.Add(Eye.CableRoot.WorldLocation + (Eye.CableRoot.ForwardVector * -250.0));

		Points.Add(Eye.CableRoot.WorldLocation);

		RuntimeSpline.Points = Points;
	}

	void DrawDebug()
	{
		TArray<FVector> Points = RuntimeSpline.Points;
		TArray<FVector> UpDirections = RuntimeSpline.UpDirections;

		TArray<FVector> Locations;
		RuntimeSpline.GetLocations(Locations, 32);
		TArray<FVector> Directions;
		RuntimeSpline.GetDirections(Directions, 32);
		TArray<FQuat> Quats;
		RuntimeSpline.GetQuats(Quats, 32);

		for (int i = 0; i < Points.Num(); i++)
			Debug::DrawDebugLine(Points[i], Points[i] + UpDirections[i] * 500.0, FLinearColor::Green, 10.0, 0.0);

		for (int i = 0; i < Locations.Num(); i++)
		{
			Debug::DrawDebugLine(Locations[i], Locations[i] + Quats[i].UpVector * 2000.0, FLinearColor::Blue, 30.0, 0.0);
			Debug::DrawDebugLine(Locations[i], Locations[i] + Quats[i].RightVector * 2000.0, FLinearColor::Green, 30.0, 0.0);
			Debug::DrawDebugLine(Locations[i], Locations[i] + Quats[i].ForwardVector * 2000.0, FLinearColor::Red, 30.0, 0.0);
		}

		// PrintToScreen("" + RuntimeSpline.Length, 0.0, FLinearColor::Green);		
	}

	void CreateSplineMeshes()
	{
		NumOfMeshes = Math::FloorToInt(RuntimeSpline.Length / DesiredMeshLength);
		MeshLength = RuntimeSpline.Length / NumOfMeshes;

		for (int i = 0; i < NumOfMeshes; i++)
		{
			auto SplineMesh = UPrisonMovableSplineMeshComponent::Create(this);
			SplineMesh.StaticMesh = Mesh;
			SplineMesh.ForwardAxis = ESplineMeshAxis::Z;
			SplineMesh.SetCastShadow(true);
			SplineMesh.SetShadowPriorityRuntime(EShadowPriority::LevelElement);
			SplineMeshComponents.Add(SplineMesh);
		}
	}

	void UpdateSplineMeshes()
	{
		if (NumOfMeshes == 0)
			return;

		MeshLength = RuntimeSpline.Length / NumOfMeshes;

		for (int i = 0; i < SplineMeshComponents.Num(); i++)
		{
			FVector StartLocation;
			FRotator StartRotation;
			RuntimeSpline.GetLocationAndRotationAtDistance(RuntimeSpline.Length - ((i + 1) * MeshLength), StartLocation, StartRotation);

			FVector EndLocation;
			FRotator EndRotation;
			RuntimeSpline.GetLocationAndRotationAtDistance(RuntimeSpline.Length - (i * MeshLength) +50, EndLocation, EndRotation);

			FRotator MidRotation = RuntimeSpline.GetRotationAtDistance(RuntimeSpline.Length - (i * MeshLength) + MeshLength * 0.5);

			auto SplineMeshComponent = SplineMeshComponents[i];

			SplineMeshComponent.SetStartAndEnd(
				SplineMeshComponent.WorldTransform.InverseTransformPosition(StartLocation),
				SplineMeshComponent.WorldTransform.InverseTransformVector(StartRotation.ForwardVector * MeshLength),
				SplineMeshComponent.WorldTransform.InverseTransformPosition(EndLocation),
				SplineMeshComponent.WorldTransform.InverseTransformVector(EndRotation.ForwardVector * MeshLength),
				false
			);

			SplineMeshComponent.SetStartScale(FVector2D(MeshScale, MeshScale), false);
			SplineMeshComponent.SetEndScale(FVector2D(MeshScale, MeshScale), false);
		
			// UpDir Roll
			SplineMeshComponent.SetSplineUpDir(StartRotation.UpVector);
			SplineMeshComponent.SetStartRoll(Math::DegreesToRadians((StartRotation.Compose(MidRotation.Inverse)).Roll), false);
			SplineMeshComponent.SetEndRoll(Math::DegreesToRadians((EndRotation.Compose(MidRotation.Inverse)).Roll), false);
		
			SplineMeshComponent.UpdateMesh(false);
		}
	}

	UFUNCTION(BlueprintPure)
	FHazeRuntimeSpline GetRuntimeSpline()
	{
		return RuntimeSpline;
	}
}