struct FTundraGnatCapsule
{
	UPROPERTY()
	float Radius;

	UPROPERTY()
	float Halfheight;

	UPROPERTY()
	FTransform Transform;

	float GetDistanceTo(FVector Location) const
	{
		return Math::Max(Location.Distance(GetCenterLocation(Location)) - Radius, 0.0);
	}

	FVector GetCenterLocation(FVector Location) const
	{
		FVector CenterLoc;
		float DummyFraction;
		FVector CapsuleCenterExtent = Transform.Rotation.UpVector * Halfheight;
		Math::ProjectPositionOnLineSegment((Transform.Location + CapsuleCenterExtent), (Transform.Location - CapsuleCenterExtent), Location, CenterLoc, DummyFraction);
		return CenterLoc;
	}
}

UCLASS(hidecategories="Rendering Activation Cooking Replication ComponentTick Disable Debug Events Physics LOD Collision")
class UTundraGnatHostComponent : USceneComponent
{
	TArray<UTundraGnatEntryScenepointComponent> EntryPoints;
	TArray<UTundraGnatEntryScenepointComponent> FrontEntryPoints;
	UTundraGnatEntryScenepointComponent WaveSpawnPoint;
	int WaveIndex = 0;
	UHazeSkeletalMeshComponentBase Mesh;
	UStaticMeshComponent Body;

	// Currently we only have two capsules for the physics of the thorax and abdomen
	UPROPERTY()
	FTundraGnatCapsule ThoraxCapsule;
	default ThoraxCapsule.Radius = 1500.0;
	default ThoraxCapsule.Halfheight = 3500.0;
	default ThoraxCapsule.Transform = FTransform(FRotator(90.0, 0.0, 0.0), FVector(0, 0.0, 0.0));

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Owner.GetComponentsByClass(EntryPoints);

		FrontEntryPoints.SetNumZeroed(2);
		FVector2D BestDot = FVector2D(-BIG_NUMBER, -BIG_NUMBER);
		for (UTundraGnatEntryScenepointComponent Point : EntryPoints)
		{
			FVector ToPoint = Point.WorldLocation - Owner.ActorLocation;
			float Dot = ToPoint.DotProduct(Owner.ActorForwardVector);
			int iSide = (ToPoint.DotProduct(Owner.ActorRightVector) > 0.0) ? 0 : 1;
			if (Dot < BestDot[iSide])
				continue;
			// Found a point to right/left which is further forward than any others of that side
			FrontEntryPoints[iSide] = Point;
			BestDot[iSide] = Dot;
		}
		check((FrontEntryPoints[0] != nullptr) && (FrontEntryPoints[1] != nullptr));
		
		//Hack for UXR, DO NOT WANT LEFT POINT
		FrontEntryPoints.RemoveAt(1);

		Mesh = UHazeSkeletalMeshComponentBase::Get(Owner);
		Body = GetBody();
	}

	UStaticMeshComponent GetBody()
	{
		return UStaticMeshComponent::Get(Owner, n"Body");
	}

	FTundraGnatCapsule GetClosestCapsule(FVector Location) const
	{
		// Only one capsule for now
		FTundraGnatCapsule Capsule = ThoraxCapsule;
		Capsule.Transform = Capsule.Transform * WorldTransform;
		Capsule.Radius *= Capsule.Transform.Scale3D.X;
		Capsule.Halfheight *= Capsule.Transform.Scale3D.Z;
		return Capsule;
	}
}

#if EDITOR
class UTundraGnatHostComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundraGnatHostComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UTundraGnatHostComponent Host = Cast<UTundraGnatHostComponent>(Component);
        if (Host == nullptr)
            return;

		FTransform ThoraxPos = Host.ThoraxCapsule.Transform * Host.WorldTransform;
		DrawWireCapsule(ThoraxPos.Location, ThoraxPos.Rotator(), FLinearColor::LucBlue, Host.ThoraxCapsule.Radius, Host.ThoraxCapsule.Halfheight + Host.ThoraxCapsule.Radius, 16, 2.0);
   	}
}
#endif
