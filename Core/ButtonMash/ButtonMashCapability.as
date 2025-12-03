
struct FButtonMashDeactivationParams
{
	bool bWasCanceled = false;
	bool bWasCompleted = false;
};

class UButtonMashCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"ButtonMash");
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UButtonMashComponent MashComp;
	UHazeCrumbSyncedVectorComponent MashSyncComp;

	FActiveButtonMash ButtonMash;
	UButtonMashWidget Widget;
	UNetworkLockComponent DoubleMashLock;

	int TotalPresses = 0;
	float NextRemotePulseTimer = 0.0;

	bool bWasCancelPressed = false;
	bool bWasCompleted = false;

	TArray<float> RunningImpulseTimers;
	TArray<float> ButtonPressRealTimes;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MashComp = UButtonMashComponent::GetOrCreate(Player);

		MashSyncComp = UHazeCrumbSyncedVectorComponent::GetOrCreate(Player, n"ButtonMashSync");
		MashSyncComp.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);

		PlayerInputDevToggles::ButtonMash::AutoButtonMash.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FActiveButtonMash& StartedButtonMash) const
	{
		if (MashComp.ActiveMashes.Num() == 0)
			return false;

		StartedButtonMash = MashComp.ActiveMashes[0];
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FActiveButtonMash StartedButtonMash)
	{
		ButtonMash = StartedButtonMash;

		TotalPresses = 0;
		ButtonPressRealTimes.Reset();

		bWasCancelPressed = false;
		bWasCompleted = false;

		float InitialProgress = 0.0;
		if (ButtonMash.Settings.ProgressionMode == EButtonMashProgressionMode::StartFullDecayDown)
			InitialProgress = 1.0;

		FButtonMashState& State = MashComp.GetState(ButtonMash.Instigator, InitialProgress);
		MashSyncComp.Value = FVector(0.0, State.CurrentProgress, 0.0);
		MashSyncComp.SnapRemote();

		// Add the Widget
		if (ButtonMash.Settings.bShowButtonMashWidget)
		{
			Widget = Player.AddWidget(MashComp.ButtonMashWidget);
			Widget.SetWidgetShowInFullscreen(true);
			Widget.MashSettings = ButtonMash.Settings;
			Widget.MashProgress = State.CurrentProgress;
			Widget.Start();

			if (ButtonMash.Settings.WidgetAttachComponent != nullptr)
			{
				Widget.AttachWidgetToComponent(ButtonMash.Settings.WidgetAttachComponent, ButtonMash.Settings.WidgetAttachSocket);
				Widget.SetWidgetRelativeAttachOffset(ButtonMash.Settings.WidgetPositionOffset);
			}
			else if (ButtonMash.Settings.WidgetPositionOffset.IsZero())
			{
				Widget.AttachWidgetToComponent(Player.Mesh);
				Widget.SetWidgetRelativeAttachOffset(FVector(0.0, 0.0, 180.0));
			}
			else
			{
				Widget.SetWidgetWorldPosition(ButtonMash.Settings.WidgetPositionOffset);
			}
		}

		// Block active gameplay if we want to
		if (ButtonMash.Settings.bBlockOtherGameplay)
		{
			Player.BlockCapabilitiesExcluding(n"GameplayAction", n"UsableWhileButtonMashing", this);
			Player.BlockCapabilitiesExcluding(n"MovementInput", n"UsableWhileButtonMashing", this);
		}

		// Add cancel prompt if canceling is allowed
		if (ButtonMash.Settings.bAllowPlayerCancel)
		{
			Player.ShowCancelPrompt(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FButtonMashDeactivationParams& OutParams) const
	{
		if (MashComp.ActiveMashes.Num() == 0 || MashComp.ActiveMashes[0].Instigator != ButtonMash.Instigator)
		{
			// Button mash was stopped externally
			return true;
		}

		if (bWasCompleted)
		{
			// Button mash was successfully completed
			OutParams.bWasCompleted = true;
			return true;
		}

		if (bWasCancelPressed)
		{
			// Player hit cancel to stop the button mash
			OutParams.bWasCanceled = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FButtonMashDeactivationParams Params)
	{
		MashComp.ClearState(ButtonMash.Instigator);
		MashSyncComp.Value = FVector(0.0, 0.0, 0.0);

		if (Widget != nullptr)
		{
			Player.RemoveWidget(Widget);
			Widget = nullptr;
		}

		if (HasControl())
		{
			MashComp.StopButtonMash(ButtonMash.Instigator, bNetworkSafe = true);
		}

		// Unblock active gameplay we've blocked
		if (ButtonMash.Settings.bBlockOtherGameplay)
		{
			Player.UnblockCapabilities(n"GameplayAction", this);
			Player.UnblockCapabilities(n"MovementInput", this);
		}

		if (Params.bWasCompleted)
			ButtonMash.OnCompleted.ExecuteIfBound();
		else if (Params.bWasCanceled)
			ButtonMash.OnCanceled.ExecuteIfBound();

		if (ButtonMash.Settings.bAllowPlayerCancel)
			Player.RemoveCancelPromptByInstigator(this);

		// Double mashes should also stop the other player's button mash
		if (ButtonMash.IsDoubleMash())
		{
			auto OtherPlayerMashComp = UButtonMashComponent::Get(Player.OtherPlayer);
			if (OtherPlayerMashComp != nullptr)
				OtherPlayerMashComp.StopButtonMash(ButtonMash.Instigator, bNetworkSafe = true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FButtonMashState& State = MashComp.GetState(ButtonMash.Instigator);
		float MashProgress = State.CurrentProgress;

		float MinRate = 0.0;
		float TargetRate = 1.0;
		float AutoProgressionMultiplier = 1.0;

		GetConfigForButtonMashDifficulty(
			ButtonMash.Settings.Difficulty, ActiveDuration / ButtonMash.Settings.Duration,
			MinRate, TargetRate, AutoProgressionMultiplier);

		// At target mash rate, it should take Duration to complete
		//    Impulse = 1 / (TargetRate * Duration)
		// At minimum mash rate, the progress should stay static
		//    DecayRate = Impulse / ((1.0 / MinRate) - DelayBeforeDecay))

		float Impulse = 1.0 / (TargetRate * ButtonMash.Settings.Duration);
		float ImpulseDuration = 0.05;

		float DelayBeforeDecay = Math::Min(0.2, 0.8 * (1.0 / MinRate));
		float DecayRate = Impulse / Math::Max((1.0 / MinRate) - DelayBeforeDecay, 0.01);

		float AllowOverBuffer = 0.5 / ButtonMash.Settings.Duration;

		float MashRate = 0.0;
		if (HasControl())
		{
			bool bIsButtonDown = IsActioning(ButtonMash.Settings.ButtonAction);
			
			if (ButtonMash.Settings.IsButtonHold(Player))
			{
				if (bIsButtonDown || PlayerInputDevToggles::ButtonMash::AutoButtonMash.IsEnabled(Player))
				{
					MashRate = TargetRate;
					MashProgress += DeltaTime / ButtonMash.Settings.Duration * AutoProgressionMultiplier;
				}
				else
				{
					MashRate = 0.0;
					MashProgress -= DecayRate * DeltaTime;
				}
			}
			else if (ButtonMash.Settings.IsAutomatic(Player))
			{
				if (ButtonMash.Settings.ProgressionMode != EButtonMashProgressionMode::MashRateOnlyIgnoreAutomatic)
				{
					MashRate = TargetRate;
					MashProgress += DeltaTime / ButtonMash.Settings.Duration * AutoProgressionMultiplier;
				}
			}
			else
			{
				// Update the mash rate
				if (WasActionStarted(ButtonMash.Settings.ButtonAction))
				{
					TotalPresses += 1;

					ButtonPressRealTimes.Add(Time::RealTimeSeconds);
					RunningImpulseTimers.Add(ImpulseDuration);
					if (Widget != nullptr)
						Widget.Pulse();
					MashComp.OnVisualPulse.Broadcast();
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

				// Apply impulses
				MashProgress += (Impulse / ImpulseDuration) * ConsumedImpulseTime;

				// Always apply the decay
				if (ButtonMash.Settings.ProgressionMode != EButtonMashProgressionMode::MashToProceedOnly)
				{
					if (!WasActionStartedDuringTime(ButtonMash.Settings.ButtonAction, DelayBeforeDecay))
						MashProgress -= DecayRate * DeltaTime;
				}

				// Remove old presses
				while (ButtonPressRealTimes.Num() > 0 && Time::GetRealTimeSince(ButtonPressRealTimes[0]) > 2.0)
					ButtonPressRealTimes.RemoveAt(0);

				// Figure out how many presses we've done in the last second
				if (ButtonPressRealTimes.Num() >= 2)
				{
					// Calculate the average time between presses that cover the last second
					float TimeSinceLastPress = Time::GetRealTimeSince(ButtonPressRealTimes.Last());
					float PressSpacingTotal = TimeSinceLastPress;
					int PressCount = 1;

					for (int i = ButtonPressRealTimes.Num() - 1; i >= 1; --i)
					{
						float TimeSincePress = Time::GetRealTimeSince(ButtonPressRealTimes[i]);
						float TimeBetweenPresses = ButtonPressRealTimes[i] - ButtonPressRealTimes[i-1];

						if (TimeSincePress < 1.0)
						{
							PressSpacingTotal += TimeBetweenPresses;
							PressCount += 1;
						}
					}

					if (TimeSinceLastPress > 0.5)
						MashRate = 0.0;
					else if (PressCount > 0 && PressSpacingTotal > 0)
						MashRate = 1.0 / (PressSpacingTotal / PressCount);
					else
						MashRate = 0.0;
				}
				else
				{
					MashRate = ButtonPressRealTimes.Num();
				}
			}

			// PrintToScreenScaled(f"{Player.Player :n} {MashRate=}");
			MashProgress = Math::Clamp(MashProgress, 0.0, 1.0 + AllowOverBuffer);

			// Update the synced state for the remote side
			MashSyncComp.Value = FVector(
				MashRate, MashProgress, TotalPresses,
			);
		}
		else
		{
			// Synced state into the mash component so it can be accessed
			if (ButtonMash.Settings.bSyncWithNetworkLatestData)
			{
				FVector LatestData;
				float LatestTime = 0;
				MashSyncComp.GetLatestAvailableData(LatestData, LatestTime);

				MashProgress = Math::FInterpTo(
					State.CurrentProgress,
					LatestData.Y, Time::UndilatedWorldDeltaSeconds, 10.0);
				MashRate = LatestData.X;
			}
			else
			{
				MashProgress = MashSyncComp.Value.Y;
				MashRate = MashSyncComp.Value.X;
			}

			// Simulated pulses based on remote mash rate
			if (!ButtonMash.Settings.IsButtonHold(Player))
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

						if (Widget != nullptr)
							Widget.Pulse();
						MashComp.OnVisualPulse.Broadcast();
					}
				}
			}
		}

		// Handle completion
		if (HasControl())
		{
			if (ButtonMash.IsDoubleMash())
			{
				// Double mash completion is decided by the host
				if (ButtonMash.DoesProgressCountAsCompleted(MashProgress))
				{
					if (Network::HasWorldControl())
					{
						auto OtherPlayerMashComp = UButtonMashComponent::Get(Player.OtherPlayer);
						if (OtherPlayerMashComp != nullptr)
						{
							float OtherPlayerProgress = OtherPlayerMashComp.GetButtonMashProgress(ButtonMash.Instigator);
							if (ButtonMash.DoesProgressCountAsCompleted(OtherPlayerProgress))
							{
								bWasCompleted = true;
							}
						}
					}
				}
			}
			else
			{
				// Simple completion for one-side button mashes
				if (State.bAllowCompletion && ButtonMash.DoesProgressCountAsCompleted(MashProgress))
					bWasCompleted = true;
			}
		}

		// Update the accessible state in the mash component
		State.CurrentProgress = MashProgress;
		State.MashRate = MashRate;
		State.bIsMashRateSufficient = MashRate >= MinRate;

		// Update the display widget
		if (Widget != nullptr)
		{
			Widget.MashProgress = Math::Saturate(MashProgress);
		}

		// Cancel the button mash if we're able
		if (HasControl() && ButtonMash.Settings.bAllowPlayerCancel)
		{
			check(!ButtonMash.IsDoubleMash()); // Enforced when starting

			if (WasActionStarted(ActionNames::Cancel))
			{
				Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
				bWasCancelPressed = true;
			}
		}
	}
};