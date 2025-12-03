struct FTundraPlayerCarryingCrackBirdDeactivateParams
{
	bool bBirdIsDead;
};

class UTundraPlayerCarryingCrackBirdCapability : UTundraPlayerCrackBirdBaseCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;
	bool bIsCarryingEgg = false;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraCrackBirdLiftBirdActivationParams& ActivationParams) const
	{
		if(CarryComp.GetCurrentState() != ETundraPlayerCrackBirdState::Carrying)
			return false;

		if(GetBird() == nullptr)
		{
			devError("Current state is carrying bird but bird is null");
			return false;
		}

		ActivationParams.bIsEgg = GetBird().bIsEgg;
		ActivationParams.Bird = CarryComp.CurrentBird;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTundraPlayerCarryingCrackBirdDeactivateParams& Params) const
	{
		if(CarryComp.GetCurrentState() != ETundraPlayerCrackBirdState::Carrying)
			return true;

		if(CarryComp.GetBird() == nullptr)
		{
			devError("Current state is carrying bird but bird is null");
			return true;
		}

		if(CarryComp.GetBird().IsDead())
		{
			Params.bBirdIsDead = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraCrackBirdLiftBirdActivationParams ActivationParams)
	{
		if(CarryComp.CurrentBird == nullptr)
		{
			CarryComp.ForceSetBird(ActivationParams.Bird);
		}
		if(CarryComp.CurrentBird.bIsLaunched)
		{
			CarryComp.CurrentBird.bNetWasForcedAttach = true;
		}

		bIsCarryingEgg = ActivationParams.bIsEgg;

		if(Player.IsZoe())
		{
			Player.BlockCapabilities(PlayerFloorMotionTags::FloorMotionTurnAround, this);
			UTundraPlayerTreeGuardianSettings::SetMaximumSpeed(Player, 700, this);
		}
		else
			UTundraPlayerSnowMonkeySettings::SetMaximumSpeed(Player, 700, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundraPlayerCarryingCrackBirdDeactivateParams Params)
	{
		if(Player.IsZoe())
		{
			Player.UnblockCapabilities(PlayerFloorMotionTags::FloorMotionTurnAround, this);
			UTundraPlayerTreeGuardianSettings::ClearMaximumSpeed(Player, this);
		}
		else
			UTundraPlayerSnowMonkeySettings::ClearMaximumSpeed(Player, this);

		if(Params.bBirdIsDead)
		{
			CarryComp.CancelOnBirdDead();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Player.Mesh.CanRequestLocomotion())
		{
			if(bIsCarryingEgg)
			{
				Player.Mesh.RequestLocomotion(n"PickUpBirdEgg", this);
			}
			else
			{
				Player.Mesh.RequestLocomotion(n"PickUpBird", this);
			}
		}
	}
};