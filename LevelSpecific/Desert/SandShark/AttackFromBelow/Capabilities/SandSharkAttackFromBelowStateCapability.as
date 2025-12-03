class USandSharkAttackFromBelowStateCapability : UHazeCapability
{
	// default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	// default CapabilityTags.Add(SandSharkTags::SandShark);
	// default CapabilityTags.Add(SandSharkTags::SandSharkAttackFromBelow);

	// default CapabilityTags.Add(SandSharkBlockedWhileIn::AttackLunge);
	// default CapabilityTags.Add(SandSharkBlockedWhileIn::Distract);

	// default TickGroup = EHazeTickGroup::BeforeMovement;
	// default TickGroupOrder = SandShark::TickGroupOrder::AttackFromBelow;
	// default TickGroupSubPlacement = 0;

	// ASandShark SandShark;
	// USandSharkAttackFromBelowComponent AttackFromBelowComp;
	// USandSharkMovementComponent MoveComp;

	// USandSharkSettings Settings;

	// UFUNCTION(BlueprintOverride)
	// void Setup()
	// {
	// 	SandShark = Cast<ASandShark>(Owner);
	// 	AttackFromBelowComp = USandSharkAttackFromBelowComponent::Get(Owner);
	// 	MoveComp = USandSharkMovementComponent::Get(Owner);
	// 	Settings = USandSharkSettings::GetSettings(Owner);
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldActivate() const
	// {
	// 	if (!SandShark.bCanAttack)
	// 		return false;

	// 	if (!AttackFromBelowComp.IsTargetPlayerAttackable())
	// 		return false;

	// 	// Distance based activation
	// 	auto SharkHeadLocation = SandShark.HeadLocation;
	// 	if (SharkHeadLocation.Dist2D(SandShark.GetTargetPlayerLocationOnLandscape()) > SandShark.AttackFromBelowValues.AttackWhenWithinDistance)
	// 		return false;

	// 	float PlayerHeightAboveSand = SandShark.GetTargetPlayer().ActorLocation.Z - Desert::GetLandscapeHeightByLevel(SandShark.GetTargetPlayer().ActorLocation, SandShark.LandscapeLevel);
	// 	if (PlayerHeightAboveSand > SandShark.AttackFromBelowValues.MaxHeightAboveSand)
	// 		return false;

	// 	return false;
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldDeactivate() const
	// {
	// 	if (AttackFromBelowComp.State == ESandSharkAttackFromBelowState::None)
	// 		return true;

	// 	if (AttackFromBelowComp.State != ESandSharkAttackFromBelowState::Jump)
	// 	{
	// 		if (!AttackFromBelowComp.IsTargetPlayerAttackable())
	// 			return true;
	// 	}

	// 	return false;
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnActivated()
	// {
	// 	AttackFromBelowComp.bIsAttackingFromBelow = true;
	// 	AttackFromBelowComp.State = ESandSharkAttackFromBelowState::None;

	// 	SandShark.BlockCapabilities(SandSharkBlockedWhileIn::Attack, this);
	// 	SandShark.BlockCapabilities(SandSharkBlockedWhileIn::AttackFromBelow, this);
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnDeactivated()
	// {
	// 	AttackFromBelowComp.bIsAttackingFromBelow = false;
	// 	AttackFromBelowComp.State = ESandSharkAttackFromBelowState::None;
	// 	AttackFromBelowComp.LastAttackFromBelowTime = Time::GameTimeSeconds;

	// 	SandShark.UnblockCapabilities(SandSharkBlockedWhileIn::Attack, this);
	// 	SandShark.UnblockCapabilities(SandSharkBlockedWhileIn::AttackFromBelow, this);
	// }
};