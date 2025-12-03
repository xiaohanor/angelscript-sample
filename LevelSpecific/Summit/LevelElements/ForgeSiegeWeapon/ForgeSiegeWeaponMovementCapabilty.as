class UForgeSiegeWeaponMovementCapabilty : UInteractionCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;


	UPlayerTailTeenDragonComponent TailDragonComp;
	UPlayerAcidTeenDragonComponent AcidDragonComp;

	//ATeenDragon TeenDragon;
	//UTeenDragonMovementComponent MoveComp;
	AForgeSiegeWeapon SiegeWeapon;

	float MovementSpeed = 0;

	UForgeSiegePlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		PlayerComp = UForgeSiegePlayerComponent::Get(Player);

		TailDragonComp = UPlayerTailTeenDragonComponent::Get(Owner);
		AcidDragonComp = UPlayerAcidTeenDragonComponent::Get(Owner);

		SiegeWeapon = Cast<AForgeSiegeWeapon>(Params.Interaction.Owner);

		// if(TailDragonComp != nullptr)
		// 	TeenDragon = TailDragonComp.TeenDragon;
		// else
		// 	TeenDragon = AcidDragonComp.TeenDragon;

		//MoveComp = TeenDragon.MovementComponent;



		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);
		Player.SmoothTeleportActor(Params.Interaction.WorldLocation, Params.Interaction.WorldRotation, this, 0.8);

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
		//SiegeWeapon.PlayerInput[Player] = MoveComp.GetMovementInput().X;

		if(PlayerComp.bIsLeft)
		{
			// SiegeWeapon.LeftInput = MoveComp.GetMovementInput().X;
			SiegeWeapon.LeftInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw).X;
		}
		else
		{
			// SiegeWeapon.RightInput = MoveComp.GetMovementInput().X;
			SiegeWeapon.RightInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw).X;
		}
	}

}