class UPlayerSnowMonkeyGroundSlamTargetableComponent : UTargetableComponent
{
	default UsableByPlayers = EHazeSelectPlayer::Mio;

	UPROPERTY(EditAnywhere)
	float TargetableRange = 500.0;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		Query.bHasHandledVisibility = true;
		if(Query.PlayerLocation.DistSquaredXY(Query.TargetableLocation) > Math::Square(TargetableRange))
		{
			Query.Result.bVisible = false;
			Query.Result.bPossibleTarget = false;
		}

		Targetable::ApplyDistanceToScore(Query);
		Targetable::RequirePlayerCanReachUnblocked(Query);
		return true;
	}
}

class UPlayerSnowMonkeyGroundSlamTargetableVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPlayerSnowMonkeyGroundSlamTargetableComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Targetable = Cast<UPlayerSnowMonkeyGroundSlamTargetableComponent>(Component);
		DrawCircle(Targetable.WorldLocation, Targetable.TargetableRange, FLinearColor::Red, 3.0);
	}
}