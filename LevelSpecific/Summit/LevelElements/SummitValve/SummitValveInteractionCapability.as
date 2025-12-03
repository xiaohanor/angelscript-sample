class USummitValveInteractionCapability : UInteractionCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;


	//UPlayerTailTeenDragonComponent DragonComp;
	//ATeenDragon TeenDragon;
	//UHazeMovementComponent MoveComp;
	ASummitValve Valve;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		//DragonComp = UPlayerTailTeenDragonComponent::Get(Owner);
		//MoveComp = UHazeMovementComponent::Get(Player);
		Valve = Cast<ASummitValve>(Params.Interaction.Owner);
		//MoveComp = TeenDragon.MovementComponent;
		//TeenDragon = DragonComp.TeenDragon;

		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);
		Player.SmoothTeleportActor(Valve.InteractComp.WorldLocation, Valve.InteractComp.WorldRotation, this, 0.8);
		Player.AttachToComponent(Valve.InteractComp, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);

		//Add an action button that spins the valve when pressed
		//
		//
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Player.UnblockCapabilities(CapabilityTags::Movement, this);

	}

};