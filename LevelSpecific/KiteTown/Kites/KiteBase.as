class AKiteBase : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostUpdateWork;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent KiteRoot;

	UPROPERTY(DefaultComponent, Attach = KiteRoot)
	UFauxPhysicsTranslateComponent KiteTranslateRoot;
	default KiteTranslateRoot.bConstrainX = true;
	default KiteTranslateRoot.bConstrainY = true;
	default KiteTranslateRoot.SpringStrength = 5.0;

	UPROPERTY(DefaultComponent, Attach = KiteTranslateRoot)
	UFauxPhysicsConeRotateComponent KiteRotateRoot;
	default KiteRotateRoot.SpringStrength = 0.1;
	default KiteRotateRoot.TorqueBounds = 220.0;
	default KiteRotateRoot.ConeAngle = 15.0;
	default KiteRotateRoot.LocalConeDirection = FVector(0.0, 0.0, -1.0);
	default KiteRotateRoot.ConstrainBounce = 0.0;

	UPROPERTY(DefaultComponent, Attach = KiteRotateRoot)
	USceneComponent KiteHoverRoot;

	UPROPERTY(DefaultComponent, Attach = KiteHoverRoot)
	USceneComponent RopeAttachComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;
	default PlayerWeightComp.PlayerForce = 150.0;
	default PlayerWeightComp.PlayerImpulseScale = 0.25;

	UPROPERTY(EditAnywhere, Category = "Rope")
	bool bUseRope = true;

	UPROPERTY(EditDefaultsOnly, Category = "Rope")
	UStaticMesh RopeMesh;

	UPROPERTY(EditDefaultsOnly, Category = "Rope")
	UStaticMesh SpiralRopeMesh;

	UPROPERTY(EditAnywhere, Category = "Rope", Meta = (MakeEditWidget, EditCondition = "bUseRope && RopeAttachPoint == nullptr", EditConditionHides))
	FVector RopeLocation = FVector(-2000.0, 0.0, -2000.0);

	UPROPERTY(EditAnywhere, Category = "Rope", Meta = (EditCondition = "bUseRope", EditConditionHides))
	AActor RopeAttachPoint;

	UPROPERTY(EditAnywhere, Category = "Rope", Meta = (EditCondition = "bUseRope", EditConditionHides))
	float RopeSlack = 180.0;

	UPROPERTY(EditAnywhere, Category = "Rope", Meta = (EditCondition = "bUseRope", EditConditionHides))
	AHazeActor RopeSplineActor;

	UPROPERTY(EditAnywhere, Category = "Rope", Meta = (EditCondition = "bUseRope", EditConditionHides))
	bool bDebugRope = false;

	bool bUseSpiralRope = false;

	float DesiredMeshLength = 400.0;
	float MeshScale = 1.0;
	ESplineMeshAxis ForwardAxis = ESplineMeshAxis::X;

	UPROPERTY(NotVisible)
	FHazeRuntimeSpline RuntimeSplineRope;

	UPROPERTY(NotVisible)
	TArray<USplineMeshComponent> SplineMeshComponents;

	int NumOfMeshes;
	float MeshLength;

	FVector DefaultKiteOffset;

	UPROPERTY(EditAnywhere, Category = "Hover")
	bool bHover = true;

	UPROPERTY(EditAnywhere, Category = "Hover", Meta = (MakeEditWidget, EditCondition = "bHover", EditConditionHides))
	FKiteHoverValues HoverValues;

	float HoverTimeOffset;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bUseRope)
		{
			SplineMeshComponents.Reset();

			UpdateSpline();
			CreateSplineMeshes();
			UpdateSplineMeshes();
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DefaultKiteOffset = KiteHoverRoot.RelativeLocation;

		TArray<UKiteMovableSplineMeshComponent> Comps;
		GetComponentsByClass(UKiteMovableSplineMeshComponent, Comps);
		for (UKiteMovableSplineMeshComponent Comp : Comps)
			Comp.DestroyComponent(this);

		UpdateSpline();

		if (bUseRope)
		{
			SplineMeshComponents.Reset();
			CreateSplineMeshes();
			UpdateSplineMeshes();
		}

		if (bHover)
		{
			HoverTimeOffset = Math::RandRange(0.0, 2.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bUseRope)
		{
			UpdateSpline();
			UpdateSplineMeshes();

			if (bDebugRope)
				RuntimeSplineRope.DrawDebugSpline(300);
		}

		if (bHover)
		{
			float Time = Time::GameTimeSeconds + HoverTimeOffset;
			float Roll = Math::DegreesToRadians(Math::Sin(Time * HoverValues.HoverRollSpeed) * HoverValues.HoverRollRange);
			float Pitch = Math::DegreesToRadians(Math::Cos(Time * HoverValues.HoverPitchSpeed) * HoverValues.HoverPitchRange);
			FQuat Rotation = FQuat(FVector::ForwardVector, Roll) * FQuat(FVector::RightVector, Pitch);

			KiteHoverRoot.SetRelativeRotation(Rotation);

			float XOffset = Math::Sin(Time * HoverValues.HoverOffsetSpeed.X) * HoverValues.HoverOffsetRange.X;
			float YOffset = Math::Sin(Time * HoverValues.HoverOffsetSpeed.Y) * HoverValues.HoverOffsetRange.Y;
			float ZOffset = Math::Sin(Time * HoverValues.HoverOffsetSpeed.Z) * HoverValues.HoverOffsetRange.Z;

			FVector Offset = DefaultKiteOffset + (FVector(XOffset, YOffset, ZOffset));

			KiteHoverRoot.SetRelativeLocation(Offset);
		}
	}

	void UpdateSpline()
	{
		if (RopeSplineActor != nullptr)
		{
			UHazeSplineComponent SplineComp = UHazeSplineComponent::Get(RopeSplineActor);
			if (SplineComp == nullptr)
				return;

			RuntimeSplineRope = SplineComp.BuildRuntimeSplineFromHazeSpline();
			RuntimeSplineRope.SetPoint(RopeAttachComp.WorldLocation, RuntimeSplineRope.Points.Num() - 1);
		}
		else
		{
			RuntimeSplineRope = FHazeRuntimeSpline();
			FVector RopeStartLoc = RopeAttachPoint == nullptr ? ActorTransform.TransformPosition(RopeLocation) : RopeAttachPoint.ActorLocation;

			TArray<FVector> Points;
			Points.Add(RopeStartLoc);

			FVector RopeAttachLoc = RopeAttachComp.WorldLocation;

			FVector Dir = (RopeAttachLoc - RopeStartLoc).GetSafeNormal();
			FVector MidLoc = (RopeStartLoc + RopeAttachLoc)/2.0;

			FRotator Rot = Dir.Rotation();
			Rot.Pitch -= 90.0;

			Points.Add(MidLoc + Rot.ForwardVector * RopeSlack);

			Points.Add(RopeAttachLoc);
			RuntimeSplineRope.SetPoints(Points);

			RuntimeSplineRope.SetCustomCurvature(0.0);
		}
	}

	void CreateSplineMeshes()
	{
		UStaticMesh Mesh = bUseSpiralRope ? SpiralRopeMesh : RopeMesh;
		MeshScale = bUseSpiralRope ? 0.25 : 1.0;
		DesiredMeshLength = bUseSpiralRope ? 200.0 : 400.0;

		NumOfMeshes = Math::FloorToInt(RuntimeSplineRope.Length / DesiredMeshLength);
		MeshLength = RuntimeSplineRope.Length / NumOfMeshes;

		for (int i = 0; i < NumOfMeshes; i++)
		{
			auto SplineMesh = UKiteMovableSplineMeshComponent::Create(this);

			UStaticMesh MeshToUse = Mesh;
			if (i < 2 || i == NumOfMeshes - 1)
				MeshToUse = RopeMesh;

			SplineMesh.SetStaticMesh(MeshToUse);
			SplineMesh.SetForwardAxis(ForwardAxis);
			SplineMesh.SetCastShadow(true);
			SplineMesh.SetShadowPriorityRuntime(EShadowPriority::GameplayElement);
			SplineMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			SplineMeshComponents.Add(SplineMesh);
		}
	}

	void UpdateSplineMeshes()
	{
		if (NumOfMeshes == 0)
			return;

		MeshLength = RuntimeSplineRope.Length / NumOfMeshes;

		for (int i = 0; i < SplineMeshComponents.Num(); i++)
		{
			FVector StartLocation;
			FRotator StartRotation;
			RuntimeSplineRope.GetLocationAndRotationAtDistance(RuntimeSplineRope.Length - ((i + 1) * MeshLength), StartLocation, StartRotation);

			FVector EndLocation;
			FRotator EndRotation;
			RuntimeSplineRope.GetLocationAndRotationAtDistance(RuntimeSplineRope.Length - (i * MeshLength), EndLocation, EndRotation);

			FRotator MidRotation = RuntimeSplineRope.GetRotationAtDistance(RuntimeSplineRope.Length - (i * MeshLength) + MeshLength * 0.5);

			auto SplineMeshComponent = SplineMeshComponents[i];

			// SplineMeshComponent.SetStartPosition(SplineMeshComponent.WorldTransform.InverseTransformPosition(StartLocation));
			// SplineMeshComponent.SetEndPosition(SplineMeshComponent.WorldTransform.InverseTransformPosition(EndLocation));

			SplineMeshComponent.SetStartAndEnd(
				SplineMeshComponent.WorldTransform.InverseTransformPosition(StartLocation),
				SplineMeshComponent.WorldTransform.InverseTransformVector(StartRotation.ForwardVector * MeshLength),
				SplineMeshComponent.WorldTransform.InverseTransformPosition(EndLocation),
				SplineMeshComponent.WorldTransform.InverseTransformVector(EndRotation.ForwardVector * MeshLength),
				false
			);

			SplineMeshComponent.SetStartScale(FVector2D(MeshScale, MeshScale), false);
			SplineMeshComponent.SetEndScale(FVector2D(MeshScale, MeshScale), false);

			SplineMeshComponent.SetForcedLodModel(1);
		
			// UpDir Roll
			SplineMeshComponent.SetSplineUpDir(StartRotation.UpVector);
			SplineMeshComponent.SetStartRoll(Math::DegreesToRadians((StartRotation.Compose(MidRotation.Inverse)).Roll), false);
			SplineMeshComponent.SetEndRoll(Math::DegreesToRadians((EndRotation.Compose(MidRotation.Inverse)).Roll), false);
		
			SplineMeshComponent.UpdateMesh(false);
		}
	}
}

class UKiteMovableSplineMeshComponent : USplineMeshComponent
{
	default Mobility = EComponentMobility::Movable;
}

struct FKiteHoverValues
{
	UPROPERTY()
	float HoverRollRange = 1.0;
	UPROPERTY()
	float HoverRollSpeed = 3.5;
	UPROPERTY()
	float HoverPitchRange = 2.0;
	UPROPERTY()
	float HoverPitchSpeed = 1.0;
	UPROPERTY()
	FVector HoverOffsetRange = FVector(50.0, 200.0, 50.0);
	UPROPERTY()
	FVector HoverOffsetSpeed = FVector(1.5, 1.0, 1.25);
}

class AKiteRopeAttachmentPointActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UEditorBillboardComponent Billboard;
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 55.0);
	default Billboard.RelativeScale3D = FVector(2.0);
	default Billboard.SpriteName = "AnchorActor";
#endif

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		TArray<AKiteBase> Actors = Editor::GetAllEditorWorldActorsOfClass(AKiteBase);
		for (AActor Actor : Actors)
		{
			AKiteBase Kite = Cast<AKiteBase>(Actor);
			if (Kite != nullptr)
			{
				if (Kite.bUseRope)
				{
					if (Kite.RopeAttachPoint == this)
					{
						Kite.RerunConstructionScripts();
					}
				}
			}
		}
	}
#endif
}