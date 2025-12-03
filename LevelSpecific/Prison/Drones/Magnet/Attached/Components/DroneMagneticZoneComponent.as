 struct FGetIsValidTargetResults
{
	UMagnetDroneAutoAimComponent AutoAimComp = nullptr;
	FVector Location = FVector::ZeroVector;
	float DistanceToPlayerSquared = BIG_NUMBER;
	FVector ImpactNormal = FVector::ZeroVector;
}
 
 enum EMagnetDroneZoneType
{
	// The player will fall off if they travel outside of the shape. A margin is used to allow for attaching to begin with.
	FallOffIfOutside,

	// The player will fall off if they travel inside of the shape.
	FallOffIfInside,

	// The player will not be able to move outside of the shapes.
	ConstrainToWithin,

	// Basically an invisible wall
	ConstrainToOutside
};

enum EMagnetDroneZoneShape
{
	Rectangle,
	Circle,
	Cuboid,
	Cylinder,
};

/**
 * Component used for the drone magnet attraction ability
 */
class UDroneMagneticZoneComponent : USceneComponent 
{ 
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	/**
	 * Whether the drone should drop off if traveling outside the magnetic zone.
	 */
	UPROPERTY(EditAnywhere, Category = "Magnetic Zone")
	protected EMagnetDroneZoneType MagneticZoneType = EMagnetDroneZoneType::FallOffIfOutside;

	UPROPERTY(EditAnywhere, Category = "Magnetic Zone")
	protected EMagnetDroneZoneShape MagneticZoneShape = EMagnetDroneZoneShape::Rectangle;

	UPROPERTY(EditAnywhere, Category = "Magnetic Zone|Circle", Meta = (EditCondition = "MagneticZoneShape == EMagnetDroneZoneShape::Circle", EditConditionHides))
	protected float CircleRadius = 100.0;

	UPROPERTY(EditAnywhere, Category = "Magnetic Zone|Rectangle", Meta = (EditCondition = "MagneticZoneShape == EMagnetDroneZoneShape::Rectangle", EditConditionHides))
	protected bool bCalculateAutoExtents = false;

	UPROPERTY(EditAnywhere, Category = "Magnetic Zone|Rectangle", Meta = (EditCondition = "MagneticZoneShape == EMagnetDroneZoneShape::Rectangle && !bCalculateAutoExtents", EditConditionHides))
	protected FVector2D RectangleExtents = FVector2D(100.0, 100.0);

	UPROPERTY(EditAnywhere, Category = "Magnetic Zone|Cuboid", Meta = (EditCondition = "MagneticZoneShape == EMagnetDroneZoneShape::Cuboid", EditConditionHides))
	protected FVector CuboidExtents = FVector(100.0, 100.0, 100.0);

	UPROPERTY(EditAnywhere, Category = "Magnetic Zone|Cylinder", Meta = (EditCondition = "MagneticZoneShape == EMagnetDroneZoneShape::Cylinder", EditConditionHides))
	protected float CylinderRadius = 100.0;

	UPROPERTY(EditAnywhere, Category = "Magnetic Zone|Cylinder", Meta = (EditCondition = "MagneticZoneShape == EMagnetDroneZoneShape::Cylinder", EditConditionHides))
	protected float CylinderHalfHeight = 100.0;

	TArray<FInstigator> Blockers;

#if EDITOR
	UPROPERTY(EditAnywhere, Category = "Magnetic Zone|Rectangle", Meta = (EditCondition = "MagneticZoneShape == EMagnetDroneZoneShape::Rectangle && bCalculateAutoExtents", EditConditionHides))
	FVector2D AutoExtentsMargin = FVector2D(10, 10);

	UPROPERTY(EditAnywhere, Category = "Magnetic Zone|Rectangle", Meta = (EditCondition = "MagneticZoneShape == EMagnetDroneZoneShape::Rectangle && bCalculateAutoExtents", EditConditionHides))
	FVector AutoExtentsOffset;

	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		if(MagneticZoneShape == EMagnetDroneZoneShape::Rectangle && bCalculateAutoExtents)
		{
			AutoScaleToBounds();
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto SurfaceComp = UDroneMagneticSurfaceComponent::GetOrCreate(GetOwner());
		SurfaceComp.MagneticZones.AddUnique(this);

#if EDITOR
		if(DevToggleMagnetDrone::DrawShapes.IsEnabled())
			SetComponentTickEnabled(true);

		DevToggleMagnetDrone::DrawShapes.BindOnChanged(this, n"OnDrawShapesChanged");
#endif
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(EndPlayReason == EEndPlayReason::Destroyed)
		{
			UDroneMagneticSurfaceComponent SurfaceComp = UDroneMagneticSurfaceComponent::Get(GetOwner());
			if(SurfaceComp != nullptr)
				SurfaceComp.MagneticZones.RemoveSingleSwap(this);
		}
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(DevToggleMagnetDrone::DrawShapes.IsEnabled())
			DebugDraw();
	}
#endif

	void Initialize(EMagnetDroneZoneType InZoneType, FVector2D InRectangleExtents)
	{
		MagneticZoneType = InZoneType;
		MagneticZoneShape = EMagnetDroneZoneShape::Rectangle;
		RectangleExtents = InRectangleExtents;

		auto SurfaceComp = UDroneMagneticSurfaceComponent::GetOrCreate(Owner);
		SurfaceComp.MagneticZones.AddUnique(this);
	}

	UFUNCTION(BlueprintPure)
	bool IsEnabled() const
	{
		return Blockers.IsEmpty();
	}

	UFUNCTION(BlueprintCallable)
	void Enable(FInstigator Instigator)
	{
		bool bWasEnabled = IsEnabled();
		Blockers.RemoveSingleSwap(Instigator);

		if(!bWasEnabled && IsEnabled())
			OnEnabled();
	}

	UFUNCTION(BlueprintCallable)
	void Disable(FInstigator Instigator)
	{
		bool bWasEnabled = IsEnabled();
		Blockers.AddUnique(Instigator);

		if(bWasEnabled && !IsEnabled())
			OnDisabled();
	}

	private void OnEnabled()
	{
		auto SurfaceComp = UDroneMagneticSurfaceComponent::Get(Owner);
		SurfaceComp.MagneticZones.AddUnique(this);
	}

	private void OnDisabled()
	{
		auto SurfaceComp = UDroneMagneticSurfaceComponent::Get(Owner);
		SurfaceComp.MagneticZones.RemoveSingleSwap(this);
	}

	EMagnetDroneZoneType GetZoneType() const
	{
		return MagneticZoneType;
	}

	EMagnetDroneZoneShape GetMagneticZoneShape() const
	{
		return MagneticZoneShape;
	}

	FVector GetRectangleExtents() const
	{
		return FVector(0.0, RectangleExtents.X, RectangleExtents.Y);
	}

	float GetCircleRadius() const
	{
		return CircleRadius;
	}

	FVector GetCuboidExtents() const
	{
		return CuboidExtents;
	}

	void GetCylinder(float&out OutCylinderRadius, float&out OutCylinderHalfHeight) const
	{
		OutCylinderRadius = CylinderRadius;
		OutCylinderHalfHeight = CylinderHalfHeight;
	}

	float DistanceFromPoint(const FVector& Point, bool bProjectToPlane = false) const
	{
		FVector InternalPoint = Point;

		const FTransform ZoneWorldTransform = GetWorldTransform();

		if(IsZoneShapePlane() && bProjectToPlane)
			InternalPoint = Point.PointPlaneProject(ZoneWorldTransform.GetLocation(), ZoneWorldTransform.GetRotation().GetForwardVector());

		const FVector RelativePoint = ZoneWorldTransform.InverseTransformPositionNoScale(InternalPoint);

		switch(MagneticZoneShape)
		{
			case EMagnetDroneZoneShape::Rectangle:
			{
				const float XDist = Math::Max(Math::Abs(RelativePoint.X) - 0.0, 0.0);
				const float YDist = Math::Max(Math::Abs(RelativePoint.Y) - RectangleExtents.X, 0.0);
				const float ZDist = Math::Max(Math::Abs(RelativePoint.Z) - RectangleExtents.Y, 0.0);

				return XDist + YDist + ZDist;
			}
			
			case EMagnetDroneZoneShape::Circle:
			{
				const float DistanceToCenter = RelativePoint.Size();
				const float DistanceToCircle = Math::Max(DistanceToCenter - CircleRadius, 0.0);
				return DistanceToCircle;
			}

			case EMagnetDroneZoneShape::Cuboid:
			{
				const float XDist = Math::Max(Math::Abs(RelativePoint.X) - CuboidExtents.X, 0.0);
				const float YDist = Math::Max(Math::Abs(RelativePoint.Y) - CuboidExtents.Y, 0.0);
				const float ZDist = Math::Max(Math::Abs(RelativePoint.Z) - CuboidExtents.Z, 0.0);

				return XDist + YDist + ZDist;
			}

			case EMagnetDroneZoneShape::Cylinder:
			{
				float XYDist = Math::Max(FVector2D(RelativePoint.X, RelativePoint.Y).Size() - CylinderRadius, 0.0);
				float ZDist = Math::Max(Math::Abs(RelativePoint.Z) - CylinderHalfHeight, 0.0);
				return XYDist + ZDist;
			}
		}
	}

	FVector GetClosestPointTo(const FVector& Point) const
	{
		FVector InternalPoint = Point;

		const FTransform ZoneWorldTransform = GetWorldTransform();

		if(IsZoneShapePlane())
			InternalPoint = Point.PointPlaneProject(ZoneWorldTransform.GetLocation(), ZoneWorldTransform.GetRotation().GetForwardVector());

		// Transform to AABB space
		const FVector RelativePoint = ZoneWorldTransform.InverseTransformPositionNoScale(InternalPoint);

		switch(MagneticZoneShape)
		{
			case EMagnetDroneZoneShape::Rectangle:
			{
				// Project each axis onto a side of the rectangle
				const FVector RelativeProjectedPoint = FVector(
					Math::Min(Math::Abs(RelativePoint.X), 0.0) * Math::Sign(RelativePoint.X),
					Math::Min(Math::Abs(RelativePoint.Y), RectangleExtents.X) * Math::Sign(RelativePoint.Y),
					Math::Min(Math::Abs(RelativePoint.Z), RectangleExtents.Y) * Math::Sign(RelativePoint.Z)
				);

				// Transform back to world space
				return ZoneWorldTransform.TransformPositionNoScale(RelativeProjectedPoint);
			}
			
			case EMagnetDroneZoneShape::Circle:
			{
				FVector ClampedDiff = RelativePoint.GetClampedToMaxSize(CircleRadius);
				return ZoneWorldTransform.TransformPositionNoScale(ClampedDiff);
			}

			case EMagnetDroneZoneShape::Cuboid:
			{
				// Project each axis onto a side of the cuboid
				const FVector RelativeProjectedPoint = FVector(
					Math::Min(Math::Abs(RelativePoint.X), CuboidExtents.X) * Math::Sign(RelativePoint.X),
					Math::Min(Math::Abs(RelativePoint.Y), CuboidExtents.Y) * Math::Sign(RelativePoint.Y),
					Math::Min(Math::Abs(RelativePoint.Z), CuboidExtents.Z) * Math::Sign(RelativePoint.Z)
				);

				// Transform back to world space
				return ZoneWorldTransform.TransformPositionNoScale(RelativeProjectedPoint);
			}

			case EMagnetDroneZoneShape::Cylinder:
			{
				FVector2D HorizontalOffset = FVector2D(RelativePoint.X, RelativePoint.Y);
				HorizontalOffset = HorizontalOffset.GetClampedToMaxSize(CylinderRadius);

				const FVector RelativeProjectedPoint = FVector(
					HorizontalOffset.X,
					HorizontalOffset.Y,
					Math::Min(Math::Abs(RelativePoint.Z), CylinderHalfHeight) * Math::Sign(RelativePoint.Z)
				);

				// Transform back to world space
				return ZoneWorldTransform.TransformPositionNoScale(RelativeProjectedPoint);
			}
		}
	}

	FVector Depenetrate(FVector Point, bool bProjectToPlane = false) const
	{
		FVector InternalPoint = Point;

		const FTransform ZoneWorldTransform = GetWorldTransform();

		if(IsZoneShapePlane() && bProjectToPlane)
			InternalPoint = Point.PointPlaneProject(ZoneWorldTransform.GetLocation(), ZoneWorldTransform.GetRotation().GetForwardVector());

		// Transform to AABB space
		const FVector RelativePoint = ZoneWorldTransform.InverseTransformPositionNoScale(InternalPoint);

		switch(MagneticZoneShape)
		{
			case EMagnetDroneZoneShape::Rectangle:
			{
				float PenetrationY = Math::Abs(Math::Abs(RelativePoint.Y) - RectangleExtents.X);
				float PenetrationZ = Math::Abs(Math::Abs(RelativePoint.Z) - RectangleExtents.Y);

				FVector TargetPoint = RelativePoint;

				// Depenetrate the side with the smallest penetration
				if(PenetrationY < PenetrationZ)
					TargetPoint.Y = RelativePoint.Y > 0.0 ? RectangleExtents.X : -RectangleExtents.X;
				else
					TargetPoint.Z = RelativePoint.Z > 0.0 ? RectangleExtents.Y : -RectangleExtents.Y;

				// Get delta to edge of the rectangle
				const FVector DepenetrationDelta = TargetPoint - RelativePoint;

				// Transform back to world space
				return ZoneWorldTransform.TransformVectorNoScale(DepenetrationDelta);
			}
			
			case EMagnetDroneZoneShape::Circle:
			{
				// Get delta to edge of circle
				const FVector DepenetrationDelta = (RelativePoint.GetSafeNormal() * CircleRadius) - RelativePoint;

				// Transform back to world space
				return ZoneWorldTransform.TransformVectorNoScale(DepenetrationDelta);
			}

			case EMagnetDroneZoneShape::Cuboid:
			{
				float PenetrationX = Math::Abs(Math::Abs(RelativePoint.X) - CuboidExtents.X);
				float PenetrationY = Math::Abs(Math::Abs(RelativePoint.Y) - CuboidExtents.Y);
				float PenetrationZ = Math::Abs(Math::Abs(RelativePoint.Z) - CuboidExtents.Z);

				FVector TargetPoint = RelativePoint;

				// Depenetrate the side with the smallest penetration
				if(PenetrationX < PenetrationY && PenetrationX < PenetrationZ)
					TargetPoint.X = RelativePoint.X > 0.0 ? CuboidExtents.X : -CuboidExtents.X;
				else if(PenetrationY < PenetrationX && PenetrationY < PenetrationZ)
					TargetPoint.Y = RelativePoint.Y > 0.0 ? CuboidExtents.Y : -CuboidExtents.Y;
				else
					TargetPoint.Z = RelativePoint.Z > 0.0 ? CuboidExtents.Z : -CuboidExtents.Z;

				// Get delta to edge of the cuboid
				const FVector DepenetrationDelta = TargetPoint - RelativePoint;

				// Transform back to world space
				return ZoneWorldTransform.TransformVectorNoScale(DepenetrationDelta);
			}

			case EMagnetDroneZoneShape::Cylinder:
			{
				FVector2D HorizontalOffset = FVector2D(RelativePoint.X, RelativePoint.Y);
				FVector2D HorizontalDepenetrationDelta = (HorizontalOffset.GetSafeNormal() * CylinderRadius) - HorizontalOffset;
				const float PenetrationXY = HorizontalDepenetrationDelta.Size();
				const float PenetrationZ = Math::Abs(Math::Abs(RelativePoint.Z) - CuboidExtents.Z);

				FVector TargetPoint = RelativePoint;

				if(PenetrationXY < PenetrationZ)
				{
					TargetPoint.X = HorizontalDepenetrationDelta.X;
					TargetPoint.Y = HorizontalDepenetrationDelta.Y;
				}
				else
				{
					TargetPoint.Z = RelativePoint.Z > 0.0 ? CylinderHalfHeight : -CylinderHalfHeight;
				}

				// Get delta to edge of the cuboid
				const FVector DepenetrationDelta = TargetPoint - RelativePoint;

				// Transform back to world space
				return ZoneWorldTransform.TransformVectorNoScale(DepenetrationDelta);
			}
		}
	}

	bool IsRelevantForWorldUp(FVector WorldUp) const
	{
		if(!MagnetDrone::ValidateMagneticZoneWorldUp)
			return true;

		switch (MagneticZoneShape)
		{
			case EMagnetDroneZoneShape::Rectangle:
			case EMagnetDroneZoneShape::Circle:
				return ForwardVector.DotProduct(WorldUp) > 0.9;
			
			case EMagnetDroneZoneShape::Cuboid:
			case EMagnetDroneZoneShape::Cylinder:
				return true;
		}
	}

#if EDITOR
	UFUNCTION()
	private void OnDrawShapesChanged(bool bNewState)
	{
		SetComponentTickEnabled(bNewState);
	}

	void DebugDraw() const
	{
		const FTransform ZoneWorldTransform = GetWorldTransform();
		const FVector Location = ZoneWorldTransform.GetLocation();
		const FQuat Rotation = ZoneWorldTransform.GetRotation();

		switch(MagneticZoneShape)
		{
			case EMagnetDroneZoneShape::Rectangle:
				Debug::DrawDebugBox(Location, GetRectangleExtents(), Rotation.Rotator(), GetZoneColor());
				break;

			case EMagnetDroneZoneShape::Circle:
				Debug::DrawDebugCircle(Location, CircleRadius, 32, GetZoneColor(), 3.0, GetRightVector(), GetUpVector());
				break;

			case EMagnetDroneZoneShape::Cuboid:
				Debug::DrawDebugBox(Location, GetCuboidExtents(), Rotation.Rotator(), GetZoneColor());
				break;

			case EMagnetDroneZoneShape::Cylinder:
				Debug::DrawDebugCylinder(Location - UpVector * CylinderHalfHeight, Location + UpVector * CylinderHalfHeight, CylinderRadius, 12, GetZoneColor());
		}
	}
#endif

	FLinearColor GetZoneColor() const
	{
		return MagnetDrone::GetZoneColor(MagneticZoneType);
	}

	bool IsZoneShapePlane() const
	{
		switch(MagneticZoneShape)
		{
			case EMagnetDroneZoneShape::Rectangle:
				return true;

			case EMagnetDroneZoneShape::Circle:
				return true;

			case EMagnetDroneZoneShape::Cuboid:
				return false;

			case EMagnetDroneZoneShape::Cylinder:
				return false;
		}
	}

#if EDITOR
	private void AutoScaleToBounds()
	{
		FBox ActorBounds = Owner.GetActorLocalBoundingBox(true);
		FVector Extents = ActorBounds.Extent * Owner.ActorScale3D;
		FVector Origin = Owner.ActorTransform.TransformPosition(ActorBounds.Center);
		AutoExtentsMargin.X = Math::Min(AutoExtentsMargin.X, Extents.Y);
		AutoExtentsMargin.Y = Math::Min(AutoExtentsMargin.Y, Extents.Z);

		AutoExtentsOffset.X = Extents.X;
		const FVector Offset = Owner.ActorTransform.TransformVector(AutoExtentsOffset);

		SetWorldLocation(Origin + Offset);
		SetWorldRotation(Owner.ActorQuat);

		RectangleExtents.X = Extents.Y - AutoExtentsMargin.X;
		RectangleExtents.Y = Extents.Z - AutoExtentsMargin.Y;
	}

	UFUNCTION(CallInEditor, Category = "Magnetic Zone")
	private void ConvertRectangleToCuboid()
	{
		if(MagneticZoneShape != EMagnetDroneZoneShape::Rectangle)
			return;

		CuboidExtents = FVector(CuboidExtents.X, RectangleExtents.X, RectangleExtents.Y);
		MagneticZoneShape = EMagnetDroneZoneShape::Cuboid;
	}

	UFUNCTION(CallInEditor, Category = "Magnetic Zone")
	private void ConvertCuboidToRectangle()
	{
		if(MagneticZoneShape != EMagnetDroneZoneShape::Cuboid)
			return;

		RectangleExtents = FVector2D(CuboidExtents.Y, CuboidExtents.Z);
		MagneticZoneShape = EMagnetDroneZoneShape::Rectangle;
	}
#endif
}

namespace MagnetDrone
{
	FLinearColor GetZoneColor(EMagnetDroneZoneType ZoneType)
	{
		switch(ZoneType)
		{
			case EMagnetDroneZoneType::FallOffIfOutside:
				return FLinearColor::Blue;
				
			case EMagnetDroneZoneType::FallOffIfInside:
				return FLinearColor::LucBlue;

			case EMagnetDroneZoneType::ConstrainToWithin:
				return FLinearColor(1.0, 0.3, 0.0);

			case EMagnetDroneZoneType::ConstrainToOutside:
				return FLinearColor::Red;
		}
	}
}

#if EDITOR
class UDroneMagneticZoneComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UDroneMagneticZoneComponent;

    UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto Component = Cast<UDroneMagneticZoneComponent>(InComponent);
		if(Component == nullptr)
			return;

		SetRenderForeground(false);

		const FTransform WorldTransform = Component.GetWorldTransform();
		
		const FVector Location = WorldTransform.GetLocation();
		const FQuat Rotation = WorldTransform.GetRotation();

		switch(Component.GetMagneticZoneShape())
		{
			case EMagnetDroneZoneShape::Rectangle:
				DrawWireBox(Location, Component.GetRectangleExtents(), Rotation, Component.GetZoneColor(), 3.0);		
				break;

			case EMagnetDroneZoneShape::Circle:
				DrawCircle(Location, Component.GetCircleRadius(), Component.GetZoneColor(), 3.0, Component.GetForwardVector(), 32);
				break;

			case EMagnetDroneZoneShape::Cuboid:
				DrawSolidBox(Component, Location, Rotation, Component.GetCuboidExtents(), Component.GetZoneColor(), 0.02, 3.0);
				break;

			case EMagnetDroneZoneShape::Cylinder:
			{
				float CylinderRadius = 0;
				float CylinderHalfHeight = 0;
				Component.GetCylinder(CylinderRadius, CylinderHalfHeight);
				DrawWireCylinder(Location, Rotation.Rotator(), Component.GetZoneColor(), CylinderRadius, CylinderHalfHeight, 12, 3);
				break;
			}
		}

		DrawArrow(Location, Location + Rotation.GetForwardVector() * 100.0, FLinearColor::Red);
	}
};
#endif