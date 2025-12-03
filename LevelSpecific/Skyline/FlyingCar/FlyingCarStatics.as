namespace FlyingCar
{
	bool ConstrainLocationToHighwayBounds(const FSkylineFlyingCarSplineParams& SplineParams, FVector& OutLocation, bool bConstrainVertical = true, bool bConstrainHorizontal = true)
	{
		bool bConstrained = false;

		if (bConstrainHorizontal && SplineParams.SplineHorizontalDistanceAlphaUnclamped >= 1.0)
		{
			OutLocation += SplineParams.DirToSpline.ConstrainToDirection(SplineParams.SplinePosition.WorldRightVector) * (SplineParams.SplineHorizontalDistanceAlphaUnclamped - 1.0) * SplineParams.HighWay.CorridorWidth;
			bConstrained = true;
		}

		if (bConstrainVertical && SplineParams.SplineVerticalDistanceAlphaUnclamped >= 1.0)
		{
			OutLocation += SplineParams.DirToSpline.ConstrainToDirection(SplineParams.SplinePosition.WorldUpVector) * (SplineParams.SplineVerticalDistanceAlphaUnclamped - 1.0) * SplineParams.HighWay.CorridorHeight;
			bConstrained = true;
		}

		return bConstrained;
	}

	bool SoftConstrainLocationToHighwayBounds(const FSkylineFlyingCarSplineParams& SplineParams, FVector& OutVelocity, float Margin, bool bConstrainVertical = true, bool bConstrainHorizontal = true)
	{
		bool bConstrained = false;

		if (bConstrainHorizontal)
		{
			if (SplineParams.SplineHorizontalDistanceAlphaUnclamped >= (1.0 - Margin) && OutVelocity.DotProduct(SplineParams.DirToSpline) < 0)
			{
				float Spill = Math::Square(1.0 - Math::Saturate((1.0 - SplineParams.SplineHorizontalDistanceAlphaUnclamped) / Margin));
				OutVelocity -= OutVelocity.ConstrainToDirection(SplineParams.SplinePosition.WorldRightVector) * Spill;

				bConstrained = true;
			}
		}

		if (bConstrainVertical)
		{
			if (SplineParams.SplineVerticalDistanceAlphaUnclamped >= (1.0 - Margin) && OutVelocity.DotProduct(SplineParams.DirToSpline) < 0)
			{
				float Spill = Math::Square(1.0 - Math::Saturate((1.0 - SplineParams.SplineVerticalDistanceAlphaUnclamped) / Margin));
				OutVelocity -= OutVelocity.ConstrainToDirection(SplineParams.SplinePosition.WorldUpVector) * Spill;

				bConstrained = true;
			}
		}

		return bConstrained;
	}

	void SteerTowardsHighway(const ASkylineFlyingCar& Car, const FSkylineFlyingCarSplineParams& FutureSplineParams, USkylineFlyingCarGotySettings Settings, FVector& OutMoveDelta)
	{
		if (Car.ActiveHighway.MovementConstraintType == ESkylineFlyingHighwayMovementConstraint::Tunnel)
		{
			const float TunnelCenterDistanceAlpha = Math::Min(FutureSplineParams.SplineHorizontalDistanceAlphaUnclamped, 1.0);
			float GuideSplineStrengthAlpha = Settings.SplineGuidanceStrengthAlphaModifier.GetFloatValue(TunnelCenterDistanceAlpha, TunnelCenterDistanceAlpha);
			GuideSplineStrengthAlpha = Settings.SplineGuidanceStrength.Lerp(Math::Saturate(GuideSplineStrengthAlpha));
			if(GuideSplineStrengthAlpha > KINDA_SMALL_NUMBER)
			{
				FSplinePosition SteeringPosition = FutureSplineParams.SplinePosition;
				float Offset = Car.ActiveHighway.CorridorWidth;
				SteeringPosition.Move(Settings.SplineGuidanceDistance + Offset);

				FVector ToSplineCenterDeltaMovement = (SteeringPosition.WorldLocation - Car.ActorLocation).GetSafeNormal();
				OutMoveDelta = Math::Lerp(OutMoveDelta.GetSafeNormal(), ToSplineCenterDeltaMovement, GuideSplineStrengthAlpha) * OutMoveDelta.Size();	
			}
		}

		if (Car.ActiveHighway.MovementConstraintType == ESkylineFlyingHighwayMovementConstraint::Corridor)
		{
			// Horizontal steer
			const float HorizontalTunnelCenterDistanceAlpha = Math::Min(FutureSplineParams.SplineHorizontalDistanceAlphaUnclamped, 1.0);
			float GuideSplineHorizontalStrengthAlpha = Settings.SplineGuidanceStrengthAlphaModifier.GetFloatValue(HorizontalTunnelCenterDistanceAlpha, HorizontalTunnelCenterDistanceAlpha);
			GuideSplineHorizontalStrengthAlpha = Settings.SplineGuidanceStrength.Lerp(Math::Saturate(GuideSplineHorizontalStrengthAlpha));

			// Vertical steer
			const float VerticalTunnelCenterDistanceAlpha = Math::Min(FutureSplineParams.SplineVerticalDistanceAlphaUnclamped, 1.0);
			float GuideSplineVerticalStrengthAlpha = Settings.SplineGuidanceStrengthAlphaModifier.GetFloatValue(VerticalTunnelCenterDistanceAlpha, VerticalTunnelCenterDistanceAlpha);
			GuideSplineVerticalStrengthAlpha = Settings.SplineGuidanceStrength.Lerp(Math::Saturate(GuideSplineVerticalStrengthAlpha));

			// Split delta into horizontal and vertical
			if (GuideSplineHorizontalStrengthAlpha > KINDA_SMALL_NUMBER || GuideSplineVerticalStrengthAlpha > KINDA_SMALL_NUMBER)
			{
				FSplinePosition SteeringPosition = FutureSplineParams.SplinePosition;
				SteeringPosition.Move(Settings.SplineGuidanceDistance);

				FVector CarToSpline = SteeringPosition.WorldLocation - Car.ActorLocation;
				FVector HorizontalSplineCenterDeltaMovement = CarToSpline.ConstrainToDirection(SteeringPosition.WorldRightVector).GetSafeNormal();
				FVector VerticalSplineCenterDeltaMovement = CarToSpline.ConstrainToDirection(SteeringPosition.WorldUpVector).GetSafeNormal();

				FVector HorizontalFinalDelta = OutMoveDelta.ConstrainToDirection(SteeringPosition.WorldRightVector);
				FVector VerticalFinalDelta = OutMoveDelta.ConstrainToDirection(SteeringPosition.WorldUpVector);

				OutMoveDelta = Math::Lerp(HorizontalFinalDelta.GetSafeNormal(), HorizontalSplineCenterDeltaMovement, GuideSplineHorizontalStrengthAlpha) * HorizontalFinalDelta.Size() +
								Math::Lerp(VerticalFinalDelta.GetSafeNormal(), VerticalSplineCenterDeltaMovement, GuideSplineVerticalStrengthAlpha) * VerticalFinalDelta.Size() +
								OutMoveDelta.ConstrainToDirection(SteeringPosition.WorldForwardVector);
			}
		}
	}

	bool IsOnSlidingGround(UHazeMovementComponent MovementComponent)
	{
		// if (!MovementComponent.GroundContact.IsValidBlockingHit())
		// 	return false;

		// if (!MovementComponent.GroundContact.Component.HasTag(FlyingCarTags::CollisionTag::NonLethal))
		// 	return false;

		if (!MovementComponent.IsOnWalkableGround())
			return false;

		return true;
	}

	AHazePlayerCharacter GetGunnerPlayer()
	{
		return Game::Mio;
	}

	AHazePlayerCharacter GetPilotPlayer()
	{
		return Game::Zoe;
	}

#if EDITOR
	void DebugDrawSplinePosition(FSplinePosition SplinePosition)
	{
		Debug::DrawDebugSphere(SplinePosition.WorldLocation, 100, 12, FLinearColor::Purple * 0.5);
		Debug::DrawDebugDirectionArrow(SplinePosition.WorldLocation, SplinePosition.WorldForwardVector, 5000, 5, FLinearColor::DPink);
		Debug::DrawDebugDirectionArrow(SplinePosition.WorldLocation, SplinePosition.WorldRightVector, 5000, 5, FLinearColor::Green);
		Debug::DrawDebugDirectionArrow(SplinePosition.WorldLocation, SplinePosition.WorldUpVector, 5000, 5, FLinearColor::LucBlue);
	}
#endif
}