class UDarkParasiteTargetComponent : UAutoAimTargetComponent
{
	default TargetableCategory = n"DarkParasite";
	default MaximumDistance = 3500.0;
	default UsableByPlayers = EHazeSelectPlayer::Zoe;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if (!bIsAutoAimEnabled)
			return false;

		if (Query.DistanceToTargetable < MinimumDistance)
			return false;
		if (Query.DistanceToTargetable > MaximumDistance)
			return false;

		float MaxAngle = CalculateAutoAimMaxAngle(Query.DistanceToTargetable);

#if !RELEASE
		ShowDebug(Query.Player, MaxAngle, Query.DistanceToTargetable);
#endif

		FVector AimOrigin = Query.AimRay.Origin;
		FVector AimDirection = Query.AimRay.Direction;
		FVector TargetDirection = (WorldLocation - AimOrigin).GetSafeNormal();
		float AngularBend = Math::RadiansToDegrees(AimDirection.AngularDistanceForNormals(TargetDirection));

		if (AngularBend > MaxAngle)
		{
			Query.Result.Score = 0.0;
			return true;
		}

		Query.Result.Score = (1.0 - (Query.DistanceToTargetable / MaximumDistance)) * TargetDistanceWeight;
		Query.Result.Score += (1.0 - (AngularBend / MaxAngle)) * (1.0 - TargetDistanceWeight);
		Query.Result.Score *= ScoreMultiplier;

		if (Query.IsCurrentScoreViableForPrimary())
		{
			auto UserComp = UDarkParasiteUserComponent::Get(Query.Player);
			if (UserComp == nullptr)
				return false;

			if (UserComp.AttachedData.IsValid())
			{
				if (UserComp.AttachedData.Actor == Owner)
					return false;

				return UserComp.HasLineOfSight(this);
			}
		}

		return true;
	}
}