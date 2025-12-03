event void FMagneticFieldRepelOnPlayerLaunched(AHazePlayerCharacter Player);

UCLASS(NotBlueprintable)
class UMagneticFieldRepelComponent : USceneComponent
{
	/**
	 * How strong should the repel force be. 
	 */
	UPROPERTY(EditAnywhere, Category = "Magnetic Field Repel")
	private float RepelMultiplier = 1.0;

	/**
	 * How big the base of the zone should be.
	 */
	UPROPERTY(EditAnywhere, Category = "Magnetic Field Repel")
	protected FVector2D FieldExtents = FVector2D(100.0, 100.0);

	/**
	 * How tall the zone is from the base to the top.
	 */
	UPROPERTY(EditAnywhere, Category = "Magnetic Field Repel")
	protected float FieldDistance = 750.0;

	UPROPERTY(EditAnywhere, Category = "Magnetic Field Repel")
	protected FRuntimeFloatCurve FalloffCurve;
	default FalloffCurve.AddDefaultKey(0, 1);
	default FalloffCurve.AddDefaultKey(1, 0);

	/**
	 * Should the force of this zone use a margin, so that the edges of the zone don't apply full force immediately?
	 * The force will linearly increase from the outer zone edge to the inner margin.
	*/ 
	UPROPERTY(EditAnywhere, Category = "Magnetic Field Repel|Margin")
	bool bUseMargin = true;

	/**
	 * How big the margin should be from each side.
	 */
	UPROPERTY(EditAnywhere, meta = (EditCondition = "bUseMargin"), Category = "Magnetic Field Repel|Margin")
	protected FVector2D FieldMargin = FVector2D(50.0, 50.0);

	/**
	 * When inside of the zone and initiating magnetic burst, should we launch?
	 */
	UPROPERTY(EditAnywhere, Category = "Magnetic Field Repel|Launch")
	bool bLaunchOnBurst = false;

	UPROPERTY(EditAnywhere, Category = "Magnetic Field Repel|Launch", Meta = (EditCondition = "bLaunchOnBurst", EditConditionHides))
	private float LaunchMultiplier = 1.0;

	UPROPERTY(EditAnywhere, Category = "Magnetic Field Repel|Launch", Meta = (EditCondition = "bLaunchOnBurst", EditConditionHides, ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float LaunchHeightFraction = 0.5;

#if EDITOR
	UPROPERTY(EditAnywhere, Category = "Magnetic Field Repel|Debug")
	bool bDebugDraw = false;
#endif

	FMagneticFieldRepelOnPlayerLaunched OnPlayerLaunchedEvent;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		RepelMultiplier = Math::Max(RepelMultiplier, KINDA_SMALL_NUMBER);

		FieldExtents.X = Math::Max(FieldExtents.X, KINDA_SMALL_NUMBER);
		FieldExtents.Y = Math::Max(FieldExtents.Y, KINDA_SMALL_NUMBER);

		FieldMargin.X = Math::Clamp(FieldMargin.X, 0.0, FieldExtents.X);
		FieldMargin.Y = Math::Clamp(FieldMargin.Y, 0.0, FieldExtents.Y);

		FieldDistance = Math::Clamp(FieldDistance, KINDA_SMALL_NUMBER, MagneticField::GetTotalRadius());
	}
#endif

	FVector GetFieldExtents(bool bBurst) const
	{
		return FVector(FieldExtents.X, FieldExtents.Y, GetFieldDistance(bBurst) / 2.0);
	}

	FVector GetFieldInnerExtents() const
	{
		check(bUseMargin);
		return FVector(FieldExtents.X - FieldMargin.X, FieldExtents.Y - FieldMargin.Y, GetFieldDistance(false) / 2.0);
	}

	float GetFieldDistance(bool bBurst) const
	{
		if(bBurst && bLaunchOnBurst)
			return FieldDistance * LaunchHeightFraction;
		else
			return FieldDistance;
	}

	FVector GetCenterLocation(bool bBurst) const
	{
		return WorldLocation + (UpVector * (GetFieldDistance(bBurst) / 2.0));
	}
	
	bool IsPointInsideZone(FVector Point, bool bBurst, float& OutVerticalDist) const
	{
		float HorizontalDist = 0.0;
		DistanceFromPoint(Point, HorizontalDist, OutVerticalDist);
		return HorizontalDist < KINDA_SMALL_NUMBER && OutVerticalDist > 0.0 && OutVerticalDist < GetFieldDistance(bBurst);
	}

	void DistanceFromPoint(const FVector& Point, float& OutHorizontalDist, float& OutVerticalDist) const
	{
		FTransform ZoneWorldTransform = GetWorldTransform();
		ZoneWorldTransform.Scale3D = FVector::OneVector;
		const FVector RelativePoint = ZoneWorldTransform.InverseTransformPosition(Point);

		const float XDist = Math::Max(Math::Abs(RelativePoint.X) - FieldExtents.X, 0.0);
		const float YDist = Math::Max(Math::Abs(RelativePoint.Y) - FieldExtents.Y, 0.0);
		const float ZDist = RelativePoint.Z;

		OutHorizontalDist = XDist + YDist;
		OutVerticalDist = ZDist;
	}

	float GetInsideZoneGradientAlpha(FVector Point)
	{
		if(!IsUsingMargin())
			return 1.0;

		FTransform ZoneWorldTransform = GetWorldTransform();
		ZoneWorldTransform.Scale3D = FVector::OneVector;
		const FVector RelativePoint = ZoneWorldTransform.InverseTransformPosition(Point);

		const FVector InnerExtents = GetFieldInnerExtents();

		const float XDist = 1.0 - (Math::Max(Math::Abs(RelativePoint.X) - InnerExtents.X, 0.0) / FieldMargin.X);
		const float YDist = 1.0 - (Math::Max(Math::Abs(RelativePoint.Y) - InnerExtents.Y, 0.0) / FieldMargin.Y);

		return (XDist + YDist) - 1.0;
	}

	bool IsUsingMargin() const
	{
		return bUseMargin;
	}

	float GetForceAlphaFromVerticalDistance(float VerticalDistance) const
	{
		float Alpha = VerticalDistance / GetFieldDistance(false);
		check(Alpha >= 0.0 && Alpha <= 1.0);
		return FalloffCurve.GetFloatValue(Alpha);
	}

	FVector GetRepelForce(float VerticalDistance) const
	{
		float ForceMagnitude = MagneticField::RepelForce * GetForceAlphaFromVerticalDistance(VerticalDistance);
		return UpVector * RepelMultiplier * ForceMagnitude;
	}

	FVector GetLaunchImpulse() const
	{
		return UpVector * MagneticField::RepelLaunchForce * LaunchMultiplier;
	}

#if EDITOR
	void DebugDraw() const
	{
		#if EDITOR
		Debug::DrawDebugBox(GetCenterLocation(false), GetFieldExtents(false), WorldRotation, FLinearColor::LucBlue, 3.0);

		if(bLaunchOnBurst)
		{
			Debug::DrawDebugBox(GetCenterLocation(true), GetFieldExtents(true), WorldRotation, FLinearColor::Red, 3.0);
		}

		if(IsUsingMargin())
			Debug::DrawDebugBox(GetCenterLocation(false), GetFieldInnerExtents(), WorldRotation, FLinearColor::Teal, 2.0);
		#endif
	}
#endif
}

class UMagneticFieldRepelSurfaceComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UMagneticFieldRepelComponent;

    UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		const auto MagneticField = Cast<UMagneticFieldRepelComponent>(Component);
		if(MagneticField == nullptr)
			return;

		SetRenderForeground(false);

		const FTransform WorldTransform = MagneticField.WorldTransform;
		
		const FVector Location = WorldTransform.GetLocation();
		const FQuat Rotation = WorldTransform.GetRotation();
		const FVector FieldExtents = MagneticField.GetFieldExtents(false);

		DrawWireBox(Location, FVector(FieldExtents.X * 0.99, FieldExtents.Y * 0.99, 0.0), Rotation, FLinearColor::Blue, 5.0);	

		DrawWireBox(MagneticField.GetCenterLocation(false), MagneticField.GetFieldExtents(false), Rotation, FLinearColor::LucBlue, 3.0);

		if(MagneticField.bLaunchOnBurst)
		{
			FVector LaunchFieldExtents = MagneticField.GetFieldExtents(true);
			LaunchFieldExtents = FVector(LaunchFieldExtents.X * 0.98, LaunchFieldExtents.Y * 0.98, LaunchFieldExtents.Z);
			DrawWireBox(MagneticField.GetCenterLocation(true), LaunchFieldExtents, Rotation, FLinearColor::Red, 3.0);
		}

		if(MagneticField.IsUsingMargin())
			DrawWireBox(MagneticField.GetCenterLocation(false), MagneticField.GetFieldInnerExtents(), Rotation, FLinearColor::Teal, 2.0);

		DrawArrow(Location, Location + Rotation.UpVector * 200.0, FLinearColor::LucBlue, 10.0, 3.0);

		if(MagneticField.bLaunchOnBurst)
		{
			SimulateLaunch(MagneticField);
		}
	}

	void SimulateLaunch(const UMagneticFieldRepelComponent MagneticField) const
	{
		const float DeltaTime = 0.02;
		const float Gravity = -2385;
		float SimulateDuration = 10;

		const float CalculatedSimulateDuration = Trajectory::GetTimeToReachTarget(-MagneticField.WorldLocation.Z, MagneticField.GetLaunchImpulse().DotProduct(FVector::UpVector), Gravity);
		if(CalculatedSimulateDuration > KINDA_SMALL_NUMBER)
			SimulateDuration = CalculatedSimulateDuration;

		float Time = 0;
		FVector WorldLocation = MagneticField.WorldLocation + MagneticField.UpVector * 50;
		FVector Velocity = FVector::ZeroVector;

		float PointTime = Time::GameTimeSeconds % SimulateDuration;
		bool bHasDrawnPoint = false;

		while(Time < SimulateDuration)
		{
			FVector PreviousLocation = WorldLocation;

			float VerticalDist = 0.0;
			if(MagneticField.IsPointInsideZone(WorldLocation, true, VerticalDist))
			{
				Velocity = MagneticField.GetLaunchImpulse();
			}
			else
			{
				const FVector VerticalVelocity = Velocity.ProjectOnTo(FVector::UpVector);
				FVector HorizontalVelocity = Velocity - VerticalVelocity;

				HorizontalVelocity = Math::VInterpConstantTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, 450.0);

				Velocity = VerticalVelocity + HorizontalVelocity;

				Velocity += FVector::UpVector * Gravity * DeltaTime;
			}

			WorldLocation += Velocity * DeltaTime;

			FLinearColor Color = Velocity.Z > 0 ? FLinearColor::Red : FLinearColor::Yellow;
			DrawLine(PreviousLocation, WorldLocation, Color, 5, false);

			Time += DeltaTime;

			if(!bHasDrawnPoint && PointTime < Time)
			{
				bHasDrawnPoint = true;
				DrawPoint(WorldLocation, FLinearColor::Green, 10);
			}
		}
	}
}