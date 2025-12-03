struct FBombTossGrappleToMeActivatedParams
{
	ABombToss_Bomb BombToss;
}

class UBombTossGrappleToMeCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"BombTossGrapple");

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 85;

	UBombTossPlayerComponent BombTossPlayerComponent;
	UPlayerTargetablesComponent PlayerTargetablesComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BombTossPlayerComponent = UBombTossPlayerComponent::Get(Player);
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBombTossGrappleToMeActivatedParams& Params) const
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

		if(BombTossPlayerComponent.ShouldGrappleTowardsEachOther(BombToss))
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
	void OnActivated(FBombTossGrappleToMeActivatedParams Params)
	{
		Params.BombToss.Launch((Player.ActorCenterLocation - Params.BombToss.ActorLocation).GetSafeNormal() * Params.BombToss.GrappleToMeImpulse);
		BombTossPlayerComponent.CurrentGrapplingBombToss = Params.BombToss;
	}
}