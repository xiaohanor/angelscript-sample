/**
 * Tries to keep the body centered over the legs.
 */
class USkylineBossBodyMovementCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossBodyMovement);

	FHazeAcceleratedVector AcceleratedLocation;
	FHazeAcceleratedFloat AcceleratedBobHeight;
	FHazeAcceleratedQuat AcceleratedRotation;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Boss.MovementQueue.IsEmpty())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Boss.MovementQueue.IsEmpty())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(HasControl())
		{
			AcceleratedLocation.SnapTo(Boss.ActorLocation, Boss.ActorVelocity);
			AcceleratedRotation.SnapTo(Boss.ActorQuat);
			AcceleratedBobHeight.SnapTo(0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			const auto& MovementData = Boss.MovementQueue[0];
			float FootstepHeight = Boss.Settings.FootStepCurve.GetFloatValue(MovementData.StepAlpha);
			AcceleratedBobHeight.SpringTo(FootstepHeight, 2, .5, DeltaTime);

			const FVector TargetLocation = CalculateTargetLocation();
			const FQuat TargetRotation = CalculateTargetRotation();

			Boss.SetActorLocationAndRotation(
				AcceleratedLocation.SpringTo(TargetLocation, 0.5, 0.8, DeltaTime * 6.0),
				AcceleratedRotation.SpringTo(TargetRotation, 0.6, 0.8, DeltaTime * 4.0)
			);
			
			Boss.SetActorVelocity(AcceleratedLocation.Velocity);
		}
		else
		{
			ApplyCrumbSyncedPosition();
		}
	}

	FVector CalculateTargetLocation() const
	{
		// Location, center of feet with height offset
		FVector CenterLocation;
		for (int i = 0; i < Boss.LegComponents.Num(); ++i)
		{
			auto LegComponent = Boss.LegComponents[i];
			FVector FootLocation = LegComponent.Leg.GetFootLocation();

			CenterLocation += FootLocation;
		}

		CenterLocation /= Boss.LegComponents.Num();
		
		FVector StepHeightOffset = FVector::UpVector * AcceleratedBobHeight.Value * Boss.Settings.StepHeight;
		
		FVector BaseHeightOffset = FVector::UpVector * Boss.Settings.BaseHeight;
		return CenterLocation + BaseHeightOffset + StepHeightOffset;
	}

	FQuat CalculateTargetRotation() const
	{
		check(HasControl());

		const auto& MovementData = Boss.MovementQueue[0];

		// Rotation, from spline when moving, towards feet when rebasing
		FVector ForwardVector = FVector::ForwardVector;
		if (MovementData.IsValid() && !MovementData.IsRebasing())
		{
			// Forward from spline direction (inverted if walking in reverse)
			auto Spline = MovementData.SplineActor.Spline;
			FTransform ClosestTransform = Spline.GetClosestSplineWorldTransformToWorldLocation(Boss.ActorLocation);
			
			const float IgnoreStartOfSplineLength = 7000;

			if (MovementData.bIsReversed)
			{
				if(Spline.GetClosestSplineDistanceToWorldLocation(ClosestTransform.Location) > Spline.SplineLength - IgnoreStartOfSplineLength)
				{
					ClosestTransform = Spline.GetWorldTransformAtSplineDistance(Spline.SplineLength - IgnoreStartOfSplineLength);
				}

				ClosestTransform.Rotation = FQuat::MakeFromZX(FVector::UpVector, -ClosestTransform.Rotation.ForwardVector);
			}
			else
			{
				if(Spline.GetClosestSplineDistanceToWorldLocation(ClosestTransform.Location) < IgnoreStartOfSplineLength)
				{
					ClosestTransform = Spline.GetWorldTransformAtSplineDistance(IgnoreStartOfSplineLength);
				}

				ClosestTransform.Rotation = FQuat::MakeFromZX(FVector::UpVector, ClosestTransform.Rotation.ForwardVector);
			}
			
			ForwardVector = ClosestTransform.TransformVectorNoScale(Boss.ForwardVector);

			FTemporalLog TemporalLog = TEMPORAL_LOG(this, "BodyMovement");
			TemporalLog.DirectionalArrow("Closest Rotation", ClosestTransform.Location + FVector::UpVector * 10, ClosestTransform.Rotation.ForwardVector * 8000, 100, 100000);
		}
		else
		{
			// From hub to center of front legs is forward
			int NumTargets = MovementData.FootTargets.Num();
			FVector LeftFootLocation = MovementData.FootTargets[NumTargets - 2].WorldLocation;
			FVector RightFootLocation = MovementData.FootTargets[NumTargets - 3].WorldLocation;

			auto Hub = Boss.CurrentHub;
			if (MovementData.IsValid())
				Hub = MovementData.ToHub;

			FVector FrontLegsCenterLocation = (LeftFootLocation + RightFootLocation) / 2.0;
			FVector HubToCenterDirection = (FrontLegsCenterLocation - Hub.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();

			FTransform TargetTransform(
				FQuat::MakeFromZX(FVector::UpVector, HubToCenterDirection),
				Hub.ActorLocation
			);
			ForwardVector = TargetTransform.TransformVectorNoScale(Boss.ForwardVector);
		}

		return FQuat::MakeFromZX(FVector::UpVector, -ForwardVector);
	}
}