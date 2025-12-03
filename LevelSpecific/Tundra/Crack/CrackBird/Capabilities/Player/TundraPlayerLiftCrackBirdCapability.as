struct FTundraCrackBirdLiftBirdActivationParams
{
	ABigCrackBird Bird;
	bool bIsEgg = false;
}

class UTundraPlayerLiftCrackBirdCapability : UTundraPlayerCrackBirdBaseCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 99;

	float BeginPickupDuration = 2;
	float FullPickupDuration = 2.2;
	bool bHasPickedUpBird = false;
	bool bIsCarryingEgg = false;


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraCrackBirdLiftBirdActivationParams& ActivationParams) const
	{
		if(CarryComp.GetCurrentState() != ETundraPlayerCrackBirdState::PickingUp)
			return false;

		if(GetBird() == nullptr)
		{
			devError("Current state is picking up bird but bird is null");
			return false;
		}

		ActivationParams.bIsEgg = GetBird().bIsEgg;
		ActivationParams.Bird = CarryComp.CurrentBird;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > FullPickupDuration)
			return true;

		if(CarryComp.GetBird().InteractingPlayer != Player)
			return true;

		if(CarryComp.GetCurrentState() != ETundraPlayerCrackBirdState::PickingUp)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraCrackBirdLiftBirdActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		
		if(CarryComp.GetBird() == nullptr)
		{
			CarryComp.ForceSetBird(ActivationParams.Bird);
		}
		if(CarryComp.CurrentBird.bIsLaunched)
		{
			CarryComp.CurrentBird.bNetWasForcedAttach = true;
		}

		bHasPickedUpBird = false;
		bIsCarryingEgg = ActivationParams.bIsEgg;

		if(Player.IsMio())
			BeginPickupDuration = 0.3;
		else
			BeginPickupDuration = 1;

		if(ActivationParams.bIsEgg)
		{
			for(auto Bird : TListedActors<ABigCrackBird>().Array)
			{
				Bird.bEggPickedUp = true;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(!bHasPickedUpBird)
		{
			CarryComp.AttachBird();
		}

		Player.UnblockCapabilities(CapabilityTags::Movement, this);

		if(CarryComp.GetBird() != nullptr && CarryComp.GetBird().InteractingPlayer == Player)
			CarryComp.FinishPickingUpBird();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bHasPickedUpBird)
		{
			if(ActiveDuration >= BeginPickupDuration)
			{
				CarryComp.AttachBird();
				bHasPickedUpBird = true;
			}
		}

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