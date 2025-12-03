event void FIslandRedBlueImpactOverchargeResponseFullChargeEvent(bool bWasOvercharged);
event void FIslandRedBlueImpactOverchargeResponseStartDischargeEvent(bool bCurrentlyAtFullCharge);
event void FIslandRedBlueImpactOverchargeResponseZeroChargeEvent(bool bWasOvercharged);

enum EIslandRedBlueOverchargeColor
{
	Red,
	Blue
}

struct FIslandRedBlueImpactOverchargeResponseComponentSettings
{
	UPROPERTY()
	EIslandRedBlueOverchargeColor OverchargeColor;

	UPROPERTY(Meta = (ClampMin = "0.0", ClampMax = "1.0"))
	float ChargeAmountPerImpact = 0.2;

	UPROPERTY(Meta = (ClampMin = "0.0"))
	float StartDischargingDelay = 2.0;

	UPROPERTY(Meta = (ClampMin = "0.0"))
	float DischargeSpeed = 1.0;

	UPROPERTY()
	bool bDischargeOnWrongColor = false;

	UPROPERTY()
	bool bBlockDischargeWhenFull = false;
}

class UIslandRedBlueImpactOverchargeResponseComponentSettingsDataAsset : UDataAsset
{
	UPROPERTY()
	FIslandRedBlueImpactOverchargeResponseComponentSettings Settings;
}

class UIslandRedBlueImpactOverchargeResponseComponent : UIslandRedBlueImpactResponseComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditAnywhere, Category = "Red Blue Settings")
	bool bUseDataAssetSettings = true;

	UPROPERTY(EditAnywhere, Category = "Red Blue Settings", DisplayName = "Settings Data Asset", Meta = (EditCondition = "bUseDataAssetSettings", EditConditionHides))
	UIslandRedBlueImpactOverchargeResponseComponentSettingsDataAsset SettingsDataAsset_Property;

	UPROPERTY(EditAnywhere, Category = "Red Blue Settings", DisplayName = "Settings", Meta = (EditCondition = "!bUseDataAssetSettings", EditConditionHides))
	FIslandRedBlueImpactOverchargeResponseComponentSettings Settings_Property;

	UPROPERTY(EditAnywhere, Category = "Red Blue Settings")
	AIslandRedBlueImpactOverchargeResponseDisplay OptionalDisplay;

	UPROPERTY(Category = "Events")
	FIslandRedBlueImpactOverchargeResponseFullChargeEvent OnFullCharge;

	UPROPERTY(Category = "Events")
	FIslandRedBlueImpactOverchargeResponseStartDischargeEvent OnStartDischarging;

	UPROPERTY(Category = "Events")
	FIslandRedBlueImpactOverchargeResponseZeroChargeEvent OnZeroCharge;

	private UHazeCrumbSyncedFloatComponent SyncedChargeAlpha;
	private UIslandRedBlueImpactOverchargeResponseDisplayComponent OptionalDisplayComponent;
	private float Internal_PreviousChargeAlpha = 0.0;
	private float TimeOfLastImpact = -100.0;
	private bool bLastImpactResultedInFullCharge = false;
	private bool bDischarging = false;
	private bool bCanDischarge = true;
	private bool bIsOvercharged = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SyncedChargeAlpha = UHazeCrumbSyncedFloatComponent::Create(Owner, FName(Name + "_SyncedChargeAlpha"));
		
		if(OptionalDisplay != nullptr)
		{
			OptionalDisplay.Display.SetColor(Settings.OverchargeColor);
			OptionalDisplay.Display.SetFillPercentage(ChargeAlpha);
		}

		if(OptionalDisplayComponent != nullptr)
		{
			OptionalDisplayComponent = UIslandRedBlueImpactOverchargeResponseDisplayComponent::Get(Owner);
			if(OptionalDisplayComponent != nullptr)
			{
				OptionalDisplayComponent.SetColor(Settings.OverchargeColor);
				OptionalDisplayComponent.SetFillPercentage(ChargeAlpha);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime) final
	{
		if(HasControl())
		{
			if(bCanDischarge && ChargeAlpha != 0.0 && Time::GetGameTimeSince(TimeOfLastImpact) > Settings.StartDischargingDelay)
			{
				if(!bDischarging)
				{
					CrumbSetDischarging(true);
					CrumbOnStartDischarging(ChargeAlpha == 1.0);
				}

				ChargeAlpha -= Settings.DischargeSpeed * DeltaTime;
				ChargeAlpha = Math::Clamp(ChargeAlpha, 0.0, 1.0);
			}
			else if(bDischarging)
			{
				CrumbSetDischarging(false);
				if(ChargeAlpha == 0.0)
					CrumbOnZeroCharge(bLastImpactResultedInFullCharge);
			}
		}

		if(OptionalDisplay != nullptr)
			OptionalDisplay.Display.SetFillPercentage(ChargeAlpha);

		if(OptionalDisplayComponent != nullptr)
			OptionalDisplayComponent.SetFillPercentage(ChargeAlpha);

		if ((ChargeAlpha <= 0.0 || !bCanDischarge) && !bDischarging)
			SetComponentTickEnabled(false);
	}

	void SetDisplayComponent(UIslandRedBlueImpactOverchargeResponseDisplayComponent DisplayComp, bool bSetColor = true)
	{
		OptionalDisplayComponent = DisplayComp;

		if(bSetColor)
			OptionalDisplayComponent.SetColor(Settings.OverchargeColor);
	}

	private void CrumbSetDischarging(bool bValue)
	{
		bDischarging = bValue;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnStartDischarging(bool bCurrentlyAtFullCharge)
	{
		OnStartDischarging.Broadcast(bCurrentlyAtFullCharge);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnZeroCharge(bool bCameFromFullCharge)
	{
		LocalOnZeroCharge();
	}

	void OnImpact(AHazePlayerCharacter ImpactInstigator, FHitResult HitResult, float DamageMultiplier) override final
	{
		Super::OnImpact(ImpactInstigator, HitResult, DamageMultiplier);

		if(!HasControl())
			return;

		if(IslandRedBlueWeapon::PlayerCanHitOverchargeComponent(ImpactInstigator, OverchargeColor))
		{
			bool bWasFullyCharged = ChargeAlpha == 1.0;
			ChargeAlpha = Math::Min(ChargeAlpha + Settings.ChargeAmountPerImpact * DamageMultiplier, 1.0);
			TimeOfLastImpact = Time::GetGameTimeSeconds();

			bLastImpactResultedInFullCharge = ChargeAlpha == 1.0;

			if(!bWasFullyCharged && bLastImpactResultedInFullCharge)
			{
				CrumbOnFullCharge(bIsOvercharged);
				if(Settings.bBlockDischargeWhenFull)
					bCanDischarge = false;
			}
		}
		else if(Settings.bDischargeOnWrongColor)
		{
			ChargeAlpha = Math::Max(ChargeAlpha - Settings.ChargeAmountPerImpact * DamageMultiplier, 1.0);
		}

		SetComponentTickEnabled(true);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnFullCharge(bool bWasOvercharged)
	{
		bIsOvercharged = true;
		OnFullCharge.Broadcast(bWasOvercharged);
	}

	bool CanApplyImpact(const AHazePlayerCharacter ImpactInstigator, FHitResult HitResult) const override
	{
		bool bBaseCanApplyImpact = Super::CanApplyImpact(ImpactInstigator, HitResult);
		if(!bBaseCanApplyImpact)
			return false;

		return true;
	}

	UFUNCTION(BlueprintPure)
	float GetChargeAlpha() const property
	{
		if(SyncedChargeAlpha == nullptr)
			return 0.0;

		return SyncedChargeAlpha.Value;
	}

	UFUNCTION(BlueprintPure)
	float GetPreviousChargeAlpha() const property
	{
		devCheck(HasControl(), "Can't get previous charge alpha if we don't have control of the overcharge comp");
		return Internal_PreviousChargeAlpha;
	}

	UFUNCTION(BlueprintPure)
	bool IsDischarging() const
	{
		return bDischarging;
	}

	UFUNCTION(BlueprintPure)
	bool IsOvercharged() const
	{
		return bIsOvercharged;
	}

	private void SetChargeAlpha(float NewChargeAlpha) property
	{
		Internal_PreviousChargeAlpha = SyncedChargeAlpha.Value;
		SyncedChargeAlpha.Value = NewChargeAlpha;
	}

	UFUNCTION()
	void ResetChargeAlpha(UObject TransitionInstigator = nullptr)
	{
		if(TransitionInstigator != nullptr)
			SyncedChargeAlpha.TransitionSync(TransitionInstigator);

		if(ChargeAlpha == 0.0)
			return;

		ChargeAlpha = 0.0;
		SetComponentTickEnabled(true);
		
		LocalOnZeroCharge();
	}

	private void LocalOnZeroCharge()
	{
		OnZeroCharge.Broadcast(bIsOvercharged);
		bIsOvercharged = false;
	}

	UFUNCTION(BlueprintPure)
	EIslandRedBlueOverchargeColor GetOverchargeColor() const property
	{
		return Settings.OverchargeColor;
	}

	FIslandRedBlueImpactOverchargeResponseComponentSettings GetSettings() const property
	{
		if(bUseDataAssetSettings)
			return SettingsDataAsset_Property.Settings;

		return Settings_Property;
	}
}