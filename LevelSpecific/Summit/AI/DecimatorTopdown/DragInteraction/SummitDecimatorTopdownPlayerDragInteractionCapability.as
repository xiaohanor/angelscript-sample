class USummitDecimatorTopdownPlayerDragInteractionCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::LastMovement;

	AAISummitDecimatorTopdown Decimator;
	USummitDecimatorTopdownFollowSplineComponent FollowSplineComp;

	UPlayerMovementComponent MoveComp;
	UPlayerTeenDragonComponent DragonComp;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		Decimator = Cast<AAISummitDecimatorTopdown>(Params.Interaction.Owner);
		FollowSplineComp = USummitDecimatorTopdownFollowSplineComponent::Get(Decimator);

		Player.AttachToComponent(Params.Interaction, AttachmentRule = EAttachmentRule::KeepWorld);

		MoveComp = UPlayerMovementComponent::Get(Player);
		DragonComp = UPlayerTeenDragonComponent::Get(Player);

		FollowSplineComp.HasBit[Player] = true;
		if(FollowSplineComp.HasBit[Player.OtherPlayer])
		{
			Decimator.OnBothPlayersBit.Broadcast();
		}
		Owner.BlockCapabilities(CapabilityTags::GameplayAction, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		
		Player.DetachFromActor(EDetachmentRule::KeepWorld);
		Owner.UnblockCapabilities(CapabilityTags::GameplayAction, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector MovementInput;
		const FVector2D RawInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		if(HasControl())
		{
			MovementInput = MoveComp.GetMovementInput();
		}
		else
		{
			MovementInput = MoveComp.GetSyncedMovementInputForAnimationOnly();
		}

		FollowSplineComp.PlayerMovementInput[Player] = MovementInput;
		FollowSplineComp.PlayerRawInput[Player] = RawInput;
				
		DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::DecimatorPush);

		TEMPORAL_LOG(Player, "Decimator Pull Interaction")
			.DirectionalArrow("Movement Input", Player.ActorLocation, MovementInput * 500, 20, 40, FLinearColor::Red)
		;
	}
};