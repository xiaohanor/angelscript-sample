event void FBridgeSegmentBlownUp();
class ASkylineInnerCityExplodingBridgeSegment : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent ImpactTargetPivot;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditAnywhere)
	ASkylineInnerCityExplodingDestroyedBridgeSegment BrokenBridgeActor;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem ExplosionVFX;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike Animation;
	default Animation.Duration = 1.0;
	default Animation.bCurveUseNormalizedTime = true;
	default Animation.Curve.AddDefaultKey(0.0, 0.0);
	default Animation.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	float ActivationDelay = 0.0;

	UPROPERTY(EditAnywhere)
	float ProjectileTimeToImpact = 3.0;

	UPROPERTY()
	FBridgeSegmentBlownUp OnSegmentBlownUp;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AActor> ProjectileClass;

	UPROPERTY(EditAnywhere)
	APlayerTrigger PlayerTrigger;

	UPROPERTY(DefaultComponent)
	UArrowComponent LaunchDirection;

	UPROPERTY(EditAnywhere)
	float ProjectileSpinRadius = 300.0;

	UPROPERTY(EditAnywhere)
	float ProjectileSpinSpeed = 360.0;

	UPROPERTY(EditAnywhere)
	ASkylineAttackShip AttackShip;

	bool bActivated = false;

	AActor Projectile;

	UPROPERTY(EditAnywhere)
	ASkylineInnerCityExplodingBridgeDoor BridgeDoor;

	UPROPERTY(EditAnywhere)
	bool bShouldKnockdown = false;

	

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");

		Animation.BindUpdate(this, n"OnAnimationUpdate");
		Animation.BindFinished(this, n"OnAnimationFinished");
	
		Animation.PlayRate = 1.0 / ProjectileTimeToImpact;
	
		if (PlayerTrigger != nullptr)
			PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		Activate();
	}

	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
		Activate();
	}

	UFUNCTION()
	void OnAnimationUpdate(float Value)
	{
		FVector StartLocation = Projectile.ActorLocation;

		float Distance = Spline.SplineLength * (1.0 - Value);
		auto SplinePosition = Spline.GetSplinePositionAtSplineDistance(Distance);
		SplinePosition.ReverseFacing();
	
		FVector Offset = SplinePosition.WorldTransformNoScale.TransformVectorNoScale((FVector::RightVector * ProjectileSpinRadius).RotateAngleAxis(ProjectileSpinSpeed * Projectile.GameTimeSinceCreation, FVector::ForwardVector));

		FVector ProjectileLocation = SplinePosition.WorldLocation + Offset;
		FQuat ProjectileRotation = (ProjectileLocation - StartLocation).ToOrientationQuat();

		Projectile.SetActorLocationAndRotation(ProjectileLocation, ProjectileRotation);
	}

	UFUNCTION()
	void OnAnimationFinished()
	{
		Explode();
		
	}

	UFUNCTION(DevFunction)
	void DevActivateGlassSegmentDestruction()
	{
		Activate();
	}

	UFUNCTION()
	void Activate()
	{
		if (bActivated)
			return;

		Timer::SetTimer(this, n"ActivateInternal", ActivationDelay + KINDA_SMALL_NUMBER);

		bActivated = true;
	}

	UFUNCTION()
	private void ActivateInternal()
	{
		if (AttackShip != nullptr)
			AttackShip.LaunchMissileAtTarget(this);
/*
		auto SplinePosition = Spline.GetSplinePositionAtSplineDistance(Spline.SplineLength);
		FTransform SpawnTransform = SplinePosition.WorldTransformNoScale;
		Projectile = SpawnActor(ProjectileClass, SpawnTransform.Location, SpawnTransform.Rotator());
	
		Animation.Play();
*/
	}

	UFUNCTION()
	void Explode()
	{
		BP_Explode();

		if (Projectile != nullptr)
			Projectile.DestroyActor();

		FVector Origin = ActorLocation;

		for (auto Player : Game::Players)
		{
			if(Player.GetDistanceTo(this) < 2400.0 && bShouldKnockdown)
			{
				if(Player.IsInAir())
				{
					Player.ApplyKnockdown(LaunchDirection.ForwardVector * 1300, 1.5);
				}else
				Player.ApplyKnockdown(LaunchDirection.ForwardVector * 3300, 1.5);		

				Player.DamagePlayerHealth(0.1);		
			}	

			if(Player.GetDistanceTo(this) < 800 && !bShouldKnockdown)
				Player.DamagePlayerHealth(0.1);
		}
		
		PrintToScreenScaled("Distance: " + Game::Mio.GetDistanceTo(this), 10, FLinearColor::DPink, 5.0);
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFX, Origin, ActorRotation, ActorScale3D);

		if(BridgeDoor!=nullptr)
		{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFX, BridgeDoor.ActorLocation, BridgeDoor.ActorRotation, ActorScale3D);
			BridgeDoor.AddActorDisable(this);
		}

		BrokenBridgeActor.PlayExplodeBridge();
		OnSegmentBlownUp.Broadcast();
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Explode()
	{

	}
}