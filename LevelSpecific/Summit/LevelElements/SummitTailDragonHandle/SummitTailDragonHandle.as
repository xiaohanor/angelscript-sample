event void FONHandleMoving(float Forward, FVector Direction, float DeltaTime);


class ASummitTailDragonHandle : AHazeActor
{
	FONHandleMoving OnHandleMoving;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DragonLocation;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent Camera;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;
	default InteractComp.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default InteractComp.InteractionCapability = n"SummitTailDragonHandleCapability";


	UPROPERTY(EditAnywhere)
	TArray<AActor> AttachedActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractComp.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
	}


	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{

		Player.ActivateCamera(Camera, 2.0, this);
	}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		Player.DeactivateCamera(Camera, 2.0);
	}

}