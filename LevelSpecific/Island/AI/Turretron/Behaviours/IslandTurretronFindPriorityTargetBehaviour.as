// Should be placed before other target finding behaviours in compounds
class UIslandTurretronFindPriorityTargetBehaviour : UBasicBehaviour
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

		if (PlayerTarget.IsPlayerDeadOrRespawning())
			return false;

		if (BubbleComp == nullptr || BubbleComp.IsDepleted())
			return false;

		if (TargetComp.Target == PlayerTarget)
			return false;
		
		if (!PerceptionComp.Sight.VisibilityExists(Owner, PlayerTarget, CollisionChannel = ECollisionChannel::WeaponTraceEnemy))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		if (PlayerTarget.IsPlayerDeadOrRespawning())
			return true;
		if (!PerceptionComp.Sight.VisibilityExists(Owner, PlayerTarget, CollisionChannel = ECollisionChannel::WeaponTraceEnemy))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		TargetComp.SetTarget(PlayerTarget);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
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
			PlayerTarget = nullptr;
	}
}