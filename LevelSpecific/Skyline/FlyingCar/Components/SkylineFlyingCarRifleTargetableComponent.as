class USkylineFlyingCarRifleTargetableComponent : UAutoAimTargetComponent
{
	default UsableByPlayers = EHazeSelectPlayer::Mio;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		Targetable::ApplyVisibleRange(Query, MaximumDistance);
		if (!Query.Result.bPossibleTarget)
			return false;

		return Super::CheckTargetable(Query);
	}
}