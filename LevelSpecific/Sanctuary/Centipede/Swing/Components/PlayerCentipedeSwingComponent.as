enum ECentipedePlayerSwingRole
{
	None,
	Biter,
	Swinger
}

event void FCentipedeSwingStartEvent(AHazePlayerCharacter Player, ECentipedePlayerSwingRole SwingRole, UCentipedeSwingPointComponent SwingPoint);
event void FCentipedeSwingPointReleaseEvent(AHazePlayerCharacter Player, UCentipedeSwingPointComponent SwingPoint);
event void FCentipedeSwingJumpEvent(AHazePlayerCharacter Player);

class UPlayerCentipedeSwingComponent : UActorComponent
{
	// Added by swing bite activation capability
	UPROPERTY(NotEditable, Transient)
	private UCentipedeSwingPointComponent PendingSwingPoint;

	UPROPERTY(NotEditable, Transient)
	private UCentipedeSwingPointComponent ActiveSwingPoint;

	UPROPERTY(NotEditable, Transient)
	private UCentipedeSwingPointComponent PreviousSwingPoint;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FCentipedeSwingSettings Settings;

	UPROPERTY()
	FCentipedeSwingStartEvent OnSwingStart;

	UPROPERTY()
	FCentipedeSwingPointReleaseEvent OnSwingPointReleased;

	UPROPERTY()
	FCentipedeSwingJumpEvent OnSwingJumpEvent;

	AHazePlayerCharacter PlayerOwner;

	access Swing = private, UCentipedeSwingCapability;
	access : Swing bool bSwinging;

	access SwingBite = private, UCentipedeSwingBiteCapability;
	access : SwingBite bool bSwingBiting;
	access : SwingBite bool bImmediateNetworkSwingBiting;

	private bool bWasBitingSwingPoint = false;
	private bool bStartedLeadJump = false;

	access SwingJump = private, UCentipedeSwingJumpCapability;
	access : SwingJump bool bJumping;

	access : SwingJump bool bJumpFollower;

	access : SwingJump UCentipedeSwingJumpTargetComponent SwingJumpTarget = nullptr;

	// Active when player is forced to jump
	access : SwingJump UCentipedeSwingLandTargetComponent ForcedSwingJumpTarget = nullptr;

	FVector Remote_LastPredictedSwingLocation;

	private float LastActivationTimeStamp = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		OnSwingJumpEvent.AddUFunction(this, n"OnSwingJump");
	}

	void ActivateSwingPoint(UCentipedeSwingPointComponent SwingPoint)
	{
		ActiveSwingPoint = SwingPoint;
		ActiveSwingPoint.OccupySwingPoint(PlayerOwner, this);

		LastActivationTimeStamp = Time::GameTimeSeconds;
	}

	void DeactivateSwingPoint()
	{
		if (ActiveSwingPoint == nullptr)
			return;

		bWasBitingSwingPoint = true;
		PreviousSwingPoint = ActiveSwingPoint;

		ActiveSwingPoint.FreeSwingPoint(this);

		OnSwingPointReleased.Broadcast(PlayerOwner, ActiveSwingPoint);
		ActiveSwingPoint = nullptr;
	}

	void WritePendingSwingPoint(UCentipedeSwingPointComponent SwingPointComponent)
	{
		PendingSwingPoint = SwingPointComponent;
	}

	bool ConsumePendingSwingPoint(UCentipedeSwingPointComponent& OutSwingPointComponent)
	{
		if (PendingSwingPoint == nullptr)
			return false;

		OutSwingPointComponent = PendingSwingPoint;
		PendingSwingPoint = nullptr;
		return true;
	}

	bool GetAndConsumeWasBitingSwingPoint()
	{
		bool Value = bWasBitingSwingPoint;
		bWasBitingSwingPoint = false;
		return Value;
	}

	bool GetAndConsumeStartedLeadJump()
	{
		bool Value = bStartedLeadJump;
		bStartedLeadJump = false;
		return Value;
	}

	// Search for the most adequate visible target, nullptr if none
	UCentipedeSwingJumpTargetComponent FindSwingJumpTarget(FVector PlayerVelocity) const
	{
		// Eman TOOD: Arbitrary value
		if (PlayerVelocity.IsNearlyZero(200))
			return nullptr;

		// Find if there is a targetted swing point close-by
		FVector HorizontalSwingPointToPlayer = (PlayerOwner.ActorLocation - PlayerOwner.OtherPlayer.ActorLocation).ConstrainToPlane(PlayerOwner.MovementWorldUp).GetSafeNormal();
		UPlayerCentipedeSwingComponent OtherPlayerSwingComponent = UPlayerCentipedeSwingComponent::Get(PlayerOwner.OtherPlayer);

		// Loop through visible swing jump targets
		TArray<UTargetableComponent> Targetables;
		UPlayerTargetablesComponent::Get(PlayerOwner).GetVisibleTargetables(UCentipedeSwingJumpTargetComponent, Targetables);
		for (auto Targetable : Targetables)
		{
			// Don't auto aim towards the one we are jumping from
			if (Targetable == OtherPlayerSwingComponent.GetPreviousSwingPoint())
				continue;

			// Don't auto aim if a swing point's auto targeting is disabled
			UCentipedeSwingPointComponent SwingPoint = Cast<UCentipedeSwingPointComponent>(Targetable);
			if (SwingPoint != nullptr)
			{
				if (!SwingPoint.bJumpAutoTargeting)
					continue;
			}

			FVector PlayerToTargetable = (Targetable.WorldLocation - PlayerOwner.ActorLocation).GetSafeNormal();

			// Are we heading there?
			// if (PlayerVelocity.GetSafeNormal().DotProduct(PlayerToTargetable) > 0.0)

			// Is player heading up?
			if (PlayerVelocity.GetSafeNormal().DotProduct(PlayerOwner.MovementWorldUp) > 0.0)
			{
				// Are we on that side of the swing?
				if (HorizontalSwingPointToPlayer.DotProduct(PlayerToTargetable) > 0.0)
				{
					return Cast<UCentipedeSwingJumpTargetComponent>(Targetable);
				}
			}
		}

		return nullptr;
	}

	UCentipedeSwingPointComponent GetActiveSwingPoint() const
	{
		return ActiveSwingPoint;
	}

	UCentipedeSwingPointComponent GetPreviousSwingPoint() const
	{
		return PreviousSwingPoint;
	}

	float GetMaxPlayerSwingDistance() const property
	{
		return Centipede::MaxPlayerDistance + Centipede::PlayerMeshMandibleOffset + Centipede::SegmentRadius;
	}

	UFUNCTION()
	void ForceJumpToLandTarget(UCentipedeSwingLandTargetComponent LandTargetComponent)
	{
		if (LandTargetComponent == nullptr)
			return;

		// Deactivate current swing point, if any
		if (ActiveSwingPoint != nullptr)
			DeactivateSwingPoint();

		ForcedSwingJumpTarget = LandTargetComponent;
	}

	bool ConsumeForcedLandTargetJump(UCentipedeSwingLandTargetComponent& OutLandTargetComponent)
	{
		if (ForcedSwingJumpTarget == nullptr)
			return false;

		OutLandTargetComponent = ForcedSwingJumpTarget;
		ForcedSwingJumpTarget = nullptr;

		return true;
	}

	UCentipedeSwingPointComponent GetBitingSwingPoint() const
	{
		if (!IsBitingSwingPoint())
			return nullptr;

		return ActiveSwingPoint;
	}

	UFUNCTION(BlueprintPure)
	bool IsJumping()
	{
		return bJumping;
	}

	UFUNCTION(BlueprintPure)
	bool IsSwinging() const
	{
		return bSwinging;
	}

	UFUNCTION(BlueprintPure)
	bool IsBitingSwingPoint() const
	{
		return bSwingBiting;
	}

	// Should be some frames before crumbed confirmation
	bool IsImmediateNetworkBitingSwingPoint() const
	{
		return bImmediateNetworkSwingBiting;
	}

	float GetLastActivationTimeStamp() const
	{
		return LastActivationTimeStamp;
	}

	UFUNCTION()
	private void OnSwingJump(AHazePlayerCharacter Player)
	{
		if (!bJumpFollower)
			bStartedLeadJump = true;
	}

	// Call when centipede dies
	void Reset()
	{
		PreviousSwingPoint = nullptr;
		PendingSwingPoint = nullptr;
		ActiveSwingPoint = nullptr;

		SwingJumpTarget = nullptr;
		ForcedSwingJumpTarget = nullptr;

		bSwinging = false;
		bSwingBiting = false;
		bImmediateNetworkSwingBiting = false;
		bWasBitingSwingPoint = false;
		bStartedLeadJump = false;
	}
}

namespace Centipede
{
	UFUNCTION(Category = "CentipedeSwing")
	void CentipedeForceSwingJumpToLandTarget(UCentipedeSwingLandTargetComponent LandTargetComponent)
	{
		for (auto Player : Game::Players)
		{
			// if (Player.HasControl())
			{
				UPlayerCentipedeSwingComponent PlayerCentipedeSwingComponent = UPlayerCentipedeSwingComponent::Get(Player);
				if (PlayerCentipedeSwingComponent != nullptr)
					PlayerCentipedeSwingComponent.ForceJumpToLandTarget(LandTargetComponent);
			}
		}
	}
}