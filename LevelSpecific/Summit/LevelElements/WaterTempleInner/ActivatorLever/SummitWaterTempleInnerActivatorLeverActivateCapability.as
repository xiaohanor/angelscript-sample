struct FSummitWaterTempleInnerActivatorLeverActivateParams
{
	FSummitWaterTempleLeverMoveParams MoveParams;
	ASummitWaterTempleInnerActivatorLever Lever;
	bool bIsDummyActivating = false;
	UPROPERTY()
	AHazePlayerCharacter Player;
}

class USummitWaterTempleInnerActivatorLeverActivateCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitWaterTempleInnerActivatorLever CurrentLever;
	UPlayerInteractionsComponent InteractionsComp;

	float TimeLastEnterFinished;

	bool bHasEntered = false;
	bool bIsDummyActivating = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		InteractionsComp = UPlayerInteractionsComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSummitWaterTempleInnerActivatorLeverActivateParams& Params) const
	{
		if(InteractionsComp.ActiveInteraction == nullptr)
			return false;

		auto Lever = Cast<ASummitWaterTempleInnerActivatorLever>(InteractionsComp.ActiveInteraction.Owner);
		if(Lever == nullptr)
			return false;

		if(Lever.bIsDoubleInteract)
		{
			if(Lever.bBothPlayersAreInteracting)
			{
				Params.Lever = Lever;
			}
			else if(Lever.AnyLinkedNonSiblingLeverIsInteracted())
			{
				Params.Lever = Lever;
				Params.bIsDummyActivating = true;
			}
			else
				return false;
		}
		else
		{
			Params.Lever = Lever;
		}
		
		Params.MoveParams.StartRoll = Lever.GetStartRotationDegrees();
		Params.MoveParams.TargetRoll = Lever.GetTargetRotationDegrees();
		Params.MoveParams.bLeverGoesToLeft = Lever.bLeverGoesToLeft;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > CurrentLever.EnterDuration + CurrentLever.MoveLeverDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSummitWaterTempleInnerActivatorLeverActivateParams Params)
	{
		bHasEntered = false;
		
		CurrentLever = Params.Lever;
		bIsDummyActivating = Params.bIsDummyActivating;

		CurrentLever.StartRoll = Params.MoveParams.StartRoll;
		CurrentLever.TargetRoll = Params.MoveParams.TargetRoll;
		CurrentLever.bLeverGoesToLeft = Params.MoveParams.bLeverGoesToLeft;

		if(ShouldInfluenceOtherLevers())
		{
			for(auto Lever : CurrentLever.LeversToInfluence)
			{
				if(Lever.bPlayerIsInteracting)
					continue;

				Lever.InteractionComp.Disable(this);
				Lever.StartRoll = Lever.GetStartRotationDegrees();
				Lever.TargetRoll = Lever.GetTargetRotationDegrees();
			}
		}

		CurrentLever.InteractionComp.bPlayerCanCancelInteraction = false;
		CurrentLever.bPlayerIsActivatingLever = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CurrentLever.RotateLever(1.0);

		if(CurrentLever.bDisableAfterUse)
			CurrentLever.InteractionComp.Disable(CurrentLever);

		if(CurrentLever.bPingPongLeverDirection)
			CurrentLever.bLeverGoesToLeft = !CurrentLever.bLeverGoesToLeft;
		
		if(CurrentLever.bResetAfterUse)
			CurrentLever.bResetRequested = true;

		CurrentLever.OnActivationFinished.Broadcast();
		USummitWaterTempleInnerActivatorLeverEventHandler::Trigger_OnActivationFinished(CurrentLever);
		CurrentLever.LastTimeFinishedInteraction = Time::GameTimeSeconds;

		if(ShouldInfluenceOtherLevers())
		{
			for(auto Lever : CurrentLever.LeversToInfluence)
			{
				Lever.InteractionComp.Enable(this);

				if(Lever.bPlayerIsInteracting)
					continue;

				if(CurrentLever.bDisableAfterUse)
					Lever.InteractionComp.Disable(Lever);

				if(CurrentLever.bPingPongLeverDirection)
					Lever.bLeverGoesToLeft = !Lever.bLeverGoesToLeft;
				
				if(CurrentLever.bResetAfterUse)
					Lever.bResetRequested = true;

				Lever.OnActivationFinished.Broadcast();
				USummitWaterTempleInnerActivatorLeverEventHandler::Trigger_OnActivationFinished(Lever);
				Lever.LastTimeFinishedInteraction = Time::GameTimeSeconds;
			}
		}

		if(CurrentLever.bIsDoubleInteract
		&& CurrentLever.SiblingLever != nullptr)
		{
			CurrentLever.bBothPlayersAreInteracting = false;
			CurrentLever.SiblingLever.bBothPlayersAreInteracting = false;
		}

		Player.StopForceFeedback(this);
		Player.PlayCameraShake(CurrentLever.AfterActivatedCameraShake, this);

		CurrentLever.InteractionComp.KickAnyPlayerOutOfInteraction();
		if(!CurrentLever.bIsDoubleInteract)
			CurrentLever.InteractionComp.bPlayerCanCancelInteraction = true;
		CurrentLever.bPlayerIsActivatingLever = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < CurrentLever.EnterDuration)
			return;

		if(!bHasEntered)
		{
			TimeLastEnterFinished = Time::GameTimeSeconds;
			CurrentLever.OnActivationStarted.Broadcast();

			FSummitWaterTempleInnerActivatorLeverActivateParams Params;
			Params.Lever = CurrentLever;
			Params.Player = Player;

			USummitWaterTempleInnerActivatorLeverEventHandler::Trigger_OnActivationStarted(CurrentLever, Params);
			Player.PlayForceFeedback(CurrentLever.ActivationRumble, true, false, this);
			bHasEntered = true;
			for(auto Lever : CurrentLever.LeversToInfluence)
			{
				Lever.OnActivationStarted.Broadcast();
				USummitWaterTempleInnerActivatorLeverEventHandler::Trigger_OnActivationStarted(Lever, Params);
			}
		}
		
		float Alpha = Time::GetGameTimeSince(TimeLastEnterFinished) / CurrentLever.MoveLeverDuration;
		CurrentLever.RotateLever(Alpha, 2.0);

		if(ShouldInfluenceOtherLevers())
		{
			for(auto Lever : CurrentLever.LeversToInfluence)
			{
				if(Lever.bPlayerIsInteracting)
					continue;

				Lever.RotateLever(Alpha, 2.0);
			}
		}
	}

	bool ShouldInfluenceOtherLevers() const
	{
		if(CurrentLever.bIsDoubleInteract
		&& !CurrentLever.bHasDoubleInteractAuthority)
			return false;

		if(CurrentLever.LeversToInfluence.IsEmpty())
			return false;

		if(bIsDummyActivating)
			return false;

		return true;
	}
};