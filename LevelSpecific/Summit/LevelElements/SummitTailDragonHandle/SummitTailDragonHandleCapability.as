class USummitTailDragonHandleCapability : UInteractionCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;


	UPlayerTailTeenDragonComponent DragonComp;
	//ATeenDragon TeenDragon;
	//UTeenDragonMovementComponent MoveComp;
	ASummitTailDragonHandle Handle;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		DragonComp = UPlayerTailTeenDragonComponent::Get(Owner);
		Handle = Cast<ASummitTailDragonHandle>(Params.Interaction.Owner);
		//TeenDragon = DragonComp.TeenDragon;
		//MoveComp = TeenDragon.MovementComponent;

		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);
		Player.SmoothTeleportActor(Handle.DragonLocation.WorldLocation, Handle.DragonLocation.WorldRotation, this, 0.8);
		Player.AttachToComponent(Params.Interaction, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);		

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Player.UnblockCapabilities(CapabilityTags::Movement, this);

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Forward = GetAttributeVector2D(AttributeVectorNames::MovementRaw).X;


		PrintToScreen("Forward: " + Forward);

		if(Forward != 0)
			Handle.OnHandleMoving.Broadcast(Forward, Player.ActorForwardVector, DeltaTime);
	}
};