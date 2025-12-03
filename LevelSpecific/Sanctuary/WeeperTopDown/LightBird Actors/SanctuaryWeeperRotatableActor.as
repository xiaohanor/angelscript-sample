class ASanctuaryWeeperRotatableActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USimplePlayerInputReceivingComponenent PlayerInputComp;
	default PlayerInputComp.PlayerInput = EHazePlayer::Mio;
	

	UPROPERTY(EditAnywhere)
	ASanctuaryWeeperLightBirdSocket Socket;

	bool bActivated;

	UPROPERTY(EditAnywhere)
	float Speed = 100.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Socket.OnActivated.AddUFunction(this, n"OnActivated");
		Socket.OnDeactivated.AddUFunction(this, n"OnDeactivated");

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bActivated)
			return;
	
		AddActorLocalRotation(FRotator(0, PlayerInputComp.Input.X * Speed * DeltaSeconds, 0));
	
	}

	UFUNCTION()
	private void OnActivated(ASanctuaryWeeperLightBird LightBird)
	{
		bActivated = true;
	}

	UFUNCTION()
	private void OnDeactivated(ASanctuaryWeeperLightBird LightBird)
	{
		bActivated = false;
	}
};