event void FOnLavaMomDied();

class ASanctuaryLavaMom : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent AppearOffset;
	default AppearOffset.RelativeLocation = FVector(0.0, 0.0, -1000.0);

	UPROPERTY(DefaultComponent, Attach = AppearOffset)
	UHazeSkeletalMeshComponentBase SkeletalMesh;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UBasicAIHealthComponent HealthComp;

	UPROPERTY(DefaultComponent, Attach = AppearOffset)
	UCapsuleComponent CapsuleOverlap;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(LavaMomActionSelectionSheet);

	UPROPERTY(DefaultComponent)
	USanctuaryLavaMomMultiBoulderLauncherComponent MultiBoulderLauncher;

	UPROPERTY(DefaultComponent)
	UCentipedeProjectileResponseComponent CentipedeProjectileResponseComp;

	UPROPERTY(DefaultComponent)
	UCentipedeProjectileTargetableComponent CentipedeProjectileTargetableComponent;

	USanctuaryLavaMomSettings Settings;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBar;

	UPROPERTY(DefaultComponent)
	USanctuaryLavaApplierComponent LavaComp;
	default LavaComp.DamagePerSecond = 3.0;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike AppearTimelike;
	default AppearTimelike.UseSmoothCurveZeroToOne();
	default AppearTimelike.Duration = 2.0;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance NormalMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance FrozenMaterial;

	UPROPERTY(EditAnywhere)
	FOnLavaMomDied OnDied;

	float LastFreezeTimestamp = 0.0;

	bool bAttacking = false;

	UFUNCTION(BlueprintOverride)
	FVector GetFocusLocation() const
	{
		return ActorLocation + ActorUpVector * 500;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CentipedeProjectileResponseComp.OnImpact.AddUFunction(this, n"OnHit");
		AppearTimelike.BindUpdate(this, n"AppearUpdate");
		AppearTimelike.BindFinished(this, n"StartAttacks");
		Settings = USanctuaryLavaMomSettings::GetSettings(this);
	}

	UFUNCTION()
	private void AppearUpdate(float CurrentValue)
	{
		float HeightOffset = Math::Clamp(1.0 - CurrentValue, 0.0, 1.0);
		AppearOffset.SetRelativeLocation(FVector(0.0, 0.0, - HeightOffset * 1000.0));
	}

	UFUNCTION(BlueprintCallable)
	void LavaMomAppear()
	{
		AppearTimelike.PlayFromStart();
	}

	UFUNCTION()
	private void StartAttacks()
	{
		// hackiest fulfix to make HP visible hehe :)
		HealthComp.TakeDamage(KINDA_SMALL_NUMBER, EDamageType::Default, this); 
		bAttacking = true;
	}

	UFUNCTION(DevFunction)
	private void TestDeath()
	{
		HealthComp.TakeDamage(1.0, EDamageType::Default, this);
		BP_OnFreezeHit();
		USanctuaryLavaMomEventHandler::Trigger_OnDeath(this);
		BP_OnDied();
		OnDied.Broadcast();
		Timer::SetTimer(this, n"DelayedDestroy", 0.5);
	}

	void Freeze()
	{
		if (LastFreezeTimestamp + 2.0 < Time::GameTimeSeconds)
		{
			LastFreezeTimestamp = Time::GameTimeSeconds;
			HealthComp.TakeDamage(1.0 / 3.0, EDamageType::Default, this);
			BP_OnFreezeHit();
			if (HealthComp.CurrentHealth <= KINDA_SMALL_NUMBER)
			{
				USanctuaryLavaMomEventHandler::Trigger_OnDeath(this);
				OnDied.Broadcast();
				Timer::SetTimer(this, n"DelayedDestroy", 0.5);
			}
		}
	}

	UFUNCTION()
	private void OnHit(FVector ImpactDirection, float Force)
	{
		HealthComp.TakeDamage(Settings.CentipedeProjectileDamage, EDamageType::Default, this);
		BP_OnFreezeHit();
		if (HealthComp.CurrentHealth <= KINDA_SMALL_NUMBER)
		{
			USanctuaryLavaMomEventHandler::Trigger_OnDeath(this);
			BP_OnDied();
			OnDied.Broadcast();
			Timer::SetTimer(this, n"DelayedDestroy", 0.5);
		}
	}
	
	UFUNCTION()
	private void DelayedDestroy()
	{
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	protected void BP_OnFreezeHit() {}

	UFUNCTION(BlueprintEvent)
	protected void BP_OnDied() {}
};