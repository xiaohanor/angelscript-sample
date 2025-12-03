struct FBombTossGrappleActivatedParams
{
	ABombToss_Bomb BombToss;
}

class UBombTossGrappleCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"BombTossGrapple");

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 85;

	UBombTossPlayerComponent BombTossPlayerComponent;
	UPlayerTargetablesComponent PlayerTargetablesComp;
	UPlayerAimingComponent AimComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BombTossPlayerComponent = UBombTossPlayerComponent::Get(Player);
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBombTossGrappleActivatedParams& Params) const
	{
		if(BombTossPlayerComponent.CurrentBombToss != nullptr)
			return false;

		if(BombTossPlayerComponent.CurrentGrapplingBombToss != nullptr)
			return false;

		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		auto Grapple = PlayerTargetablesComp.GetPrimaryTarget(UBombTossGrapplePointComponent);

		if(Grapple == nullptr)
			return false;

		auto BombToss = Cast<ABombToss_Bomb>(Grapple.Owner);
		if(BombToss == nullptr)
			return false;

		if(Time::GetGameTimeSince(BombToss.TimeOfLastChangeToIsThrown) < BombToss.CooldownToCatchAfterThrowing)
			return false;

		if(!BombTossPlayerComponent.ShouldGrappleTowardsEachOther(BombToss))
			return false;

		Params.BombToss = BombToss;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBombTossGrappleActivatedParams Params)
	{
		Params.BombToss.Launch((Player.ActorCenterLocation - Params.BombToss.ActorLocation).GetSafeNormal() * Params.BombToss.GrappleTowardsEachOtherBallImpulse);
		MoveComp.AddPendingImpulse((Params.BombToss.ActorLocation - Player.ActorCenterLocation).GetSafeNormal() * Params.BombToss.GrappleTowardsEachOtherPlayerImpulse);
		BombTossPlayerComponent.CurrentGrapplingBombToss = Params.BombToss;
	}
}