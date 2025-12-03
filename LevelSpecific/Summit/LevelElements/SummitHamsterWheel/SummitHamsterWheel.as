class ASummitHamsterWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent RotateRoot;
	default RotateRoot.LocalRotationAxis = FVector(0.0, 1.0, 0.0);

	UPROPERTY(EditAnywhere)
	AHazeCameraActor Camera;

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractComp;
	default InteractComp.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default InteractComp.InteractionCapability = n"TeenDragonHamsterWheelRollingCapability";

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedCurrentRollPosition;
	// Overridden when interacting
	default SyncedCurrentRollPosition.SyncRate = EHazeCrumbSyncRate::Low;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float RollSpeed = 50.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (Camera != nullptr)
			Camera.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		SyncedCurrentRollPosition.Value = 0.0;

		SetActorControlSide(Game::Zoe);
	}
};