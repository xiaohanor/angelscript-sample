class ASkylineBossChaser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Collision;
	default Collision.SphereRadius = 200.0;
	default Collision.CollisionProfileName = n"BlockAllDynamic";
	default Collision.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = Collision)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent)
	UAutoAimTargetComponent AutoAimTarget;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UBasicAIProjectileLauncherComponent ProjectileLauncherComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeFreeImpactResponseComponent ImpactResponseComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeWeaponProjectileResponseComponent ProjectileResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineBossChaserMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineBossChaserAttackCapability");

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(EditDefaultsOnly)
	USkylineBossChaserSettings DefaultSettings;

	UPROPERTY(EditAnywhere)
	FVector GravityDirection = -FVector::UpVector;

	TInstigated<AActor> CurrentTarget;

	UPROPERTY(EditAnywhere)
	FVector TargetOffset = FVector::ForwardVector * 10000.0 + FVector::RightVector * 1000.0;

	USkylineBossChaserSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = USkylineBossChaserSettings::GetSettings(this);
		{
			UMovementStandardSettings::SetWalkableSlopeAngle(this, 70.0, this, EHazeSettingsPriority::Defaults);
		}

		ApplyDefaultSettings(DefaultSettings);
	
		CurrentTarget.Apply(Game::Mio, this);

		ProjectileResponseComp.OnImpact.AddUFunction(this, n"HandleProjectileImpact");
	}

	UFUNCTION()
	private void HandleProjectileImpact(FGravityBikeWeaponImpactData ImpactData)
	{
		HealthComp.TakeDamage(0.1, EDamageType::Default, this);

		HealthBarComp.UpdateHealthBarVisibility();

		if (HealthComp.CurrentHealth <= 0.0)
			Die();
	}

	UFUNCTION()
	void Die()
	{
		USkylineBossChaserEventHandler::Trigger_Die(this);
		DestroyActor();
	}
};