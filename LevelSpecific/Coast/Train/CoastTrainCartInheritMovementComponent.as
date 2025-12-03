
/**
 * Special inherit component that takes care of the level-specific quirks of following the coast train carts.
 */
class UCoastTrainInheritMovementComponent : UHazeMovablePlayerTriggerComponent
{	
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_DuringPhysics;
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	// If the player ends up this far below the train, stop the follow
	UPROPERTY(EditAnywhere)
	float FallOffDistanceBelowTrain = 250.0;

	private TPerPlayer<FCoastTrainInheritMovementState> PlayerData;
	private TPerPlayer<bool> ForceEnterMovementZonePerPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnPlayerEnteredTrigger(AHazePlayerCharacter Player)
	{
		PlayerData[Player].bIsInsideTrigger = true;
		UpdateFollow(Player);
		SetComponentTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnPlayerLeftTrigger(AHazePlayerCharacter Player)
	{
		PlayerData[Player].bIsInsideTrigger = false;
		UpdateFollow(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bool bAnyPlayerInside = false;
		for(auto Player : Game::GetPlayers())
		{
			auto& PlayerDataIt = PlayerData[Player];
			UpdateFollow(Player);

			if (PlayerDataIt.bIsInsideTrigger || PlayerDataIt.bFollowActive)
				bAnyPlayerInside = true;
		}

		if (!bAnyPlayerInside)
			SetComponentTickEnabled(false);
	}

	private void UpdateFollow(AHazePlayerCharacter Player)
	{
		FCoastTrainInheritMovementState& State = PlayerData[Player];

		auto MoveComp = UPlayerMovementComponent::Get(Player);

		// Update whether the player's last ground is this cart or not
		auto CurrentGround = MoveComp.GroundContact.Component;
		auto CurrentFollow = MoveComp.GetCurrentMovementFollowAttachment();

		if ((CurrentGround != nullptr && CurrentGround.IsAttachedTo(Owner)) ||
			(CurrentFollow.IsValid() && !CurrentFollow.IsReferenceFrame() && CurrentFollow.Component.IsAttachedTo(Owner)))
		{
			// We are standing on this cart, set this as the last ground
			if (!State.bLastAttachWasThisCart)
			{
				State.bLastAttachWasThisCart = true;
			}
		}
		else
		{
			if (CurrentGround != nullptr || (CurrentFollow.IsValid() && !CurrentFollow.IsReferenceFrame()))
			{
				// We are standing on something that is not this cart, remove this as last ground
				State.bLastAttachWasThisCart = false;
			}
		}

		bool bShouldFollow = true;
		EInstigatePriority FollowPriority = EInstigatePriority::Low;

		auto WingSuitComp = UWingSuitPlayerComponent::Get(Player);
		auto TrainRiderComp = UCoastTrainRiderComponent::Get(Player);

		FVector TrainBoundsOrigin;
		FVector TrainBoundsExtent;
		Owner.GetActorBounds(true, TrainBoundsOrigin, TrainBoundsExtent);

		bool bIsBelowTrain = Player.ActorLocation.Z - (TrainBoundsOrigin.Z - TrainBoundsExtent.Z) < -FallOffDistanceBelowTrain && !Player.IsPlayerDead();
		if (bIsBelowTrain)
			bShouldFollow = false;
		// Never follow if the player is wingsuiting
		else if (WingSuitComp != nullptr && WingSuitComp.bWingsuitActive)
			bShouldFollow = false;
		else if(Player.IsCapabilityTagBlocked(n"TrainInheritMovement"))
			bShouldFollow = false;
			
		// If our last ground was this cart, the follow is high priority
		if (State.bLastAttachWasThisCart && !IsDisabledForPlayer(Player))
			FollowPriority = EInstigatePriority::High;
		else if (!State.bIsInsideTrigger)
			bShouldFollow = false;

		if(ForceEnterMovementZonePerPlayer[Player])
		{
			ForceEnterMovementZonePerPlayer[Player] = false;
			bShouldFollow = true;
		}

		if (TrainRiderComp.bHasTriggeredImpulseFromFallingOff)
			bShouldFollow = false;

		// Update the follow state in the movement component
		if (bShouldFollow)
		{
			if (!State.bFollowActive || State.ActivePriority != FollowPriority)
			{
				State.bFollowActive = true;
				State.ActivePriority = FollowPriority;

				MoveComp.FollowComponentMovement(this, this,
					EMovementFollowComponentType::ReferenceFrame,
					FollowPriority);
			}
		}
		else
		{
			if (State.bFollowActive)
			{
				State.bFollowActive = false;
				MoveComp.UnFollowComponentMovement(this);

				// If the player is falling off the train, add the train's movement as an impulse instead of following
				if (!Player.IsAnyCapabilityActive(n"Wingsuit")
					&& !Player.IsCapabilityTagBlocked(n"TrainInheritMovement")
					&& bIsBelowTrain
					&& MoveComp.GetCurrentMovementAttachmentComponent() == nullptr
					&& !TrainRiderComp.bHasTriggeredImpulseFromFallingOff)
				{
					auto Cart = Cast<ACoastTrainCart>(Owner);
					if (Cart != nullptr && Cart.Driver != nullptr)
					{
						TrainRiderComp.TriggerFallOffTrain();
						Player.AddMovementImpulse(Cart.ActorForwardVector * Cart.Driver.GetTrainSpeed());
					}
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for(auto Player : Game::GetPlayers())
		{
			if (PlayerData[Player].bFollowActive)
			{
				PlayerData[Player].bIsInsideTrigger = false;
				PlayerData[Player].bFollowActive = false;

				auto MoveComp = UPlayerMovementComponent::Get(Player);
				MoveComp.UnFollowComponentMovement(this);
			}
		}
	}

	UFUNCTION(BlueprintCallable)
	void ForceEnterMovementZone(AHazePlayerCharacter Player)
	{
		ForceEnterMovementZonePerPlayer[Player] = true;
	}
}

struct FCoastTrainInheritMovementState
{
	bool bIsInsideTrigger = false;
	bool bLastAttachWasThisCart = false;
	bool bFollowActive = false;
	EInstigatePriority ActivePriority;
};