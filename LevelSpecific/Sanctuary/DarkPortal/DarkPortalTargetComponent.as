class UDarkPortalTargetComponent : UTargetableComponent
{
	default TargetableCategory = n"DarkPortal";
	default UsableByPlayers = EHazeSelectPlayer::Zoe;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targetable")
	float MaximumDistance = DarkPortal::Grab::Range;

	// Whether to limit the grabbable angle of this targetable.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targetable")
	bool bLimitAngle = false;

	// Angle at which the portal can grab the targetable, relative to targetable up vector.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targetable", Meta = (EditCondition = "bLimitAngle", EditConditionHides))
	float LimitedAngle = 45.0;

	// Whether we want to automatically release this targetable if it exits our limited angle.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targetable", Meta = (EditCondition = "bLimitAngle", EditConditionHides))
	bool bAutoReleaseLimited = true;

	// If true, we do not need line of sight between portal and targetable to hold on to it (we might need LOS to start grab though)
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targetable")
	bool bIgnoreLOSWhenGrabbed = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Points")
	TArray<FVector> GrabPoints;

	// When grabbed, we do not release from angle or blocked LOS for at least this time, to avoid flickering grab/release.
	float MinGrabTime = 0.1;
	float LastGrabbedTime = -BIG_NUMBER;

	void OnGrabbed()
	{
		LastGrabbedTime = Time::GameTimeSeconds;
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		return true;
	}

	// clustered, close to the location of the mesh
	UFUNCTION(CallInEditor, Category = "Points")
	private void ClearGrabPoints()
	{
		GrabPoints.Empty();
	}

	// clustered, close to the location of the mesh
	UFUNCTION(CallInEditor, Category = "Points")
	private void RegenerateGrabPoints_Clustered()
	{
		GrabPoints.Empty();
		GenerateGrabPoints_Clustered(DarkPortal::Grab::MaxGrabs);
	}

	// (more) uniformely around the entire mesh
	UFUNCTION(CallInEditor, Category = "Points")
	private void RegenerateGrabPoints_Uniform()
	{
		GrabPoints.Empty();
		GenerateGrabPoints_Uniform(DarkPortal::Grab::MaxGrabs);
	}

	private void GenerateGrabPoints_Uniform(int NumPoints)
	{
		USceneComponent Parent = AttachParent;
		UPrimitiveComponent Primitive = nullptr;
		while (Parent != nullptr && Primitive == nullptr)
		{
			Primitive = Cast<UPrimitiveComponent>(Parent);
			Parent = Parent.AttachParent;
		}

		if (Primitive == nullptr)
			return;

		for (int i = 0; i < NumPoints; ++i)
		{
			FVector Point;
			if (GetRelativeClosestPointOnCollision(Primitive, Point))
				GrabPoints.Add(Point);
		}
	}

	private void GenerateGrabPoints_Clustered(int NumPoints)
	{
		USceneComponent Parent = AttachParent;
		UPrimitiveComponent Primitive = nullptr;
		while (Parent != nullptr && Primitive == nullptr)
		{
			Primitive = Cast<UPrimitiveComponent>(Parent);
			Parent = Parent.AttachParent;
		}

		if (Primitive == nullptr)
			return;

		for (int i = 0; i < NumPoints; ++i)
		{
			FVector Point;
			if (GetRelativePointFromTrace(Primitive, Point))
				GrabPoints.Add(Point);
		}
	}
	
	private bool GetRelativeClosestPointOnCollision(UPrimitiveComponent Primitive, FVector& Point)
	{
		if (Primitive == nullptr)
			return false;

		FVector Offset = Math::GetRandomPointOnSphere() * Primitive.BoundsRadius;
		Primitive.GetClosestPointOnCollision(WorldLocation + Offset, Point);
		Point = WorldTransform.InverseTransformPositionNoScale(Point);
		return true;
	}

	private bool GetRelativePointFromTrace(UPrimitiveComponent Primitive, FVector& Point, int TraceAttempts = 32, bool TraceComplex = true)
	{
		if (Primitive == nullptr || TraceAttempts <= 0)
			return false;

		for (int j = 0; j < TraceAttempts; ++j)
		{
			FVector Offset = Math::GetRandomPointInSphere() * Primitive.BoundsRadius * 2.0;

			FName BoneName;
			FVector ImpactPoint, ImpactNormal;
			FHitResult HitResult;
			Primitive.LineTraceComponent(
				WorldLocation + Offset,
				WorldLocation - Offset,
				TraceComplex,
				false,
				false,
				ImpactPoint,
				ImpactNormal,
				BoneName,
				HitResult
			);

			if (HitResult.Time > KINDA_SMALL_NUMBER && HitResult.Time < 1.0 - KINDA_SMALL_NUMBER)
			{
				Point = WorldTransform.InverseTransformPositionNoScale(HitResult.ImpactPoint);
				return true;
			}
		}

		return false;
	}
}

#if EDITOR
class UDarkPortalTargetComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UDarkPortalTargetComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto Component = Cast<UDarkPortalTargetComponent>(InComponent);
		if (Component == nullptr)
			return;

		if (Component.bLimitAngle)
		{
			float Distance = 100.0; // Component.MaximumDistance;
			FVector Origin = Component.WorldLocation + Component.UpVector * Distance;
			float Size = Math::Tan(Math::DegreesToRadians(Component.LimitedAngle)) * Distance;
			DrawCircle(Origin, Size, FLinearColor::DPink, 2.0, Normal = Component.UpVector);

			int NumLines = 4;
			for (int i = 0; i < NumLines; ++i)
			{
				float Angle = (i / float(NumLines)) * PI * 2.0;
				FRotator LineOffset = Math::RotatorFromAxisAndAngle(Component.UpVector, Math::RadiansToDegrees(Angle));
				DrawDashedLine(Component.WorldLocation, Origin + LineOffset.ForwardVector * Size, FLinearColor::Gray);
			}
		}

		for (auto& Point : Component.GrabPoints)
		{
			DrawPoint(Component.WorldTransform.TransformPositionNoScale(Point), FLinearColor::DPink, 25.f);
		}
	}
}
#endif