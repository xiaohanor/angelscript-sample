class USkylineFylingCarPilotCameraPostMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

    default DebugCategory = CameraTags::Camera;
	default TickGroup = EHazeTickGroup::AfterPhysics;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	USkylineFlyingCarPilotComponent PilotComponent;
	UHazeOffsetComponent CameraRoot;
	UCameraUserComponent CameraUser;

	FHazeAcceleratedVector FinalTargetLocation;
	FVector PreviousCameraLocation;
	FVector PreviousCarLocation;

	ASkylineFlyingHighway PreviousHighWay;
	float HighWayActiveAlpha = 0.0;
	FVector CurrentSplineDiff = FVector::ZeroVector;
	FVector PreviousHighwayDiff = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PilotComponent = USkylineFlyingCarPilotComponent::Get(Owner);
		CameraRoot = Player.CameraOffsetComponent;
		CameraUser = UCameraUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PilotComponent.Car == nullptr)
	        return false;
		
		// ASkylineFlyingHighway CurrentHighwar = PilotComponent.Car.GetActiveHighway();
		// if(CurrentHighwar == nullptr)
		// 	return false;

        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PilotComponent.Car == nullptr)
	        return true;

		// ASkylineFlyingHighway CurrentHighwar = PilotComponent.Car.GetActiveHighway();
		// if(CurrentHighwar == nullptr)
		// 	return true;

        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PreviousCarLocation = PilotComponent.Car.GetActorLocation();
		PreviousCameraLocation = CameraRoot.WorldLocation;
		FinalTargetLocation.SnapTo(PilotComponent.Car.ActorLocation);
		PreviousHighWay = PilotComponent.Car.ActiveHighway;
		HighWayActiveAlpha = 1.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CameraRoot.SetRelativeLocation(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (PilotComponent.Car.IsCarExploding())
			return;

		const FVector CarLocation = PilotComponent.Car.ActorLocation;

		FVector TargetLocation;
		FSkylineFlyingCarSplineParams SplineData;
		if (PilotComponent.Car.GetSplineDataAtPosition(CarLocation, SplineData))
		{
			// When we are jumping between highways, going from the left side to the right side
			// will give an ugly blend, so we need to lerp the previous splines offset to the new splines offset
			HighWayActiveAlpha = Math::FInterpConstantTo(HighWayActiveAlpha, 1.0, DeltaTime, 1.0 / PilotComponent.BlendInSpeed);
			if(PreviousHighWay != SplineData.HighWay)
			{
				HighWayActiveAlpha = 0.0;
				PreviousHighWay = SplineData.HighWay;
				PreviousHighwayDiff = CurrentSplineDiff;
			}	
			
			const FSplinePosition SplinePosition = SplineData.SplinePosition;
			const float SplineCenterDistance = SplinePosition.WorldLocation.Distance(CarLocation);
			const float SplineDistanceAlpha = SplineCenterDistance / PilotComponent.Car.ActiveHighway.TunnelRadius;
			const float FinalDistanceAlpha = PilotComponent.GetFollowCarPercentageModifierFromSplineCenter(SplineDistanceAlpha);

			FVector ClosestSplinePosition = SplinePosition.WorldLocation;

			// When freeflying, we lerp the cameras offset into the the closest spline offset making it smoother
			// going in and out of the spline, since that will move the camera in the upcoming offset
			if(PilotComponent.Car.IsFreeFlying())
			{
				const float TimeAlpha = PilotComponent.FreeFlyPercentage;
				ClosestSplinePosition = Math::Lerp(ClosestSplinePosition, CarLocation, TimeAlpha);

				FVector HorizontalSplineOffset = SplineData.DirToSpline.ConstrainToDirection(SplinePosition.WorldRightVector) * SplineData.HighWay.CorridorWidth * Math::Min(SplineData.SplineHorizontalDistanceAlphaUnclamped, 1.0);
				FVector VerticalSplineOffset = SplineData.DirToSpline.ConstrainToDirection(SplinePosition.WorldUpVector) * SplineData.HighWay.CorridorHeight * Math::Min(SplineData.SplineVerticalDistanceAlphaUnclamped, 1.0);

				ClosestSplinePosition = Math::Lerp(ClosestSplinePosition, CarLocation + HorizontalSplineOffset + VerticalSplineOffset, TimeAlpha);
			}

			const float HorizontalSplineFollowAlpha = (1.0 - (PilotComponent.HorizontalFollowCarPercentage * FinalDistanceAlpha));
			FVector TargetHorizontalLocation = Math::Lerp(CarLocation, ClosestSplinePosition, HorizontalSplineFollowAlpha);
			TargetHorizontalLocation = TargetHorizontalLocation.VectorPlaneProject(PilotComponent.Car.MovementWorldUp);

			const float VerticalSplineFollowAlpha = (1.0 - (PilotComponent.VerticalFollowCarPercentage * FinalDistanceAlpha));
			FVector TargetVerticalLocation = Math::Lerp(CarLocation, ClosestSplinePosition, VerticalSplineFollowAlpha);
			TargetVerticalLocation = TargetVerticalLocation.ProjectOnToNormal(PilotComponent.Car.MovementWorldUp);
			TargetLocation = TargetHorizontalLocation + TargetVerticalLocation;

			CurrentSplineDiff = TargetLocation - CarLocation;
			CurrentSplineDiff = CurrentSplineDiff.VectorPlaneProject(SplinePosition.WorldForwardVector);
			CurrentSplineDiff = Math::Lerp(PreviousHighwayDiff, CurrentSplineDiff, HighWayActiveAlpha);

			TargetLocation = CarLocation + CurrentSplineDiff;
		}
		else
		{
			// No currently active highway (i.e. free flying), just interp back to zero
			FVector TargetRelativeLocation = Math::VInterpTo(CameraRoot.RelativeLocation, FVector::ZeroVector, DeltaTime, 5);
			TargetLocation = CameraRoot.AttachParent.WorldTransform.TransformPositionNoScale(TargetRelativeLocation);
		}

		CameraRoot.SetWorldLocation(TargetLocation);
		PreviousCarLocation = PilotComponent.Car.GetActorLocation();

#if EDITOR
		if (PilotComponent.Car.DebugDrawer.IsVisible())
		{
			Debug::DrawDebugDiamond(TargetLocation, 100, LineColor = FLinearColor::Yellow);
			Debug::DrawDebugString(TargetLocation, "CameraRoot", FLinearColor::Yellow, Scale = 0.7);
		}
#endif
	}
}