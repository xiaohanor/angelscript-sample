/**
 * Tries to keep the body centered over the legs.
 */
class USkylineBossPendingDownBodyMovementCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossBodyMovement);

	FHazeAcceleratedVector AcceleratedLocation;
	FHazeAcceleratedQuat AcceleratedRotation;
	FHazeAcceleratedQuat AcceleratedHeadPivotRotation;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AcceleratedLocation.SnapTo(Boss.ActorLocation, Boss.ActorVelocity);
		AcceleratedRotation.SnapTo(Boss.ActorQuat);

		AcceleratedHeadPivotRotation.SnapTo(Boss.HeadPivot.ComponentQuat);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			const FQuat TargetBodyRotation = CalculateBodyTargetRotation();
			const FQuat TargetHeadRotation = CalculateHeadTargetRotation();
			const FVector TargetLocation = CalculateTargetLocation(TargetHeadRotation.ForwardVector);

			Boss.SetActorLocationAndRotation(
				AcceleratedLocation.SpringTo(TargetLocation, 1, 0.8, DeltaTime),
				AcceleratedRotation.AccelerateTo(TargetBodyRotation, 5, DeltaTime)
			);

			Boss.SetActorVelocity(AcceleratedLocation.Velocity);
			
			Boss.HeadPivot.SetWorldRotation(
				AcceleratedHeadPivotRotation.AccelerateTo(TargetHeadRotation, 2, DeltaTime)
			);
		}
		else
		{
			ApplyCrumbSyncedPosition();
			ApplyCrumbSyncedHeadPivotRotation();
		}
	}

	FVector CalculateTargetLocation(FVector TargetForward) const
	{
		check(HasControl());

		const auto& MovementData = Boss.MovementQueue[0];

		// Location, center of feet with height offset
		FVector CenterLocation;
		for (int i = 0; i < Boss.LegComponents.Num(); ++i)
		{
			auto LegComponent = Boss.LegComponents[i];
			FVector FootLocation = LegComponent.Leg.GetFootLocation();

			CenterLocation += FootLocation;
		}
		CenterLocation /= Boss.LegComponents.Num();

		FVector AheadOffset;

		if(MovementData.IsValid())
		{
			FVector ToTarget = (MovementData.ToHub.ActorLocation - Boss.ActorLocation).VectorPlaneProject(FVector::UpVector);
			float Distance = ToTarget.Size();
			float Alpha = Math::GetPercentageBetweenClamped(SkylineBoss::Fall::HorizontalDistanceThreshold, 20000, Distance);
			AheadOffset = TargetForward * Alpha * 15000;
		}
		
		float BobAlpha = Math::EaseIn(0.0, 1.0, Math::Sin(MovementData.StepAlpha * PI), 1.4);
		if (Boss.Settings.FootStepCurve != nullptr)
			BobAlpha = Boss.Settings.FootStepCurve.GetFloatValue(MovementData.StepAlpha);
		FVector StepHeightOffset = FVector::UpVector * BobAlpha * Boss.Settings.StepHeight;
		
		FVector BaseHeightOffset = FVector::UpVector * Boss.Settings.PendingDownHeight;
		return CenterLocation + BaseHeightOffset + StepHeightOffset + AheadOffset;
	}
	
	FQuat CalculateHeadTargetRotation() const
	{
		check(HasControl());

		const auto& MovementData = Boss.MovementQueue[0];

		auto Spline = MovementData.SplineActor.Spline;
		FTransform ClosestTransform = Spline.GetClosestSplineWorldTransformToWorldLocation(Boss.ActorLocation);
		// Rotation, from spline when moving, towards feet when rebasing
		if(MovementData.IsValid() && !MovementData.IsRebasing())
		{
			// Forward from spline direction (inverted if walking in reverse)

			if (MovementData.bIsReversed)
			{
				ClosestTransform.Rotation = FQuat::MakeFromZX(FVector::UpVector, -ClosestTransform.Rotation.ForwardVector);
			}
			else
			{
				ClosestTransform.Rotation = FQuat::MakeFromZX(FVector::UpVector, ClosestTransform.Rotation.ForwardVector);
			}
		}

		return FQuat::MakeFromZX(FVector::UpVector, ClosestTransform.Rotation.ForwardVector);
	}

	FQuat CalculateBodyTargetRotation() const
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