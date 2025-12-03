event void FSplitTraversalTurretLaserSignature();
class ASplitTraversalFloatingPlatformLaser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LaserOutputRootComp;

	UPROPERTY(DefaultComponent, Attach = LaserOutputRootComp)
	USceneComponent LaserRootComp;

	UPROPERTY()
	FHazeTimeLike LaserAppearTimeLike;
	default LaserAppearTimeLike.UseSmoothCurveZeroToOne();
	default LaserAppearTimeLike.Duration = 0.5;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDamageEffect> DamageEffect;
	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY()
	FSplitTraversalTurretLaserSignature OnPlayerDetected;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;


	bool bActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LaserAppearTimeLike.BindUpdate(this, n"LaserAppearTimeLikeUpdate");
		LaserAppearTimeLike.BindFinished(this, n"LaserAppearTimeLikeFinished");
		LaserRootComp.SetRelativeScale3D(FVector(0.0));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bActivated)
		{
			auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			Trace.IgnoreActor(this);
			auto HitResult = Trace.QueryTraceSingle(
				LaserRootComp.WorldLocation + LaserRootComp.ForwardVector * 50.0,
				LaserRootComp.WorldLocation + LaserRootComp.ForwardVector * 5000.0);

			if (HitResult.bBlockingHit)
			{
				auto Player = Cast<AHazePlayerCharacter>(HitResult.Actor);
				if (Player != nullptr)
				{
					Player.DamagePlayerHealth(1.0,FPlayerDeathDamageParams(),DamageEffect,DeathEffect);
					//PlayerDetected();
				}
			}
		}
	}

	UFUNCTION()
	void Activate()
	{
		Timer::SetTimer(this, n"DelayedActivation", Math::RandRange(0.1, 1.0));

		auto KineticMovingActor = Cast<AKineticMovingActor>(AttachParentActor);
		if (KineticMovingActor != nullptr)
			KineticMovingActor.UnpauseMovement(KineticMovingActor);

		BP_Activated();
	}

	UFUNCTION()
	private void DelayedActivation()
	{
		LaserAppearTimeLike.Play();
	}

	UFUNCTION()
	void Deactivate()
	{
		LaserAppearTimeLike.Reverse();
	}

	UFUNCTION()
	private void LaserAppearTimeLikeUpdate(float CurrentValue)
	{
		LaserRootComp.SetRelativeScale3D(FVector(1.0, 1.0, CurrentValue));
	}

	UFUNCTION()
	private void LaserAppearTimeLikeFinished()
	{
		if (LaserAppearTimeLike.IsReversed())
		{
			bActivated = false;
		}

		else
		{
			bActivated = true;
		}
	}

	private void PlayerDetected()
	{
		BP_PlayerDetected();
		OnPlayerDetected.Broadcast();
	}
	
	UFUNCTION(BlueprintEvent)
	void BP_PlayerDetected(){}

	UFUNCTION(BlueprintEvent)
	void BP_Activated(){}
};