class UTeenDragonSummitWheelTurningCapability : UInteractionCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;


	UPlayerTailTeenDragonComponent DragonComp;
	//ATeenDragon TeenDragon;
	UHazeMovementComponent MoveComp;
	ASummitTurningWheel TurningWheel;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);


		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		TurningWheel = Cast<ASummitTurningWheel>(Params.Interaction.Owner);
		//TeenDragon = DragonComp.TeenDragon;
		MoveComp = UHazeMovementComponent::Get(Player);

		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);
		Player.SmoothTeleportActor(TurningWheel.PlayerAttachComp.WorldLocation, TurningWheel.PlayerAttachComp.WorldRotation, this, 0.8);

		Player.AttachToComponent(TurningWheel.PlayerAttachComp, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
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
		float Forward = MoveComp.GetMovementInput().X;


		float RotationSpeed = -Forward * 30.0;
		TurningWheel.MeshRoot.AddRelativeRotation(FRotator(0.0, RotationSpeed * DeltaTime, 0.0));

		TurningWheel.OnWheelTurning.Broadcast(RotationSpeed * DeltaTime);

	}
};
