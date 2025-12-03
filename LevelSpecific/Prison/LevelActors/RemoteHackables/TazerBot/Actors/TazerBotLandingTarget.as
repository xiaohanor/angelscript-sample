struct FTazerBotLandingTargetQuery
{
	ATazerBot TazerBot;
	FVector Direction;

	FTazerBotLandingTargetQueryResult Result;
}

struct FTazerBotLandingTargetQueryResult
{
	ATazerBotLandingTarget LandingTarget = nullptr;
	FVector LandingLocation = FVector::ZeroVector;
	float Score = -1.0;

	bool IsValid() const
	{
		return Score != -1.0;
	}
}

class ATazerBotLandingTarget : AHazeActor
{
#if EDITOR
	UPROPERTY(DefaultComponent, NotEditable, BlueprintHidden)
	UTazerBotLandingTargetVisualizerDummyComponent VisualizerDummy;
#endif

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
 
	UPROPERTY(DefaultComponent)
	UHazeSplineComponent SplineTarget;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY(EditAnywhere, Category = "Targeting")
	float MinRange = 1000.0;

	UPROPERTY(EditAnywhere, Category = "Targeting")
	float MaxRange = 2100.0;

	// Max angle allowed between magnetic force and robot-to-spline
	UPROPERTY(EditAnywhere, Category = "Targeting")
	float MaxAngle = 30.0;

	bool CheckTargetable(FTazerBotLandingTargetQuery& TargetQuery)
	{
		ATazerBot TazerBot = TargetQuery.TazerBot;
		TargetQuery.Result = FTazerBotLandingTargetQueryResult();

		// Check general aiming
		FVector RobotToTarget = (ActorLocation - TazerBot.ActorLocation).ConstrainToPlane(TazerBot.MovementWorldUp);
		if (RobotToTarget.DotProduct(TargetQuery.Direction) < 0.2)
			return false;

		// Check distance
		FVector ClosestSplineLocation = SplineTarget.GetClosestSplineWorldLocationToWorldLocation(TazerBot.ActorLocation + TargetQuery.Direction * RobotToTarget.Size());
		FVector RobotToClosestSplineLocation = (ClosestSplineLocation - TazerBot.ActorLocation).ConstrainToPlane(TazerBot.MovementWorldUp);
		if (RobotToClosestSplineLocation.Size() > MaxRange || RobotToClosestSplineLocation.Size() < MinRange)
			return false;

		// Check angle relative to actual spline location
		float Angle = RobotToClosestSplineLocation.GetAngleDegreesTo(TargetQuery.Direction);
		if (Angle > MaxAngle)
			return false;

		// Debug::DrawDebugLine(TazerBot.ActorLocation, ClosestSplineLocation, FLinearColor::Green, 3, 1);

		float AngleScore = 1.0 - Math::Saturate(Angle / MaxAngle);
		float DistanceScore = 1.0 - Math::Saturate(RobotToClosestSplineLocation.Size() / MaxRange);

		TargetQuery.Result.Score = AngleScore + DistanceScore;
		TargetQuery.Result.LandingLocation = ClosestSplineLocation;
		TargetQuery.Result.LandingTarget = this;

		return true;
	}
}