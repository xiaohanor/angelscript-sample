event void FSanctuaryPlayerWeightComponentSignature();

class USanctuaryPlayerWeightComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	// Force applied at Player Location in Gravity Direction
	UPROPERTY(EditAnywhere)
	float PlayerForce = 500.0;

	// Amount of Velocity to use for impact impulse
	UPROPERTY(EditAnywhere)
	float PlayerImpulseScale = 0.0;

	UPROPERTY()
	FSanctuaryPlayerWeightComponentSignature OnAffected;

	UPROPERTY()
	FSanctuaryPlayerWeightComponentSignature OnUnaffected;

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

			MovementImpactCallbackComponent.OnGroundImpactedByPlayer.AddUFunction(this, n"HandleAddPlayer");
			MovementImpactCallbackComponent.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"HandleRemovePlayer");

			// Setup events from PerchPoints
			TArray<UPerchPointComponent> PerchPointComponents;
			AttachedActor.GetComponentsByClass(PerchPointComponents);

			for (auto PerchPointComponent : PerchPointComponents)
			{
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
	void Tick(float DeltaSeconds)
	{
		for (auto Player : Players)
		{
		//	PrintToScreen("Affected by: " + Player, 0.0, FLinearColor::Green);

			FauxPhysics::ApplyFauxForceToActorAt(Owner, Player.ActorLocation, -Player.MovementWorldUp * PlayerForce);
		//	Debug::DrawDebugLine(Player.ActorLocation, Player.ActorLocation - Player.MovementWorldUp * PlayerForce, FLinearColor::Green, 10.0, 0.0);
		}
	}

	UFUNCTION()
	private void HandleAddPlayer(AHazePlayerCharacter Player)
	{
		if (!Player.HasControl())
			return;

		CrumbAddPlayer(Player);
	}

	UFUNCTION()
	private void PerchHandleAddPlayer(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
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
	private void HandleRemovePlayer(AHazePlayerCharacter Player)
	{
		if (!Player.HasControl())
			return;

		CrumbRemovePlayer(Player);
	}

	UFUNCTION()
	private void PerchHandleRemovePlayer(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
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

	UFUNCTION(CrumbFunction)
	private void CrumbAddPlayer(AHazePlayerCharacter Player)
	{
		auto MovementComponent = UHazeMovementComponent::Get(Player);
		FauxPhysics::ApplyFauxImpulseToActorAt(Owner, Player.ActorLocation, MovementComponent.PreviousVelocity * PlayerImpulseScale);

		if (Players.Num() == 0)
		{
			OnAffected.Broadcast();
			SetComponentTickEnabled(true);
		}

		Players.AddUnique(Player);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbRemovePlayer(AHazePlayerCharacter Player)
	{
		Players.Remove(Player);

		if (Players.Num() == 0)
		{
			OnUnaffected.Broadcast();		
			SetComponentTickEnabled(false);
		}
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
}