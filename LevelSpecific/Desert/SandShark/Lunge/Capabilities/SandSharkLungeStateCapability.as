class USandSharkLungeStateCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(SandSharkTags::SandShark);
	default CapabilityTags.Add(SandSharkTags::SandSharkLunge);

	default CapabilityTags.Add(SandSharkBlockedWhileIn::AttackFromBelow);
	default CapabilityTags.Add(SandSharkBlockedWhileIn::Distract);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = SandShark::TickGroupOrder::Lunge;

	USandSharkMovementComponent MoveComp;
	USandSharkChaseComponent ChaseComp;
	USandSharkLungeComponent LungeComp;
	ASandShark SandShark;

	USandSharkSettings SharkSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SandShark = Cast<ASandShark>(Owner);
		MoveComp = USandSharkMovementComponent::Get(Owner);
		ChaseComp = USandSharkChaseComponent::Get(Owner);
		LungeComp = USandSharkLungeComponent::Get(Owner);
		SharkSettings = USandSharkSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SandShark.HasTargetPlayer())
			return false;

		if (!SandShark.IsTargetPlayerAttackable())
			return false;

		if (!SandShark.CheckPlayerInsideTerritory(SandShark.GetTargetPlayer()))
			return false;

		auto PlayerComp = USandSharkPlayerComponent::Get(SandShark.GetTargetPlayer());
		if (!PlayerComp.bHasTouchedSand)
			return false;

		float DistSq = SandShark.ActorCenterLocation.DistSquared2D(SandShark.GetTargetPlayer().ActorLocation);
		float ActivationRange = SandShark.SphereComp.SphereRadius + 350;

		auto LungeZoneComp = USandSharkPlayerLungeZoneComponent::Get(SandShark.GetTargetPlayer());
		if (LungeZoneComp.IsPlayerHeadedToZoneSafety())
		{
			ActivationRange += 250;
		}
		//Debug::DrawDebugSphere(SandShark.ActorLocation, ActivationRange, Duration = 1);

		float TriggerDistSq = ActivationRange * ActivationRange;

		if (DistSq > TriggerDistSq)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!LungeComp.bIsLunging)
			return true;

		if (LungeComp.bTargetBecameUnattackable)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.AccDive.SnapTo(0);
		LungeComp.bIsLunging = true;
		SandShark.BlockChase(this);
		SandShark.BlockCapabilities(SandSharkBlockedWhileIn::Attack, this);
		SandShark.BlockCapabilities(SandSharkBlockedWhileIn::AttackLunge, this);

		LungeComp.bTargetBecameUnattackable = false;

		LungeComp.State = ESandSharkLungeState::None;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SandShark.UnblockChase(this);
		SandShark.UnblockCapabilities(SandSharkBlockedWhileIn::Attack, this);
		SandShark.UnblockCapabilities(SandSharkBlockedWhileIn::AttackLunge, this);

		LungeComp.bIsLunging = false;
	}
};