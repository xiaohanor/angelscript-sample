
class UTeenDragonTailBombCapability : UInteractionCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonRollComponent RollComp;
	UTeenDragonTailBombCarrierComponent BombCarrierComponent;
	bool bHasThrowBomb = false; 

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params) override
	{	
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		BombCarrierComponent = UTeenDragonTailBombCarrierComponent::GetOrCreate(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);

		auto ActiveTailBombInteractionComponent = Cast<UTeenDragonTailBombPickupComponent>(Params.Interaction);

		BombCarrierComponent.ActiveTailBomb = Cast<AHazeActor>(ActiveTailBombInteractionComponent.GetOwner());
		BombCarrierComponent.ActiveTailBomb.AttachToComponent(DragonComp.DragonMesh, n"Tail10");

		// Handle the throw component
		auto BombComp = UTeenDragonTailBombComponent::Get(BombCarrierComponent.ActiveTailBomb);
		if(BombComp != nullptr)
		{	
			BombComp.PickUp();
		}

		Super::OnActivated(Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated() override
	{	
		if(BombCarrierComponent.ActiveTailBomb != nullptr)
		{
			BombCarrierComponent.ActiveTailBomb.DetachRootComponentFromParent();

			// Handle the throw component
			auto BombComp = UTeenDragonTailBombComponent::Get(BombCarrierComponent.ActiveTailBomb);
			if(BombComp != nullptr)
			{	
				// Throw the bomb away
				if(bHasThrowBomb)
					BombComp.Throw(Player.GetActorForwardVector(), BombComp.ThrowAmount);
				else
					BombComp.Drop(Player.GetActorForwardVector());
			}

			bHasThrowBomb = false;
			BombCarrierComponent.ActiveTailBomb = nullptr;
		}

		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(RollComp.IsRolling())
		{
			bHasThrowBomb = true;
			LeaveInteraction();
		}
	}
};