// class UForgeMoveableTrackCapability : UInteractionCapability
// {
// 	default CapabilityTags.Add(n"Example");
	
// 	default TickGroup = EHazeTickGroup::Gameplay;
// 	default TickGroupOrder = 100;


// 	UPlayerTailTeenDragonComponent DragonComp;
// 	ATeenDragon TeenDragon;
// 	UTeenDragonMovementComponent MoveComp;
// 	AForgeMoveableTrack MoveableTrack;

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FInteractionCapabilityParams Params)
// 	{
// 		Super::OnActivated(Params);

// 		DragonComp = UPlayerTailTeenDragonComponent::Get(Owner);
// 		MoveableTrack = Cast<AForgeMoveableTrack>(Params.Interaction.Owner);
// 		MoveComp = TeenDragon.MovementComponent;
// 		TeenDragon = DragonComp.TeenDragon;

// 		TeenDragon.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);
// 		TeenDragon.SmoothTeleportActor(Params.Interaction.WorldLocation, Params.Interaction.WorldRotation, this, 0.8);
// 		TeenDragon.AttachToComponent(Params.Interaction, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);		

// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated()
// 	{
// 		Super::OnDeactivated();
// 		TeenDragon.UnblockCapabilities(CapabilityTags::Movement, this);

// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		float Forward = MoveComp.GetMovementInput().X;
// 		if(Forward > 0)
// 			MoveableTrack.MeshComp.WorldLocation += Forward * MoveableTrack.PushSpeed * DeltaTime;
// 	}

// };