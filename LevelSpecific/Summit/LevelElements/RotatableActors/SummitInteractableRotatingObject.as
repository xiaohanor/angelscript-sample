event void FOnSummitInteractableRotatingObjectActivated();
event void FOnSummitInteractableRotatingObjectRotating(float RotationRadians);
event void FOnSummitInteractableRotatingObjectReleased();

class ASummitInteractableRotatingObject : AHazeActor
{
	FOnSummitInteractableRotatingObjectActivated OnActivated;
	FOnSummitInteractableRotatingObjectRotating OnRotating;
	FOnSummitInteractableRotatingObjectReleased OnReleased;

	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsAxisRotateComponent RotationComponent;

	UPROPERTY(DefaultComponent, Attach = RotationComponent)
	UInteractionComponent InteractComp;
	default InteractComp.InteractionCapability = n"TailRotationInteractionCapability";
	default InteractComp.UsableByPlayers = EHazeSelectPlayer::Zoe;

	// Doing Teleport manually for dragon, don't want to move player
	default InteractComp.MovementSettings.Type = EMoveToType::NoMovement;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Only Zoe is able to interact with this, so makes sense to sync it on that players side
		SetActorControlSide(Game::Zoe);
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbRotate(float Radians)
	{
		FauxPhysics::ApplyFauxMovementToParentsAt(RotationComponent, RotationComponent.WorldLocation + RotationComponent.ForwardVector * 5000, RotationComponent.RightVector * Radians);
		OnRotating.Broadcast(Radians);
	}

	void EnterInteraction()
	{
		OnActivated.Broadcast();
	}

	void ExitInteraction()
	{
		OnReleased.Broadcast();
	}
}