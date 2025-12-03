class UDentistBossToolDenturesInteractionCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBossToolDentures Dentures;
	ADentistBoss Dentist;
	UDentistBossSettings Settings;

	UDentistToothPlayerComponent ToothComp;

	bool bHasBlockedCancel = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		Dentist = TListedActors<ADentistBoss>().Single;
		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		ToothComp = UDentistToothPlayerComponent::Get(Player);
		Dentures = Cast<ADentistBossToolDentures>(Params.Interaction.Owner);
		Dentures.ControllingPlayer.Set(Player);
		Dentures.PlayerJumpingTo.Reset();
		Player.AttachToActor(Dentures, AttachmentRule = EAttachmentRule::KeepWorld);
		FTransform RelativeTransformToInteractComp = FTransform(FQuat::Identity, FVector::UpVector * Player.ScaledCapsuleHalfHeight);
		Player.MeshOffsetComponent.SnapToRelativeTransform(Dentures, Dentures.InteractComp, RelativeTransformToInteractComp, EInstigatePriority::High);

		CapabilityInput::LinkActorToPlayerInput(Dentures, Player);
		Player.ShowTutorialPromptWorldSpace(Settings.DenturesTutorial, this, Dentures.Root, ScreenSpaceOffset = -60);
		Dentist.HasSwatAmnesty[Player] = true;

		FDentistBossEffectHandlerOnDenturesBeingRiddenByPlayerParams EffectParams;
		EffectParams.Dentures = Dentures;
		EffectParams.Player = Player;
		UDentistBossEffectHandler::Trigger_OnDenturesBeingRiddenByPlayer(Dentist, EffectParams);

		Dentures.EyesSpringinessEnabled.Apply(false, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Dentures.ControllingPlayer.Reset();

		Player.DetachFromActor(EDetachmentRule::KeepWorld);
		Player.MeshOffsetComponent.ResetOffsetWithLerp(Dentures, 0.);
		
		CapabilityInput::LinkActorToPlayerInput(Dentures, nullptr);
		Player.RemoveTutorialPromptByInstigator(this);
		Dentist.HasSwatAmnesty[Player] = false;

		Dentures.EyesSpringinessEnabled.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bHasBlockedCancel)
		{
			if(Dentures.IsBitingHand())
			{
				Dentures.InteractComp.SetPlayerIsAbleToCancel(Player, false);
				Player.BlockCapabilities(n"InteractionCancel", this);
				Player.RemoveTutorialPromptByInstigator(this);
				bHasBlockedCancel = true;
			}
		}
		else
		{
			if(!Dentures.IsBitingHand())
			{
				Dentures.InteractComp.SetPlayerIsAbleToCancel(Player, true);
				Player.UnblockCapabilities(n"InteractionCancel", this);
				bHasBlockedCancel = false;
			}
		}

		// if(!ToothComp.HasSetMeshRotationThisFrame())
			// ToothComp.SetMeshWorldRotation(Dentures.InteractComp.ComponentQuat, this);

		if(Dentures.bDestroyed
		|| !Dentures.bActive
		|| !Dentures.ControllingPlayer.IsSet())
		{
			LeaveInteraction();
		}
	}
};