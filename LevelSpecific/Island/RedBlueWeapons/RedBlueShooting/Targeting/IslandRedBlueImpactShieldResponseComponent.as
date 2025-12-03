event void FIslandRedBlueImpactShieldResponseSignature(FIslandRedBlueImpactShieldResponseParams Data);

struct FIslandRedBlueImpactShieldResponseParams
{
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(BlueprintReadOnly)
	UIslandRedBlueImpactShieldResponseComponent Component;

	UPROPERTY(BlueprintReadOnly)
	FVector ImpactLocation;

	UPROPERTY()
	float ImpactDamageMultiplier;
}

class UIslandRedBlueImpactShieldResponseComponentSettings : UDataAsset
{
	UPROPERTY()
	EIslandRedBlueShieldType ShieldType;

	UPROPERTY(Meta = (ClampMin = "0.0", ClampMax = "1.0"))
	float ShieldAlphaToDeductEachImpact;

	UPROPERTY(Meta = (ClampMin = "0.0"))
	float ShieldRegenerationDelay;

	UPROPERTY(Meta = (ClampMin = "0.0"))
	float ShieldRegenerationSpeed;

	UPROPERTY()
	bool bAddShieldAlphaOnWrongColor = true;
}

struct FIslandRedBlueImpactShieldResponseInternalData
{
	UHazeCrumbSyncedFloatComponent SyncedAlpha;
	float TimeOfLastShieldImpact = -1.0;

	float GetShieldAlpha() const property
	{
		return SyncedAlpha.Value;
	}

	void SetShieldAlpha(float Value) property
	{
		SyncedAlpha.Value = Value;
	}
}

class UIslandRedBlueImpactShieldResponseComponent : UIslandRedBlueImpactResponseComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditAnywhere, Category = "Red Blue Settings")
	UIslandRedBlueImpactShieldResponseComponentSettings Settings;

	UPROPERTY(EditAnywhere, Category = "Red Blue Settings")
	AIslandRedBlueImpactOverchargeResponseDisplay OptionalDisplay;

	/* Called when a bullet impacts and the shield is destroyed */
	UPROPERTY(Category = "Events")
	FIslandRedBlueImpactShieldResponseSignature OnImpactWhenShieldDestroyed;

	/* Called when a bullet impacts and the shield is still up */
	UPROPERTY(Category = "Events")
	FIslandRedBlueImpactShieldResponseSignature OnImpactOnShield;

	private TPerPlayer<FIslandRedBlueImpactShieldResponseInternalData> PlayerData;

	UHazeCrumbSyncedFloatComponent MioSyncedAlpha;
	UHazeCrumbSyncedFloatComponent ZoeSyncedAlpha;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		if(OptionalDisplay != nullptr)
		{
			OptionalDisplay.Display.SetColor(Settings.ShieldType);
		}

		MioSyncedAlpha = UHazeCrumbSyncedFloatComponent::Create(Owner, FName(Name + "_MioSyncedAlpha"));
		MioSyncedAlpha.Value = 1.0;

		ZoeSyncedAlpha = UHazeCrumbSyncedFloatComponent::Create(Owner, FName(Name + "_ZoeSyncedAlpha"));
		ZoeSyncedAlpha.Value = 1.0;

		PlayerData[Game::Mio].SyncedAlpha = MioSyncedAlpha;
		PlayerData[Game::Zoe].SyncedAlpha = ZoeSyncedAlpha;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime) final
	{
		bool bAnyShieldAlphaActive = false;
		for(auto& Data : PlayerData)
		{
			if(Data.ShieldAlpha == 1.0)
				continue;

			bAnyShieldAlphaActive = true;

			if(HasControl())
			{
				if(Time::GetGameTimeSince(Data.TimeOfLastShieldImpact) > Settings.ShieldRegenerationDelay)
				{
					Data.ShieldAlpha = Data.ShieldAlpha + Settings.ShieldRegenerationSpeed * DeltaTime;
					Data.ShieldAlpha = Math::Clamp(Data.ShieldAlpha, 0.0, 1.0);
				}
			}
		}

		if(OptionalDisplay != nullptr)
		{
			OptionalDisplay.Display.SetFillPercentage(1.0 - GetShieldAlpha());
		}

		if (!bAnyShieldAlphaActive)
			SetComponentTickEnabled(false);
	}

	void OnImpact(AHazePlayerCharacter ImpactInstigator, FHitResult HitResult, float DamageMultiplier) override final
	{
		Super::OnImpact(ImpactInstigator, HitResult, DamageMultiplier);
		SetComponentTickEnabled(true);

		if(!HasControl())
			return;

		if(IslandRedBlueWeapon::PlayerCanHitShieldType(ImpactInstigator, ShieldType))
		{
			auto& Data = PlayerData[ImpactInstigator];

			Data.ShieldAlpha = Math::Max(Data.ShieldAlpha - Settings.ShieldAlphaToDeductEachImpact * DamageMultiplier, 0.0);
			Data.TimeOfLastShieldImpact = Time::GetGameTimeSeconds();
		}
		else if(Settings.bAddShieldAlphaOnWrongColor && ShieldAlpha > KINDA_SMALL_NUMBER)
		{
			auto& Data = PlayerData[ImpactInstigator.OtherPlayer];

			Data.ShieldAlpha = Math::Min(Data.ShieldAlpha + Settings.ShieldAlphaToDeductEachImpact * DamageMultiplier, 1.0);
		}

		FIslandRedBlueImpactShieldResponseParams Params;
		Params.Component = this;
		Params.ImpactLocation = HitResult.ImpactPoint;
		Params.Player = ImpactInstigator;
		Params.ImpactDamageMultiplier = DamageMultiplier;

		if(ShieldAlpha < KINDA_SMALL_NUMBER)
			CrumbOnImpactWhenShieldDestroyed(Params);
		else
			CrumbOnImpactOnShield(Params);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnImpactWhenShieldDestroyed(FIslandRedBlueImpactShieldResponseParams Params)
	{
		SetComponentTickEnabled(true);
		OnImpactWhenShieldDestroyed.Broadcast(Params);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnImpactOnShield(FIslandRedBlueImpactShieldResponseParams Params)
	{
		SetComponentTickEnabled(true);
		OnImpactOnShield.Broadcast(Params);
	}

	UFUNCTION(BlueprintPure)
	float GetShieldAlpha() const property
	{
		float RedAlpha = PlayerData[IslandRedBlueWeapon::GetPlayerForColor(EIslandRedBlueWeaponType::Red)].ShieldAlpha;
		float BlueAlpha = PlayerData[IslandRedBlueWeapon::GetPlayerForColor(EIslandRedBlueWeaponType::Blue)].ShieldAlpha;
		switch(Settings.ShieldType)
		{
			case EIslandRedBlueShieldType::Red:
				return RedAlpha;
			case EIslandRedBlueShieldType::Blue:
				return BlueAlpha;
			case EIslandRedBlueShieldType::Both:
				return RedAlpha * 0.5 + BlueAlpha * 0.5;
		}
	}

	UFUNCTION()
	void ResetShieldAlpha()
	{
		PlayerData[IslandRedBlueWeapon::GetPlayerForColor(EIslandRedBlueWeaponType::Red)].ShieldAlpha = 1.0;
		PlayerData[IslandRedBlueWeapon::GetPlayerForColor(EIslandRedBlueWeaponType::Blue)].ShieldAlpha = 1.0;
		SetComponentTickEnabled(true);
	}

	UFUNCTION(BlueprintPure)
	EIslandRedBlueShieldType GetShieldType() const property
	{
		return Settings.ShieldType;
	}
}