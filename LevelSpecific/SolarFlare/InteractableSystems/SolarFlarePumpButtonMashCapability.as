class USolarFlarePumpButtonMashCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 150;

	UButtonMashComponent ButtonMashComp;
	ASolarFlarePumpInteraction Pump;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);
		Pump = Cast<ASolarFlarePumpInteraction>(ActiveInteraction.Owner); 
		ButtonMashComp = UButtonMashComponent::GetOrCreate(Player);
		Pump.ButtonMashComp = ButtonMashComp;
		FButtonMashSettings Settings;
		// Settings.Difficulty = EButtonMashDifficulty::Easy;
		Settings.Difficulty = EButtonMashDifficulty::Medium;
		ButtonMashComp.StartButtonMash(Settings, Pump, FOnButtonMashCompleted(), FOnButtonMashCompleted(), EDoubleButtonMashType::None);
		Player.SetButtonMashAllowCompletion(Pump, false);

		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		ButtonMashComp.StopButtonMash(Pump, true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Run from control side
		// if (HasControl())
		
		Pump.OnButtonMashApplied.Broadcast(ButtonMashComp.GetButtonMashProgress(Pump));
	}
}