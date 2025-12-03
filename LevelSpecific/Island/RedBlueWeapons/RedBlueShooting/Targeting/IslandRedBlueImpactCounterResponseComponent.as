

enum EIslandRedBlueImpactCounterResponseValidation
{
	None,
	MioImpactRequiresFullZoeAlpha,
	ZoeImpactRequiresFullMioAlpha,
}

struct FIslandRedBlueImpactCounterResponseComponentSettingsInternal
{
	// How much will the alpha increase per impact
	UPROPERTY(Category = "Settings", Meta = (ClampMin = "0.0", ClampMax = "1.0"))
	float AlphaPerImpact = 1;

	// How long time, from impact, until the next impact can trigger
	UPROPERTY(Category = "Settings", Meta = (ClampMin = "0.0"))
	float BlockNextImpactTime = 0;

	// How long will it take until the alpha starts to decay
	UPROPERTY(Category = "Settings", Meta = (ClampMin = "0.0"))
	float AlphaDecayDelay = 0;

	// How fast will the alpha decay
	UPROPERTY(Category = "Settings", Meta = (ClampMin = "0.0"))
	float AlphaDecayRate = 0;
}

class UIslandRedBlueImpactCounterResponseComponentSettings : UDataAsset
{
	UPROPERTY(Category = "Settings")
	EIslandRedBlueImpactCounterResponseValidation ValidationType = EIslandRedBlueImpactCounterResponseValidation::None;

	UPROPERTY(Category = "Settings")
	FIslandRedBlueImpactCounterResponseComponentSettingsInternal SettingsMio;

	UPROPERTY(Category = "Settings")
	FIslandRedBlueImpactCounterResponseComponentSettingsInternal SettingsZoe;
}

struct FIslandRedBlueImpactCounterResponseComponentInternal
{
	float ImpactAlphaImpactDecayStartTime = 0;
	float NextValidImpactTime = 0;
	bool bHasTriggeredFullAlpha = false;

	UHazeCrumbSyncedFloatComponent SyncedImpactAlpha;

	float GetImpactAlpha() const property
	{
		return SyncedImpactAlpha.Value;
	}

	void SetImpactAlpha(float Alpha) property
	{
		SyncedImpactAlpha.Value = Alpha;
	}
}

event void FIslandRedBlueImpactCounterFullAlphaResponseSignature(AHazePlayerCharacter Player);

/**
 * Component used to count the impacts made by both players
 * Has an alpha, 0 -> 1.
 * Calls OnFullyCharged every time the alpha reaches 1
 */
class UIslandRedBlueImpactCounterResponseComponent : UIslandRedBlueImpactResponseComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(Category = "Red Blue Settings")
	UIslandRedBlueImpactCounterResponseComponentSettings Settings;

	UPROPERTY(Category = "Events")
	FIslandRedBlueImpactCounterFullAlphaResponseSignature OnFullAlpha;

	private TPerPlayer<FIslandRedBlueImpactCounterResponseComponentInternal> InternalData;

	UHazeCrumbSyncedFloatComponent MioSyncedAlpha;
	UHazeCrumbSyncedFloatComponent ZoeSyncedAlpha;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		MioSyncedAlpha = UHazeCrumbSyncedFloatComponent::Create(Owner, FName(Name + "_MioSyncedAlpha"));
		ZoeSyncedAlpha = UHazeCrumbSyncedFloatComponent::Create(Owner, FName(Name + "_ZoeSyncedAlpha"));

		InternalData[Game::Mio].SyncedImpactAlpha = MioSyncedAlpha;
		InternalData[Game::Zoe].SyncedImpactAlpha = ZoeSyncedAlpha;
	}

	private FIslandRedBlueImpactCounterResponseComponentSettingsInternal GetPlayerSettings(AHazePlayerCharacter Player) const
	{
		FIslandRedBlueImpactCounterResponseComponentSettingsInternal PlayerSettings;
		if(Settings != nullptr)
		{
			if(Player.IsMio())
				PlayerSettings = Settings.SettingsMio;
			else
				PlayerSettings = Settings.SettingsZoe;
		}
		return PlayerSettings;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds) final
	{
		if(!HasControl())
			return;

		// Update the player data for each player,
		// applying decay rate if we have that
		bool bHasAnyAlpha = false;
		for(auto Player : Game::GetPlayers())
		{
			auto& PlayerData = InternalData[Player];
			if(PlayerData.ImpactAlpha <= 0)
				continue;

			auto PlayerSettings = GetPlayerSettings(Player);
			if (PlayerSettings.AlphaDecayRate > SMALL_NUMBER)
				continue;

			bHasAnyAlpha = true;

			if(Time::GameTimeSeconds >= PlayerData.ImpactAlphaImpactDecayStartTime)
			{
				PlayerData.bHasTriggeredFullAlpha = false;
				PlayerData.ImpactAlpha = Math::Max(PlayerData.ImpactAlpha - (DeltaSeconds * PlayerSettings.AlphaDecayRate), 0);
			}
		}

		if (!bHasAnyAlpha)
			SetComponentTickEnabled(false);
	}

	protected void OnImpact(AHazePlayerCharacter ImpactInstigator, FHitResult HitResult, float DamageMultiplier) override final
	{
		Super::OnImpact(ImpactInstigator, HitResult, DamageMultiplier);

		if(!HasControl())
			return;

		auto& PlayerData = InternalData[ImpactInstigator];
		auto PlayerSettings = GetPlayerSettings(ImpactInstigator);
		
		PlayerData.NextValidImpactTime = Time::GameTimeSeconds + PlayerSettings.BlockNextImpactTime;
		PlayerData.ImpactAlphaImpactDecayStartTime = Time::GameTimeSeconds + PlayerSettings.AlphaDecayDelay;

		PlayerData.ImpactAlpha = Math::Clamp(PlayerData.ImpactAlpha + Math::Clamp(PlayerSettings.AlphaPerImpact * DamageMultiplier, 0, 1), 0, 1);
		if(PlayerData.ImpactAlpha > 1 - KINDA_SMALL_NUMBER && !PlayerData.bHasTriggeredFullAlpha)
		{
			CrumbOnFullAlpha(ImpactInstigator);
		}

		SetComponentTickEnabled(true);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnFullAlpha(AHazePlayerCharacter Player)
	{
		auto& PlayerData = InternalData[Player];
		PlayerData.bHasTriggeredFullAlpha = true;
		PlayerData.ImpactAlpha = 1;
		OnFullAlpha.Broadcast(Player);
		SetComponentTickEnabled(true);
	}

	protected bool CanApplyImpact(const AHazePlayerCharacter ImpactInstigator, FHitResult HitResult) const override
	{
		if(!Super::CanApplyImpact(ImpactInstigator, HitResult))
			return false;
			
		const auto& PlayerData = InternalData[ImpactInstigator];

		// Validate impact delay
		if(Time::GameTimeSeconds < PlayerData.NextValidImpactTime)
			return false;
		
		if(Settings != nullptr)
		{
			// Validate the required alpha amount for each player
			if(Settings.ValidationType == EIslandRedBlueImpactCounterResponseValidation::MioImpactRequiresFullZoeAlpha)
			{
				const auto& OtherPlayerData = InternalData[ImpactInstigator.OtherPlayer];
				if(ImpactInstigator.IsMio() && OtherPlayerData.ImpactAlpha < 1 - KINDA_SMALL_NUMBER)
					return false;
			}
			else if(Settings.ValidationType == EIslandRedBlueImpactCounterResponseValidation::ZoeImpactRequiresFullMioAlpha)
			{
				const auto& OtherPlayerData = InternalData[ImpactInstigator.OtherPlayer];
				if(ImpactInstigator.IsZoe() && OtherPlayerData.ImpactAlpha < 1 - KINDA_SMALL_NUMBER)
					return false;
			}
		}

		return true;
	}

	UFUNCTION(BlueprintPure, Category = "Red Blue Impact")
	float GetImpactAlpha(AHazePlayerCharacter ForPlayer) const
	{
		const auto& PlayerData = InternalData[ForPlayer];
		return PlayerData.ImpactAlpha;
	}
}