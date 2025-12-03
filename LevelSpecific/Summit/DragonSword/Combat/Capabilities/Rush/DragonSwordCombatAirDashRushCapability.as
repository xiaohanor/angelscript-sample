class UDragonSwordCombatAirDashRushCapability : UHazePlayerCapability
{
	// default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	// default CapabilityTags.Add(CapabilityTags::GameplayAction);

	// default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSword);
	
	// default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordCombat);
	// default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordRush);
	// default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordDashRush);

	// default DebugCategory = SummitDebugCapabilityTags::DragonSword;

	// default TickGroup = EHazeTickGroup::ActionMovement;
	// default TickGroupOrder = 85;
	// default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 30);

	// float TimeForAnimationToHit;
	// float TimeToReachTarget;

	// UDragonSwordCombatUserComponent CombatComp;
	// UDragonSwordUserComponent SwordComp;
	// UPlayerTargetablesComponent TargetablesComp;
	// UPlayerMovementComponent MoveComp;
	// USweepingMovementData Movement;

	// FRotator StartRotation;
	// FVector StartLocation;
	// bool bAttack = false;
	// float AttackStartTime = 0;

	// FVector TargetLocation;
	// FRotator TargetRotation;

	// UFUNCTION(BlueprintOverride)
	// void Setup()
	// {
	// 	CombatComp = UDragonSwordCombatUserComponent::Get(Owner);
	// 	SwordComp = UDragonSwordUserComponent::Get(Owner);
		
	// 	TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
	// 	MoveComp = UPlayerMovementComponent::Get(Owner);
	// 	Movement = MoveComp.SetupSweepingMovementData();
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldActivate() const
	// {
	// 	if (!CombatComp.CanStartNewAttack())
	// 		return false;

	// 	if(CombatComp.PendingAttackData.AttackType != EDragonSwordCombatAttackType::DashRush)
	// 		return false;

	// 	if(!MoveComp.IsInAir())
	// 		return false;

	// 	return true;
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldDeactivate() const
	// {
	// 	if (!CombatComp.IsActiveAttackType(EDragonSwordCombatAttackType::DashRush))
	// 		return true;

	// 	if(bAttack)
	// 	{
	// 		float TimeSinceAttackStart = Time::GetGameTimeSince(AttackStartTime);
	// 		if (TimeSinceAttackStart > CombatComp.ActiveAttackData.AnimationData.AttackMetaData.Duration)
	// 			return true;
	// 	}

	// 	if (CombatComp.HasPendingAttack())
	// 	{
	// 		if (CombatComp.bInsideComboWindow)
	// 			return true;
	// 	}

	// 	if(CombatComp.bInsideSettleWindow && CombatComp.ShouldExitSettle())
	// 		return true;
		
	// 	return false;
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnActivated()
	// {
	// 	CombatComp.SetActiveAttackData(CombatComp.PendingAttackData, this);

	// 	if(HasControl())
	// 	{
	// 		bAttack = false;
	// 	}

	// 	StartLocation = Player.ActorCenterLocation;
	// 	StartRotation = Player.ActorRotation;

	// 	UAnimSequence AnimationSequence = CombatComp.ActiveAttackData.AnimationData.AnimationWithMetaData.Animation.Sequence;
	// 	TimeForAnimationToHit = AnimationSequence.GetAnimNotifyStateStartTime(UAnimNotifyDragonSwordHitWindow);

	// 	DragonSwordCombatRush::CalculateTargetLocationAndRotation(
	// 		true,
	// 		Player,
	// 		CombatComp.ActiveAttackData.Target,
	// 		StartLocation,
	// 		TargetLocation,
	// 		TargetRotation
	// 	);

	// 	TimeToReachTarget = StartLocation.Distance(TargetLocation) / DragonSwordCombat::RushSpeed;

	// 	FDragonSwordCombatStartRushEventData EventData;
	// 	EventData.StartLocation = StartLocation;
	// 	EventData.EndLocation = TargetLocation;
	// 	EventData.TimeForAnimationToHit = TimeForAnimationToHit;
	// 	UDragonSwordCombatEventHandler::Trigger_StartRush(SwordComp.Weapon, EventData);

	// 	Player.BlockCapabilities(DragonSwordCapabilityTags::DragonSwordAttack, this);
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnDeactivated()
	// {
	// 	if(CombatComp.HasActiveAttack() && CombatComp.ActiveAttackInstigator == this)
	// 		CombatComp.StopActiveAttackData(this);

	// 	if(SwordComp.Weapon != nullptr)
	// 		UDragonSwordCombatEventHandler::Trigger_StopRush(SwordComp.Weapon);

	// 	Player.UnblockCapabilities(DragonSwordCapabilityTags::DragonSwordAttack, this);
	// }

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// 	DragonSwordCombatRush::CalculateTargetLocationAndRotation(
	// 		true,
	// 		Player,
	// 		CombatComp.ActiveAttackData.Target,
	// 		StartLocation,
	// 		TargetLocation,
	// 		TargetRotation
	// 	);

	// 	const float DistanceToTarget = Player.ActorCenterLocation.Distance(TargetLocation);
	// 	const float TimeToTarget = DistanceToTarget / AdjustedRushSpeed();

	// 	float Alpha = Math::Saturate(ActiveDuration / TimeToReachTarget);
	// 	Alpha = Math::EaseIn(0, 1, Alpha, 2);

	// 	CombatComp.AnimData.RushAlpha = Alpha;

	// 	if (MoveComp.PrepareMove(Movement))
	// 	{
	// 		if(HasControl())
	// 		{
	// 			const FVector NewLocation = Math::Lerp(Player.ActorCenterLocation, TargetLocation, Alpha);
	// 			const FRotator NewRotation = Math::LerpShortestPath(Player.ActorRotation, TargetRotation, Alpha);

	// 			const FVector Delta = NewLocation - Player.ActorCenterLocation;

	// 			Movement.AddDelta(Delta);
	// 			Movement.SetRotation(NewRotation);
	// 		}
	// 		else
	// 		{
	// 			Movement.ApplyCrumbSyncedAirMovement();
	// 		}
			
	// 		MoveComp.ApplyMoveAndRequestLocomotion(Movement, DragonSwordCombat::Feature);
	// 	}

	// 	if(HasControl())
	// 	{
	// 		if(TimeToTarget < TimeForAnimationToHit && !bAttack)
	// 		{
	// 			bAttack = true;
	// 			AttackStartTime = Time::GameTimeSeconds;

	// 			CombatComp.CrumbStartAttackAnimation();
	// 		}

	// 		if (bAttack && CombatComp.bInsideHitWindow)
	// 			CombatComp.TryAttack();

	// #if EDITOR
	// 		//DragonSwordCombatRush::DebugDraw(StartLocation, TargetLocation, AdjustedRushSpeed(), TimeForAnimationToHit);
	// #endif
	// 	}
	// }

	// private float AdjustedRushSpeed() const
	// {
	// 	return DragonSwordCombat::RushSpeed * 2;
	// }
}