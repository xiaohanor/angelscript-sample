class ASanctuaryCentipedeTranslateActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UCentipedeBiteResponseComponent BiteResponseComp;
	default BiteResponseComp.bBlocksPlayerMovement = true;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent MeshComp;
	default MeshComp.RelativeScale3D = FVector(0.75, 0.75, 1.5);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryCentipedeTranslateCapability");

	UPROPERTY(EditAnywhere)
	float Speed = 2000;

	AHazePlayerCharacter ControllingPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BiteResponseComp.OnCentipedeBiteStarted.AddUFunction(this, n"HandleBiteStarted");
		BiteResponseComp.OnCentipedeBiteStopped.AddUFunction(this, n"HandleBiteStopped");
	}

	UFUNCTION()
	private void HandleBiteStarted(FCentipedeBiteEventParams BiteParams)
	{
		ControllingPlayer = FCentipedeBiteEventParams().Player;
		MeshComp.SetRelativeScale3D(FVector(0.5, 0.5, 1.5));
		CapabilityInput::LinkActorToPlayerInput(this, ControllingPlayer);
	}

	UFUNCTION()
	private void HandleBiteStopped(FCentipedeBiteEventParams BiteParams)
	{
		ControllingPlayer = nullptr;
		MeshComp.SetRelativeScale3D(FVector(0.75, 0.75, 1.5));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (IsValid(ControllingPlayer))
		{
			ControllingPlayer.SetActorLocation(BiteResponseComp.WorldLocation + FVector::UpVector * 25);
		}
	}
};
