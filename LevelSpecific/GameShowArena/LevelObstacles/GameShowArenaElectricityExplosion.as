class AGameShowArenaElectricityExplosion : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ExplosionVFX;
	default ExplosionVFX.bAutoActivate = false;

	UPROPERTY(EditInstanceOnly)
	TArray<AGameShowArenaPlatformArm> Platforms;

	UPROPERTY(EditAnywhere)
	bool bIsAlternateDecal;

	UPROPERTY()
	UTexture2D DecalTexture;
	UPROPERTY()
	FLinearColor DecalTint;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ExplosionCameraShake;

	UPROPERTY()
	TSubclassOf<UDeathEffect> ElectricityExplosionDeathEffect;

	bool bShouldTickChargeUpTimer = false;
	float ChargeUpTimer = 0;
	UPROPERTY(BlueprintReadOnly)
	float ChargeUpTimerDuration = 2.0;

	bool bShouldTickCoolDownTimer = false;
	float CoolDownTimer = 0;
	UPROPERTY(BlueprintReadOnly)
	float CoolDownTimerDuration = 0.5;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	TArray<UGameShowArenaDisplayDecalPlatformComponent> PlatformDecalComps;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto Platform : Platforms)
		{
			auto Comp = UGameShowArenaDisplayDecalPlatformComponent::GetOrCreate(Platform);
			if (Comp != nullptr)
			{
				Comp.AssignTarget(Platform.PlatformMesh, Platform.PanelMaterial);
				PlatformDecalComps.Add(Comp);
			}
		}
	}
	UFUNCTION()
	void ActivateElectricityExplosion()
	{
		SetActorTickEnabled(true);
		StartChargeUp();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FGameShowArenaDisplayDecalParams Params;

		if (bShouldTickChargeUpTimer)
		{
			ChargeUpTimer += DeltaSeconds;
			Params.DecalWorldTransform.Scale3D = FVector::OneVector * Math::Lerp(0, 150, ChargeUpTimer / ChargeUpTimerDuration);

			if (ChargeUpTimer >= ChargeUpTimerDuration)
			{
				bShouldTickChargeUpTimer = false;
				StartCoolDown();
				Explode();
			}
			//float Alpha = Math::CircularIn(0, 1, Math::Saturate(ChargeUpTimer / ChargeUpTimerDuration));
			//float Pulse = Math::MakePulsatingValue(ChargeUpTimer, Alpha * 3);
			//Params.Opacity = Math::Lerp(0, 80, Pulse);
			if (ChargeUpTimer > 0.6 * ChargeUpTimerDuration)
			{
				Params.Opacity = 80;
			}
			else if (ChargeUpTimer > 0.3 * ChargeUpTimerDuration)
			{
				Params.Opacity = 30;
			}
			else
			{
				Params.Opacity = 5;
			}
			Params.DecalWorldTransform.Scale3D = FVector::OneVector * 150;
		}

		if (bShouldTickCoolDownTimer)
		{
			CoolDownTimer += DeltaSeconds;
			Params.DecalWorldTransform.Scale3D = FVector::OneVector * 150;

			if (CoolDownTimer >= CoolDownTimerDuration)
			{
				bShouldTickCoolDownTimer = false;
				StartChargeUp();
			}
			Params.Opacity = 0.2;
		}

		for (auto DecalComp : PlatformDecalComps)
		{
			if (!DecalComp.CanUpdateParams())
				continue;

			Params.Texture = DecalTexture;
			//Params.DecalWorldTransform.Scale3D = FVector::OneVector * 175;
			FVector ForwardOffset = -DecalComp.GetMeshComponent().ForwardVector * 15;
			FVector RightOffset = -DecalComp.GetMeshComponent().RightVector * 15;

			Params.DecalWorldTransform.Location = DecalComp.GetMeshComponent().WorldLocation + ForwardOffset + RightOffset;
			Params.DecalWorldTransform.SetRotation(DecalComp.GetMeshComponent().WorldRotation);
			Params.Tint = DecalTint;
			DecalComp.UpdateMaterialParameters(Params, bIsAlternateDecal);
		}
	}

	void StartChargeUp()
	{
		ChargeUpTimer = 0;
		bShouldTickChargeUpTimer = true;
		BP_OnChargeUp(ChargeUpTimerDuration);
	}

	void StartCoolDown()
	{
		CoolDownTimer = 0;
		bShouldTickCoolDownTimer = true;
	}

	void Explode()
	{
		ExplosionVFX.Activate(true);
		BP_OnExplode();

		for (auto Player : Game::Players)
		{
			Player.PlayWorldCameraShake(ExplosionCameraShake, this, ActorLocation, 800.0, 5000.0);

			if (BoxCollision.IsOverlappingActor(Player))
				Player.KillPlayer(FPlayerDeathDamageParams(), ElectricityExplosionDeathEffect);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnChargeUp(float ChargeUpTime)
	{}

	UFUNCTION(BlueprintEvent)
	void BP_OnExplode()
	{}
};