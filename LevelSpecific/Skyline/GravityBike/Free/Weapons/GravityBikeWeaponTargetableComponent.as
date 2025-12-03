/**
 * Copy of USkylineAxisAutoAimTargetComponent
 * Used by GravityBikeFree MissileLauncher
 */
UCLASS(NotBlueprintable)
class UGravityBikeWeaponTargetableComponent : UAutoAimTargetComponent
{
	default TargetableCategory = GravityBikeWeapon::TargetableCategory;

    UPROPERTY(EditAnywhere, Category = "Auto Aim", Meta = (EditCondition = "!bUseVariableAutoAimMaxAngle", EditConditionHides))
    bool bInfiniteVertical = true;

	default MaxAimAngle = 15;
/*
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

			AimDirection = ProjectedDirection;
		}

		float AngularBend = Math::RadiansToDegrees(AimDirection.AngularDistanceForNormals(TargetDirection));

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
		if (Query.Result.Score >= Query.CurrentEvalPrimaryScore)
		{
			Targetable::MarkVisibilityHandled(Query);
			return CheckPrimaryOcclusion(Query, TargetLocation);
		}

		return true;
	}
*/
};