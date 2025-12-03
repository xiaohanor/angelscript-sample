class UDarkCaveSpiritFishTargetableComponent : UTargetableComponent
{
	default TargetableCategory = n"SpiritFish";

	UPROPERTY()
	float MaxRange = 1000.0;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		auto Player = Query.Player;
		float Distance = Owner.GetDistanceTo(Player);

		if (Distance > MaxRange)
			return false;
		
		Query.bDistanceAppliedToScore = true;
		Targetable::ApplyDistanceToScore(Query);
		Targetable::ScoreLookAtAim(Query);

		return Query.IsCurrentScoreViableForPrimary();
	}
};