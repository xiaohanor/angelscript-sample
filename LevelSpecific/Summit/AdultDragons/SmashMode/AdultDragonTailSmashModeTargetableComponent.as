class UAdultDragonTailSmashModeTargetableComponent : UTargetableComponent
{
	default TargetableCategory = n"PrimaryLevelAbility";
	default UsableByPlayers = EHazeSelectPlayer::Zoe;

	// Range from player under which the targetable is disregarded
	UPROPERTY(EditAnywhere, Category = "Settings")
	float MaxRange = 12000;

	// Maximum degrees allowed between dragon forward and the targetable
	UPROPERTY(EditAnywhere, Category = "Settings")
	float MaxDegreesAllowed = 50;

	// How fast the dragon rotates towards the targetable
	UPROPERTY(EditAnywhere, Category = "Settings")
	float InterpSpeed = 10.0;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if(Query.Player == nullptr)
			return false;

		Targetable::ApplyTargetableRange(Query, MaxRange);

		FVector DirToPoint = (Query.Component.WorldLocation - Query.Player.ActorLocation).GetSafeNormal();
		float AngleDist = Query.Player.ActorForwardVector.AngularDistance(DirToPoint);

		if(Math::RadiansToDegrees(AngleDist) > MaxDegreesAllowed)
			return false;

		Query.Result.Score = 1.0 / Math::Max(AngleDist, 0.001);
		return true;
	}

}