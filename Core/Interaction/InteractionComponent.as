

event void FOnInteractionEvent(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player);
delegate EInteractionConditionResult FInteractionCondition(const UInteractionComponent InteractionComponent, AHazePlayerCharacter Player);

enum EInteractionConditionResult
{
	// Interaction condition allows the user to interact
	Enabled,
	// Interaction condition does not allow the user to interact right now
	Disabled,
	// Interaction condition does not allow interaction, but the interaction should still be visible
	DisabledVisible,
};

UCLASS(Meta = (HideCategories = "LOD Physics AssetUserData Collision Tags Cooking Activation Rendering"))
class UInteractionComponent : UTargetableComponent
{
	access InteractionSetting = private, * (editdefaults, readonly);

	// By default, show the widget somewhat above the interaction
	default bVisualizeComponent = false;
	default TargetableCategory = n"Interaction";
	default WidgetVisualOffset = FVector(0.0, 0.0, 50.0);

	/* Whether the user can cancel this interaction manually while in it. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Interaction", Meta = (EditCondition = "!bIsImmediateTrigger", EditConditionHides))
	bool bPlayerCanCancelInteraction = true;

	/* Whether to show a cancel prompt when the player is inside this interaction. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, AdvancedDisplay, Category = "Interaction", Meta = (EditCondition = "bPlayerCanCancelInteraction", EditConditionHides))
	bool bShowCancelPrompt = true;

	/* Whether to use a unique Cancel prompt for this interaction. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, AdvancedDisplay, Category = "Interaction", Meta = (EditCondition = "bPlayerCanCancelInteraction && bShowCancelPrompt", EditConditionHides))
	bool bOverrideCancelText = false;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, AdvancedDisplay, Category = "Interaction", Meta = (EditCondition = "bOverrideCancelText && bShowCancelPrompt && bPlayerCanCancelInteraction", EditConditionHides))
	FText CancelText;

	/**
	 * If set, the interaction does not start a sheet on the player, but exits immediately.
	 */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Interaction")
	access:InteractionSetting
	bool bIsImmediateTrigger = false;

	/**
	 * The capability that is started on the player while in this interaction.
	 */
	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "Interaction", Meta = (EditCondition = "!bIsImmediateTrigger", EditConditionHides))
	access:InteractionSetting
	FName InteractionCapability;

	/**
	 * The capability that is started on the player while in this interaction.
	 */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Interaction", Meta = (EditCondition = "!bIsImmediateTrigger", EditConditionHides), DisplayName = "Interaction Capability")
	TSubclassOf<UHazeCapability> InteractionCapabilityClass;

	/**
	 * The capability sheet to use while in this interaction. If not specified, uses the default interaction sheet.
	 * When specifying a custom sheet, you usually want to contain the default interaction sheet within your custom sheet.
	 */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Interaction", Meta = (EditCondition = "!bIsImmediateTrigger", EditConditionHides))
	access:InteractionSetting
	UHazeCapabilitySheet InteractionSheet;

	/* Movement used by the player to reach this interaction. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Movement", Meta = (ShowOnlyInnerProperties))
	FMoveToParams MovementSettings;

	/* Whether to disable the interaction by default when it enters play. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Activate", Meta = (InlineEditConditionToggle))
	access:InteractionSetting
	bool bStartDisabled = false;

	/* Instigator to disable with if the interaction enters play disabled. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Activate", Meta = (EditCondition = "bStartDisabled"))
	access:InteractionSetting
	FName StartDisabledInstigator = n"StartDisabled";

	/* Must be in this volume to consider this interaction for usage. */
	UPROPERTY(BlueprintReadOnly, EditInstanceOnly, Category = "ActionArea")
	access:InteractionSetting
	AVolume ActionVolume = nullptr;

	/* Automatically create an action shape of this type. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "ActionArea", Meta = (ShowOnlyInnerProperties))
	access:InteractionSetting
	FHazeShapeSettings ActionShape;
    default ActionShape.Type = EHazeShapeType::Box;
	default ActionShape.BoxExtents = FVector(100.0, 100.0, 100.0);
	default ActionShape.SphereRadius = 100.0;
	 
	/* The automatically created action shape should have this as its transform. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "ActionArea", Meta = (MakeEditWidget))
	access:InteractionSetting
	FTransform ActionShapeTransform = FTransform(FVector(0.0, 0.0, 100.0));

	/* Must be in this volume to consider this interaction for usage. */
	UPROPERTY(BlueprintReadOnly, EditInstanceOnly, Category = "FocusArea")
	access:InteractionSetting
	AVolume FocusVolume = nullptr;

	/* Automatically create an action shape of this type. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "FocusArea", Meta = (ShowOnlyInnerProperties))
	access:InteractionSetting
	FHazeShapeSettings FocusShape;
    default FocusShape.Type = EHazeShapeType::Sphere;
	default FocusShape.BoxExtents = FVector(700.0, 700.0, 700.0);
	default FocusShape.SphereRadius = 700.0;
	 
	/* The automatically created action shape should have this as its transform. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "FocusArea", Meta = (MakeEditWidget))
	access:InteractionSetting
	FTransform FocusShapeTransform;

	/**
	 * Whether to use lazy shapes for the action and focus volumes.
	 * Lazy shapes avoid the physics system and are faster if the shapes move around a lot.
	 * They should not be used if the shapes don't move.
	 */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Activate", AdvancedDisplay)
	access:InteractionSetting
	bool bUseLazyTriggerShapes = false;

	access InteractionInternal =
		private,
		UInteractionCancelCapability,
		UInteractionEnterCapability,
		UInteractionExitCapability,
		UInteractionNetworkSafetyChecks;

	access ForInteractionCapability =
		private,
		UInteractionCapability (inherited),
		UInteractionCancelCapability,
		UInteractionEnterCapability,
		UInteractionExitCapability;

	private TPerPlayer<FInteractionPerPlayerData> InteractionPlayerData;
	private TArray<UPrimitiveComponent> FocusAreas;
	private TArray<UPrimitiveComponent> ActionAreas;
	private TArray<UInteractionComponent> MutuallyExclusiveInteractions;
	private TArray<FInteractionConditionData> InteractionConditions;
	private TSubclassOf<UHazeCapability> ResolvedInteractionCapability;

	access:InteractionInternal
	UNetworkLockComponent NetworkLock = nullptr;

	/**
	 * Called when a player starts interacting with this.
	 */
	UPROPERTY()
	FOnInteractionEvent OnInteractionStarted;

	/**
	 * Called when a player stops interacting with this.
	 */
	UPROPERTY()
	FOnInteractionEvent OnInteractionStopped;

	/**
	 * Configure the specified interactions so they are mutually exclusive and cannot
	 * be used at the same time.
	 */
	UFUNCTION(Category = "Interaction")
	void AddMutuallyExclusiveInteraction(UInteractionComponent OtherInteraction)
	{
		if (OtherInteraction == nullptr)
			return;

		// Take any mutually exclusives the other interaction already has into our own
		for (auto ExclusiveInteraction : OtherInteraction.MutuallyExclusiveInteractions)
		{
			if (ExclusiveInteraction != this)
				MutuallyExclusiveInteractions.AddUnique(ExclusiveInteraction);
		}

		// Make sure the other side has any mutually exclusives we already had
		for (auto ExclusiveInteraction : MutuallyExclusiveInteractions)
		{
			if (ExclusiveInteraction != OtherInteraction)
				OtherInteraction.MutuallyExclusiveInteractions.AddUnique(ExclusiveInteraction);
		}

		// Add reciprocity to both sides
		MutuallyExclusiveInteractions.AddUnique(OtherInteraction);
		OtherInteraction.MutuallyExclusiveInteractions.AddUnique(this);

		// We use a global lock for interactions that span actors.
		if (Owner != OtherInteraction.Owner)
		{
			//  This is suboptimal, but we have no way of choosing a 'leader'
			//  interaction to lock with consistently if they span multiple actors.
			NetworkLock = UNetworkLockComponent::GetOrCreate(Game::Mio, n"GlobalInteractionLock");
			for (auto ExclusiveInteraction : MutuallyExclusiveInteractions)
				ExclusiveInteraction.NetworkLock = NetworkLock;
		}
	}

	/**
	 * Enable the interaction with the instigator set as the start disabled instigator.
	 */
	UFUNCTION(Category = "Interaction")
	void EnableAfterStartDisabled()
	{
		if (bStartDisabled)
			Enable(StartDisabledInstigator);
	}

	/**
	 * Add a condition to the interaction that is checked before a player is able to use it.
	 */
	UFUNCTION(Category = "Interaction")
	void AddInteractionCondition(FInstigator Instigator, FInteractionCondition Condition)
	{
		for (FInteractionConditionData& ExistingCondition : InteractionConditions)
		{
			if (ExistingCondition.Instigator == Instigator)
			{
				ExistingCondition.Condition = Condition;
				return;
			}
		}

		FInteractionConditionData ConditionData;
		ConditionData.Instigator = Instigator;
		ConditionData.Condition = Condition;

		InteractionConditions.Add(ConditionData);
	}

	/**
	 * Remove a previously added interaction condition.
	 */
	UFUNCTION(Category = "Interaction")
	void RemoveInteractionCondition(FInstigator Instigator)
	{
		for (int i = InteractionConditions.Num() - 1; i >= 0; --i)
		{
			if (InteractionConditions[i].Instigator == Instigator)
			{
				InteractionConditions.RemoveAt(i);
				break;
			}
		}
	}

	/**
	 * If a player is currently interacting, kick them out of the interaction.
	 * This behaves as if the player pressed the 'Cancel' button.
	 */
	UFUNCTION(Category = "Interaction")
	void KickAnyPlayerOutOfInteraction()
	{
		for (auto Player : Game::Players)
		{
			if (!Player.HasControl())
				continue;

			if (InteractionPlayerData[Player].bIsInteracting)
			{
				auto PlayerInteractionsComp = UPlayerInteractionsComponent::Get(Player);
				if (PlayerInteractionsComp != nullptr)
					PlayerInteractionsComp.KickPlayerOutOfInteraction(this);
			}
		}
	}

	/**
	 * If the player is currently interacting, kick them out of the interaction.
	 * This behaves as if the player pressed the 'Cancel' button.
	 */
	UFUNCTION(Category = "Interaction")
	void KickPlayerOutOfInteraction(AHazePlayerCharacter Player)
	{
		if (!Player.HasControl())
			return;

		if (InteractionPlayerData[Player].bIsInteracting)
		{
			auto PlayerInteractionsComp = UPlayerInteractionsComponent::Get(Player);
			if (PlayerInteractionsComp != nullptr)
				PlayerInteractionsComp.KickPlayerOutOfInteraction(this);
		}
	}


	/**
	 * Block players from cancelling out of this interaction temporarily.
	 */
	UFUNCTION(Category = "Interaction")
	void BlockCancelInteraction(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		InteractionPlayerData[Player].CancelBlockers.AddUnique(Instigator);
	}

	/**
	 * Unblock players from cancelling out of this interaction temporarily.
	 */
	UFUNCTION(Category = "Interaction")
	void UnblockCancelInteraction(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		InteractionPlayerData[Player].CancelBlockers.Remove(Instigator);
	}

	// Implementation of checking for range and the like for the interaction targeting
	protected bool CheckTargetable(FTargetableQuery& Query) const override
	{
		const FInteractionPerPlayerData& PlayerData = InteractionPlayerData[Query.Player];

		// Ignore interactions we are not nearby
		if (PlayerData.EnteredActionAreas.Num() == 0 && PlayerData.EnteredFocusAreas.Num() == 0)
			return false;

		// If a player is validating this interaction it can't be used by the other player
		//  This isn't actually guaranteed network safe, but we only use it as a hueristic,
		//  even if both players can validate at the same time the lock will fix it.
		if (IsAnyPlayerValidating())
			return false;
		
		// If we have any mutually exclusive interactions, also check them
		for (auto OtherInteraction : MutuallyExclusiveInteractions)
		{
			if (OtherInteraction.IsAnyPlayerValidating())
				return false;
			if (OtherInteraction.IsAnyPlayerInteracting())
				return false;
		}

		// Don't allow active targeting if not in the action area
		if (PlayerData.EnteredActionAreas.Num() == 0)
			Query.Result.Score = 0.0;

		// Check conditions that were added to this interaction
		for (const FInteractionConditionData& ConditionData : InteractionConditions)
		{
			if (ConditionData.Condition.IsBound())
			{
				EInteractionConditionResult ConditionResult = ConditionData.Condition.Execute(this, Query.Player);
				switch (ConditionResult)
				{
					case EInteractionConditionResult::Disabled:
						return false;
					case EInteractionConditionResult::DisabledVisible:
						Query.Result.Score = 0.0;
					break;
					case EInteractionConditionResult::Enabled:
					break;
				}
			}
		}

		// Don't show the widget for an unusable interaction if in fullscreen, and the
		// other player is nearby enough to show their own widget.
		if (bShowForOtherPlayer
			&& !Query.Player.IsSelectedBy(UsableByPlayers)
			&& SceneView::IsFullScreen()
			&& InteractionPlayerData[Query.Player.OtherPlayer].EnteredFocusAreas.Num() != 0)
		{
			return false;
		}

		// Score based on camera targeting
		Targetable::ScoreCameraTargetingInteraction(Query);
		return true;
	}

	protected float GetWidgetFullSizeRange() const
	{
		float ActionAreaRadius = ActionShape.GetEncapsulatingSphereRadius() * ActionShapeTransform.GetMaximumAxisScale();
		return Math::Max(ActionAreaRadius, 400.0);
	}

	protected void UpdateWidget(UTargetableWidget Widget, FTargetableResult QueryResult) const override
	{
		Super::UpdateWidget(Widget, QueryResult);

		UInteractionWidget InteractionWidget = Cast<UInteractionWidget>(Widget);
		if (InteractionWidget != nullptr)
		{
			UPlayerTargetablesComponent TargetablesComp = UPlayerTargetablesComponent::Get(Widget.Player);

			float Distance = InteractionWidget.GetWidgetWorldPosition().Distance(
				Widget.Player.ViewLocation + TargetablesComp.TargetingWidgetLocationOffset.Get()
			);

			// Scale the whole widget to be smaller as the player gets further away
			float FullSizeRange = GetWidgetFullSizeRange() + 600;
			if (TargetablesComp.IgnoreVisualWidgetDistance.Get())
				Distance = FullSizeRange;
			float WantedScale = FullSizeRange / Math::Max(Distance, 1.0);

			// Fullscreen and 2D situations don't do this scaling
			auto PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Widget.Player);
			if (SceneView::IsFullScreen())
				WantedScale = 1.0;
			else if (PerspectiveModeComp.GetPerspectiveMode() != EPlayerMovementPerspectiveMode::ThirdPerson)
				WantedScale = 1.0;

			// If the widget is in its targetable state we don't scale it
			if (InteractionWidget.bIsPrimaryTarget)
				WantedScale = 1.0;

			float Scale = Math::Clamp(WantedScale, 0.6, 1.0);
			InteractionWidget.SetRenderScale(FVector2D(Scale, Scale));
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Find the network lock to use for this interaction
		if (NetworkLock == nullptr)
			NetworkLock = UNetworkLockComponent::GetOrCreate(Owner, n"InteractionNetworkLock");

		// Don't consider the interaction until we enter a focus or action area with the player
		for (auto Player : Game::Players)
			SetTargetableConsidered(Player, false);

		// Apply start disabled
		if (bStartDisabled)
			Disable(StartDisabledInstigator);

		// Set the configured action areas
        if (ActionVolume != nullptr)
            AddActionArea(ActionVolume.BrushComponent);

        if ((ActionShape.Type != EHazeShapeType::None) && !ActionShape.IsZeroSize() && ActionShapeTransform.GetScale3D().GetMin() >= SMALL_NUMBER)
		{
			if (bUseLazyTriggerShapes)
			{
				AddActionArea(Shape::CreateLazyPlayerTriggerShape(
					Owner, this, ActionShape, ActionShapeTransform, FName(GetName() + "_ActionArea")
				));
			}
			else
			{
				auto ShapeComp = Shape::CreateTriggerShape(
					Owner, this, ActionShape, ActionShapeTransform, n"TriggerOnlyPlayer", FName(GetName() + "_ActionArea")
				);
				// Shape doesn't need to update overlaps, because the player updates overlaps every frame
				ShapeComp.bDisableUpdateOverlapsOnComponentMove = true;
				AddActionArea(ShapeComp);
			}
		}

        // Set the configured action areas
        if (FocusVolume != nullptr)
            AddFocusArea(FocusVolume.BrushComponent);

        if ((FocusShape.Type != EHazeShapeType::None) && !FocusShape.IsZeroSize() && FocusShapeTransform.GetScale3D().GetMin() >= SMALL_NUMBER)
		{
			if (bUseLazyTriggerShapes)
			{
				AddFocusArea(Shape::CreateLazyPlayerTriggerShape(
					Owner, this, FocusShape, FocusShapeTransform, FName(GetName() + "_FocusArea")
				));
			}
			else
			{
				auto ShapeComp = Shape::CreateTriggerShape(
					Owner, this, FocusShape, FocusShapeTransform, n"TriggerOnlyPlayer", FName(GetName() + "_FocusArea")
				);
				// Shape doesn't need to update overlaps, because the player updates overlaps every frame
				ShapeComp.bDisableUpdateOverlapsOnComponentMove = true;
				AddFocusArea(ShapeComp);
			}
		}

		if (!bIsImmediateTrigger)
		{
			// Request the class capability we've specified
			if (InteractionCapabilityClass.IsValid())
				ResolvedInteractionCapability = InteractionCapabilityClass.Get();
			// Request the named capability we've specified
			else if (InteractionCapability != NAME_None)
				ResolvedInteractionCapability = Capability::Get(InteractionCapability);

			if (ResolvedInteractionCapability.IsValid() || InteractionSheet != nullptr)
			{
				if (Owner.IsPlacedInLevel())
				{
					auto RequestComp = UHazeRequestCapabilityOnPlayerComponent::GetOrCreate(Owner);
					if (ResolvedInteractionCapability.IsValid())
						RequestComp.AddCapabilityToInitialStopped(ResolvedInteractionCapability);
					if (InteractionSheet != nullptr)
						RequestComp.AddSheetToInitialStopped(InteractionSheet);
				}
			}
		}

		Super::BeginPlay();

		// Do the initial update of the hints for the network lock
		UpdateNetworkHints();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Update hints for the network lock to figure out which player should own it
		UpdateNetworkHints();

		// Keep updating while players are nearby
		bool bAnyPlayersNearby = false;
		for (auto Player : Game::Players)
		{
			FInteractionPerPlayerData& PlayerData = InteractionPlayerData[Player];
			if (PlayerData.EnteredActionAreas.Num() != 0 || PlayerData.EnteredFocusAreas.Num() != 0)
				bAnyPlayersNearby = true;
		}

		// Stop ticking when no more players are here
		if (!bAnyPlayersNearby)
			SetComponentTickEnabled(false);
	}

	protected void OnUpdateEnableStatus(AHazePlayerCharacter Player, bool bEnabled) override
	{
		Super::OnUpdateEnableStatus(Player, bEnabled);

		// Update network hints when this becomes enabled or disabled for a player
		UpdateNetworkHints(OnlyForPlayer = Player);

		// When an interaction gets disabled for both players, disable collision on its spawned triggers
		if (IsDisabled() && !bShowWhileDisabled)
		{
			for (auto Trigger : ActionAreas)
			{
				if (Trigger.AttachParent == this)
					Trigger.AddComponentCollisionBlocker(FInstigator(this, n"InteractionDisabled"));
			}
			for (auto Trigger : FocusAreas)
			{
				if (Trigger.AttachParent == this)
					Trigger.AddComponentCollisionBlocker(FInstigator(this, n"InteractionDisabled"));
			}
		}
		else
		{
			for (auto Trigger : ActionAreas)
			{
				if (Trigger.AttachParent == this)
					Trigger.RemoveComponentCollisionBlocker(FInstigator(this, n"InteractionDisabled"));
			}
			for (auto Trigger : FocusAreas)
			{
				if (Trigger.AttachParent == this)
					Trigger.RemoveComponentCollisionBlocker(FInstigator(this, n"InteractionDisabled"));
			}
		}

#if TEST
		// If the targetable got disabled during a trigger, we want to check network safety
		if (!bEnabled)
			UInteractionNetworkSafetyChecks::Get().CheckDisable(this, Player);
#endif
	}

	access:InteractionInternal
	bool ShouldUseInteractionSheet() const
	{
		return !bIsImmediateTrigger;
	}

	access:InteractionInternal
	UHazeCapabilitySheet GetPlayerInteractionSheet(AHazePlayerCharacter Player)
	{
		return InteractionSheet;
	}

	access:InteractionInternal
	TSubclassOf<UHazeCapability> GetPlayerInteractionCapability(AHazePlayerCharacter Player)
	{
		return ResolvedInteractionCapability;
	}

	access:InteractionInternal
	void SetPlayerValidating(AHazePlayerCharacter Player, bool bValidating)
	{
		FInteractionPerPlayerData& PlayerData = InteractionPlayerData[Player];
		PlayerData.bIsValidating = bValidating;
	}

	access:InteractionInternal
	bool IsAnyPlayerValidating() const
	{
		return InteractionPlayerData[0].bIsValidating || InteractionPlayerData[1].bIsValidating;
	}

	access:InteractionInternal
	bool IsAnyPlayerInteracting() const
	{
		return InteractionPlayerData[0].bIsInteracting || InteractionPlayerData[1].bIsInteracting;
	}

	access:InteractionInternal
	bool IsValidToUse(AHazePlayerCharacter Player) const
	{
		// Don't allow if disabled right now
		if (IsDisabledForPlayer(Player))
			return false;

		// If we have any mutually exclusive interactions, also check them
		for (auto OtherInteraction : MutuallyExclusiveInteractions)
		{
			if (OtherInteraction.IsAnyPlayerInteracting())
				return false;
		}

		// Check if any of our conditions are disabling right now
		for (const FInteractionConditionData& ConditionData : InteractionConditions)
		{
			if (ConditionData.Condition.IsBound())
			{
				EInteractionConditionResult ConditionResult = ConditionData.Condition.Execute(this, Player);
				if (ConditionResult != EInteractionConditionResult::Enabled)
					return false;
			}
		}

		return true;
	}

	bool CanPlayerCancel(AHazePlayerCharacter Player) const
	{
		if (!bPlayerCanCancelInteraction)
			return false;

		const FInteractionPerPlayerData& PlayerData = InteractionPlayerData[Player];
		if (!PlayerData.bIsInteracting)
			return false;
		if (PlayerData.CancelBlockers.Num() != 0)
			return false;
		if (!PlayerData.bAbleToCancel)
			return false;

		return true;
	}

	access:ForInteractionCapability
	void SetPlayerIsAbleToCancel(AHazePlayerCharacter Player, bool bAbleToCancel)
	{
		FInteractionPerPlayerData& PlayerData = InteractionPlayerData[Player];
		PlayerData.bAbleToCancel = bAbleToCancel;
	}

	access:InteractionInternal
	void StartInteracting(AHazePlayerCharacter Player)
	{
		FInteractionPerPlayerData& PlayerData = InteractionPlayerData[Player];
		if (PlayerData.bIsInteracting)
			return;


		TEMPORAL_LOG(this).Event(f"Started interacting: {Player.Name}");
		Disable(n"InteractionActive");

#if TEST
		FScopeInteractionExecution ScopeExecuting(this, Player);
#endif

		PlayerData.bIsInteracting = true;
		OnInteractionStarted.Broadcast(this, Player);
	}

	access:InteractionInternal
	void StopInteracting(AHazePlayerCharacter Player)
	{
		FInteractionPerPlayerData& PlayerData = InteractionPlayerData[Player];
		if (!PlayerData.bIsInteracting)
			return;

		TEMPORAL_LOG(this).Event(f"Stopped interacting: {Player.Name}");

		PlayerData.bIsInteracting = false;
		OnInteractionStopped.Broadcast(this, Player);

		Enable(n"InteractionActive");
	}

	/**
	 * Whether this player is currently in the interaction.
	 * 
	 * OBS! Determined by player control side, so be careful not to create desyncs in network by using this.
	 */
	bool IsInteracting(AHazePlayerCharacter Player) const
	{
		const FInteractionPerPlayerData& PlayerData = InteractionPlayerData[Player];
		return PlayerData.bIsInteracting;
	}

	private void UpdateNetworkHints(AHazePlayerCharacter OnlyForPlayer = nullptr)
	{
		if (NetworkLock == nullptr)
			return;
		if (!IsObjectNetworked())
			return;

		for (auto Player : Game::Players)
		{
			if (OnlyForPlayer != nullptr && Player != OnlyForPlayer)
				continue;

			if (IsDisabledForPlayer(Player))
			{
				// Disabled players have no hint
				NetworkLock.ClearOwnerHint(Player, this, bComputeHintUpdate = false);
				continue;
			}

			const FInteractionPerPlayerData& PlayerData = InteractionPlayerData[Player];
			if (PlayerData.EnteredActionAreas.Num() != 0)
			{
				// Players in action area have highest hint
				float Distance = Math::Max(Player.ActorLocation.Distance(WorldLocation), 100.0);
				float HintWeight = 1000.0 / (Distance / 1000.0);

				NetworkLock.ApplyOwnerHint(Player, this, HintWeight, bComputeHintUpdate = false);
			}
			else if (PlayerData.EnteredFocusAreas.Num() != 0)
			{
				// Players in focus area have medium hint
				float Distance = Math::Max(Player.ActorLocation.Distance(WorldLocation), 100.0);
				float HintWeight = 100.0 / (Distance / 1000.0);

				NetworkLock.ApplyOwnerHint(Player, this, HintWeight, bComputeHintUpdate = false);
			}
			else
			{
				// Players far away have no hint
				NetworkLock.ClearOwnerHint(Player, this, bComputeHintUpdate = false);
			}
		}

		NetworkLock.UpdateHintValues();
	}

	void AddActionArea(UPrimitiveComponent Shape)
	{
		ActionAreas.Add(Shape);

		// If any players are already overlapping the shape, track that
		TArray<UPrimitiveComponent> ExistingOverlaps;
		Shape.GetOverlappingComponents(ExistingOverlaps);
		for (UPrimitiveComponent Overlap : ExistingOverlaps)
		{
			auto Player = Cast<AHazePlayerCharacter>(Overlap.Owner);
			if (Player == nullptr)
				return;
			if (Overlap != Player.CapsuleComponent)
				return;

			EnterActionArea(Player, Shape);
		}

		// Bind to new overlaps on this shape
		Shape.OnComponentBeginOverlap.AddUFunction(this, n"BeginOverlapActionArea");
		Shape.OnComponentEndOverlap.AddUFunction(this, n"EndOverlapActionArea");
	}

	void AddFocusArea(UPrimitiveComponent Shape)
	{
		FocusAreas.Add(Shape);

		// If any players are already overlapping the shape, track that
		TArray<UPrimitiveComponent> ExistingOverlaps;
		Shape.GetOverlappingComponents(ExistingOverlaps);
		for (UPrimitiveComponent Overlap : ExistingOverlaps)
		{
			auto Player = Cast<AHazePlayerCharacter>(Overlap.Owner);
			if (Player == nullptr)
				return;
			if (Overlap != Player.CapsuleComponent)
				return;

			EnterFocusArea(Player, Shape);
		}

		// Bind to new overlaps on this shape
		Shape.OnComponentBeginOverlap.AddUFunction(this, n"BeginOverlapFocusArea");
		Shape.OnComponentEndOverlap.AddUFunction(this, n"EndOverlapFocusArea");
	}

	private void UpdatePlayerConsideration(AHazePlayerCharacter Player)
	{
		FInteractionPerPlayerData& PlayerData = InteractionPlayerData[Player];
		bool bConsider = PlayerData.EnteredFocusAreas.Num() != 0 || PlayerData.EnteredActionAreas.Num() != 0;
		SetTargetableConsidered(Player, bConsider);
	}

	private void EnterFocusArea(AHazePlayerCharacter Player, UPrimitiveComponent Area)
	{
		FInteractionPerPlayerData& PlayerData = InteractionPlayerData[Player];
		PlayerData.EnteredFocusAreas.Add(Area);
		UpdatePlayerConsideration(Player);
		SetComponentTickEnabled(true);
	}

	private void ExitFocusArea(AHazePlayerCharacter Player, UPrimitiveComponent Area)
	{
		FInteractionPerPlayerData& PlayerData = InteractionPlayerData[Player];
		PlayerData.EnteredFocusAreas.Remove(Area);
		UpdatePlayerConsideration(Player);
	}

	private void EnterActionArea(AHazePlayerCharacter Player, UPrimitiveComponent Area)
	{
		FInteractionPerPlayerData& PlayerData = InteractionPlayerData[Player];
		PlayerData.EnteredActionAreas.Add(Area);
		UpdatePlayerConsideration(Player);
		SetComponentTickEnabled(true);
	}

	private void ExitActionArea(AHazePlayerCharacter Player, UPrimitiveComponent Area)
	{
		FInteractionPerPlayerData& PlayerData = InteractionPlayerData[Player];
		PlayerData.EnteredActionAreas.Remove(Area);
		UpdatePlayerConsideration(Player);
	}

    UFUNCTION()
    private void BeginOverlapActionArea(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		if (OtherComponent != Player.CapsuleComponent)
			return;

		EnterActionArea(Player, OverlappedComponent);
    }

    UFUNCTION()
    private void EndOverlapActionArea(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		if (OtherComponent != Player.CapsuleComponent)
			return;

		ExitActionArea(Player, OverlappedComponent);
    }

    UFUNCTION()
    private void BeginOverlapFocusArea(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		if (OtherComponent != Player.CapsuleComponent)
			return;

		EnterFocusArea(Player, OverlappedComponent);
    }

    UFUNCTION()
    private void EndOverlapFocusArea(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		if (OtherComponent != Player.CapsuleComponent)
			return;

		ExitFocusArea(Player, OverlappedComponent);
    }

#if EDITOR
	// Move the actor this interaction is in so the interaction is at the ground, preventing the player from hovering/popping while using it
	UFUNCTION(CallInEditor, Category = "Editor")
	private void SnapActorSoInteractionIsOnGround()
	{
		auto GroundTrace = Trace::InitProfile(n"PlayerCharacter");
		GroundTrace.IgnoreActor(Owner);
		GroundTrace.UseCapsuleShape(30.0, 88.0, ComponentQuat);

		FHitResultArray Hits = GroundTrace.QueryTraceMulti(
			WorldTransform.Location + UpVector * 150.0,
			WorldTransform.Location - UpVector * 150.0,
		);

		for (FHitResult Hit : Hits)
		{
			if (!Hit.bBlockingHit)
				continue;
			if (Hit.bStartPenetrating)
				continue;

			FVector OwnerLocation = Owner.GetActorLocation();
			FVector InteractionLocation = GetWorldLocation();
			float InteractionHeight = InteractionLocation.DotProduct(UpVector);
			float GroundHeight = Hit.ImpactPoint.DotProduct(UpVector);

			OwnerLocation += UpVector * (GroundHeight - InteractionHeight);
			Owner.SetActorLocation(OwnerLocation);

			break;
		}
	}
#endif
};

struct FInteractionPerPlayerData
{
	TArray<UPrimitiveComponent> EnteredActionAreas;
	TArray<UPrimitiveComponent> EnteredFocusAreas;
	TArray<FInstigator> CancelBlockers;
	bool bAbleToCancel = true;
	bool bIsInteracting = false;
	bool bIsValidating = false;
};

struct FInteractionConditionData
{
	FInstigator Instigator;
	FInteractionCondition Condition;
};

#if TEST
class UInteractionNetworkSafetyChecks 
{
	UInteractionComponent ExecutingInteraction;
	AHazePlayerCharacter ExecutingPlayer;

	void CheckDisable(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		// Don't warn outside network
		if (!Network::IsGameNetworked())
			return;

		// Nothing to warn about if we aren't executing an interaction right now
		if (ExecutingInteraction == nullptr)
			return;
		
		// Nothing to warn about if we're disabling for the same player that is executing
		if (ExecutingPlayer == Player)
			return;

		// Don't need to warn if both interactions are using the same network lock
		if (ExecutingInteraction.NetworkLock == Interaction.NetworkLock)
			return;

		// Disabling an interaction under a different lock for a different player,
		// this is not network safe and could create a race where both players are
		// able to use interactions at the same time when they shouldn't.
		devError(
			"Disabling interaction "+Interaction.GetPathName()+" for player "+Player
			+" while executing interaction "+ExecutingInteraction.GetPathName()+"."
			+"\n\nThis is not network safe because the interactions are on different actors!"
			+"\n\nUse UInteractionComponent.AddMutuallyExclusiveInteraction() instead."
		);
	}

	void StartedExecuting(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		ExecutingInteraction = Interaction;
		ExecutingPlayer = Player;
	}

	void StoppedExecuting(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		ExecutingInteraction = nullptr;
		ExecutingPlayer = nullptr;
	}
};

struct FScopeInteractionExecution
{
	UInteractionComponent ExecuteInteraction;
	AHazePlayerCharacter ExecutePlayer;

	FScopeInteractionExecution()
	{
	}

	FScopeInteractionExecution(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		ExecuteInteraction = Interaction;
		ExecutePlayer = Player;
		UInteractionNetworkSafetyChecks::Get().StartedExecuting(ExecuteInteraction, ExecutePlayer);
	}

	~FScopeInteractionExecution()
	{
		if (ExecuteInteraction != nullptr)
		{
			auto SafetyChecks = UInteractionNetworkSafetyChecks::Get();
			if (SafetyChecks != nullptr)
				SafetyChecks.StoppedExecuting(ExecuteInteraction, ExecutePlayer);
		}
	}
}

namespace UInteractionNetworkSafetyChecks
{

UInteractionNetworkSafetyChecks Get()
{
	return Game::GetSingleton(UInteractionNetworkSafetyChecks);
}

};
#endif