class UDarkPortalAutoAimComponent : UAutoAimTargetComponent
{
	default TargetableCategory = n"DarkPortalAutoAim";
	default UsableByPlayers = EHazeSelectPlayer::Zoe;

	default MaximumDistance = 2500.0;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if (!bIsAutoAimEnabled)
			return false;

		if (Query.Is2DTargeting())
		{
			Targetable::ApplyVisibleRange(Query, MaximumDistance);
			Targetable::ApplyTargetableRange(Query, MaximumDistance);
			Targetable::Score2DTargeting(Query);

			if (Query.IsCurrentScoreViableForPrimary())
			{
				return CheckPrimaryOcclusion(Query, Query.Component.WorldLocation);
			}
		}
		else
		{
			return Super::CheckTargetable(Query);
		}

		return true;
	}
}