// Should be placed before other target finding behaviours in compounds
class UIslandBeamTurretronFindPriorityTargetBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UIslandForceFieldBubbleComponent BubbleComp;
	
	AHazePlayerCharacter PlayerTarget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		BubbleComp = UIslandForceFieldBubbleComponent::Get(Owner);

		if (BubbleComp != nullptr && !BubbleComp.IsDepleted())
		{
			UpdateCurrentPlayerTarget();
		}

		BubbleComp.OnShieldBurst.AddUFunction(this, n"UpdateCurrentPlayerTarget");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		if(PlayerTarget == nullptr)
			return false;

		if (BubbleComp == nullptr || BubbleComp.IsDepleted())
			return false;
		
		// Keep target if one is already found
		if (TargetComp.HasValidTarget())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		if (PlayerTarget != nullptr)
			TargetComp.SetTarget(PlayerTarget);
	}

	UFUNCTION()
	void UpdateCurrentPlayerTarget()
	{
		EIslandForceFieldType CurrentType = BubbleComp.GetCurrentForceFieldType();
		if (CurrentType == EIslandForceFieldType::Red)
			PlayerTarget = Game::Mio;
		else if (CurrentType == EIslandForceFieldType::Blue)
			PlayerTarget = Game::Zoe;
		else
			PlayerTarget = nullptr; //TODO: take closest
	}
}