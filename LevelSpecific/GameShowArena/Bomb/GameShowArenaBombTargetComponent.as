class UGameShowArenaBombTargetComponent : UAutoAimTargetComponent
{
	default MaximumDistance = GameShowArenaBombAutoAim::MaximumDistance;
	default bUseVariableAutoAimMaxAngle = GameShowArenaBombAutoAim::bUseVariableAutoAimMaxAngle;
	default AutoAimMaxAngleMinDistance = GameShowArenaBombAutoAim::AutoAimMaxAngleMinDistance;
	default AutoAimMaxAngleAtMaxDistance = GameShowArenaBombAutoAim::AutoAimMaxAngleAtMaxDistance;
	const float AngleBuffer = GameShowArenaBombAutoAim::AutoAimAngleBuffer;

	bool bIsOverrideTarget = false;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		FVector TargetLocation = GetAutoAimTargetPointForRay(Query.AimRay);
		// Bail if this target is disabled
		if (!bIsAutoAimEnabled)
			return false;

		auto Player = Cast<AHazePlayerCharacter>(Owner);
		if (Player != nullptr && Player.IsPlayerDead())
			return false;

		if (bIsOverrideTarget)
		{
			Targetable::MarkVisibilityHandled(Query);
			return CheckPrimaryOcclusion(Query, TargetLocation);
		}

		// Pre-cull based on total distance, this is technically a bit inaccurate with the shape,
		// but max distances are generally so far that it doesn't matter
		float BaseDistanceSQ = WorldLocation.DistSquared(Query.AimRay.Origin);

		if (BaseDistanceSQ < Math::Square(MinimumDistance))
			return false;

		if (BaseDistanceSQ > Math::Square(MaximumDistance))
			return false;

		if (bOnlyValidIfAimOriginIsWithinAngle)
		{
			// If the aim origin is outside of an aiming cone, then this target is invalid
			const FVector ToAimOrigin = Query.AimRay.Origin - WorldLocation;
			float Angle = ForwardVector.GetAngleDegreesTo(ToAimOrigin);
			if (Angle > MaxAimAngle)
				return false;
		}

		// Check if we are actually inside the auto-aim arc

		if (!Targetable::IsOnScreen(Query))
			return false;

		// Cull the minimum distance again, since it's likely we're closer to the shape than to the origin
		Query.DistanceToTargetable = TargetLocation.Distance(Query.AimRay.Origin);
		if (Query.DistanceToTargetable < MinimumDistance)
			return false;

		// Auto aim angle can change based on distance
		float MaxAngle = CalculateAutoAimMaxAngle(Query.DistanceToTargetable);
		if (Query.bWasPreviousPrimary)
			MaxAngle += AngleBuffer;

#if !RELEASE
		// Show debugging for auto-aim if we want to
		ShowDebug(Query.Player, MaxAngle, Query.DistanceToTargetable);
#endif
		Targetable::MarkVisibilityHandled(Query);
		return CheckPrimaryOcclusion(Query, TargetLocation);
	}
};