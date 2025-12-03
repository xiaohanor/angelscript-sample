class UTeenDragonRollRailComponent : UActorComponent
{
	TArray<FInstigator> RollRailInstigators;

	TArray<USummitTeenDragonRollRailSplineComponent> RollRailsInRange;
	TOptional<USummitTeenDragonRollRailSplineComponent> CurrentRollRail;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	TOptional<USummitTeenDragonRollRailSplineComponent> GetFirstValidRollRailInRange() const
	{
		TOptional<USummitTeenDragonRollRailSplineComponent> RollRailToReturn;
		for(auto RollRail : RollRailsInRange)
		{
			FVector ClosestSplineLoc = RollRail.SplineComp.GetClosestSplineWorldLocationToWorldLocation(Player.ActorLocation);
			float DistanceToSplineLocSqrd = ClosestSplineLoc.DistSquared(Player.ActorLocation);
			if(DistanceToSplineLocSqrd <= Math::Square(RollRail.SplineSize))
			{
				RollRailToReturn.Set(RollRail);
				break;
			}
		}
		return RollRailToReturn;
	}

	bool IsInRollRail() const
	{
		return RollRailInstigators.Num() > 0;
	}
};