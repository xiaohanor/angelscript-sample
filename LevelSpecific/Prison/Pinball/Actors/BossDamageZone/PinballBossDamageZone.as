event void FPinballBossDamageZoneOnDestroyed();

UCLASS(Abstract)
class APinballBossDamageZone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.Mobility = EComponentMobility::Static;

	UPROPERTY(DefaultComponent)
	USphereComponent BossTriggerComp;
	default BossTriggerComp.Mobility = EComponentMobility::Static;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent PlayerTriggerComp;
	default PlayerTriggerComp.Mobility = EComponentMobility::Static;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;
	default MeshRoot.Mobility = EComponentMobility::Movable;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 5000;

	UPROPERTY(EditAnywhere, Meta = (ClampMin = "1", ClampMax = "3"))
	int Charges = 3;

	UPROPERTY(EditAnywhere)
	bool bResetVelocity = false;

	UPROPERTY(EditAnywhere)
	FVector ImpulseDirection = FVector(0, 0, -2000.0);

	UPROPERTY(EditAnywhere)
	float RotateSpeed = 360;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve DisableMoveAlphaCurve;
	default DisableMoveAlphaCurve.AddDefaultKey(0.0, 0.0);
	default DisableMoveAlphaCurve.AddDefaultKey(3.0, 1.0);

	UPROPERTY()
	FPinballBossDamageZoneOnDestroyed OnDamageZoneDestroyed;

	bool bCanApplyDamage = true;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BossTriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"OnBossTriggerEntered");
		PlayerTriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"OnPlayerTriggerEntered");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Just keep rotating forever
		MeshRoot.SetRelativeRotation(FRotator(0, 0, Time::GameTimeSeconds * RotateSpeed));
	}

	UFUNCTION()
	private void OnBossTriggerEntered(
		UPrimitiveComponent OverlappedComponent,
		AActor OtherActor,
	    UPrimitiveComponent OtherComp,
		int OtherBodyIndex,
		bool bFromSweep,
	    const FHitResult&in SweepResult
	)
	{
		auto BossBall = Cast<APinballBossBall>(OtherActor);
		if(BossBall == nullptr)
			return;

		if(!BossBall.HasControl())
			return;

		if(!bCanApplyDamage)
			return;

		NetDamageBossBall(BossBall);
	}

	UFUNCTION(NetFunction)
	private void NetDamageBossBall(APinballBossBall BossBall)
	{
		bCanApplyDamage = false;

		bool bBreakBar = false;
		BossBall.DamageBoss(ActorLocation, ImpulseDirection, bResetVelocity, bBreakBar);

		UPinballBossDamageZoneEventHandler::Trigger_OnDamageBoss(this);

		Charges--;

		if(Charges <= 0)
		{
			Explode();
		}
		else
		{
			Timer::SetTimer(this, n"ResetAfterDelay", 0.2);
		}
	}

	UFUNCTION()
	private void ResetAfterDelay()
	{
		bCanApplyDamage = true;
		UPinballBossDamageZoneEventHandler::Trigger_OnResetAfterDamageBoss(this);
	}

	UFUNCTION()
	private void OnPlayerTriggerEntered(
		UPrimitiveComponent OverlappedComponent,
		AActor OtherActor,
	    UPrimitiveComponent OtherComp,
		int OtherBodyIndex,
	    bool bFromSweep,
		const FHitResult&in SweepResult
	)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		if(!Player.HasControl())
			return;

		NetKillPlayer(Player);
	}

	UFUNCTION(NetFunction)
	private void NetKillPlayer(AHazePlayerCharacter Player)
	{
		Player.KillPlayer();
		UPinballBossDamageZoneEventHandler::Trigger_OnKillPlayer(this);
	}

	private void Explode()
	{
		OnDamageZoneDestroyed.Broadcast();
		UPinballBossDamageZoneEventHandler::Trigger_OnDestroyed(this);

		AddActorDisable(this);
	}
};
