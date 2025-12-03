
class UOneShotInteractionCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 29;

	AHazeActor InteractionActor;
	UOneShotInteractionComponent OneShotComp;

	FOneShotSettings Settings;
	UHazeSkeletalMeshComponentBase RelevantMesh;
	bool bAnimationActive = false;

	bool SupportsInteraction(UInteractionComponent CheckInteraction) const override
	{
		return CheckInteraction.IsA(UOneShotInteractionComponent);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		OneShotComp = Cast<UOneShotInteractionComponent>(ActiveInteraction);
		InteractionActor = Cast<AHazeActor>(ActiveInteraction.Owner);
		Settings = OneShotComp.GetOneShotSettingsForPlayer(Player);
		RelevantMesh = OneShotComp.GetMeshForPlayer(Player);

		UOneShotEffectEventHandler::Trigger_Activated(InteractionActor, MakeEffectEventParams());

		// Play audio
		if (Settings.AudioEvent != nullptr)
		{
			Player.PlayerAudioComponent.PostEvent(Settings.AudioEvent);
		}

		// Play animation
		if (Settings.Animation != nullptr)
		{
			if (OneShotComp.MovementSettings.HasMovement())
			{
				FMoveToDestination Destination(OneShotComp);
				FTransform DestinationTransform = Destination.CalculateDestination(Player.ActorTransform, OneShotComp.MovementSettings);

				Player.RootComponent.AttachToComponent(OneShotComp, NAME_None,
					EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget,
					EAttachmentRule::KeepRelative, false);

				Player.SetActorTransform(DestinationTransform);
			}
			else
			{
				Player.RootComponent.AttachToComponent(OneShotComp, NAME_None,
					EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld,
					EAttachmentRule::KeepRelative, false);
			}

			bAnimationActive = true;
			RelevantMesh.PlaySlotAnimation(
				FHazeAnimationDelegate(this, n"OnAnimationBlendedIn"),
				FHazeAnimationDelegate(this, n"OnAnimationBlendingOut"),
				Settings.ToPlaySlotAnimParams()
			);
		}
		else
		{
			OnAnimationBlendedIn();
			OnAnimationBlendingOut();
		}

		auto MoveComp = UPlayerMovementComponent::Get(Player);
		if (MoveComp != nullptr)
			MoveComp.ClearVerticalLerp();
	}

	UFUNCTION()
	private void OnAnimationBlendedIn()
	{
		UOneShotEffectEventHandler::Trigger_BlendedIn(InteractionActor, MakeEffectEventParams());
		OneShotComp.OnOneShotBlendedIn.Broadcast(Player, OneShotComp);
	}

	UFUNCTION()
	private void OnAnimationBlendingOut()
	{
		bAnimationActive = false;
		if (Player.RootComponent.AttachParent == OneShotComp)
			Player.DetachRootComponentFromParent();
		LeaveInteraction();

		UOneShotEffectEventHandler::Trigger_BlendingOut(InteractionActor, MakeEffectEventParams());
		OneShotComp.OnOneShotBlendingOut.Broadcast(Player, OneShotComp);
	}

	FOneShotEffectEventParams MakeEffectEventParams()
	{
		FOneShotEffectEventParams Params;
		Params.Player = Player;
		Params.InteractionActor = InteractionActor;
		Params.InteractionComponent = OneShotComp;
		return Params;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (bAnimationActive)
		{
			bAnimationActive = false;
			RelevantMesh.StopSlotAnimationByAsset(Settings.ToStopAnimByAssetParams());
			if (Player.RootComponent.AttachParent == OneShotComp)
				Player.DetachRootComponentFromParent();
		}

		Super::OnDeactivated();

		// Put the player back on the ground but lerp the mesh there as the player moves
		Player.SnapToGround(bLerpVerticalOffset=true, OverrideTraceDistance = 10);
	}
};