class ASkylineBallBossThrowableMotorcycleAOE : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeDecalComponent DecalComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FireVFXComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY()
	float Lifetime = 9.0;

	UPROPERTY()
	float Radius = 500.0;

	UPROPERTY()
	float Damage = 0.1;

	UPROPERTY()
	float DamageCooldown = 0.2;

	UPROPERTY()
	UMaterialInterface DecalMaterial;

	UMaterialInstanceDynamic DecalMID;

	UPROPERTY()
	float GlowSmoothStep = 0.24;

	UPROPERTY()
	float SootSmoothStep = 0.1;

	UPROPERTY()
	float SootAdditionalLifetime = 3.0;

	UPROPERTY()
	FHazeTimeLike GlowFadeOutTimeLike;
	default GlowFadeOutTimeLike.UseLinearCurveZeroToOne();
	default GlowFadeOutTimeLike.Duration = 1.0;

	UPROPERTY()
	FHazeTimeLike SootFadeOutTimeLike;
	default SootFadeOutTimeLike.UseLinearCurveZeroToOne();
	default SootFadeOutTimeLike.Duration = 2.0;

	TPerPlayer<float> DamageTimeStamp;
	TPerPlayer<UPlayerMovementComponent> MoveComp;

	bool bDangerous = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto Player : Game::GetPlayers())
		{
			MoveComp[Player] = UPlayerMovementComponent::Get(Player);
		}
	
		DecalMID = Material::CreateDynamicMaterialInstance(this, DecalMaterial);
		DecalMID.SetScalarParameterValue(n"EMISSIVE_Smoothstep", GlowSmoothStep);
		DecalMID.SetScalarParameterValue(n"OPACITY_Smoothstep", SootSmoothStep);
		DecalComp.SetDecalMaterial(DecalMID);
		
		GlowFadeOutTimeLike.BindUpdate(this, n"GlowFadeOutTimeLikeUpdate");
		SootFadeOutTimeLike.BindUpdate(this, n"SootFadeOutTimeLikeUpdate");
		SootFadeOutTimeLike.BindFinished(this, n"SootFadeOutTimeLikeFinished");

		Timer::SetTimer(this, n"DisableFire", Lifetime);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (auto Player : Game::GetPlayers())
		{
			if (MoveComp[Player].HasGroundContact() && 
				Player.ActorLocation.Distance(ActorLocation) < Radius &&
				bDangerous)
			{
				DamagePlayer(Player);	
			}
		}
	}

	UFUNCTION()
	private void DisableFire()
	{
		bDangerous = false;
		FireVFXComp.Deactivate();
		GlowFadeOutTimeLike.Play();
		Timer::SetTimer(this, n"DisableSoot", SootAdditionalLifetime);
	}

	UFUNCTION()
	private void DisableSoot()
	{
		SootFadeOutTimeLike.Play();
	}

	UFUNCTION()
	private void GlowFadeOutTimeLikeUpdate(float CurrentValue)
	{
		DecalMID.SetScalarParameterValue(n"EMISSIVE_Smoothstep", Math::Lerp(GlowSmoothStep, 1.0, CurrentValue));
	}

	UFUNCTION()
	private void SootFadeOutTimeLikeUpdate(float CurrentValue)
	{
		DecalMID.SetScalarParameterValue(n"OPACITY_Smoothstep", Math::Lerp(SootSmoothStep, 1.0, CurrentValue));
	}

	UFUNCTION()
	private void SootFadeOutTimeLikeFinished()
	{
		DestroyActor();
	}

	private void DamagePlayer(AHazePlayerCharacter Player)
	{
		if (DamageTimeStamp[Player] + DamageCooldown < Time::GameTimeSeconds)
		{
			DamageTimeStamp[Player] = Time::GameTimeSeconds;
			Player.DamagePlayerHealth(Damage, FPlayerDeathDamageParams(FVector::UpVector), DamageEffect, DeathEffect);
		}
	}
};