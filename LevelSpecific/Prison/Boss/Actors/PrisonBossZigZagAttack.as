UCLASS(Abstract)
class APrisonBossZigZagAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	bool bLaunched = false;

	FHazeRuntimeSpline RuntimeSpline;

	float Dist = 0.0;
	float Speed = 2400.0;

	bool bReachedEnd = false;
	float CurrentDisableDuration = 0.0;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	void LaunchAttack(ASplineActor Spline)
	{	
		Dist = 0.0;

		for (FHazeSplinePoint Point : Spline.Spline.SplinePoints)
		{
			FVector Loc = Spline.ActorTransform.TransformPosition(Point.RelativeLocation);
			RuntimeSpline.AddPoint(Loc);
		}

		bLaunched = true;

		UPrisonBossZigZagEffectEventHandler::Trigger_Activate(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bLaunched)
			return;

		if (bReachedEnd)
		{
			CurrentDisableDuration += DeltaTime;
			if (CurrentDisableDuration >= 1.5)
				return;
		}
		else
		{
			Dist += Speed * DeltaTime;
			FVector Loc = RuntimeSpline.GetLocationAtDistance(Dist);
			SetActorLocation(Loc);

			if (Dist >= RuntimeSpline.Length)
				PrepareDisable();
		}

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			float ClosestDist = RuntimeSpline.GetClosestSplineDistanceToLocation(Player.ActorLocation);
			if (Dist >= ClosestDist - 100.0)
			{
				FVector SplineLoc = RuntimeSpline.GetLocationAtDistance(ClosestDist);
				float VerticalDif = Player.ActorLocation.Z - SplineLoc.Z;
				if (SplineLoc.Distance(Player.ActorLocation) <= 50.0 && VerticalDif <= 0.0)
				{
					FVector SplineDir = RuntimeSpline.GetDirectionAtDistance(ClosestDist);
					Player.DamagePlayerHealth(0.5, FPlayerDeathDamageParams(SplineDir), DamageEffect, DeathEffect);
				}
			}
		}
	}

	void PrepareDisable()
	{
		bReachedEnd = true;
		BP_PrepareDisable();

		Timer::SetTimer(this, n"Disable", 3.0);
	}

	UFUNCTION(BlueprintEvent)
	void BP_PrepareDisable() {}

	UFUNCTION()
	private void Disable()
	{
		AddActorDisable(this);

		UPrisonBossZigZagEffectEventHandler::Trigger_Dissipate(this);
	}
}