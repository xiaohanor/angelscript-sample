UCLASS(NotBlueprintable)
class USketchbookGoatSplineMovementComponent : UActorComponent
{
	FSplinePosition SplinePosition;
	float HorizontalSpeed = 0;
	float VerticalOffset = 0;

	bool bCanExitAir = true;

	private UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	bool IsInAir() const
	{
		if(SplinePosition.CurrentSpline != nullptr)
		{
		}
		
		if(!bCanExitAir)
			return true;

		if(VerticalOffset > 0)
			return true;

		if(MoveComp.HasUpwardsImpulse() )
			return true;

		if(IsInHole())
			return true;

		return false;
	}

	bool IsInHole() const
	{
		if(SplinePosition.CurrentSpline == nullptr)
			return false;

		auto FoundComponent = GetCurrentSplineActor().Spline.FindPreviousComponentAlongSpline(USketchbookGoatSplineHoleComponent, false, SplinePosition.CurrentSplineDistance);
		if(!FoundComponent.IsSet())
			return false;

		auto HoleComp = Cast<USketchbookGoatSplineHoleComponent>(FoundComponent.Value.Component);
		if(HoleComp == nullptr)
			return false;

		if(SplinePosition.CurrentSplineDistance > FoundComponent.Value.DistanceAlongSpline + HoleComp.HoleSize)
			return false;

		return true;
	}

	bool HasFallenDownHole() const
	{
		if(!IsInHole())
			return false;

		// Above the spline
		if(VerticalOffset > 0)
			return false;

		return true;
	}

	bool ConstrainLocationToHole(FVector WorldLocation, FVector Velocity, FVector&out ConstrainedLocation, FVector&out ConstraintNormal) const
	{
		if(!IsInHole())
		{
			ConstrainedLocation = WorldLocation;
			return false;
		}

		auto FoundComponent = GetCurrentSplineActor().Spline.FindPreviousComponentAlongSpline(USketchbookGoatSplineHoleComponent, false, SplinePosition.CurrentSplineDistance);

		auto HoleComp = Cast<USketchbookGoatSplineHoleComponent>(FoundComponent.Value.Component);

		FTransform SplineTransformAtHoleStart = GetCurrentSpline().GetWorldTransformAtSplineDistance(FoundComponent.Value.DistanceAlongSpline);

		FTransform SplineTransformAtHoleEnd = GetCurrentSpline().GetWorldTransformAtSplineDistance(FoundComponent.Value.DistanceAlongSpline + HoleComp.HoleSize);

		FPlane HoleStartPlane = FPlane(SplineTransformAtHoleStart.Location, SplineTransformAtHoleStart.Rotation.ForwardVector);

		FPlane HoleEndPlane = FPlane(SplineTransformAtHoleEnd.Location, SplineTransformAtHoleEnd.Rotation.ForwardVector);

		if(Velocity.DotProduct(HoleStartPlane.Normal) < 0 && HoleStartPlane.PlaneDot(WorldLocation) < 0)
		{
			// Before start
			ConstraintNormal = HoleStartPlane.Normal;
			ConstrainedLocation =  WorldLocation.PointPlaneProject(HoleStartPlane.Origin, HoleStartPlane.Normal) + ConstraintNormal;
			return true;
		}
		else if(Velocity.DotProductNormalized(HoleEndPlane.Normal) > 0 && HoleEndPlane.PlaneDot(WorldLocation) > 0)
		{
			// After end
			ConstraintNormal = -HoleEndPlane.Normal;
			ConstrainedLocation = WorldLocation.PointPlaneProject(HoleEndPlane.Origin, HoleEndPlane.Normal)  + ConstraintNormal;
			return true;
		}

		ConstrainedLocation = WorldLocation;
		return false;
	}

	FVector GetLocation() const
	{
		return SplinePosition.WorldLocation + SplinePosition.WorldUpVector * VerticalOffset;
	}

	UHazeSplineComponent GetCurrentSpline() const
	{
		return SplinePosition.CurrentSpline;
	}

	ASketchbookGoatSpline GetCurrentSplineActor() const
	{
		if(SplinePosition.CurrentSpline == nullptr)
			return Sketchbook::Goat::GetClosestSpline(Owner.ActorLocation);
		
		return Cast<ASketchbookGoatSpline>(SplinePosition.CurrentSpline.Owner);
	}

	FVector GetWorldUp() const
	{
		if(!devEnsure(GetCurrentSplineActor() != nullptr, "GetCurrentSplineActor() returned null!"))
		{
			return FVector::UpVector;
		}

		if(!devEnsure(SplinePosition.GetCurrentSpline() != nullptr, "SplinePosition.GetCurrentSpline() returned null!"))
		{
			return FVector::UpVector;
		}

		//Debug::DrawDebugArrow(SplinePosition.WorldLocation, SplinePosition.WorldLocation + GetCurrentSplineActor().GetSplineUpAtDistanceAlongSpline(SplinePosition.CurrentSplineDistance) * 100);
		return GetCurrentSplineActor().GetSplineUpAtDistanceAlongSpline(SplinePosition.GetCurrentSpline().GetClosestSplineDistanceToWorldLocation(Owner.ActorLocation));
	}

	FVector GetGravityDirection(FVector WorldUp) const
	{
		if(GetCurrentSplineActor().bAlignGravityWithSplineUp)
			return -GetWorldUp();
		else
			return -WorldUp;
	}

	FVector GetWorldRight() const
	{
		return SplinePosition.WorldForwardVector;
	}

	float GetSpeedAlongSpline() const
	{
		return Math::Abs(Owner.ActorVelocity.DotProduct(GetWorldRight()));
	}

	float GetDotSplineForward(FVector Vector) const
	{
		float DotSplineForward = Vector.DotProduct(SplinePosition.WorldForwardVector);

		if(Math::Abs(DotSplineForward) > 0.1)
		{
			if(DotSplineForward > 0)
				return 1;
			
			return -1;
		}
		
		return 0;
	}
};