struct FCongaLineStrikePoseActivateParams
{
	int Measure;
}


class UCongaLineStrikePoseInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CongaLine::Tags::CongaLine);
	default CapabilityTags.Add(CongaLine::Tags::CongaLineStrikePose);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	ACongaLineManager Manager;
	UCongaLineStrikePoseComponent StrikePoseComp;
	UPlayerTargetablesComponent TargetableComp;
	UCongaLinePlayerComponent PlayerComp;

	int PoseMeasure = -1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = CongaLine::GetManager();
		StrikePoseComp = UCongaLineStrikePoseComponent::Get(Player);
		TargetableComp = UPlayerTargetablesComponent::Get(Player);
		PlayerComp = UCongaLinePlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCongaLineStrikePoseActivateParams& Params) const
	{
		if(!StrikePoseComp.bActive)
			return false;

		if(PoseMeasure == Manager.GetCurrentMeasure())
			return false;

		Params.Measure = Manager.GetCurrentMeasure();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!StrikePoseComp.bActive)
		{
			return true;
		}

		
		const ECongaLineStrikePose Input = GetInput();

		if(Input == ECongaLineStrikePose::None)
			return false;

		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCongaLineStrikePoseActivateParams Params)
	{
		PoseMeasure = Params.Measure;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// if(WasActionStarted(ActionNames::Interaction) && StrikePoseComp.CanPose())
		// {
		// 	StrikePoseComp.StrikeNewPose();

		// 	TArray<UTargetableComponent> Monkeys;
		// 	TargetableComp.GetVisibleTargetables(UCongaLineMonkeyTargetableComponent, Monkeys);
		// 	if(!Monkeys.IsEmpty())
		// 	{
		// 		PlayerComp.PlayMonkeyCollectedRumble();
		// 		for(int i = 0; i < Monkeys.Num(); i++)
		// 		{
		// 			Cast<UCongaLineMonkeyTargetableComponent>(Monkeys[i]).DancerComp.CurrentLeader = PlayerComp;
		// 		}
		// 	}
		// }
	}

	ECongaLineStrikePose GetInput() const
	{
		// if(Player.IsUsingGamepad())
		// {
		// 	if(WasActionStarted(ActionNames::Interaction))
		// 		return ECongaLineStrikePoseInput::Up;

		// 	if(WasActionStarted(ActionNames::MovementJump))
		// 		return ECongaLineStrikePoseInput::Down;

		// 	if(WasActionStarted(ActionNames::MovementDash))
		// 		return ECongaLineStrikePoseInput::Left;

		// 	if(WasActionStarted(ActionNames::Cancel))
		// 		return ECongaLineStrikePoseInput::Right;
		// }
		// else
		// {
		// 	// FB TODO: Keyboard bindings for WASD

		// 	if(WasActionStarted(ActionNames::UI_Up))
		// 		return ECongaLineStrikePoseInput::Up;

		// 	if(WasActionStarted(ActionNames::UI_Down))
		// 		return ECongaLineStrikePoseInput::Down;

		// 	if(WasActionStarted(ActionNames::UI_Left))
		// 		return ECongaLineStrikePoseInput::Left;

		// 	if(WasActionStarted(ActionNames::UI_Right))
		// 		return ECongaLineStrikePoseInput::Right;
		// }

		 return ECongaLineStrikePose::None;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		//TargetableComp.ShowWidgetsForTargetables(UCongaLineMonkeyTargetableComponent);
	}
};