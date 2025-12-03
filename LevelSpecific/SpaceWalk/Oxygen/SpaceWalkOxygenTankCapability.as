class USpaceWalkOxygenTankCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"ConsumeOxygen");
	default TickGroup = EHazeTickGroup::Gameplay;

	USpaceWalkOxygenPlayerComponent OxyComp;
	USpaceWalkOxygenSettings OxySettings;
	USpaceWalkOxygenWidget WarningWidget;

	bool bTriggeredDeath = false;
	bool bHasOxygenLowWarning = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		OxyComp = USpaceWalkOxygenPlayerComponent::Get(Player);
		OxySettings = USpaceWalkOxygenSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SpacewalkOxygen::DevToggle_InfiniteOxygen.MakeVisible();
		USpaceWalkOxygenEffectHandler::Trigger_OxygenMeterWidgetShown(Player);
		WarningWidget = Player.AddWidget(OxyComp.WidgetClass);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (WarningWidget != nullptr)
		{
			Player.RemoveWidget(WarningWidget);
			WarningWidget = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("OxygenLevel", OxyComp.OxygenLevel);
		TemporalLog.Value("OxygenDepletionRate", OxyComp.OxygenDepletionRate.Get());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!SpacewalkOxygen::DevToggle_InfiniteOxygen.IsEnabled())
		{
			float MinimumOxygen = 0.0;

			// If we're making progress towards completing an oxygen interaction, don't allow the oxygen to run out
			// until we fail the interaction
			if (OxyComp.OxygenInteraction != nullptr && OxyComp.OxygenInteraction.SuccessfulPumps > 0 && OxyComp.OxygenLevel > 0.0)
			{
				MinimumOxygen = 0.0001;
				// OxyComp.OxygenLevel = MinimumOxygen;
			}

			OxyComp.OxygenLevel = Math::Clamp(
				OxyComp.OxygenLevel - (DeltaTime / OxySettings.OxygenDuration * OxyComp.OxygenDepletionRate.Get()),
				MinimumOxygen, 1.0);
		}

		if (HasControl())
		{
			if (OxyComp.OxygenLevel <= 0.0 && !PlayerHealth::ArePlayersGameOver() && !bTriggeredDeath)
			{
				CrumbTriggerOxygenGameOver();
				bTriggeredDeath = true;
			}

		}

		if (OxyComp.OxygenLevel <= 0.25)
		{
			if (!bHasOxygenLowWarning)
			{
				USpaceWalkOxygenEffectHandler::Trigger_OxygenLowWarningAdded(Player);
				bHasOxygenLowWarning = true;
				USpaceWalkOxygenEventHandler::Trigger_OxygenLowWarningAdded(Player);

			}
		}
		else
		{
			if (bHasOxygenLowWarning)
			{
				USpaceWalkOxygenEffectHandler::Trigger_OxygenLowWarningRemoved(Player);
				bHasOxygenLowWarning = false;
				USpaceWalkOxygenEventHandler::Trigger_OxygenLowWarningRemoved(Player);

			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerOxygenGameOver()
	{
		OxyComp.bHasRunOutOfOxygen = true;
		OxyComp.OxygenLevel = 0.0;

		auto OtherPlayerOxyComp = USpaceWalkOxygenPlayerComponent::Get(Player.OtherPlayer);
		OtherPlayerOxyComp.OxygenLevel = 0.0;

		if (OxyComp.OxygenInteraction != nullptr)
			Player.PlaySlotAnimation(Animation = OxyComp.OxygenDeathTouchScreen[Player]);
		else
			Player.PlaySlotAnimation(Animation = OxyComp.OxygenDeathFloating[Player]);

		USpaceWalkOxygenEffectHandler::Trigger_OxygenDeathTriggered(Player);

		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(CapabilityTags::Death, this);
		Timer::SetTimer(this, n"OnOxygenDeathComplete", 5.0);
	}

	UFUNCTION()
	private void OnOxygenDeathComplete()
	{
		PlayerHealth::TriggerGameOver();
	}
};