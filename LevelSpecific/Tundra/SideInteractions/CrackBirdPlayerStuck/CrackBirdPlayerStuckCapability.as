struct FCrackBirdPlayerStuckDeactivateParams
{
	bool bIsBirdOnFloor = false;
};

class UCrackBirdPlayerStuckCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UCrackBirdPlayerStuckComponent StuckComp;
	UTundraPlayerShapeshiftingComponent ShapeShiftComp;
	UTundraPlayerShapeshiftingIgnoreCollisionContainerComponent IgnoreCollisionContainerComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StuckComp = UCrackBirdPlayerStuckComponent::Get(Player);
		ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		IgnoreCollisionContainerComp = UTundraPlayerShapeshiftingIgnoreCollisionContainerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!StuckComp.IsStuckInBird())
			return false;

		if(Player.IsMio())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FCrackBirdPlayerStuckDeactivateParams& Params) const
	{
		if(!ShapeShiftComp.IsSmallShape())
		{
			Params.bIsBirdOnFloor = IsBirdOnFloor();
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(CapabilityTags::Visibility, this);

		IgnoreCollisionContainerComp.ActorsToIgnore.Add(StuckComp.StuckInBird);

		Player.AttachToActor(StuckComp.StuckInBird);

		FCrackBirdPlayerStuckOnBecomeStuckInBirdEventData EventData;
		EventData.CrackBird = StuckComp.StuckInBird;
		UCrackBirdPlayerStuckEventHandler::Trigger_OnBecomeStuckInBird(Player, EventData);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCrackBirdPlayerStuckDeactivateParams Params)
	{
		Player.DetachFromActor();

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(CapabilityTags::Visibility, this);

		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Big);
		IgnoreCollisionContainerComp.ActorsToIgnore.RemoveSingleSwap(StuckComp.StuckInBird);

		FCrackBirdPlayerStuckOnExplodeBirdEventData EventData;
		EventData.CrackBird = StuckComp.StuckInBird;
		UCrackBirdPlayerStuckEventHandler::Trigger_OnExplodeBird(Player, EventData);

		StuckComp.ExplodeBird();

		if(Params.bIsBirdOnFloor)
		{
			// Place us on the nest floor
			MoveComp.SnapToGround(true, 500);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Make sure the player is in the center of the bird
		Player.SetActorLocation(StuckComp.StuckInBird.ActorCenterLocation);
	}

	bool IsBirdOnFloor() const
	{
		if(StuckComp.StuckInBird == nullptr)
			return false;

		switch(StuckComp.StuckInBird.GetState())
		{
			case ETundraCrackBirdState::InNest:
				return true;
			case ETundraCrackBirdState::PickupStarted:
				return true;
			case ETundraCrackBirdState::PickedUp:
				return false;
			case ETundraCrackBirdState::PuttingDown:
				return false;
			case ETundraCrackBirdState::Launched:
				return false;
			case ETundraCrackBirdState::Hover:
				return false;
			case ETundraCrackBirdState::HitByLog:
				return false;
			case ETundraCrackBirdState::HitWall:
				return true;
			case ETundraCrackBirdState::RunningAway:
				return true;
			case ETundraCrackBirdState::Dead:
				return false;
		}
	}
};