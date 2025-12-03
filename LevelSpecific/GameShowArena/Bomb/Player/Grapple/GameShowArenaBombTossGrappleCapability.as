struct FGameShowArenaBombTossGrappleActivatedParams
{
	AGameShowArenaBomb Bomb;
}

class UGameShowArenaBombTossGrappleCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"BombTossGrapple");

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 85;

	UGameShowArenaBombTossPlayerComponent BombTossPlayerComponent;
	UPlayerTargetablesComponent PlayerTargetablesComp;
	UPlayerAimingComponent AimComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BombTossPlayerComponent = UGameShowArenaBombTossPlayerComponent::Get(Player);
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGameShowArenaBombTossGrappleActivatedParams& Params) const
	{
		if (BombTossPlayerComponent.CurrentBomb != nullptr)
			return false;

		if (BombTossPlayerComponent.CurrentGrapplingBomb != nullptr)
			return false;

		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		auto Grapple = PlayerTargetablesComp.GetPrimaryTarget(UGameShowArenaBombTossGrapplePointComponent);
		if (Grapple == nullptr)
			return false;

		auto BombToss = Cast<AGameShowArenaBomb>(Grapple.Owner);
		if (BombToss == nullptr)
			return false;

		if (BombTossPlayerComponent.HasRecentlyThrownBomb())
			return false;

		// if (BombTossPlayerComponent.ShouldGrappleTowardsEachOther(BombToss))
		// 	return false;

		Params.Bomb = BombToss;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGameShowArenaBombTossGrappleActivatedParams Params)
	{
		//Params.Bomb.MovementComponent.AddPendingImpulse((Player.ActorCenterLocation - Params.Bomb.ActorLocation).GetSafeNormal() * BombTossPlayerComponent.GrappleToMeImpulse);
		BombTossPlayerComponent.CurrentGrapplingBomb = Params.Bomb;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BombTossPlayerComponent.CurrentGrapplingBomb = nullptr;
	}
}