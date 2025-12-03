class UGravityBladeCombatGrappleAttackActivationCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(GravityBladeTags::GravityBlade);
	
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeCombat);
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeAttackActivation);

	default DebugCategory = GravityBlade::DebugCategory;

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 110;

	UGravityBladeCombatUserComponent CombatComp;
	UGravityBladeGrappleUserComponent GrappleComp;
	UGravityBladeUserComponent BladeComp;
	UPlayerTargetablesComponent TargetablesComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CombatComp = UGravityBladeCombatUserComponent::Get(Owner);
		GrappleComp = UGravityBladeGrappleUserComponent::Get(Owner);
		BladeComp = UGravityBladeUserComponent::Get(Owner);
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBladeCombatAttackData& PendingAttackData) const
	{
		if(!BladeComp.IsBladeEquipped())
			return false;

		if(CombatComp.HasPendingAttack())
			return false;

		if(CombatComp.HasActiveAttack() && !CombatComp.bInsideSettleWindow)
			return false;

		if(!WasActionStarted(ActionNames::SecondaryLevelAbility))
			return false;

		if (!GrappleComp.AimGrappleData.IsValid())
			return false;

		if (!GrappleComp.AimGrappleData.bIsCombatGrapple)
			return false;

		float HeightDifference = (Player.ActorLocation - GrappleComp.AimGrappleData.Actor.ActorLocation).DotProduct(MoveComp.WorldUp);

		EGravityBladeAttackMovementType MovementType;
		EGravityBladeAttackAnimationType AnimationType;
		if (GrappleComp.AimGrappleData.bAlwaysAirGrapple)
		{
			MovementType = EGravityBladeAttackMovementType::AirRush;
			AnimationType = EGravityBladeAttackAnimationType::AirRushAttack;
		}
		else if (MoveComp.IsOnWalkableGround() && Math::Abs(HeightDifference) < 30)
		{
			MovementType = EGravityBladeAttackMovementType::GroundRush;
			AnimationType = EGravityBladeAttackAnimationType::GroundRushAttack;
		}
		else
		{
			MovementType = EGravityBladeAttackMovementType::AirRush;
			AnimationType = EGravityBladeAttackAnimationType::AirRushAttack;
		}

		UGravityBladeCombatTargetComponent Target = UGravityBladeCombatTargetComponent::Get(GrappleComp.AimGrappleData.Actor);
		if (Target == nullptr)
			return false;

		// This is the first attack
		int SequenceIndex = CombatComp.GetNextSequenceIndexForType(AnimationType);

		FGravityBladeCombatAttackAnimationData AttackAnimation;
		const bool bHasTarget = true;

		CombatComp.GetAttackAnimationData(AnimationType, SequenceIndex, 0, AttackAnimation);
		PendingAttackData = FGravityBladeCombatAttackData(MovementType, AnimationType, Target, AttackAnimation);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBladeCombatAttackData PendingAttackData)
	{
		if (GrappleComp.TargetWidget != nullptr)
			GrappleComp.TargetWidget.BP_OnActivationAnimation();
		CombatComp.SetPendingAttackData(PendingAttackData);
		CombatComp.PrimaryHoldStartTime = 0;
		CombatComp.PrimaryHoldEndTime = 0;
		PendingAttackData.Target.OnCombatGrappleActivation.Broadcast();
		GrappleComp.OnActivation.Broadcast();
	}
}
