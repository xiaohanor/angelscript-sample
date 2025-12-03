struct FStickWiggleActivateParams
{
	FActiveStickWiggle StartedWiggle;
};

struct FStickWiggleDeactivateParams
{
	bool bWasCanceled = false;
	bool bWasCompleted = false;
};

class UStickWiggleCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"StickWiggle");
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Input;

	UStickWiggleComponent WiggleComp;
	UHazeCrumbSyncedFloatComponent WiggleSyncComp;

	FActiveStickWiggle ActiveWiggle;
	UStickWiggleWidget Widget;

	bool bWasCancelPressed = false;
	FVector2D PreviousStickInput;
	float LastWiggleTime;

	FHazeAcceleratedFloat AccAlpha;
	float TargetAlpha = 0;

	const float SpringStiffness = 1500;
	const float SpringDamping = 0.3;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WiggleComp = UStickWiggleComponent::GetOrCreate(Player);
		WiggleSyncComp = UHazeCrumbSyncedFloatComponent::GetOrCreate(Player, n"StickWiggleSync");
		WiggleSyncComp.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FStickWiggleActivateParams& Params) const
	{
		if (WiggleComp.ActiveWiggles.Num() == 0)
			return false;

		Params.StartedWiggle = WiggleComp.ActiveWiggles[0];
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FStickWiggleDeactivateParams& Params) const
	{
		if (WiggleComp.ActiveWiggles.Num() == 0 || WiggleComp.ActiveWiggles[0].Instigator != ActiveWiggle.Instigator)
		{
			// Stick wiggle mash was stopped externally
			return true;
		}

		if(WiggleComp.GetState(ActiveWiggle.Instigator).State.IsFinished())
		{
			// Stick wiggle was successfully completed
			Params.bWasCompleted = true;
			return true;
		}

		if (bWasCancelPressed)
		{
			// Player hit cancel to stop the stick wiggle
			Params.bWasCanceled = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FStickWiggleActivateParams Params)
	{
		ActiveWiggle = Params.StartedWiggle;
		bWasCancelPressed = false;
		PreviousStickInput = FVector2D::ZeroVector;
		LastWiggleTime = 0.0;
		TargetAlpha = 0;
		AccAlpha.SnapTo(0);
		WiggleSyncComp.Value = 0;

		FActiveStickWiggleState& State = WiggleComp.GetState(ActiveWiggle.Instigator);

		// Add the Widget
		if (ActiveWiggle.Settings.bShowStickSpinWidget)
		{
			if (ActiveWiggle.Settings.WidgetAttachComponent == nullptr && ActiveWiggle.Settings.WidgetPositionOffset.IsZero())
				Widget = Cast<UStickWiggleWidget>(Player.AddWidgetToHUDSlot(n"Tutorial", WiggleComp.StickWiggleWidget));
			else
				Widget = Player.AddWidget(WiggleComp.StickWiggleWidget);

			Widget.SetWidgetShowInFullscreen(true);
			Widget.WiggleSettings = ActiveWiggle.Settings;
			Widget.WiggleState = State.State;
			Widget.Start();

			if (ActiveWiggle.Settings.WidgetAttachComponent != nullptr)
			{
				Widget.AttachWidgetToComponent(ActiveWiggle.Settings.WidgetAttachComponent);
				Widget.SetWidgetRelativeAttachOffset(ActiveWiggle.Settings.WidgetPositionOffset);
			}
			else if (!ActiveWiggle.Settings.WidgetPositionOffset.IsZero())
			{
				Widget.SetWidgetWorldPosition(ActiveWiggle.Settings.WidgetPositionOffset);
			}
		}

		// Block active gameplay if we want to
		if (ActiveWiggle.Settings.bBlockOtherGameplay)
		{
			Player.BlockCapabilitiesExcluding(n"GameplayAction", n"UsableWhileButtonMashing", this);
			Player.BlockCapabilitiesExcluding(n"MovementInput", n"UsableWhileButtonMashing", this);
		}

		// Add cancel prompt if canceling is allowed
		if (ActiveWiggle.Settings.bAllowPlayerCancel)
		{
			Player.ShowCancelPrompt(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FStickWiggleDeactivateParams Params)
	{
		WiggleComp.ClearState(ActiveWiggle.Instigator);

		if (Widget != nullptr)
		{
			Player.RemoveWidget(Widget);
			Widget = nullptr;
		}

		if (HasControl())
		{
			WiggleComp.StopStickWiggle(ActiveWiggle.Instigator);
		}

		// Unblock active gameplay we've blocked
		if (ActiveWiggle.Settings.bBlockOtherGameplay)
		{
			Player.UnblockCapabilities(n"GameplayAction", this);
			Player.UnblockCapabilities(n"MovementInput", this);
		}

		if(Params.bWasCompleted)
			ActiveWiggle.OnCompleted.ExecuteIfBound();
		else if(Params.bWasCanceled)
			ActiveWiggle.OnCanceled.ExecuteIfBound();

		if (ActiveWiggle.Settings.bAllowPlayerCancel)
			Player.RemoveCancelPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FActiveStickWiggleState& State = WiggleComp.GetState(ActiveWiggle.Instigator);

		if (HasControl())
		{
			const float RawInput = GetAttributeFloat(AttributeNames::MoveRight);

			if (IsWiggleAutomatic())
			{
				LastWiggleTime = Time::RealTimeSeconds;
			}
			else if (IsWiggleHoldDirection())
			{
				// If simplified, just increase if any horizontal input is given at all
				if(Math::Abs(RawInput) > 0.1)
				{
					LastWiggleTime = Time::RealTimeSeconds;
				}
			}
			else
			{
				int PrevPosition = State.State.WiggleInput;

				if (RawInput < -ActiveWiggle.Settings.HorizontalWiggleThreshold)
				{
					State.State.WiggleInput = -1;
				}
				else if (RawInput > ActiveWiggle.Settings.HorizontalWiggleThreshold)
				{
					State.State.WiggleInput = 1;
				}
				else
				{
					State.State.WiggleInput = 0;
				}

				if(State.State.WiggleInput != 0)
				{
					if(PrevPosition != State.State.WiggleInput)
					{
						LastWiggleTime = Time::RealTimeSeconds;
						TargetAlpha = Math::Saturate(TargetAlpha + 1 / float(ActiveWiggle.Settings.WigglesRequired));
					}
				}
			}
			
			if(Time::GetRealTimeSince(LastWiggleTime) < ActiveWiggle.Settings.WiggleStartDecreasingDelay)
			{
				if(ActiveWiggle.Settings.bChunkProgress && !IsWiggleAutomatic() && !IsWiggleHoldDirection())
				{
					AccAlpha.SpringTo(TargetAlpha, SpringStiffness, SpringDamping, DeltaTime);
					State.State.WiggledAlpha = AccAlpha.Value;
				}
				else
				{
					State.State.WiggledAlpha = Math::FInterpConstantTo(State.State.WiggledAlpha, 1.0, DeltaTime, 1.0 / ActiveWiggle.Settings.WiggleIntensityIncreaseTime);
				}
			}
			else
			{
				// If DecreaseTime is 0 or negative, we don't decrease
				if(ActiveWiggle.Settings.WiggleIntensityDecreaseTime > 0)
				{
					if(ActiveWiggle.Settings.bChunkProgress && !IsWiggleAutomatic() && !IsWiggleHoldDirection())
					{
						TargetAlpha = Math::FInterpConstantTo(TargetAlpha, 0, DeltaTime, 1.0 / ActiveWiggle.Settings.WiggleIntensityDecreaseTime);
						AccAlpha.SnapTo(TargetAlpha);
						State.State.WiggledAlpha = AccAlpha.Value;
					}
					else
					{
						State.State.WiggledAlpha = Math::FInterpConstantTo(State.State.WiggledAlpha, 0, DeltaTime, 1.0 / ActiveWiggle.Settings.WiggleIntensityDecreaseTime);
					}
				}
			}

			WiggleSyncComp.Value = State.State.WiggledAlpha;
		}
		else
		{
			// Synced state into the mash component so it can be accessed
			AccAlpha.SnapTo(WiggleSyncComp.Value);
			State.State.WiggledAlpha = AccAlpha.Value;
		}

		// Update the display widget
		if (Widget != nullptr)
		{
			Widget.WiggleState = State.State;

			bool bSimplified = IsWiggleHoldDirection();
			if (Widget.bIsSimplified != bSimplified)
			{
				Widget.bIsSimplified = bSimplified;
				Widget.BP_UpdateSettings();
			}
		}

		// Cancel the stick wiggle if we're able
		if (HasControl() && ActiveWiggle.Settings.bAllowPlayerCancel)
		{
			if (WasActionStarted(ActionNames::Cancel))
			{
				Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
				bWasCancelPressed = true;
			}
		}
	}

	bool IsWiggleHoldDirection() const
	{
		if (Player.IsMio())
		{
			if (StickWiggle::CVar_RemoveStickWiggle_Mio.GetInt() == 1)
				return true;
		}
		else
		{
			if (StickWiggle::CVar_RemoveStickWiggle_Zoe.GetInt() == 1)
				return true;
		}

		return false;
	}

	bool IsWiggleAutomatic() const
	{
		if (Player.IsMio())
		{
			if (StickWiggle::CVar_RemoveStickWiggle_Mio.GetInt() == 2)
				return true;
		}
		else
		{
			if (StickWiggle::CVar_RemoveStickWiggle_Zoe.GetInt() == 2)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		#if !RELEASE
		TemporalLog.Value("Active Wiggle;Instigator", ActiveWiggle.Instigator);

		for(int i = 0; i < WiggleComp.ActiveWiggles.Num(); i++)
		{
			auto Wiggle = WiggleComp.ActiveWiggles[i];
			TemporalLog.Value(f"{i:03}#Wiggle {i + 1};Instigator", Wiggle.Instigator);

			auto State = WiggleComp.GetState(Wiggle.Instigator);
			TemporalLog.Value(f"{i:03}#Wiggle {i + 1};State;Wiggle Input", State.State.WiggleInput);
			TemporalLog.Value(f"{i:03}#Wiggle {i + 1};State;Wiggled Alpha", State.State.WiggledAlpha);
			TemporalLog.Value(f"{i:03}#Wiggle {i + 1};State;Is Finished", State.State.IsFinished());
		}
		#endif
	}
};