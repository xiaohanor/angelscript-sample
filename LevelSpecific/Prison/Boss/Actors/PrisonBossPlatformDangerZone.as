UCLASS(Abstract)
class APrisonBossPlatformDangerZone : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent DangerZoneRoot;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike OpacityTimeLike;
	default OpacityTimeLike.Duration = 3.0;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger PlayerDamageTrigger;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	float Duration = 2.5;

	FTimerHandle FadeTimerHandle;

	float CurrentDamageCooldown = 0.0;
	float DamageCooldown = 0.5;

	bool bActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OpacityTimeLike.BindUpdate(this, n"UpdateFade");
		OpacityTimeLike.BindFinished(this, n"FinishFade");
	}

	UFUNCTION()
	void ActivateDangerZone(float Dur)
	{
		Duration = Dur;
		OpacityTimeLike.PlayFromStart();

		BP_Activate();
		
		bActive = true;

		SetActorTickEnabled(true);

		UPrisonBossPlatformDangerZoneEffectEventHandler::Trigger_Activate(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activate() {}

	UFUNCTION()
	private void UpdateFade(float CurValue)
	{

	}

	UFUNCTION()
	private void FinishFade()
	{
		FadeTimerHandle = Timer::SetTimer(this, n"Explode", Duration);
	}

	UFUNCTION()
	private void Explode()
	{
		if (Game::Zoe.IsOverlappingActor(PlayerDamageTrigger))
			Game::Zoe.DamagePlayerHealth(1.0, FPlayerDeathDamageParams(FVector::UpVector, 2.0), DamageEffect, DeathEffect);

		BP_Explode();

		SetActorTickEnabled(false);

		UPrisonBossPlatformDangerZoneEffectEventHandler::Trigger_Explode(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Explode() {}

	UFUNCTION()
	void FizzleOut()
	{
		OpacityTimeLike.Stop();
		FadeTimerHandle.ClearTimerAndInvalidateHandle();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bActive)
			return;

		CurrentDamageCooldown += DeltaTime;
		if (CurrentDamageCooldown >= DamageCooldown)
		{
			if (Game::Zoe.IsOverlappingActor(PlayerDamageTrigger))
				Game::Zoe.DamagePlayerHealth(0.1, FPlayerDeathDamageParams(FVector::UpVector), DamageEffect, DeathEffect);
		}
	}
}