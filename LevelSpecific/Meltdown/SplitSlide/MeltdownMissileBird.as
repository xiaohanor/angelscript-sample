event void FSplitSlideMissileExplodeSignature();

class AMeltdownMissileBird : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UHazeSplineComponent SplineComp;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent BirdRoot;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent MissileRoot;

	UPROPERTY()
	UNiagaraSystem ExplosionSystem;

	UPROPERTY(EditAnywhere)
	UCurveFloat ProgressCurve;

	UPROPERTY(EditInstanceOnly)
	AHazeActor ProgressSplineActor;
	UHazeSplineComponent ProgressSplineComp;
	float SplineProgress = 0.0;

	UPROPERTY()
	FSplitSlideMissileExplodeSignature OnMissileExploded;

	FHazeAcceleratedTransform AcceleratedTransform;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if (ProgressSplineActor != nullptr)
			ProgressSplineComp = UHazeSplineComponent::Get(ProgressSplineActor);

		AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float BackmostSplineProgress = 0.0;
		bool bValidProgress = false;

		for (auto Player : Game::Players)
		{
			if (!Player.IsPlayerDead())
			{
				float ClosestSplineDistance = ProgressSplineComp.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);

				if (!bValidProgress || BackmostSplineProgress < ClosestSplineDistance)
				{
					BackmostSplineProgress = ClosestSplineDistance;
				}

				bValidProgress = true;
			}
		}

		if (bValidProgress)
			SplineProgress = BackmostSplineProgress / ProgressSplineComp.SplineLength;

		float SplineAlpha = ProgressCurve.GetFloatValue(SplineProgress);
		AcceleratedTransform.AccelerateTo(SplineComp.GetWorldTransformAtSplineFraction(SplineAlpha), 1.0, DeltaSeconds);

		MissileRoot.SetWorldLocationAndRotation(AcceleratedTransform.Value.Location, AcceleratedTransform.Value.Rotation);
		BirdRoot.SetRelativeLocationAndRotation(MissileRoot.RelativeLocation, MissileRoot.RelativeRotation);
		
		if (SplineAlpha >= 1.0)
			ExplodeMissile();
	}

	UFUNCTION()
	void Activate()
	{
		if (ProgressSplineComp == nullptr)
			return;

		RemoveActorDisable(this);
		AcceleratedTransform.SnapTo(SplineComp.GetWorldTransformAtSplineFraction(0.0));
	}
	
	private void ExplodeMissile()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionSystem, SplineComp.GetWorldLocationAtSplineFraction(1.0));
		OnMissileExploded.Broadcast();
		BP_ExplodeMissile();
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_ExplodeMissile(){}
};