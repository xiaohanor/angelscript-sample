class ASolarFlareBasicCoverRaisable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot, ShowOnActor)
	USolarFlarePlayerCoverComponent CoverPlayerComp;

	UPROPERTY(DefaultComponent)
	USolarFlareEffectComponent EffectComp;

	UPROPERTY(DefaultComponent)
	USolarFlareFireWaveReactionComponent WaveReactComp;

	UPROPERTY(EditInstanceOnly)
	ADoubleInteractionActor DoubleInteract;

	UPROPERTY(EditInstanceOnly)
	ARespawnPoint RespawnPoint;

	UPROPERTY(EditInstanceOnly)
	bool bStartUp;

	UPROPERTY(EditInstanceOnly)
	float DelayForMove = 0.0;

	FVector TargetLocation;
	FVector StartLocation;
	float ZOffset = -600.0;
	
	UPROPERTY(EditAnywhere)
	float MoveSpeed = 800.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (DoubleInteract != nullptr)
			DoubleInteract.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted");
		
		if (!bStartUp)
		{
			TargetLocation = ActorLocation;
			ActorLocation += FVector(0,0,ZOffset);
			StartLocation = ActorLocation;
		}
		else
		{
			StartLocation = ActorLocation;
			TargetLocation = ActorLocation + FVector(0,0,ZOffset);
		}
		
		SetActorTickEnabled(false);
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (DelayForMove > 0.0)
		{
			DelayForMove -= DeltaSeconds;
			return;
		}

		ActorLocation = Math::VInterpConstantTo(ActorLocation, TargetLocation, DeltaSeconds, MoveSpeed);
		if (ActorLocation == TargetLocation)
		{
			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (RespawnPoint != nullptr)
					Player.SetStickyRespawnPoint(RespawnPoint);
			}
			SetActorTickEnabled(false);
			USolarFlareBasicCoverRaisableEventHandler::Trigger_OnCoverEndMove(this);
		}
	}

	UFUNCTION()
	void ActivateCover()
	{
		USolarFlareBasicCoverRaisableEventHandler::Trigger_OnCoverStartMove(this);
		SetActorTickEnabled(true);		
	}

	UFUNCTION()
	void SetEndState()
	{
		ActorLocation = TargetLocation;
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (RespawnPoint != nullptr)
				Player.SetStickyRespawnPoint(RespawnPoint);
		}

		Timer::SetTimer(this, n"Wiggle", 0.01);
	}

	UFUNCTION()
	private void Wiggle()
	{
		ActorLocation = ActorLocation + FVector(0, 0, 0.01);
	}

	UFUNCTION()
	private void OnDoubleInteractionCompleted()
	{
		USolarFlareBasicCoverRaisableEventHandler::Trigger_OnCoverStartMove(this);
		SetActorTickEnabled(true);
		DoubleInteract.AddActorDisable(this);
	}
}