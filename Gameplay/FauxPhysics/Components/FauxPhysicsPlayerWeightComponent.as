event void FFauxPhysicsPlayerWeightComponentSignature();

class UFauxPhysicsPlayerWeightComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	// Force applied at Player Location in Gravity Direction
	UPROPERTY(EditAnywhere)
	float PlayerForce = 500.0;

	// Amount of Velocity to use for impact impulse
	UPROPERTY(EditAnywhere)
	float PlayerImpulseScale = 0.0;

	UPROPERTY(EditAnywhere)
	bool bAffectedByGroundImpact = true;

	UPROPERTY(EditAnywhere)
	bool bAffectedByWallImpact = true;

	UPROPERTY()
	FFauxPhysicsPlayerWeightComponentSignature OnAffected;

	UPROPERTY()
	FFauxPhysicsPlayerWeightComponentSignature OnUnaffected;

	TArray<AHazePlayerCharacter> Players;

	TArray<FInstigator> DisableInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors;
		Owner.GetAttachedActors(AttachedActors, true, true);
		AttachedActors.Add(Owner);

		for (auto AttachedActor : AttachedActors)
		{
			// Setup events from Player ground impacts
			auto MovementImpactCallbackComponent = UMovementImpactCallbackComponent::GetOrCreate(AttachedActor);
			if (bAffectedByGroundImpact)
			{
				MovementImpactCallbackComponent.OnGroundImpactedByPlayer.AddUFunction(this, n"HandleAddPlayer");
				MovementImpactCallbackComponent.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"HandleRemovePlayer");
			}

			if (bAffectedByWallImpact)
			{
				MovementImpactCallbackComponent.OnAttachedToWallByPlayer.AddUFunction(this, n"AttachHandleAddPlayer");
				MovementImpactCallbackComponent.OnWallAttachByPlayerEnded.AddUFunction(this, n"AttachHandleRemovePlayer");
			}

			// Setup events from PerchPoints
			TArray<UPerchPointComponent> PerchPointComponents;
			AttachedActor.GetComponentsByClass(PerchPointComponents);

			for (auto PerchPointComponent : PerchPointComponents)
			{
				auto PerchSpline = Cast<APerchSpline>(PerchPointComponent.Owner);
				if (PerchSpline != nullptr)
				{
					PerchSpline.OnPlayerLandedOnSpline.AddUFunction(this, n"PerchSplineHandleAddPlayer");
					PerchSpline.OnPlayerJumpedOnSpline.AddUFunction(this, n"PerchSplineHandleRemovePlayer");
					continue;
				}

				PerchPointComponent.OnPlayerStartedPerchingEvent.AddUFunction(this, n"PerchHandleAddPlayer");
				PerchPointComponent.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"PerchHandleRemovePlayer");
			}

			// Setup events from SwingPoints
			TArray<USwingPointComponent> USwingPointComponents;
			AttachedActor.GetComponentsByClass(USwingPointComponents);

			for (auto USwingPointComponent : USwingPointComponents)
			{
				USwingPointComponent.OnPlayerAttachedEvent.AddUFunction(this, n"SwingHandleAddPlayer");
				USwingPointComponent.OnPlayerDetachedEvent.AddUFunction(this, n"SwingHandleRemovePlayer");
			}

			// Setup events from PoleActors
			auto AsPoleActor = Cast<APoleClimbActor>(AttachedActor);
			if (AsPoleActor != nullptr)
			{
				AsPoleActor.OnStartPoleClimb.AddUFunction(this, n"PoleClimbHandleAddPlayer");
				AsPoleActor.OnStopPoleClimb.AddUFunction(this, n"PoleClimbHandleRemovePlayer");
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds) final
	{
		bool bHasMio = false;
		bool bHasZoe = false;
		for (auto Player : Players)
		{
			if (Player.IsMio())
			{
				if (bHasMio)
					continue;
				bHasMio = true;
			}
			else
			{
				if (bHasZoe)
					continue;
				bHasZoe = true;
			}

			ApplyPlayerWeight(Player);
		}

		if (Players.Num() == 0)
			SetComponentTickEnabled(false);
	}

	protected void ApplyPlayerWeight(AHazePlayerCharacter Player)
	{
		FauxPhysics::ApplyFauxForceToActorAt(Owner, Player.ActorLocation, -Player.MovementWorldUp * PlayerForce);
	}

	UFUNCTION()
	private void HandleAddPlayer(AHazePlayerCharacter Player)
	{
		AddPlayer(Player);
	}

	UFUNCTION()
	private void PerchHandleAddPlayer(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		HandleAddPlayer(Player);
	}


	UFUNCTION()
	private void PerchSplineHandleAddPlayer(AHazePlayerCharacter Player)
	{
		HandleAddPlayer(Player);
	}

	UFUNCTION()
	private void PoleClimbHandleAddPlayer(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		HandleAddPlayer(Player);
	}

	UFUNCTION()
	private void SwingHandleAddPlayer(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		HandleAddPlayer(Player);
	}

	UFUNCTION()
	private void AttachHandleAddPlayer(AHazePlayerCharacter Player)
	{
		HandleAddPlayer(Player);
	}

	UFUNCTION()
	private void HandleRemovePlayer(AHazePlayerCharacter Player)
	{
		RemovePlayer(Player);
	}

	UFUNCTION()
	private void PerchHandleRemovePlayer(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		HandleRemovePlayer(Player);
	}

	UFUNCTION()
	private void PerchSplineHandleRemovePlayer(AHazePlayerCharacter Player)
	{
		HandleRemovePlayer(Player);
	}

	UFUNCTION()
	private void PoleClimbHandleRemovePlayer(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		HandleRemovePlayer(Player);
	}

	UFUNCTION()
	private void SwingHandleRemovePlayer(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		HandleRemovePlayer(Player);
	}

	UFUNCTION()
	private void AttachHandleRemovePlayer(AHazePlayerCharacter Player)
	{
		HandleRemovePlayer(Player);
	}

	private void AddPlayer(AHazePlayerCharacter Player)
	{
		if (Players.Contains(Player))
			return;

		auto MovementComponent = UHazeMovementComponent::Get(Player);
		FauxPhysics::ApplyFauxImpulseToActorAt(Owner, Player.ActorLocation, MovementComponent.PreviousVelocity * PlayerImpulseScale);

		if (Players.Num() == 0)
			OnAffected.Broadcast();

		Players.Add(Player);
		SetComponentTickEnabled(true);
	}

	private void RemovePlayer(AHazePlayerCharacter Player)
	{
		if (!Players.Contains(Player))
			return;

		Players.Remove(Player);

		if (Players.Num() == 0)
			OnUnaffected.Broadcast();		
	}

	UFUNCTION()
	void AddDisabler(FInstigator DisableInstigator)
	{
		DisableInstigators.Add(DisableInstigator);
		AddComponentTickBlocker(DisableInstigator);
	}

	UFUNCTION()
	void RemoveDisabler(FInstigator DisableInstigator)
	{
		DisableInstigators.Remove(DisableInstigator);
		RemoveComponentTickBlocker(DisableInstigator);
	}

	UFUNCTION()
	void RemoveAllDisablers(FInstigator DisableInstigator)
	{
		for (auto Disabler : DisableInstigators)
			RemoveComponentTickBlocker(Disabler);
		
		DisableInstigators.Empty();
	}

	UFUNCTION(BlueprintPure)
	bool IsEnabled()
	{
		return DisableInstigators.Num() == 0;
	}
}