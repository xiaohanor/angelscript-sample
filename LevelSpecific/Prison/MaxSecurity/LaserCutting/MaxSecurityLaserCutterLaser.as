UCLASS(Abstract)
class AMaxSecurityLaserCutterLaser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LaserRoot;
	default LaserRoot.RelativeRotation = FRotator(-35.0, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = LaserRoot)
	UNiagaraComponent LaserEffectComp;

	UPROPERTY(BlueprintReadWrite)
	UNiagaraComponent LaserImpactComp;

	AHazeTargetPoint ImpactEffectAttachActor;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem ImpactEffect;

	float LaserLength = 50.0;
	float Pitch = -35.0;

	bool bImpactEffectActive = false;

	bool bActive = true;

	float BeamWidth = 20.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactEffectAttachActor = SpawnActor(AHazeTargetPoint, ActorLocation);
		ImpactEffectAttachActor.SetActorHiddenInGame(false);

		LaserEffectComp.SetFloatParameter(n"Width", BeamWidth);
	}

	void ActivateLaser()
	{
		if (bActive)
			return;

		BP_ResetLaser();

		bImpactEffectActive = false;
		LaserLength = 50.0;
		Pitch = -60.0;
		BeamWidth = 20.0;
		LaserRoot.SetRelativeRotation(FRotator(-60.0, 0.0, 0.0));
		LaserEffectComp.SetFloatParameter(n"Width", BeamWidth);
		LaserEffectComp.SetVectorParameter(n"BeamStart", LaserRoot.WorldLocation);
		LaserEffectComp.SetVectorParameter(n"BeamEnd", LaserRoot.WorldLocation + (LaserRoot.ForwardVector * (LaserLength + 50.0)));
		
		LaserEffectComp.Activate(true);
		RemoveActorDisable(this);

		bActive = true;
	}

	UFUNCTION(BlueprintEvent)
	void BP_ResetLaser() {}

	void DeactivateLaser()
	{
		if (!bActive)
			return;

		bActive = false;
		LaserEffectComp.DeactivateImmediately();
		DeactivateImpactEffect();
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Math::IsNearlyEqual(Pitch, -90.0))
		{
			BeamWidth = Math::FInterpConstantTo(BeamWidth, 250.0, DeltaTime, 250.0);
			// LaserEffectComp.SetFloatParameter(n"Width", BeamWidth);
		}

		LaserEffectComp.SetVectorParameter(n"BeamStart", LaserRoot.WorldLocation);

		LaserRoot.SetRelativeRotation(FRotator(Pitch, LaserRoot.RelativeRotation.Yaw, 0.0));

		FVector LaserImpactPoint;

		if (bActive)
		{
			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			Trace.IgnorePlayers();
			Trace.UseLine();

			FHitResult Hit = Trace.QueryTraceSingle(LaserRoot.WorldLocation, LaserRoot.WorldLocation + (LaserRoot.ForwardVector * (LaserLength + 50.0)));
			if (Hit.bBlockingHit)
			{
				ActivateImpactEffect();
				LaserImpactComp.SetWorldLocation(Hit.ImpactPoint);
				LaserImpactComp.SetWorldRotation(FRotator(90.0, 0.0, 0.0));
			}
			else
			{
				DeactivateImpactEffect();
			}

			LaserImpactPoint = Hit.bBlockingHit ? Hit.ImpactPoint : Hit.TraceEnd;
		}

		if (!bActive)
			LaserImpactPoint =  LaserRoot.WorldLocation + (LaserRoot.ForwardVector * (LaserLength + 50.0));

		LaserEffectComp.SetVectorParameter(n"BeamEnd", LaserImpactPoint);
	}

	void ActivateImpactEffect()
	{
		if (bImpactEffectActive)
			return;

		bImpactEffectActive = true;
		LaserImpactComp = Niagara::SpawnLoopingNiagaraSystemAttached(ImpactEffect, ImpactEffectAttachActor.RootComponent);
	}

	void DeactivateImpactEffect()
	{
		if (!bImpactEffectActive)
			return;

		bImpactEffectActive = false;
		LaserImpactComp.Deactivate();
	}

	void ActivateAsMainLaser()
	{
		BP_ActivateAsMainLaser();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateAsMainLaser() {}

	void DeactivateAsMainLaser()
	{
		BP_DeactivateAsMainLaser();
	}

	UFUNCTION(BlueprintEvent)
	void BP_DeactivateAsMainLaser() {}
}