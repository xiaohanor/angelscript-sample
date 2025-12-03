struct FRespawnMashActivationParams
{
	bool bIsHold;
	bool bIsAutomatic;
};

class UPlayerRespawnMashCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = n"PlayerHealth";

	default CapabilityTags.Add(n"RespawnButtonMash");

	UPlayerHealthSettings HealthSettings;
	UPlayerHealthComponent HealthComp;
	UPlayerRespawnComponent RespawnComp;
	UHazeCrumbSyncedVectorComponent MashSyncComp;
	FRespawnMashActivationParams ActiveParams;

	const float InitialRespawnTimerDelay = 0.4;

	int TotalPresses = 0;
	float NextRemotePulseTimer = 0.0;

	TArray<float> RunningImpulseTimers;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthSettings = UPlayerHealthSettings::GetSettings(Owner);
		HealthComp = UPlayerHealthComponent::Get(Owner);
		RespawnComp = UPlayerRespawnComponent::Get(Owner);

		MashSyncComp = UHazeCrumbSyncedVectorComponent::GetOrCreate(Player, n"ButtonMashSync");
		MashSyncComp.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FRespawnMashActivationParams& Params) const
	{
		if (!HealthComp.bIsDead)
			return false;
		if (!HealthComp.bHasFinishedDying)
			return false;
		if (HealthComp.bIsGameOver)
			return false;
		if (!HealthComp.bRespawnTimerActive)
			return false;
		if (!HealthSettings.bEnableRespawnTimer)
			return false;
		if (HealthSettings.RespawnTimer <= 0.0)
			return false;
		if (HealthComp.RespawnTimer >= HealthSettings.RespawnTimer)
			return false;
		if (!HealthSettings.bRespawnTimerButtonMash)
			return false;

		Params.bIsHold = AreMashesHolds();
		Params.bIsAutomatic = AreMashesAutomatic();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!HealthComp.bIsDead)
			return true;
		if (!HealthComp.bHasFinishedDying)
			return true;
		if (HealthComp.bIsGameOver)
			return true;
		if (!HealthComp.bRespawnTimerActive)
			return true;
		if (!HealthSettings.bEnableRespawnTimer)
			return true;
		if (HealthSettings.RespawnTimer <= 0.0)
			return true;
		if (HealthComp.RespawnTimer >= HealthSettings.RespawnTimer)
			return true;
		if (!HealthSettings.bRespawnTimerButtonMash)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// In case we're running a respawn timer but mashing is disabled, we still need to increase the respawn timer
		if (HealthComp.bRespawnTimerActive && !HealthSettings.bRespawnTimerButtonMash && !IsBlocked())
			HealthComp.RespawnTimer += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FRespawnMashActivationParams Params)
	{
		ActiveParams = Params;

		MashSyncComp.Value = FVector(0.0, 0.0, 0.0);
		MashSyncComp.SnapRemote();

		TotalPresses = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		RespawnComp.bIsRespawnMashActive = false;
		MashSyncComp.Value = FVector(0.0, 0.0, 0.0);

		if (RespawnComp.OverlayWidget != nullptr)
			RespawnComp.OverlayWidget.bIsRespawnMashActive = false;
	}

	bool AreMashesHolds() const
	{
		if (Player.HasControl())
		{
			if (Player.IsMio())
			{
				if (ButtonMash::CVar_RemoveButtonMashes_Mio.GetInt() == 1)
					return true;
			}
			else
			{
				if (ButtonMash::CVar_RemoveButtonMashes_Zoe.GetInt() == 1)
					return true;
			}
		}

		return false;
	}

	bool AreMashesAutomatic() const
	{
		if (Player.HasControl())
		{
			if (Player.IsMio())
			{
				if (ButtonMash::CVar_RemoveButtonMashes_Mio.GetInt() == 2)
					return true;
			}
			else
			{
				if (ButtonMash::CVar_RemoveButtonMashes_Zoe.GetInt() == 2)
					return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > InitialRespawnTimerDelay)
		{
			RespawnComp.bIsRespawnMashActive = true;
			if (RespawnComp.OverlayWidget != nullptr)
				RespawnComp.OverlayWidget.bIsRespawnMashActive = true;

			if (HasControl())
			{
				if (AreMashesAutomatic())
				{
					if (RespawnComp.OverlayWidget != nullptr)
						RespawnComp.OverlayWidget.SetState(false, true);
					HealthComp.RespawnTimer += DeltaTime * HealthSettings.RespawnMashMaxSpeedMultiplier;
				}
				else if (AreMashesHolds())
				{
					if (RespawnComp.OverlayWidget != nullptr)
						RespawnComp.OverlayWidget.SetState(true, false);

					// If accessibility settings are turning mashes into holds, apply that
					if (IsActioning(ActionNames::Interaction))
					{
						HealthComp.RespawnTimer += DeltaTime * HealthSettings.RespawnMashMaxSpeedMultiplier;
					}
					else
					{
						HealthComp.RespawnTimer += DeltaTime;
					}
				}
				else
				{
					float MashableExtraProgress = HealthSettings.RespawnTimer * (HealthSettings.RespawnMashMaxSpeedMultiplier - 1.0);
					float Impulse = MashableExtraProgress / (HealthSettings.RespawnMashRequiredMashRate * HealthSettings.RespawnTimer);
					float ImpulseDuration = 0.20;

					if (WasActionStarted(ActionNames::Interaction))
					{
						TotalPresses += 1;
						RunningImpulseTimers.Add(ImpulseDuration);

						if (RespawnComp.OverlayWidget != nullptr)
							RespawnComp.OverlayWidget.Pulse();
					}

					// Update impulse timers
					float ConsumedImpulseTime = 0;
					for (int i = RunningImpulseTimers.Num() - 1; i >= 0; --i)
					{
						if (RunningImpulseTimers[i] <= DeltaTime)
						{
							ConsumedImpulseTime += RunningImpulseTimers[i];
							RunningImpulseTimers.RemoveAt(i);
						}
						else
						{
							RunningImpulseTimers[i] -= DeltaTime;
							ConsumedImpulseTime += DeltaTime;
						}
					}

					// Apply progress and impulses
					HealthComp.RespawnTimer += DeltaTime;
					HealthComp.RespawnTimer += (Impulse / ImpulseDuration) * ConsumedImpulseTime;

					if (RespawnComp.OverlayWidget != nullptr)
						RespawnComp.OverlayWidget.SetState(false, false);
				}

				MashSyncComp.Value = FVector(
					0.0, HealthComp.RespawnTimer, TotalPresses,
				);
			}
			else
			{
				if (RespawnComp.OverlayWidget != nullptr)
				{
					RespawnComp.OverlayWidget.SetState(ActiveParams.bIsHold, ActiveParams.bIsAutomatic);

					// Simulated pulses based on remote mash rate
					if (!ActiveParams.bIsHold)
					{
						FVector LatestData;
						float LatestTime = 0;
						MashSyncComp.GetLatestAvailableData(LatestData, LatestTime);

						float TimeRemaining = LatestTime - Time::GetPlayerCrumbTrailTime(Player);
						int PressesRemaining = int(LatestData.Z) - TotalPresses;

						if (PressesRemaining > 0)
						{
							float PressSpacing = TimeRemaining / PressesRemaining;
							NextRemotePulseTimer += DeltaTime;
							if (NextRemotePulseTimer >= PressSpacing)
							{
								NextRemotePulseTimer = 0.0;
								TotalPresses += 1;

								RespawnComp.OverlayWidget.Pulse();
							}
						}
					}
				}

				HealthComp.RespawnTimer = MashSyncComp.Value.Y;
			}

			if (RespawnComp.OverlayWidget != nullptr)
			{
				RespawnComp.OverlayWidget.Update(
					Math::Saturate(HealthComp.RespawnTimer / Math::Max(HealthSettings.RespawnTimer, 0.01))
				);
			}
		}
	}
};