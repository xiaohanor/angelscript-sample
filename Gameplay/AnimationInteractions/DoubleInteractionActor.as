
enum EDoubleInteractionExclusiveMode
{
	// Left interaction is for Mio, Right Interaction is for Zoe
	LeftMioRightZoe,
	// Left interaction is for Zoe, Right Interaction is for Mio
	LeftZoeRightMio,
	// Both players can use either interaction point
	NotExclusive,
}

event void FDoubleInteractionEvent(AHazePlayerCharacter Player, ADoubleInteractionActor Interaction, UInteractionComponent InteractionComponent);
event void FDoubleInteractionCompletion();

/**
 * A double interaction that requires both players to interact with it at the same time before it triggers.
 *
 * Handles network synchronization internally to make sure it can't trigger desynced.
 */
UCLASS(HideCategories = "Interaction Movement Debug Rendering Collision HLOD LOD Cooking Input Actor Replication WorldPartition DataLayers", Meta = (HighlightPlacement))
class ADoubleInteractionActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent LeftInteraction;
	default LeftInteraction.RelativeLocation = FVector(0.0, -100.0, 0.0);
	default LeftInteraction.MovementSettings = FMoveToParams::SmoothTeleport();
	default LeftInteraction.InteractionSheet = DoubleInteractionSheet;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent RightInteraction;
	default RightInteraction.RelativeLocation = FVector(0.0, 100.0, 0.0);
	default RightInteraction.MovementSettings = FMoveToParams::SmoothTeleport();
	default RightInteraction.InteractionSheet = DoubleInteractionSheet;

	UPROPERTY(DefaultComponent)
	UNetworkLockComponent CompletionLock;

	UPROPERTY(DefaultComponent)
	UHazeEffectEventHandlerComponent EffectEventHandler;

	// Determine which player can use which interaction point
	UPROPERTY(EditAnywhere, Category = "Double Interaction")
	EDoubleInteractionExclusiveMode ExclusiveMode = EDoubleInteractionExclusiveMode::LeftMioRightZoe;

	// Animations used for Mio when interacting with the left interaction point
	UPROPERTY(EditAnywhere, Category = "Double Interaction Animations", Meta = (EditCondition = "ExclusiveMode != EDoubleInteractionExclusiveMode::LeftZoeRightMio", EditConditionHides))
	FDoubleInteractionSettings MioLeftAnimations;

	// Animations used for Mio when interacting with the right interaction point
	UPROPERTY(EditAnywhere, Category = "Double Interaction Animations", Meta = (EditCondition = "ExclusiveMode != EDoubleInteractionExclusiveMode::LeftMioRightZoe", EditConditionHides))
	FDoubleInteractionSettings MioRightAnimations;

	// Animations used for Zoe when interacting with the left interaction point
	UPROPERTY(EditAnywhere, Category = "Double Interaction Animations", Meta = (EditCondition = "ExclusiveMode != EDoubleInteractionExclusiveMode::LeftMioRightZoe", EditConditionHides))
	FDoubleInteractionSettings ZoeLeftAnimations;

	// Animations used for Zoe when interacting with the right interaction point
	UPROPERTY(EditAnywhere, Category = "Double Interaction Animations", Meta = (EditCondition = "ExclusiveMode != EDoubleInteractionExclusiveMode::LeftZoeRightMio", EditConditionHides))
	FDoubleInteractionSettings ZoeRightAnimations;

	/**
	 * Triggered when the double interaction is fully completed.
	 * This is triggered _before_ the completed animation has started playing on both players.
	 */
    UPROPERTY(Category = "Double Interaction")
	FDoubleInteractionCompletion OnDoubleInteractionCompleted;

	/**
	 * Triggered when both players are first locked into finishing the interaction.
	 * This is triggered _before_ the completed animation starts, and when the double interaction might still be prevented from completing.
	 */
    UPROPERTY(Category = "Double Interaction")
	FDoubleInteractionCompletion OnDoubleInteractionLockedIn;

	/**
	 * Triggered when a player has entered the interaction and the enter animation has blended in.
	 * OBS! Do not implement completion logic here, it will not be network safe.
	 */
    UPROPERTY(Category = "Double Interaction")
    FDoubleInteractionEvent OnEnterBlendedIn;

	/**
	 * Triggered when a player has completed the enter animation and is blending out of it.
	 * OBS! Do not implement completion logic here, it will not be network safe.
	 */
    UPROPERTY(Category = "Double Interaction")
    FDoubleInteractionEvent OnEnterBlendingOut;

	/**
	 * Triggered when a player has fully blended into the MH animation.
	 * OBS! Do not implement completion logic here, it will not be network safe.
	 */
    UPROPERTY(Category = "Double Interaction")
    FDoubleInteractionEvent OnMHBlendedIn;

	/**
	 * Triggered when a player's MH animation has blended out, either into Cancel or Completed.
	 * OBS! Do not implement completion logic here, it will not be network safe.
	 */
    UPROPERTY(Category = "Double Interaction")
    FDoubleInteractionEvent OnMHBlendingOut;

	/**
	 * Triggered when a player's cancel animation has blended in.
	 * OBS! Do not implement completion logic here, it will not be network safe.
	 */
    UPROPERTY(Category = "Double Interaction")
    FDoubleInteractionEvent OnCancelBlendingIn;

	/**
	 * Triggered when a player's cancel animation has blended out.
	 * OBS! Do not implement completion logic here, it will not be network safe.
	 */
    UPROPERTY(Category = "Double Interaction")
    FDoubleInteractionEvent OnCancelBlendingOut;

	/**
	 * Triggered when a player's completed animation has blended in.
	 * OBS! Do not implement completion logic here, it will not be network safe.
	 */
    UPROPERTY(Category = "Double Interaction")
    FDoubleInteractionEvent OnCompletedBlendingIn;

	/**
	 * Triggered when a player's completed animation has blended out.
	 * OBS! Do not implement completion logic here, it will not be network safe.
	 */
    UPROPERTY(Category = "Double Interaction")
    FDoubleInteractionEvent OnCompletedBlendingOut;

	/**
	 * Triggered when a player starts interacting with the double interaction.
	 */
    UPROPERTY(Category = "Double Interaction")
    FDoubleInteractionEvent OnPlayerStartedInteracting;

	/**
	 * Triggered when a player stops interacting with the double interaction.
	 * Will trigger regardless of whether the interaction was cancelled or completed.
	 */
    UPROPERTY(Category = "Double Interaction")
    FDoubleInteractionEvent OnPlayerStoppedInteracting;

	bool bVisualizeMHPose = true;

	/**
	 * Prevent the double interaction from being completed until allowed again with this instigator.
	 * This does not prevent the players from interacting and being locked into the interaction!
	 */
	UFUNCTION()
	void PreventDoubleInteractionCompletion(FInstigator Instigator)
	{
		State.PreventCompletionInstigators.AddUnique(Instigator);
	}

	/**
	 * Allow this interaction to be completed again from being previously prevented with this instigator.
	 */
	UFUNCTION()
	void AllowDoubleInteractionCompletion(FInstigator Instigator)
	{
		State.PreventCompletionInstigators.Remove(Instigator);
	}

	/**
	 * Disable this double interaction for both players.
	 */
	UFUNCTION()
	void DisableDoubleInteraction(FInstigator Instigator)
	{
		LeftInteraction.Disable(Instigator);
		RightInteraction.Disable(Instigator);
	}

	/**
	 * Enable this double interaction for both players.
	 */
	UFUNCTION()
	void EnableDoubleInteraction(FInstigator Instigator)
	{
		LeftInteraction.Enable(Instigator);
		RightInteraction.Enable(Instigator);
	}

	/**
	 * Disable this double interaction for a specific player.
	 */
	UFUNCTION()
	void DisableDoubleInteractionForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		LeftInteraction.DisableForPlayer(Player, Instigator);
		RightInteraction.DisableForPlayer(Player, Instigator);
	}

	/**
	 * Enable this double interaction for a specific player.
	 */
	UFUNCTION()
	void EnableDoubleInteractionForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		LeftInteraction.EnableForPlayer(Player, Instigator);
		RightInteraction.EnableForPlayer(Player, Instigator);
	}

	// State for use by the capabilities
	FDoubleInteractionState State;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		EHazePlayer LeftPlayer = EHazePlayer::Mio;
		if(ExclusiveMode == EDoubleInteractionExclusiveMode::LeftZoeRightMio)
			LeftPlayer = EHazePlayer::Zoe;
		else if(LeftInteraction.UsableByPlayers == EHazeSelectPlayer::Zoe)
			LeftPlayer = EHazePlayer::Zoe;
			
		CreateInteractionEditorVisualizer(LeftInteraction, EHazeSelectPlayer(LeftPlayer));

		auto VisMesh = CreatePlayerEditorVisualizer(LeftInteraction, LeftPlayer, FTransform::Identity);
		if (bVisualizeMHPose)
		{
			VisMesh.AnimationMode = EAnimationMode::AnimationSingleNode;
			if (LeftPlayer == EHazePlayer::Zoe)
				VisMesh.AnimationData.AnimToPlay = ZoeLeftAnimations.MHAnimation;
			else
				VisMesh.AnimationData.AnimToPlay = MioLeftAnimations.MHAnimation;
			VisMesh.RefreshEditorPose();
		}

		EHazePlayer RightPlayer = EHazePlayer::Zoe;
		if(ExclusiveMode == EDoubleInteractionExclusiveMode::LeftZoeRightMio)
			RightPlayer = EHazePlayer::Mio;
		else if(RightInteraction.UsableByPlayers == EHazeSelectPlayer::Mio)
			RightPlayer = EHazePlayer::Mio;

		VisMesh = CreatePlayerEditorVisualizer(RightInteraction, RightPlayer, FTransform::Identity);
		if (bVisualizeMHPose)
		{
			VisMesh.AnimationMode = EAnimationMode::AnimationSingleNode;
			if (RightPlayer == EHazePlayer::Mio)
				VisMesh.AnimationData.AnimToPlay = MioRightAnimations.MHAnimation;
			else
				VisMesh.AnimationData.AnimToPlay = ZoeRightAnimations.MHAnimation;
			VisMesh.RefreshEditorPose();
		}

		CreateInteractionEditorVisualizer(RightInteraction, EHazeSelectPlayer(RightPlayer));
#endif
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (ExclusiveMode == EDoubleInteractionExclusiveMode::LeftMioRightZoe)
		{
			LeftInteraction.SetUsableByPlayers(EHazeSelectPlayer::Mio);
			LeftInteraction.bShowForOtherPlayer = true;

			RightInteraction.SetUsableByPlayers(EHazeSelectPlayer::Zoe);
			RightInteraction.bShowForOtherPlayer = true;
		}
		else if (ExclusiveMode == EDoubleInteractionExclusiveMode::LeftZoeRightMio)
		{
			LeftInteraction.SetUsableByPlayers(EHazeSelectPlayer::Zoe);
			LeftInteraction.bShowForOtherPlayer = true;

			RightInteraction.SetUsableByPlayers(EHazeSelectPlayer::Mio);
			RightInteraction.bShowForOtherPlayer = true;
		}

		LeftInteraction.OnInteractionStarted.AddUFunction(this, n"TriggerStartInteraction");
		RightInteraction.OnInteractionStarted.AddUFunction(this, n"TriggerStartInteraction");

		LeftInteraction.OnInteractionStopped.AddUFunction(this, n"TriggerStopInteraction");
		RightInteraction.OnInteractionStopped.AddUFunction(this, n"TriggerStopInteraction");
	}

	UFUNCTION()
	private void TriggerStartInteraction(UInteractionComponent InteractionComponent,
	                                     AHazePlayerCharacter Player)
	{
		OnPlayerStartedInteracting.Broadcast(Player, this, InteractionComponent);
	}

	UFUNCTION()
	private void TriggerStopInteraction(UInteractionComponent InteractionComponent,
	                                    AHazePlayerCharacter Player)
	{
		OnPlayerStoppedInteracting.Broadcast(Player, this, InteractionComponent);
	}

	const FDoubleInteractionSettings& GetDoubleInteractionSettingsForPlayer(AHazePlayerCharacter Player, UInteractionComponent InteractionComponent)
	{
		if (Player.IsMio())
		{
			if (InteractionComponent == LeftInteraction)
				return MioLeftAnimations;
			else
				return MioRightAnimations;
		}
		else
		{
			if (InteractionComponent == LeftInteraction)
				return ZoeLeftAnimations;
			else
				return ZoeRightAnimations;
		}
	}
}

enum EDoubleInteractionStatus
{
	None,
	LockedIn,
	Completed,
};

struct FDoubleInteractionPlayerState
{
	bool bIsInteracting = false;
	bool bHasCanceled = false;
	bool bHasCompletedInteraction = false;

	bool bHasEnterStarted = false;
	bool bHasEnterCompleted = false;
	bool bHasMHStarted = false;
	bool bHasMHCompleted = false;

	void Reset()
	{
		bIsInteracting = false;
		bHasCanceled = false;
		bHasEnterStarted = false;
		bHasEnterCompleted = false;
		bHasMHStarted = false;
		bHasMHCompleted = false;
		bHasCompletedInteraction = false;
	}
};

struct FDoubleInteractionState
{
	EDoubleInteractionStatus Status = EDoubleInteractionStatus::None;
	TArray<FInstigator> PreventCompletionInstigators;
	TPerPlayer<FDoubleInteractionPlayerState> PlayerState;
};

struct FDoubleInteractionEnterAnimationSettings
{
	// Blend time from the player's previous animation
	UPROPERTY(EditAnywhere, Category = "Double Interaction Animation")
	float BlendTime = 0.2;

	// Type of blending to use from the player's previous animation
	UPROPERTY(EditAnywhere, Category = "Double Interaction Animation", AdvancedDisplay)
    EHazeBlendType BlendType = EHazeBlendType::BlendType_Inertialization;

	// Allow the enter animation te blend into completion _before_ it is finished
	UPROPERTY(EditAnywhere, Category = "Double Interaction Animation")
	float EarlyBlendIntoCompletionWindowDuration = 0.0;
}

struct FDoubleInteractionMHAnimationSettings
{
	// Blend time from the player's previous animation
	UPROPERTY(EditAnywhere, Category = "Double Interaction Animation")
	float BlendTime = 0.2;

	// Type of blending to use from the player's previous animation
	UPROPERTY(EditAnywhere, Category = "Double Interaction Animation", AdvancedDisplay)
    EHazeBlendType BlendType = EHazeBlendType::BlendType_Inertialization;
}

struct FDoubleInteractionCompletedAnimationSettings
{
	// Blend time from the player's previous animation
	UPROPERTY(EditAnywhere, Category = "Double Interaction Animation")
	float BlendTime = 0.2;

	// Type of blending to use from the player's previous animation
	UPROPERTY(EditAnywhere, Category = "Double Interaction Animation", AdvancedDisplay)
    EHazeBlendType BlendType = EHazeBlendType::BlendType_Inertialization;

	// Allow the animation to be canceled if the player inputs movement during this amount of time before the actual animation ends
	UPROPERTY(EditAnywhere, Category = "Double Interaction Animation")
	float MovementCancelWindowDuration = 0.0;
}

struct FDoubleInteractionCancelAnimationSettings
{
	// Blend time from the player's previous animation
	UPROPERTY(EditAnywhere, Category = "Double Interaction Animation")
	float BlendTime = 0.2;

	// Type of blending to use from the player's previous animation
	UPROPERTY(EditAnywhere, Category = "Double Interaction Animation", AdvancedDisplay)
    EHazeBlendType BlendType = EHazeBlendType::BlendType_Inertialization;

	// Allow the animation to be canceled if the player inputs movement during this amount of time before the actual animation ends
	UPROPERTY(EditAnywhere, Category = "Double Interaction Animation")
	float MovementCancelWindowDuration = 0.0;
}

struct FDoubleInteractionGestureAnimations
{
	UPROPERTY(EditAnywhere, Category = "Double Interaction Gestures")
	float MinTimeBetweenGestures = 2.0;
	
	UPROPERTY(EditAnywhere, Category = "Double Interaction Gestures")
	float MaxTimeBetweenGestures = 10.0;

	UPROPERTY(EditAnywhere, Category = "Double Interaction Gestures")
	FHazePlayRndSequenceData GesturesGeneric;

	UPROPERTY(EditAnywhere, Category = "Double Interaction Gestures")
	FHazePlayRndSequenceData GesturesLeftDirection;

	UPROPERTY(EditAnywhere, Category = "Double Interaction Gestures")
	FHazePlayRndSequenceData GesturesRightDirection;
}

struct FDoubleInteractionSettings
{
	// Animation that plays once when entering the interaction
	UPROPERTY(EditAnywhere, Category = "Double Interaction Animation")
	UAnimSequence EnterAnimation;

	UPROPERTY(EditAnywhere, Category = "Double Interaction Animation")
	FDoubleInteractionEnterAnimationSettings EnterAnimationSettings;

	// Animation that loops while inside the interaction
	UPROPERTY(EditAnywhere, Category = "Double Interaction Animation", DisplayName = "MH Animation")
	UAnimSequence MHAnimation;

	UPROPERTY(EditAnywhere, Category = "Double Interaction Animation", DisplayName = "MH Animation Settings")
	FDoubleInteractionMHAnimationSettings MHAnimationSettings;

	// Animation that plays when the player cancels the interaction
	UPROPERTY(EditAnywhere, Category = "Double Interaction Animation")
	UAnimSequence CancelAnimation;

	UPROPERTY(EditAnywhere, Category = "Double Interaction Animation")
	FDoubleInteractionCancelAnimationSettings CancelAnimationSettings;

	// Animation that plays when the double interaction is completed by both players
	UPROPERTY(EditAnywhere, Category = "Double Interaction Animation")
	UAnimSequence CompletedAnimation;
	
	UPROPERTY(EditAnywhere, Category = "Double Interaction Animation")
	FDoubleInteractionCompletedAnimationSettings CompletedAnimationSettings;

	UPROPERTY(EditAnywhere, Category = "Double Interaction Animation")
	FDoubleInteractionGestureAnimations Gestures;

	// Audio event to play when the player enters the interaction
	UPROPERTY(EditAnywhere, Category = "Double Interaction Audio")
	UHazeAudioEvent EnterAudio;

	// Audio event to play when the player cancels the interaction
	UPROPERTY(EditAnywhere, Category = "Double Interaction Audio")
	UHazeAudioEvent CancelAudio;

	// Audio event to play when the double interaction is completed by both players
	UPROPERTY(EditAnywhere, Category = "Double Interaction Audio")
	UHazeAudioEvent CompletedAudio;
}

asset DoubleInteractionSheet of UHazeCapabilitySheet
{
	AddCapability(n"DoubleInteractionCapability");
	AddCapability(n"DoubleInteractionEnterAnimationCapability");
	AddCapability(n"DoubleInteractionMHAnimationCapability");
	AddCapability(n"DoubleInteractionCancelAnimationCapability");
	AddCapability(n"DoubleInteractionCompletedAnimationCapability");

	Blocks.Add(n"Movement");
	Blocks.Add(n"GameplayAction");
};