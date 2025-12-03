event void FOnDragonRunActivateAttack(AActor Target);

UCLASS(Abstract)
class ADragonRunPlayerDragon : AHazeCharacter
{
	float PauseDistance;

	ADragonRunPlayerDragon OtherDragon;

	FOnDragonRunActivateAttack OnDragonRunActivateAttack;

	FSplinePosition SplinePos;
	UHazeSplineComponent CurrentSplineComp;

	float Speed = 6500.0;
	float AttackLaunchTime;
	bool bLaunchedAttack = false;
	AActor CurrentTarget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DeactivateActor();
		TListedActors<ADragonRunPlayerDragon> Dragons;
		//GetAllActorsOfClass(Dragons);

		for (ADragonRunPlayerDragon Dragon : Dragons)
		{
			if (Dragon != this)
				OtherDragon = Dragon;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SplinePos.Move(Speed * DeltaSeconds);
		SetActorLocationAndRotation(SplinePos.WorldLocation, SplinePos.WorldRotation);

		if (SplinePos.CurrentSplineDistance >= CurrentSplineComp.SplineLength)	
		{
			DeactivateActor();
		}

		if (Time::GameTimeSeconds > AttackLaunchTime && !bLaunchedAttack)
		{
			bLaunchedAttack = true;
			OnDragonRunActivateAttack.Broadcast(CurrentTarget);	
			CurrentTarget = nullptr;
		}

	}

	UFUNCTION()
	void ActivateSplineMove(ASplineActor SplineActor, float AttackDelay, AActor Target = nullptr)
	{
		SetActorTickEnabled(true);
		SetActorHiddenInGame(false);
		CurrentSplineComp = SplineActor.Spline;
		SplinePos = CurrentSplineComp.GetSplinePositionAtSplineDistance(0);

		bLaunchedAttack = false;
		AttackLaunchTime = Time::GameTimeSeconds + AttackDelay;
		CurrentTarget = Target;
	}

	void DeactivateActor()
	{
		SetActorHiddenInGame(true);
		SetActorTickEnabled(false);
	}
}