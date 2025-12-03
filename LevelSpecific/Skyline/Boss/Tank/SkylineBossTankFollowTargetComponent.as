class USkylineBossTankFollowTargetComponent : UActorComponent
{
	FVector CurrentTarget;

	float TargetRadius = 1000.0;
	bool bFlipFlop = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentTarget = Game::Mio.RootComponent.WorldLocation;
	}

	FVector GetTarget()
	{
		return CurrentTarget;
	}

	void SetTarget(FVector Target)
	{
		CurrentTarget = Target;
	}

	void FindNewTarget(FTransform Transform, float Radius)
	{
		FVector Target = (bFlipFlop ? Transform.InverseTransformPositionNoScale(Game::Mio.ActorLocation) : Transform.InverseTransformPositionNoScale(Game::Zoe.ActorLocation)).GetClampedToMaxSize(Radius);
		bFlipFlop = !bFlipFlop;

		auto RandPoint = Math::RandPointInCircle(Radius);
//		CurrentTarget = Transform.TransformPositionNoScale(FVector(RandPoint.X, RandPoint.Y, 0.0));
		CurrentTarget = Transform.TransformPositionNoScale(FVector(Target.X, Target.Y, 0.0));
	}
};