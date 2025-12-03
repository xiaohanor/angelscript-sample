class APrisonBossBrainCable : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostUpdateWork;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	USceneComponent CableRoot;

	UPROPERTY(EditInstanceOnly)
	AActor SplineActor;
	UHazeSplineComponent TargetSplineComp;

	UPROPERTY(EditInstanceOnly)
	AActor AttachActor;

	FHazeRuntimeSpline RuntimeSpline;

	UPROPERTY(EditAnywhere)
	UStaticMesh Mesh;

	UPROPERTY(EditAnywhere)
	float DesiredMeshLength = 600.0;

	UPROPERTY(EditAnywhere)
	float MeshScale = 0.25;

	UPROPERTY(EditAnywhere)
	AActor StartTangentTarget;

	UPROPERTY(EditAnywhere)
	AActor EndTangentTarget;

	TArray<USplineMeshComponent> SplineMeshComponents;

	int NumOfMeshes;
	float MeshLength;
	FVector FootLocation;
	FRotator FootRotation;

	bool bSagging = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetSplineComp = UHazeSplineComponent::Get(SplineActor);

		RuntimeSpline.SetCustomCurvature(1.0);
		
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
		TArray<FVector> UpDirs;

		for (FHazeSplinePoint SplinePoint : TargetSplineComp.SplinePoints)
		{
			FTransform Transform = FTransform(SplineActor.ActorRotation, SplineActor.ActorLocation);
			FVector Loc = Transform.TransformPosition(SplinePoint.RelativeLocation);
			FRotator Rot = Transform.TransformRotation(SplinePoint.RelativeRotation.Rotator());
			Points.Add(Loc);
			UpDirs.Add(Rot.UpVector);
		}

		FTransform StartTransform = FTransform(SplineActor.ActorRotation, SplineActor.ActorLocation);
		FVector StartLoc = StartTransform.TransformPosition(TargetSplineComp.SplinePoints[0].RelativeLocation);
		FVector TransformedStartTangent = StartTransform.TransformVector(TargetSplineComp.SplinePoints[0].ArriveTangent).GetSafeNormal();
		FVector StartTangentLoc = StartLoc + (-TransformedStartTangent * 2000.0);

		RuntimeSpline.SetCustomEnterTangentPoint(StartTangentTarget.ActorLocation);

		RuntimeSpline.SetCustomExitTangentPoint(EndTangentTarget.ActorLocation);

		Points.RemoveAt(Points.Num() - 1);
		Points.Add(AttachActor.ActorLocation);

		// RuntimeSpline.SetPointsAndUpDirections(Points, UpDirs);
		RuntimeSpline.SetPoints(Points);
		RuntimeSpline.SetCustomCurvature(1.0);
	}

	void CreateSplineMeshes()
	{
		NumOfMeshes = Math::FloorToInt(RuntimeSpline.Length / DesiredMeshLength);
		MeshLength = RuntimeSpline.Length / NumOfMeshes;

		for (int i = 0; i < NumOfMeshes; i++)
		{
			auto SplineMesh = UPrisonMovableSplineMeshComponent::Create(this);
			SplineMesh.StaticMesh = Mesh;
			SplineMesh.ForwardAxis = ESplineMeshAxis::X;
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
			RuntimeSpline.GetLocationAndRotationAtDistance(RuntimeSpline.Length - (i * MeshLength), EndLocation, EndRotation);

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