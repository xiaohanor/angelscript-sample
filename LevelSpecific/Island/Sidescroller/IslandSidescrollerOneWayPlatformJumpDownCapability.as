class UIslandSidescrollerOneWayPlatformJumpDownCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	UIslandSidescrollerComponent SidescrollerComp;
	UPlayerMovementComponent MoveComp;

	const float JumpInputGraceTime = 0.1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SidescrollerComp = UIslandSidescrollerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandSidescrollerOneWayPlatformJumpDownActivatedParams& Params) const
	{
		if(!SidescrollerComp.IsInSidescrollerMode())
			return false;

		if(!MoveComp.GroundContact.bBlockingHit)
			return false;

		FVector2D MovementInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		if(Math::Abs(MovementInput.X) < 0.2)
			return false;

		if(GetAttributeVector2D(AttributeVectorNames::MovementRaw).X > 0.0)
			return false;

		if(!WasActionStartedDuringTime(ActionNames::MovementJump, JumpInputGraceTime))
			return false;

		auto Platform = Cast<AIslandSidescrollerOneWayPlatform>(MoveComp.GroundContact.Actor);

		if(Platform == nullptr)
			return false;

		Params.Platform = Platform;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration < 0.1)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandSidescrollerOneWayPlatformJumpDownActivatedParams Params)
	{
		MoveComp.AddMovementIgnoresActor(this, Params.Platform);
		MoveComp.ClearCurrentGroundedState();
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.RemoveMovementIgnoresActor(this);
	}
}

struct FIslandSidescrollerOneWayPlatformJumpDownActivatedParams
{
	AIslandSidescrollerOneWayPlatform Platform;
}