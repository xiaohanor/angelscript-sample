UCLASS(Abstract)
class AOilRigTransportShipProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ProjectileRoot;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect FF_Impact;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> ImpactCamShake;

	UPROPERTY(EditAnywhere)
	float DestroyDelay = 1.0;

	UPROPERTY(EditAnywhere)
	float LaunchDelay = 1.0;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	bool bActive = false;

	float Speed = 8000.0;

	UPROPERTY(BlueprintReadOnly)
	FVector RelativeTargetLocation;

	bool bDestroyed = false;

	void StartTargeting(FVector TargetLoc)
	{
		RelativeTargetLocation = ActorTransform.InverseTransformPosition(TargetLoc);
		BP_StartTargeting();

		Timer::SetTimer(this, n"Launch", LaunchDelay);

		UOilRigTransportShipProjectileEffectEventHandler::Trigger_StartTargeting(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartTargeting() {}

	UFUNCTION()
	void Launch()
	{
		bActive = true;

		UOilRigTransportShipProjectileEffectEventHandler::Trigger_Launch(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bActive)
			return;

		if (bDestroyed)
			return;
		
		float Height = Math::FInterpConstantTo(ProjectileRoot.RelativeLocation.Z, -12000.0, DeltaTime, Speed);
		ProjectileRoot.SetRelativeLocation(FVector(0.0, 0.0, Height));
		
		if (Math::IsNearlyEqual(Height, -12000.0, 5.0))
			Explode();
	}

	void Explode()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (!Player.IsPlayerInvulnerable() && Player.ActorLocation.Distance(ProjectileRoot.WorldLocation) <= 120.0)
			{
				FVector Dir = (Player.ActorLocation - ProjectileRoot.WorldLocation).GetSafeNormal().ConstrainToPlane(FVector::UpVector);
				Player.DamagePlayerHealth(0.5, FPlayerDeathDamageParams(Dir, 20.0), DamageEffect, DeathEffect);
				Player.ApplyKnockdown(Dir * 300.0, 1.0);
			}

			Player.PlayWorldCameraShake(ImpactCamShake, this, ProjectileRoot.WorldLocation, 300.0, 500.0);
		}

		ForceFeedback::PlayWorldForceFeedback(FF_Impact, ProjectileRoot.WorldLocation, true, this, 300.0, 200.0);

		FauxPhysics::ApplyFauxImpulseToActorAt(AttachParentActor, ProjectileRoot.WorldLocation, FVector::UpVector * 175.0);

		BP_Explode();

		bDestroyed = true;
		Timer::SetTimer(this, n"ActuallyDestroy", DestroyDelay);

		UOilRigTransportShipProjectileEffectEventHandler::Trigger_Explode(this);
	}

	UFUNCTION()
	void ActuallyDestroy()
	{
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Explode() {}
}

class UOilRigTransportShipProjectileEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void StartTargeting() {}
	UFUNCTION(BlueprintEvent)
	void Launch() {}
	UFUNCTION(BlueprintEvent)
	void Explode() {}
}