class ASkylineGravityBikeBrokenBalcony : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MissileRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BalconyRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent SignRotateComp;

	UPROPERTY(DefaultComponent, Attach = SignRotateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSplineComponent MissilePathSplineComp;

	UPROPERTY()
	UNiagaraSystem ExplosionVFXSystem;

	FHazeTimeLike MissileTimeLike;
	default MissileTimeLike.UseLinearCurveZeroToOne();
	default MissileTimeLike.Duration = 1.0;

	bool bConstraintHit = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MissileTimeLike.BindUpdate(this, n"MissileTimeLikeUpdate");
		MissileTimeLike.BindFinished(this, n"MissileTimeLikeFinished");
		SignRotateComp.OnMinConstraintHit.AddUFunction(this, n"HandleConstraintHit");
	}

	UFUNCTION()
	private void HandleConstraintHit(float Strength)
	{
		if (!bConstraintHit)
		{
			USkylineGravityBikeBrokenBalconyEventHandler::Trigger_OnImpact(this);
			bConstraintHit = true;
		}
	}

	UFUNCTION()
	void ActivateMissile()
	{
		MissileTimeLike.Play();
		USkylineGravityBikeBrokenBalconyEventHandler::Trigger_OnRocketStart(this);
	}

	UFUNCTION()
	private void MissileTimeLikeUpdate(float CurrentValue)
	{
		MissileRoot.SetWorldLocationAndRotation(MissilePathSplineComp.GetWorldLocationAtSplineFraction(CurrentValue),
													MissilePathSplineComp.GetWorldRotationAtSplineDistance(MissilePathSplineComp.SplineLength * CurrentValue));
	}
	
	UFUNCTION()
	private void MissileTimeLikeFinished()
	{
		ForceComp.Force = FVector::ForwardVector * -800.0;

		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFXSystem, MissileRoot.WorldLocation);

		MissileRoot.SetHiddenInGame(true, true);
		BalconyRoot.SetHiddenInGame(true, true);

		USkylineGravityBikeBrokenBalconyEventHandler::Trigger_OnRocketExplode(this);
		USkylineGravityBikeBrokenBalconyEventHandler::Trigger_OnStartFalling(this);
	}
};

UCLASS(Abstract)
class USkylineGravityBikeBrokenBalconyEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartFalling() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRocketStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRocketExplode() {}
};
