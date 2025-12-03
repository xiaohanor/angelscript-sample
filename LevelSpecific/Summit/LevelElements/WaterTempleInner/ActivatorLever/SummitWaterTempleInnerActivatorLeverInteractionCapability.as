class USummitWaterTempleInnerActivatorLeverInteractionCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ASummitWaterTempleInnerActivatorLever CurrentLever;

	bool bHasActivatedCancel = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		CurrentLever = Cast<ASummitWaterTempleInnerActivatorLever>(Params.Interaction.Owner);
		Player.AddLocomotionFeature(CurrentLever.LeverFeature, this);
		CurrentLever.bPlayerIsInteracting = true;
		if(CurrentLever.bIsDoubleInteract)
			CurrentLever.InteractionComp.bPlayerCanCancelInteraction = false;
		bHasActivatedCancel = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.RemoveLocomotionFeature(CurrentLever.LeverFeature, this);

		CurrentLever.bPlayerIsInteracting = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.RequestLocomotion(n"ThreeStateLever", this);
		Player.SetAnimFloatParam(n"ThreeStateLeverBlendSpaceAlpha", CurrentLever.AnimBlendAlpha);

		Player.SetAnimBoolParam(n"GoesToLeft", CurrentLever.bLeverGoesToLeft);

		if(CurrentLever.bIsDoubleInteract
		&& ActiveDuration > CurrentLever.EnterDuration
		&& !CurrentLever.bPlayerIsActivatingLever
		&& !bHasActivatedCancel)
		{	
			CurrentLever.InteractionComp.bPlayerCanCancelInteraction = true;
			bHasActivatedCancel = true;
		}

		if(HasControl())
		{
			if(CurrentLever.bIsDoubleInteract
			&& CurrentLever.SiblingLever != nullptr
			&& CurrentLever.bHasDoubleInteractAuthority
			&& CurrentLever.SiblingLever.bPlayerIsInteracting
			&& !CurrentLever.bBothPlayersAreInteracting)
			{
				NetSetBothPlayersInteracting(CurrentLever, CurrentLever.SiblingLever);
			}
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetSetBothPlayersInteracting(ASummitWaterTempleInnerActivatorLever Lever, ASummitWaterTempleInnerActivatorLever SiblingLever)
	{
		Lever.bBothPlayersAreInteracting = true;
		SiblingLever.bBothPlayersAreInteracting = true;
	}
};