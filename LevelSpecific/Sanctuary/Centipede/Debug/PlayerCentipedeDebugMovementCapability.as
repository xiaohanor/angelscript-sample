#if !RELEASE
class UPlayerCentipedeDebugMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	UPlayerCentipedeDebugMovementComponent DebugMovementComponent;
	UPlayerMovementComponent MovementComponent;

	UHazeCrumbSyncedVector2DComponent CrumbedRightStick;

	// Used for networking
	bool bSecondaryBiteActionStarted;
	bool bSecondaryBiteActioning;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DebugMovementComponent = UPlayerCentipedeDebugMovementComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);

		CrumbedRightStick = UHazeCrumbSyncedVector2DComponent::GetOrCreate(Player, n"CentipedeDebugInputRightStick");
		CrumbedRightStick.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DebugMovementComponent == nullptr)
			return false;

		if (!DebugMovementComponent.IsActive())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!DebugMovementComponent.IsActive())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsActioning(ActionNames::MovementSprint))
		{
			if (WasActionStarted(ActionNames::CenterView))
			{
				if (DebugMovementComponent.IsPrimary())
					NetSetDebugMovementActive(false);
				else
					NetSetDebugMovementActive(true);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (DebugMovementComponent.IsPrimary())
		{
			// Network stuff
			if (HasControl())
			{
				// Send right stick
				FVector2D RawInput = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);
				CrumbedRightStick.SetValue(FVector2D(RawInput.Y, RawInput.X).GetClampedToMaxSize(1.0));

				// Sync jaw
				NetSetActionStates(WasActionStarted(ActionNames::PrimaryLevelAbility), IsActioning(ActionNames::PrimaryLevelAbility));
			}

			DebugMovementComponent.PrimaryMovementInput = MovementComponent.MovementInput;
			DebugMovementComponent.bPrimaryBiteActionStarted = WasActionStarted(ActionNames::SecondaryLevelAbility);
			DebugMovementComponent.bPrimaryBiteActioning = IsActioning(ActionNames::SecondaryLevelAbility);

			DebugMovementComponent.SecondaryMovementInput = Centipede::GetPlayerHeadMovementInput(Player.OtherPlayer, CrumbedRightStick.Value);
			DebugMovementComponent.bSecondaryBiteActionStarted = bSecondaryBiteActionStarted;
			DebugMovementComponent.bSecondaryBiteActioning = bSecondaryBiteActioning;

			Debug::DrawDebugString(Player.ActorCenterLocation, "Left");
		}
		else
		{
			Debug::DrawDebugString(Player.ActorCenterLocation, "Right");
		}
	}

	UFUNCTION(NetFunction)
	void NetSetDebugMovementActive(bool bValue)
	{
		if (bValue)
			DebugMovementComponent.Activate();
		else
			DebugMovementComponent.Deactivate();
	}

	UFUNCTION(NetFunction)
	void NetSetActionStates(bool bSecondaryStarted, bool bSecondaryActioning)
	{
		bSecondaryBiteActionStarted = bSecondaryStarted;
		bSecondaryBiteActioning = bSecondaryActioning;
	}
}
#endif