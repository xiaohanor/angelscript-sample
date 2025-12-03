class AForgeSiegeWeapon : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent KillBoxComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp1;
	default InteractComp1.UsableByPlayers = EHazeSelectPlayer::Both;
	default InteractComp1.InteractionCapability = n"ForgeSiegeWeaponMovementCapability";

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp2;
	default InteractComp2.UsableByPlayers = EHazeSelectPlayer::Both;
	default InteractComp2.InteractionCapability = n"ForgeSiegeWeaponMovementCapability";


	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent Camera;
	

	float MoveSpeed = 550.0;
	float RotationSpeed = 20.0;

	float LeftInput;
	float RightInput;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp1.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractComp1.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");

		InteractComp2.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractComp2.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");

	}





	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{	
		float InputDifference = LeftInput - RightInput;
		float DeltaRotationOffset = RotationSpeed * InputDifference * DeltaSeconds;

		ActorRotation += FRotator(0.0, DeltaRotationOffset, 0.0);

		
		ActorLocation += ActorForwardVector * (LeftInput + RightInput) * MoveSpeed * DeltaSeconds;
	}


	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		Player.DeactivateCamera(Camera, 2.0);
	}


	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{

		Player.ActivateCamera(Camera, 2.0, this);

		UForgeSiegePlayerComponent PlayerComp = UForgeSiegePlayerComponent::Get(Player);

		if(Interaction == InteractComp1)
			PlayerComp.bIsLeft = true;
		else
			PlayerComp.bIsLeft = false;

	}


}