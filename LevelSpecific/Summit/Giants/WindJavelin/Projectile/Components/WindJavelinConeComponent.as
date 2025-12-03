class UWindJavelinConeComponent : USceneComponent
{
	const bool DEBUG_DRAW = false;

	default PrimaryComponentTick.bStartWithTickEnabled = DEBUG_DRAW;

	UPROPERTY(Category = "Wind Javelin Cone Component")
	float BottomRadius = 64.0;

	UPROPERTY(Category = "Wind Javelin Cone Component")
	float TopRadius = 256.0;

	UPROPERTY(Category = "Wind Javelin Cone Component")
	float Height = 750.0;

	UPROPERTY(Category = "Wind Javelin Cone Component")
	float ForceMagnitude = 6000.0;

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        BottomRadius = Math::Clamp(BottomRadius, 0.0, TopRadius);
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		DebugDraw();
	}

	float DistanceToCone(const FVector& p)
	{
		const FVector a = TopLocation;
		const float ra = TopRadius;

		const FVector b = BottomLocation;
		const float rb = BottomRadius;

		// Capped Cone SDF
		// https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
		const float rba  = rb - ra;
		const float baba = (b - a).DotProduct(b - a);
		const float papa = (p - a).DotProduct(p - a);
		const float paba = (p - a).DotProduct(b - a) / baba;
		const float x = Math::Sqrt(papa - paba * paba * baba);
		const float cax = Math::Max(0.0, x - ((paba < 0.5) ? ra : rb));
		const float cay = Math::Abs(paba - 0.5) - 0.5;
		const float k = rba * rba + baba;
		const float f = Math::Clamp((rba * (x - ra) + paba * baba) / k, 0.0, 1.0);
		const float cbx = x - ra - f * rba;
		const float cby = paba - f;
		const float s = (cbx<0.0 && cay < 0.0) ? -1.0 : 1.0;
		return Math::Max(s * Math::Sqrt(Math::Min(cax * cax + cay * cay * baba, cbx * cbx + cby * cby * baba)), 0.0);
	}

	FVector GetFullWindForce() const
	{
		return ForwardVector * ForceMagnitude;
	}

	FVector CalculateAccelerationAtLocation(FVector Location) const
	{
		float AccelerationMultiplier = GetMoveFractionAtLocation(Location);
		return GetFullWindForce() * AccelerationMultiplier;
	}

	FVector CalculateDrag(FVector Velocity, FVector WorldUp) const
	{
		// Add hover drag
		const FVector HoverDragConstrainedVelocity = -Velocity.ConstrainToDirection(ForwardVector);
		const float Dot = HoverDragConstrainedVelocity.DotProduct(WorldUp);
		const FVector HoverDrag = HoverDragConstrainedVelocity * Math::Max(0.0, Dot);

		return HoverDrag.GetClampedToMaxSize(3000.0);	// Filip TODO: Should use player gravity
	}

	float GetMoveFractionAtLocation(FVector Location) const
	{
		const FVector ShapeBase = GetBottomLocation();
		const FVector Diff = Location - ShapeBase;
		const float HeightInVolume = Diff.DotProduct(ForwardVector);

		const float Fraction = 1.0 - Math::Saturate(HeightInVolume / Height);

		return Fraction;
	}

	FVector GetBottomLocation() const property
	{
		return WorldTransform.GetLocation();
	}

	FVector GetCenterLocation() const property
	{
		return GetBottomLocation() + (ForwardVector * (Height * 0.5));
	}

	FVector GetTopLocation() const property
	{
		return GetBottomLocation() + (ForwardVector * Height);
	}

	void DebugDraw() const
	{
		if(!DEBUG_DRAW)
			return;

		const FQuat Rotation = WorldTransform.GetRotation();

		Debug::DrawDebugCircle(BottomLocation, BottomRadius, 16, FLinearColor::Blue, 3.0, Rotation.RightVector, Rotation.UpVector);	
		Debug::DrawDebugCircle(TopLocation, TopRadius, 16, FLinearColor::Blue, 3.0, Rotation.RightVector, Rotation.UpVector);	

		TArray<FVector> RadiusOffsetLocation;
		RadiusOffsetLocation.Add(Rotation.UpVector);
		RadiusOffsetLocation.Add(-Rotation.UpVector);
		RadiusOffsetLocation.Add(Rotation.RightVector);
		RadiusOffsetLocation.Add(-Rotation.RightVector);
		for (const auto& Direction : RadiusOffsetLocation)
		{
			FVector Bottom = BottomLocation + Direction * BottomRadius;
			FVector Top = TopLocation + Direction * TopRadius;
			Debug::DrawDebugLine(Bottom, Top, FLinearColor::Blue);
		}

		Debug::DrawDebugArrow(BottomLocation, CenterLocation, 15.0, FLinearColor::Blue, 3.0);
	}
}

class UWindJavelinConeComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UWindJavelinConeComponent;

    UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		const auto Component = Cast<UWindJavelinConeComponent>(InComponent);
		if(Component == nullptr)
			return;

		SetRenderForeground(false);

		const FTransform WorldTransform = Component.GetWorldTransform();
		const FQuat Rotation = WorldTransform.GetRotation();
		
		DrawWireCylinder(Component.BottomLocation, WorldTransform.TransformRotation(FRotator(90.0, 0.0, 0.0).Quaternion()).Rotator(), FLinearColor::Blue, Component.BottomRadius, 0.0, 16);	
		DrawWireCylinder(Component.TopLocation, WorldTransform.TransformRotation(FRotator(90.0, 0.0, 0.0).Quaternion()).Rotator(), FLinearColor::Blue, Component.TopRadius, 0.0, 16);	

		TArray<FVector> RadiusOffsetLocation;
		RadiusOffsetLocation.Add(Rotation.UpVector);
		RadiusOffsetLocation.Add(-Rotation.UpVector);
		RadiusOffsetLocation.Add(Rotation.RightVector);
		RadiusOffsetLocation.Add(-Rotation.RightVector);
		for (const auto& Direction : RadiusOffsetLocation)
		{
			FVector Bottom = Component.BottomLocation + Direction * Component.BottomRadius;
			FVector Top = Component.TopLocation + Direction * Component.TopRadius;
			DrawLine(Bottom, Top, FLinearColor::Blue);
		}

		DrawArrow(Component.BottomLocation, Component.CenterLocation, FLinearColor::Blue, 10.0, 3.0);
	}
}