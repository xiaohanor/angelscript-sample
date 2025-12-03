event void FIslandOverseerRollerSweepComponentCancelHitEvent(FIslandOverseerRollerSweepComponentOnCancelHitParams Params);

class UIslandOverseerRollerSweepComponent : UActorComponent
{
	UHazeSplineComponent Spline;
	bool bInterrupted;
	bool bReverse;
	FVector StartLocation;
	int ShieldActivationsLimit;
	float FlashDuration = 0.1;
	float FlashTime;

	FIslandOverseerRollerSweepComponentCancelHitEvent OnCancelHit;

	void SetSpline()
	{
		Spline = TListedActors<AIslandOverseerRollerSweepSpline>().GetSingle().Spline;
		SetStartLocation();
		OnCancelHit.AddUFunction(this, n"CancelHit");
	}

	private void SetStartLocation()
	{
		float ClosestDistance = BIG_NUMBER;
		for(int i = 0; i < Spline.SplinePoints.Num(); i++)
		{
			FVector Location = Spline.GetWorldLocationAtSplineDistance(Spline.GetSplineDistanceAtSplinePointIndex(i));
			float SplineDistance = Location.Distance(Owner.ActorLocation);
			if(SplineDistance < ClosestDistance)
			{
				StartLocation = Location;
				ClosestDistance = SplineDistance;
				bReverse = i == Spline.SplinePoints.Num()-1;
			}
		}
	}

	UFUNCTION()
	private void CancelHit(FIslandOverseerRollerSweepComponentOnCancelHitParams Params)
	{
		if(Time::GetGameTimeSince(FlashTime) > FlashDuration + 0.1)
		{
			DamageFlash::DamageFlashActor(Owner, FlashDuration, FLinearColor(0.9, 0, 0, 1));
			FlashTime = Time::GameTimeSeconds;
			FlashDuration = Math::RandRange(0.1, 0.2);
		}
	}
}

struct FIslandOverseerRollerSweepComponentOnCancelHitParams
{
	FVector ImpactLocation;
}