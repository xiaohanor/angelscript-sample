
struct FInteractionEnterCapabilityParams
{
	UInteractionComponent Interaction;
	UNetworkLockComponent NetworkLock;
	bool bStartInteraction = false;
	bool bInteractionValidationSuccess = false;
};

struct FInteractionEnterCapabilityDeactivateParams
{
	bool bStartInteraction = false;
	bool bInteractionValidationSuccess = false;
};

class UInteractionEnterCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"Interaction");

	default BlockExclusionTags.Add(n"UsableDuringMoveTo");

	default DebugCategory = n"Interaction";
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 10;

	UPlayerInteractionsComponent PlayerInteractionsComp;
	UPlayerTargetablesComponent PlayerTargetablesComp;
	UMoveToComponent MoveToComp;

	UInteractionComponent Interaction;
	UNetworkLockComponent NetworkLock;
	bool bInteractionStarted = false;
	bool bHasValidationSheet = false;

	bool bIsMoving = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerInteractionsComp = UPlayerInteractionsComponent::GetOrCreate(Player);
		PlayerTargetablesComp = UPlayerTargetablesComponent::GetOrCreate(Player);
		MoveToComp = UMoveToComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Render widgets for all the interactions that we can target
		if (!IsBlocked() && !IsActive())
		{
			PlayerTargetablesComp.ShowWidgetsForTargetables(
				UInteractionComponent,
				PlayerInteractionsComp.InteractionWidgetClass
			);

			UTargetableComponent MostVisibleTargetable;
			FTargetableResult MostVisibleResult;
			PlayerTargetablesComp.GetMostVisibleTargetAndResult(
				UInteractionComponent, 
				MostVisibleTargetable,
				MostVisibleResult,
			);

			if (MostVisibleTargetable != nullptr)
			{
				PlayerInteractionsComp.bIsNearInteraction = true;
				PlayerInteractionsComp.DistanceToNearestInteraction = MostVisibleTargetable.WorldLocation.Distance(Player.ActorLocation);
			}
			else
			{
				PlayerInteractionsComp.bIsNearInteraction = false;
				PlayerInteractionsComp.DistanceToNearestInteraction = -1.0;
			}
		}
		else
		{
			PlayerInteractionsComp.bIsNearInteraction = false;
			PlayerInteractionsComp.DistanceToNearestInteraction = -1.0;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FInteractionEnterCapabilityParams& Params) const
	{
		if (!WasActionStarted(n"Interaction"))
			return false;
		if (bIsMoving)
			return false;
		if (MoveToComp.IsAnyMoveToActive())
			return false;

		UInteractionComponent PrimaryTarget = PlayerTargetablesComp.GetPrimaryTarget(UInteractionComponent);
		if (PrimaryTarget == nullptr)
			return false;

		Params.Interaction = PrimaryTarget;

		// Try to acquire the lock on the control side straight away,
		// if this succeeds, we can validate now and do the interaction in OnActivated
		Params.NetworkLock = PrimaryTarget.NetworkLock;
		Params.NetworkLock.Acquire(Player, this);

		bool bCanMoveInstantly = MoveTo::CanApplyMoveToInstantly(Player, Params.Interaction.MovementSettings, FMoveToDestination(PrimaryTarget));
		if (Params.NetworkLock.IsAcquired(Player) && bCanMoveInstantly)
		{
			Params.bStartInteraction = true;
			Params.bInteractionValidationSuccess = Params.Interaction.IsValidToUse(Player);
		}
		else
		{
			Params.bStartInteraction = false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionEnterCapabilityParams Params)
	{
		Interaction = Params.Interaction;
		NetworkLock = Params.NetworkLock;

		if (!HasControl())
			NetworkLock.Acquire(Player, this);

		// Start the movement to the interaction
		bIsMoving = true;
		
		if (Params.bStartInteraction)
		{
			// Apply the instant move to
			MoveTo::ApplyMoveToInstantly(
				Player,
				Interaction.MovementSettings,
				FMoveToDestination(Interaction)
			);
			OnMoveComplete(Player);

			// We managed to insta-lock the network lock, so start the interaction right away
			bInteractionStarted = true;

			// Remove the validation sheet since our validation succeeded immediately
			if (bHasValidationSheet)
			{
				Player.StopCapabilitySheet(PlayerInteractionsComp.DefaultValidationSheet, this);
				bHasValidationSheet = false;
			}

			if (Params.bInteractionValidationSuccess)
				StartInteraction();
		}
		else
		{
			Player.MovePlayerTo(
				Interaction.MovementSettings,
				FMoveToDestination(Interaction),
				FOnMoveToEnded(this, n"OnMoveComplete"));

			Interaction.SetPlayerValidating(Player, true);

			// We have to wait until we acquire the network lock, put the player in validation.
			// If we started non-instant movement we don't go into validation until that finishes.
			if (!bIsMoving && !bHasValidationSheet)
			{
				bHasValidationSheet = true;
				Player.StartCapabilitySheet(PlayerInteractionsComp.DefaultValidationSheet, this);
			}
		}
	}

	UFUNCTION()
	void OnMoveComplete(AHazeActor Actor)
	{
		bIsMoving = false;

		// Put the player in validation until we can start the interaction
		if (!bHasValidationSheet && IsActive())
		{
			bHasValidationSheet = true;
			Player.StartCapabilitySheet(PlayerInteractionsComp.DefaultValidationSheet, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FInteractionEnterCapabilityDeactivateParams& Params) const
	{
		// Always end the capability if the interaction is already started
		if (bInteractionStarted)
			return true;

		// If we're waiting for a lock deactivate once we have the lock and finished moving
		if (NetworkLock.IsAcquired(Player) && !bIsMoving)
		{
			// If we haven't started the interaction in OnActivated, we can start it in OnDeactivated
			if (!bInteractionStarted)
			{
				Params.bStartInteraction = true;
				Params.bInteractionValidationSuccess = Interaction.IsValidToUse(Player);
			}
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FInteractionEnterCapabilityDeactivateParams Params)
	{
		// The player might be in a validating state
		if (bHasValidationSheet)
		{
			Player.StopCapabilitySheet(PlayerInteractionsComp.DefaultValidationSheet, this);
			bHasValidationSheet = false;
		}

		Interaction.SetPlayerValidating(Player, false);

		// Interaction validation completed and we want to start the interaction now
		if (Params.bStartInteraction && !bInteractionStarted)
		{
			bInteractionStarted = true;
			if (Params.bInteractionValidationSuccess)
				StartInteraction();
		}

		// Release validation lock
		if (NetworkLock != nullptr)
			NetworkLock.Release(Player, this);

		bInteractionStarted = false;
		NetworkLock = nullptr;
		Interaction = nullptr;
	}

	void StartInteraction()
	{
		auto StartedInteraction = Interaction;

		// Actually mark the interaction as started now that it's validated
		PlayerInteractionsComp.ActiveInteraction = StartedInteraction;
		StartedInteraction.StartInteracting(Player);

		// If the interaction doesn't have a sheet, we stop it again immediately as well
		// If it does have a sheet, the rest of the interaction is handled by InteractionExitCapability.
		if (!StartedInteraction.ShouldUseInteractionSheet())
		{
			StartedInteraction.StopInteracting(Player);
			if (PlayerInteractionsComp.ActiveInteraction == Interaction)
				PlayerInteractionsComp.ActiveInteraction = nullptr;
		}
	}
};