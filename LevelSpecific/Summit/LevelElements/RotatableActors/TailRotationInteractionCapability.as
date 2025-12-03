class UTailRotationInteractionCapbaility : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UPlayerTailTeenDragonComponent DragonComp;
	//ATeenDragon TeenDragon;
	ASummitInteractableRotatingObject RotatingObject;

	UPROPERTY(EditAnywhere)
	USummitInteractableRotatingObjectSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		Settings = USummitInteractableRotatingObjectSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);
		
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		//TeenDragon = DragonComp.TeenDragon;

		RotatingObject = Cast<ASummitInteractableRotatingObject>(Params.Interaction.Owner);

		FVector FlatAttachLocation = Params.Interaction.WorldLocation - RotatingObject.ActorForwardVector * Settings.InteractionAttachmentOffset;

		FHazeTraceSettings Trace;
		Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);

		auto DragonCollision = Player.CapsuleComponent;
		Trace.UseCapsuleShape(DragonCollision.CapsuleRadius, DragonCollision.CapsuleHalfHeight, DragonCollision.ComponentQuat);
		auto HitResults = Trace.QueryTraceSingle(Player.ActorLocation, Player.ActorLocation - FVector::UpVector * 5000);

		if(HitResults.bBlockingHit)
			FlatAttachLocation.Z = HitResults.ImpactPoint.Z;
		else
			FlatAttachLocation.Z = Player.ActorLocation.Z;

		Player.AttachToActor(RotatingObject, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		Player.SmoothTeleportActor(FlatAttachLocation, Params.Interaction.WorldRotation, this, Settings.InteractionTeleportDuration);
		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);

		RotatingObject.EnterInteraction();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		//TeenDragon.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		
		RotatingObject.ExitInteraction();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Input = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).X;
		float DeltaRotation = Input * Settings.RotationSpeed * DeltaTime;

		RotatingObject.CrumbRotate(DeltaRotation);
	}
}