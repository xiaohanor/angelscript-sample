class USkylineAxisAutoAimTargetComponent : UAutoAimTargetComponent
{
	default TargetableCategory = GravityBikeWeapon::TargetableCategory;

	/*
    UPROPERTY(EditAnywhere, Category = "Auto Aim", Meta = (EditCondition = "!bUseVariableAutoAimMaxAngle", EditConditionHides))
    float AutoAimMaxHorizontalAngle = 3.0;

    UPROPERTY(EditAnywhere, Category = "Auto Aim", Meta = (EditCondition = "!bUseVariableAutoAimMaxAngle", EditConditionHides))
    float AutoAimMaxVerticalAngle = 3.0;
	*/

    UPROPERTY(EditAnywhere, Category = "Auto Aim", Meta = (EditCondition = "!bUseVariableAutoAimMaxAngle", EditConditionHides))
    bool bInfiniteVertical = true;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		// Bail if this target is disabled
		if (!bIsAutoAimEnabled)
			return false;

		// Pre-cull based on total distance, this is technically a bit inaccurate with the shape,
		// but max distances are generally so far that it doesn't matter
		float BaseDistanceSQ = WorldLocation.DistSquared(Query.AimRay.Origin);
		if (BaseDistanceSQ > Math::Square(MaximumDistance))
			return false;
		if (BaseDistanceSQ < Math::Square(MinimumDistance))
			return false;

		if(bOnlyValidIfAimOriginIsWithinAngle)
		{
			// If the aim origin is outside of an aiming cone, then this target is invalid
			const FVector ToAimOrigin = Query.AimRay.Origin - WorldLocation;
			float Angle = ForwardVector.GetAngleDegreesTo(ToAimOrigin);
			if(Angle > MaxAimAngle)
				return false;
		}

		// Check if we are actually inside the auto-aim arc
		FVector TargetLocation = GetAutoAimTargetPointForRay(Query.AimRay);

		// Cull the minimum distance again, since it's likely we're closer to the shape than to the origin
		Query.DistanceToTargetable = TargetLocation.Distance(Query.AimRay.Origin);
		if (Query.DistanceToTargetable < MinimumDistance)
			return false;

		// Auto aim angle can change based on distance
		float MaxAngle = CalculateAutoAimMaxAngle(Query.DistanceToTargetable);

#if !RELEASE
		// Show debugging for auto-aim if we want to
		ShowDebug(Query.Player, MaxAngle, Query.DistanceToTargetable);
#endif

		FVector TargetDirection = (TargetLocation - Query.AimRay.Origin).GetSafeNormal();

		FVector AimDirection = Query.AimRay.Direction;

		if (bInfiniteVertical)
		{
			FVector AimRightVector = TargetDirection.CrossProduct(FVector::UpVector);
			FVector AimUpVector = AimRightVector.CrossProduct(TargetDirection).SafeNormal;
			FVector ProjectedDirection = Query.AimRay.Direction.VectorPlaneProject(AimUpVector).SafeNormal;

		//	Debug::DrawDebugLine(Query.AimRay.Origin, Query.AimRay.Origin + AimUpVector * 3000.0, FLinearColor::Blue, 10.0);
		//	Debug::DrawDebugLine(Query.AimRay.Origin, Query.AimRay.Origin + ProjectedDirection * 3000.0, FLinearColor::Red, 10.0);
		//	Debug::DrawDebugLine(Query.AimRay.Origin, Query.AimRay.Origin + TargetDirection * 3000.0, FLinearColor::Green, 10.0);

			AimDirection = ProjectedDirection;
		}

		float AngularBend = Math::RadiansToDegrees(AimDirection.AngularDistanceForNormals(TargetDirection));

//		if (AngularBend <= MaxAngle)
//			Debug::DrawDebugLine(Query.AimRay.Origin, Query.AimRay.Origin + AimDirection * 3000.0, FLinearColor::LucBlue, 30.0);

//		float AngularBend = Math::RadiansToDegrees(Query.AimRay.Direction.AngularDistanceForNormals(TargetDirection));

/*
		Debug::DrawDebugEllipse(TargetLocation, FVector2D(AutoAimMaxVerticalAngle, AutoAimMaxHorizontalAngle) * 100.0, FLinearColor::Green, 20.0, TargetDirection.SafeNormal, FVector::UpVector, 48);

		FVector ProjectedPoint = Math::LinePlaneIntersection(Query.AimRay.Origin, Query.AimRay.Origin + Query.AimRay.Direction * MaximumDistance, TargetLocation, TargetDirection);

		FTransform Transform;
		Transform.Location = TargetLocation;
		Transform.Rotation = (-TargetDirection).ToOrientationQuat();
		Transform.Scale3D = FVector::OneVector;

		FVector RelativePoint = Transform.InverseTransformPositionNoScale(ProjectedPoint);

		PrintToScreen("RelativePoint" + RelativePoint, 0.0, FLinearColor::Green);

		Debug::DrawDebugPoint(ProjectedPoint, 100.0, FLinearColor::Red);
		float a = AutoAimMaxHorizontalAngle * 100.0;
		float b = AutoAimMaxVerticalAngle * 100.0;
		float angle = Math::Atan2(RelativePoint.Z, RelativePoint.Y);

		float k = (a * b) / Math::Sqrt(Math::Pow(b, 2.0) * Math::Pow(Math::Cos(angle), 2.0) + Math::Pow(a, 2.0) * Math::Pow(Math::Sin(angle), 2.0));

		FVector PointOnEllipse = FVector(0.0, k * Math::Cos(angle), k * Math::Sin(angle));

		FVector PointOnEllipseWorld = Transform.TransformPositionNoScale(PointOnEllipse);
		FVector DirectionToPointOnEllipse = (PointOnEllipseWorld - Query.AimRay.Origin).SafeNormal;

		Debug::DrawDebugLine(Query.AimRay.Origin, Query.AimRay.Origin + DirectionToPointOnEllipse * 3000.0, FLinearColor::Red, 10.0);

		MaxAngle = DirectionToPointOnEllipse.AngularDistanceForNormals(TargetDirection);

	//	MaxAngle *= PointOnEllipse.Size();

		PrintToScreen("MaxAngle" + MaxAngle, 0.0, FLinearColor::Green);

		Debug::DrawDebugPoint(PointOnEllipseWorld, 50.0, FLinearColor::Yellow);
*/

		if (AngularBend > MaxAngle)
		{
			Query.Result.Score = 0.0;
			return true;
		}

		// Score the distance based on how much we have to bend the aim
		Query.Result.Score = (1.0 - (AngularBend / MaxAngle));
		Query.Result.Score /= Math::Pow(Math::Max(Query.DistanceToTargetable, 0.01) / 1000.0, TargetDistanceWeight);

		// Apply bonus to score
		Query.Result.Score *= ScoreMultiplier;

		// If the point is occluded we can't target it,
		// we only do this test if we would otherwise become primary target (performance)
		if (Query.IsCurrentScoreViableForPrimary())
		{
			Targetable::MarkVisibilityHandled(Query);
			return CheckPrimaryOcclusion(Query, TargetLocation);
		}

		return true;
	}
}