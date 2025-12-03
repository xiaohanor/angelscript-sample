class UIslandJetpackHolderInteractionCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AIslandJetpackHolder Holder;
	UIslandJetpackComponent JetpackComp;

	bool bAttachedToBackpack = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		JetpackComp = UIslandJetpackComponent::Get(Player);
		
		Holder = Cast<AIslandJetpackHolder>(Params.Interaction.Owner);
		Holder.InteractComp.SetPlayerIsAbleToCancel(Player, false);

		JetpackComp.ToggleJetpack(false);
		Holder.ToggleVisualsOfFakeJetpack(true);
		Holder.FakeJetpackRoot.AttachToComponent(Player.Mesh, n"Spine2", EAttachmentRule::SnapToTarget);
		Holder.FakeJetpackRoot.RelativeRotation = FRotator(0.0, 180.0, 0.0);
		Holder.FakeJetpackRoot.RelativeLocation = FVector(-20.0, 0.0, 0.0);
		bAttachedToBackpack = false;

		Player.PlaySlotAnimation(Holder.PlacingAnim);

		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		Holder.bHasInteracted = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.SnapToGround(bLerpVerticalOffset=true, OverrideTraceDistance = 10);
		Holder.FakeJetpackRoot.AttachToComponent(Holder.JetpackPlacementLocation, n"NAME_None", EAttachmentRule::KeepWorld);
		Holder.FakeJetpackRoot.RelativeRotation = FRotator::ZeroRotator;
		Holder.PowerIndicatorMesh.SetMaterial(0, Holder.PoweredMaterial);

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		
		Holder.bJetpackIsPlaced = true;

		Holder.OnJetpackPlaced.Broadcast();
		if(Holder.bIsDoubleInteract)
		{
			if(Holder.OtherHolder != nullptr
			&& Holder.OtherHolder.bJetpackIsPlaced)
			{
				Holder.OnBothJetpacksPlaced.Broadcast();
				Holder.OtherHolder.OnBothJetpacksPlaced.Broadcast();
			}
		}

		Holder.InteractComp.Disable(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration > Holder.PlacingAnim.Animation.PlayLength)
		{
			LeaveInteraction();
		}

		if(ActiveDuration > 0.2 && !bAttachedToBackpack)
		{
			Holder.FakeJetpackRoot.AttachToComponent(Player.Mesh, n"Backpack", EAttachmentRule::KeepWorld);
			//Holder.FakeJetpackRoot.RelativeRotation = FRotator(0.0, 180.0, 0.0);
			bAttachedToBackpack = true;
		}
	}

}