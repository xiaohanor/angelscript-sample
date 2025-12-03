
class UPlayerDefaultAudioDeathSettings : UHazeComposableSettings
{
	UPROPERTY(EditDefaultsOnly)
	bool bCanActivate = true;

	UPROPERTY(EditDefaultsOnly)
	bool bDisableEffectsAndGameOverEvents = false;

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioBusMixer GameOverBusMixerOverride = nullptr;
	
	UPROPERTY(EditDefaultsOnly)
	float FilteringDurationFadeIn = 1;

	UPROPERTY(EditDefaultsOnly)
	float FilteringDurationFadeOut = 1;

	UPROPERTY(EditDefaultsOnly)
	float StutterDurationFadeIn = 2;

	UPROPERTY(EditDefaultsOnly)
	float StutterDurationFadeOut = 2;
}

asset PlayerDeathAudioFilteringDisabled of UPlayerDefaultAudioDeathSettings
{
	bCanActivate = false;
}

asset PlayerDeathAudioFilteringGameOverDisabled of UPlayerDefaultAudioDeathSettings
{
	bDisableEffectsAndGameOverEvents = true;
}

struct FFilterAudioOnDeathCapabilityActivationParams
{
	bool bIsGameOver = false;
}

class UPlayerFilterAudioOnDeathCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Audio");
	default TickGroup = EHazeTickGroup::Audio;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerAudioFilterDeathManager> ManagerClass = UPlayerAudioFilterDeathManager;

	UPROPERTY(EditDefaultsOnly)
	FSoundDefReference ScreenspaceDeathSoundDef;

	UPlayerHealthComponent HealthComp;
	UPlayerHealthComponent OtherPlayerHealthComp;
	UPlayerHealthSettings HealthSettings;
	UPlayerDefaultAudioDeathSettings Settings;

	const FHazeAudioID Rtpc_PlayerDead_Mio("Rtpc_PlayerDead_Mio");
	const FHazeAudioID Rtpc_PlayerDead_Zoe("Rtpc_PlayerDead_Zoe");

	UPlayerAudioFilterDeathManager FilterManager;

	bool bDevDeath = false;
	bool bWaitingForRespawn = false;
	bool EffectController = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UPlayerHealthComponent::Get(Owner);
		OtherPlayerHealthComp = UPlayerHealthComponent::Get(Player.OtherPlayer);
		HealthSettings = UPlayerHealthSettings::GetSettings(Owner);
		Settings = UPlayerDefaultAudioDeathSettings::GetSettings(Owner);
		FilterManager =  Game::GetSingleton(ManagerClass);

		HealthComp.OnReviveTriggered.AddUFunction(this, n"OnPlayerRespawn");
		EffectController = Player.IsMio();

		Reset();
	}

	void Reset()
	{
		if (Player.IsMio())
		{
			AudioComponent::SetGlobalRTPC(Rtpc_PlayerDead_Mio, 0);
		}
		else
		{
			AudioComponent::SetGlobalRTPC(Rtpc_PlayerDead_Zoe, 0);
		}
	}

	UFUNCTION()
	void OnPlayerRespawn()
	{
		TEMPORAL_LOG(this).Event("OnPlayerRespawn");

		if (bWaitingForRespawn)
		{
			bWaitingForRespawn = false;
			PlayerRespawned();
		}
	}

	bool ShouldTriggerGameOver() const
	{
		if (!HealthSettings.bGameOverWhenBothPlayersDead)
			return false;

		if (!HealthComp.bIsDead)
			return false;
		if (HealthComp.bIsRespawning)
			return false;
		if (Player.bIsControlledByCutscene)
			return false;

		if (!OtherPlayerHealthComp.bIsDead)
			return false;
		if (OtherPlayerHealthComp.bIsRespawning)
			return false;
		if (Player.OtherPlayer.bIsControlledByCutscene)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FFilterAudioOnDeathCapabilityActivationParams& ActivationParams) const
	{
		#if TEST
		if (bDevDeath)
			return true;
		#endif

		if (Settings.bCanActivate == false)
			return false;

		if(ShouldTriggerGameOver())
		{
			ActivationParams.bIsGameOver = true;
			return true;
		}

		if (HealthComp.bIsDead)
		{		
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		#if TEST
		if (bDevDeath)
			return false;
		#endif

		if (HealthComp.bIsGameOver)
			return false;

		if (HealthComp.bIsRespawning)
			return false;

		if (HealthComp.bIsDead)
			return false;

		return true;
	}

	UFUNCTION(CallInEditor, DevFunction)
	void TriggerAudioDeath()
	{
		bDevDeath = true;
	}

	UFUNCTION(CallInEditor, DevFunction)
	void TriggerAudioRespawn()
	{
		if (!bDevDeath)
			return;
		
		bDevDeath = false;
		PlayerRespawned();
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TEMPORAL_LOG(this)
			.Value("WaitingForRespawn", bWaitingForRespawn)
			.Value("IsDead", HealthComp.bIsDead);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FFilterAudioOnDeathCapabilityActivationParams& ActivationParams)
	{
		if(ActivationParams.bIsGameOver || !SceneView::IsFullScreen())
		{
			bWaitingForRespawn = true;	
			FilterManager.PlayerFilterActivated(Player, Settings, ActivationParams.bIsGameOver, HealthSettings.bEnableRespawnTimer);
			FilterManager.StartFilteringForPlayer(Player.Player, 
				HealthComp.HealthSettings.RespawnFadeOutDuration, 
				Settings.FilteringDurationFadeIn,
				HealthComp.HealthSettings.RespawnFadeInDuration, 
				Settings.FilteringDurationFadeOut);	
				
			if (Player.IsMio())
			{
				AudioComponent::SetGlobalRTPC(Rtpc_PlayerDead_Mio, 1);
			}
			else
			{
				AudioComponent::SetGlobalRTPC(Rtpc_PlayerDead_Zoe, 1);
			}	
		}

		if (Settings.bDisableEffectsAndGameOverEvents)
			return;

		// Screenspace Death SoundDef (Respawn Widget Sounds)
		if(ScreenspaceDeathSoundDef.IsValid() && HealthSettings.bEnableRespawnTimer)
			ScreenspaceDeathSoundDef.SpawnSoundDefAttached(Player);	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(ScreenspaceDeathSoundDef.IsValid())
			ScreenspaceDeathSoundDef.RemoveFromActor(Player);
	}

	private void PlayerRespawned()
	{
		bWaitingForRespawn = false;
		FilterManager.StopFilteringForPlayer(Player.Player);

		if (Player.IsMio())
		{
			AudioComponent::SetGlobalRTPC(Rtpc_PlayerDead_Mio, 0);
		}
		else
		{
			AudioComponent::SetGlobalRTPC(Rtpc_PlayerDead_Zoe, 0);
		}
	}
}
