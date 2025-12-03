class UPinballBossAutoAimComponent : UMagnetDroneAutoAimComponent
{
	bool TopDownTargeting(FTargetableQuery& Query) const override
	{
		float Padding = 0;
		if(TargetShape.Type == EHazeShapeType::Box)
			Padding = TargetShape.BoxExtents.Size();
		else if(TargetShape.Type == EHazeShapeType::Sphere)
			Padding = TargetShape.SphereRadius;

		Query.DistanceToTargetable = DistanceFromPoint(Query.PlayerLocation);

		Targetable::ApplyVisibleRange(Query, MagnetDrone::VisibleDistance_2D + Padding);
		Targetable::ApplyTargetableRange(Query, MaximumDistance + Padding);

		if(bOnlyValidIfAimOriginIsWithinAngle)
		{
			// If the aim origin is outside of an aiming cone, then this target is invalid
			const FVector ToAimOrigin = Query.PlayerLocation - WorldLocation;
			float Angle = ForwardVector.GetAngleDegreesTo(ToAimOrigin);
			if(Angle > MaxAimAngle)
				return false;
		}

		// if (Query.Result.Score >= Query.CurrentEvalPrimaryScore)
		// {
		// 	FVector TargetLocation = GetAutoAimTargetPointForRay(Query.AimRay);
		// 	return RequireMagnetDroneCanReachUnblocked(Query, TargetLocation, bIgnoreActorCollisionForAimTrace);
		// }

		return true;
	}
};