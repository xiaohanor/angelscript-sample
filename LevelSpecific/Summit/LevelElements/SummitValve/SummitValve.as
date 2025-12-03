event void FOnValveRotate();

class ASummitValve : AHazeActor
{
	FOnValveRotate OnValveRotate;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent Camera;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UInteractionComponent InteractComp;
	default InteractComp.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default InteractComp.InteractionCapability = n"ForgeTrackPusherCapability";

	UPROPERTY(EditAnywhere)
	TArray<AActor> ConnectedActors;


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