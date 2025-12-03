class UPlayerSolarEnergyPulseCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"PlayerSolarEnergyPulseCapability");

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UPlayerSolarEnergyPulseComponent UserComp;
	float MoveSpeed = 1300.0;

	float CooldownTime;
	float CooldownDuration = 0.3;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UPlayerSolarEnergyPulseComponent::Get(Player);
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
		FTutorialPrompt TriggerPrompt;
		TriggerPrompt.Action = ActionNames::PrimaryLevelAbility;
		TriggerPrompt.Text = NSLOCTEXT("EnergyPulse", "TriggerPrompt", "Swap power");


		Player.ShowTutorialPrompt(TriggerPrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (WasActionStarted(ActionNames::PrimaryLevelAbility) && Time::GameTimeSeconds > CooldownTime)
		{
			UserComp.Controller.SwapActivePlatforms();
			CooldownTime = Time::GameTimeSeconds + CooldownDuration;
		}

		// FVector2D CamInput = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);
		// FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		// UserComp.Spline1.MoveEnergyPulse(CamInput.Y * MoveSpeed, DeltaTime);
		// UserComp.Spline2.MoveEnergyPulse(MoveInput.Y * MoveSpeed, DeltaTime);
	}
}