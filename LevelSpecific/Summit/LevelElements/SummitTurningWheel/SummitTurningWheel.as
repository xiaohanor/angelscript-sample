event void FOnWheelTurning(float TurnAmount);


class ASummitTurningWheel : AHazeActor
{
	FOnWheelTurning OnWheelTurning;


	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBillboardComponent PlayerAttachComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UInteractionComponent InteractComp;
	default InteractComp.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default InteractComp.InteractionCapability = n"TeenDragonSummitWheelTurningCapability";

	UPROPERTY(EditAnywhere)
	AHazeCameraActor Camera;

	UPROPERTY(EditAnywhere)
	TArray<AActor> AttachedActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractComp.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");

		for(AActor Actor : AttachedActors)
		{
			Actor.AttachToComponent(MeshRoot, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		}
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