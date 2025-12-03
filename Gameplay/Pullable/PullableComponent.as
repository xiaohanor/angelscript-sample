
event void FOnPullableCompleted(AHazePlayerCharacter Player);
event void FOnPullableEvent(AHazePlayerCharacter Player);

/**
 * Component for an actor that can be pulled along a spline by one or more players.
 */
class UPullableComponent : UActorComponent
{
	// Spline that the pullable starts on
	UPROPERTY(EditInstanceOnly, Category = "Pullable")
	AActor Spline;

	// Maximum units per second that the pullable can be moved
	UPROPERTY(EditAnywhere, Category = "Pullable")
	float PullSpeed = 300.0;

	// Acceleration to the pull speed while input is being held
	UPROPERTY(EditAnywhere, Category = "Pullable")
	float PullAcceleration = 600.0;

	// Deceleration for pulling when no input is being held anymore
	UPROPERTY(EditAnywhere, Category = "Pullable")
	float PullDeceleration = 10000.0;

	/**
	 * Whether both players are required to pull the actor.
	 * Note that the actor should then have two interaction points so both players can actually interact.
	 */
	UPROPERTY(EditAnywhere, Category = "Pullable")
	bool bRequireBothPlayers = false;

	/**
	 * When the pullable reaches the end of the spline, the player(s) stop pulling,
	 * and the OnPullableCompleted event fires.
	 */
	UPROPERTY(EditAnywhere, Category = "Pullable")
	bool bCompleteAtEndOfSpline = false;

	/**
	 * Animation feature to use when the player is pulling.
	 */
	UPROPERTY(EditAnywhere, Category = "Pullable")
	TPerPlayer<UHazeLocomotionFeatureBase> PullAnimationFeature;

	/**
	 * When no player is holding the pullable, automatically pull back on the spline.
	 */
	UPROPERTY(EditAnywhere, Category = "Pullback")
	bool bAutomaticallyPullBack = false;

	/**
	 * How fast to pull back when no player is holding it.
	 */
	UPROPERTY(EditAnywhere, Category = "Pullback", Meta = (EditConditionHides, EditCondition = "bAutomaticallyPullBack"))
	float PullBackSpeed = 300.0;

	/**
	 * How fast to accelerate the pullback when no player is holding it.
	 */
	UPROPERTY(EditAnywhere, Category = "Pullback", Meta = (EditConditionHides, EditCondition = "bAutomaticallyPullBack"))
	float PullBackAcceleration = 600.0;

	// Called when a player starts pulling the pullable
	UPROPERTY()
	FOnPullableEvent OnStartedPulling;

	// Called when a player stops pulling the pullable
	UPROPERTY()
	FOnPullableEvent OnStoppedPulling;

	// Called when the pullable reaches the end of the spline and bCompleteAtEndOfSpline is on
	UPROPERTY()
	FOnPullableCompleted OnPullableCompleted;

	private TPerPlayer<FPullablePlayerState> PerPlayerState;
	private FSplinePosition CurrentPosition;
	private UHazeCrumbSyncedActorPositionComponent SyncPosition;
	private uint LastMovedFrame = 0;
	private bool bCompleted = false;
	private float ActivePullSpeed = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (Spline == nullptr)
		{
			devError(f"Pullable {Owner.Name} does not have a valid spline set.");
			return;
		}

		auto SplineComp = Spline::GetGameplaySpline(Spline, this);
		if (SplineComp == nullptr)
		{
			devError(f"Pullable {Owner.Name} has {Spline.Name} set as its Spline, but that does not have a spline component.");
			return;
		}

		CurrentPosition = SplineComp.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);

		// Teleport the actor to the closest position on the spline to start with
		FTransform CurrentTransform = CurrentPosition.WorldTransform;
		Owner.SetActorLocationAndRotation(CurrentTransform.Location, CurrentTransform.Rotator());
	}

	void StartPulling(AHazePlayerCharacter Player, UInteractionComponent Interaction)
	{
		FPullablePlayerState& State = PerPlayerState[Player];
		State.bIsPulling = true;
		State.Interaction = Interaction;
		State.SyncPullInput = UHazeCrumbSyncedFloatComponent::GetOrCreate(
			Owner, Player.IsZoe() ? n"PullInput_Zoe" : n"PullInput_Mio"
		);
		State.SyncPullInput.OverrideSyncRate(EHazeCrumbSyncRate::High);
		State.SyncPullInput.OverrideControlSide(Player);

		if (SyncPosition == nullptr)
		{
			SyncPosition = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner);
			SyncPosition.OverrideSyncRate(EHazeCrumbSyncRate::High);
		}

		if (!bRequireBothPlayers && !AreBothPlayersPulling())
			Owner.SetActorControlSide(Player);

		OnStartedPulling.Broadcast(Player);
	}

	void StopPulling(AHazePlayerCharacter Player)
	{
		FPullablePlayerState& State = PerPlayerState[Player];
		State.bIsPulling = false;
		ActivePullSpeed = 0.0;

		OnStoppedPulling.Broadcast(Player);
	}

	void ApplyPullInput(AHazePlayerCharacter Player, FVector MovementInput, float DeltaTime)
	{
		if (!Player.HasControl())
			return;

		FVector CurrentForward = CurrentPosition.WorldForwardVector;

		float PullOnSpline = CurrentForward.DotProduct(MovementInput);
		if (Math::Abs(PullOnSpline) > 0.2)
			PullOnSpline = Math::Sign(PullOnSpline);
		else
			PullOnSpline = 0.0;

		FPullablePlayerState& State = PerPlayerState[Player];
		State.PullInput = PullOnSpline;
		State.SyncPullInput.Value = State.PullInput;
	}

	void ApplyPullableMovement(float DeltaTime)
	{
		if (LastMovedFrame == GFrameNumber)
			return;
		LastMovedFrame = GFrameNumber;

		if (!CurrentPosition.IsValid())
			return;

		if (HasControl())
		{
			// Check if we should apply the movement to the actor now or wait until later
			float ActiveDirection = GetActivePullDirection();
			float TargetPullSpeed = ActiveDirection * PullSpeed;

			if (ActiveDirection == 0.0)
			{
				ActivePullSpeed = Math::FInterpConstantTo(
					ActivePullSpeed, TargetPullSpeed,
					DeltaTime, PullDeceleration
				);
			}
			else
			{
				ActivePullSpeed = Math::FInterpConstantTo(
					ActivePullSpeed, TargetPullSpeed,
					DeltaTime, PullAcceleration
				);
			}
		}

		MoveBasedOnPullSpeed(DeltaTime);
	}

	void ApplyPullBack(float DeltaTime)
	{
		if (LastMovedFrame == GFrameNumber)
			return;
		LastMovedFrame = GFrameNumber;

		if (!CurrentPosition.IsValid())
			return;

		if (HasControl())
		{
			float TargetPullSpeed = -PullBackSpeed;

			if (CurrentPosition.GetCurrentSplineDistance() > 0.0)
			{
				ActivePullSpeed = Math::FInterpConstantTo(
					ActivePullSpeed, TargetPullSpeed,
					DeltaTime, PullBackAcceleration
				);
			}
			else
			{
				ActivePullSpeed = 0.0;
			}
		}

		if (CurrentPosition.GetCurrentSplineDistance() > 0.0)
			MoveBasedOnPullSpeed(DeltaTime);
	}

	private void MoveBasedOnPullSpeed(float DeltaTime)
	{
		if (!CurrentPosition.IsValid())
			return;

		if (SyncPosition == nullptr)
		{
			SyncPosition = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner);
			SyncPosition.OverrideSyncRate(EHazeCrumbSyncRate::High);
		}

		if (HasControl())
		{
			if (ActivePullSpeed != 0.0)
			{
				bool bCanContinue = CurrentPosition.Move(ActivePullSpeed * DeltaTime);

				FTransform CurrentTransform = CurrentPosition.WorldTransform;
				Owner.SetActorLocationAndRotation(CurrentTransform.Location, CurrentTransform.Rotator());

				// Always sync relative to the spline
				SyncPosition.ApplySplineRelativePositionSync(this, CurrentPosition);

				if (!bCanContinue && bCompleteAtEndOfSpline && !bCompleted)
				{
					// Check if we should 'complete' the pullable
					bool bReachedEnd = false;
					if (CurrentPosition.IsForwardOnSpline())
						bReachedEnd = Math::IsNearlyEqual(CurrentPosition.CurrentSplineDistance, CurrentPosition.CurrentSpline.SplineLength);
					else
						bReachedEnd = Math::IsNearlyEqual(CurrentPosition.CurrentSplineDistance, 0.0);

					if (bReachedEnd)
						CrumbCompletePullable();
				}
			}
		}
		else
		{
			// Apply the position from the synced component
			FHazeSyncedActorPosition Position = SyncPosition.GetPosition();
			Owner.SetActorLocationAndRotation(Position.WorldLocation, Position.WorldRotation);

			CurrentPosition = Position.GetSyncedSplinePosition();
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbCompletePullable()
	{
		bCompleted = true;

		AHazePlayerCharacter PullingPlayer;
		for (auto Player : Game::Players)
		{
			FPullablePlayerState& State = PerPlayerState[Player];
			if (!State.bIsPulling)
				continue;

			PullingPlayer = Player;
			if (State.Interaction != nullptr)
			{
				State.Interaction.Disable(FInstigator(this, n"PullableFinished"));
				State.Interaction.KickAnyPlayerOutOfInteraction();
			}
		}

		if (bRequireBothPlayers)
			OnPullableCompleted.Broadcast(nullptr);
		else
			OnPullableCompleted.Broadcast(PullingPlayer);
	}

	float GetWantedPullDirection(AHazePlayerCharacter Player) const
	{
		const FPullablePlayerState& State = PerPlayerState[Player];
		return State.SyncPullInput.Value;
	}

	float GetActivePullDirection() const
	{
		float Direction = 0.0;
		int PullingPlayerCount = 0;

		bool bAnyNotPulling = false;

		for (const FPullablePlayerState& State : PerPlayerState)
		{
			if (State.bIsPulling && Math::Abs(State.SyncPullInput.Value) > 0.1)
			{
				Direction += State.SyncPullInput.Value;
				PullingPlayerCount += 1;
			}
			else
			{
				bAnyNotPulling = true;
			}
		}

		if (bAnyNotPulling && bRequireBothPlayers)
			return 0.0;
		if (PullingPlayerCount == 0)
			return 0.0;
		return Direction / float(PullingPlayerCount);
	}

	bool AreBothPlayersPulling() const
	{
		for (const FPullablePlayerState& State : PerPlayerState)
		{
			if (!State.bIsPulling)
				return false;
		}

		return true;
	}

	bool IsAnyPlayerPulling() const
	{
		for (const FPullablePlayerState& State : PerPlayerState)
		{
			if (State.bIsPulling)
				return true;
		}

		return false;
	}

	float GetPulledDistanceOnSpline() const
	{
		return CurrentPosition.GetCurrentSplineDistance();
	}
};

struct FPullablePlayerState
{
	bool bIsPulling = false;
	float PullInput = 0.0;
	UInteractionComponent Interaction;
	UHazeCrumbSyncedFloatComponent SyncPullInput;
};