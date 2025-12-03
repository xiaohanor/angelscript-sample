event void FonMissileHit();
event void FonMissileLaunched();

class AMeltdownBossPhaseOneShockwaveMissile : AHazeActor
{
	UPROPERTY(EditAnywhere)
	ASplineActor Spline;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UHazeSplineComponent SplineComp;

	UPROPERTY(EditAnywhere)
	float Speed = 6000;

	UPROPERTY()
	bool bIsDestroyed;

	UPROPERTY()
	float CurrentSplineDistance;
	
	UPROPERTY(EditAnywhere)
	APlayerTrigger EnterTrigger;

	UPROPERTY(EditAnywhere)
	APlayerTrigger ExitTrigger;

	UPROPERTY()
	FonMissileLaunched MissileLaunched;

	UPROPERTY()
	FonMissileHit MissileHit;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		SetActorHiddenInGame(true);

		SplineComp = Spline.Spline;
		ActorRotation = FRotator(0,Math::RandRange(0.0,350.0),0);

	}

	UFUNCTION(BlueprintCallable)
	void Bp_MissileLaunch()
	{
		MissileLaunched.Broadcast();
	}	

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	//	AddActorWorldOffset(ActorForwardVector * Speed);
		CurrentSplineDistance += Speed * DeltaSeconds;

		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentSplineDistance);

		SetActorRotation(SplineComp.GetWorldRotationAtSplineDistance(CurrentSplineDistance));

			if(CurrentSplineDistance >= SplineComp.SplineLength)
			{
				MissileHit.Broadcast();
				AddActorDisable(this);
			}

	}
};