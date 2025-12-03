event void FOnSolarFlareBatteryLiftReachedTop(bool bPlayerOnLift);
event void FOnSolarFlareBatteryLiftNearTop(bool bPlayerOnLift);

class ASolarFlareBatteryLift : AHazeActor
{
	UPROPERTY()
	FOnSolarFlareBatteryLiftReachedTop OnSolarFlareBatteryLiftReachedTop;
	UPROPERTY()
	FOnSolarFlareBatteryLiftNearTop OnSolarFlareBatteryLiftNearTop;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxOverlap;
	default BoxOverlap.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BoxOverlap.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(EditAnywhere)
	bool bUseDoubleInteract = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = !bUseDoubleInteract, EditConditionHides))
	ASolarFlareBatteryPerch Battery;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = bUseDoubleInteract, EditConditionHides))
	ADoubleInteractionActor DoubleInteract;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect Rumble;

	FVector Start;
	FVector End;

	UPROPERTY(EditAnywhere)
	float ZOffset = -800.0;
	UPROPERTY(EditAnywhere)
	float Speed = 15000.0;
	UPROPERTY(EditAnywhere)
	float Acceleration = 0.8;
	UPROPERTY(EditAnywhere)
	ALadder Ladder;
	UPROPERTY(EditAnywhere)
	ADeathVolume DeathVolume;
	UPROPERTY(EditAnywhere)
	float NearTopRegisterEventThresholdDistance = 600.0;

	TPerPlayer<bool> bPlayerOnLift;

	bool bIsMoving;
	bool bMovingUp;
	bool bLiftIsOn;
	bool bFenceActivated;
	bool bRegisterNearTopEvent = false;
	float DoubleInteractTime = 0;

	FVector FenceEnd;

	FHazeAcceleratedVector AccelVec;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Start = ActorLocation;
		End = ActorLocation + FVector(0,0,ZOffset);
		AccelVec.Value = ActorLocation;

		if (!bUseDoubleInteract)
		{
			Battery.OnSolarFlareBatteryPerchActivated.AddUFunction(this, n"OnSolarFlareBatteryPerchActivated");
			Battery.OnSolarFlareBatteryPerchDeactivated.AddUFunction(this, n"OnSolarFlareBatteryPerchDeactivated");
		}
		else
		{
			DoubleInteract.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted");
		}

		if(DeathVolume != nullptr)
			DeathVolume.DisableDeathVolume(this);

		BoxOverlap.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		BoxOverlap.OnComponentEndOverlap.AddUFunction(this, n"OnComponentEndOverlap");

		SetActorEnableCollision(false);
		SetActorEnableCollision(true);
	}

	UFUNCTION()
	void DelayedCollisionRejig()
	{
		SetActorEnableCollision(false);
		SetActorEnableCollision(true);
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor); 
		if (Player != nullptr)
			bPlayerOnLift[Player] = true;
	}

	UFUNCTION()
	private void OnComponentEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                   UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor); 
		
		if (Player != nullptr)
			bPlayerOnLift[Player] = false;		
	}

	UFUNCTION()
	private void OnSolarFlareBatteryPerchActivated(AHazePlayerCharacter Player)
	{
		bLiftIsOn = true;

		for (AHazePlayerCharacter CurrentPlayer : Game::Players)
		{
			if (bPlayerOnLift[CurrentPlayer])
				CurrentPlayer.PlayForceFeedback(Rumble, false, false, this);
		}

		if(DeathVolume != nullptr)
			DeathVolume.EnableDeathVolume(this);
	}

	UFUNCTION()
	private void OnSolarFlareBatteryPerchDeactivated()
	{
		bLiftIsOn = false;

		for (AHazePlayerCharacter CurrentPlayer : Game::Players)
		{
			if (bPlayerOnLift[CurrentPlayer])
				CurrentPlayer.PlayForceFeedback(Rumble, false, false, this);
		}

		if(DeathVolume != nullptr)
			DeathVolume.DisableDeathVolume(this);
	}


	UFUNCTION()
	private void OnDoubleInteractionCompleted()
	{
		bLiftIsOn = true;
		DoubleInteract.DisableDoubleInteraction(this);
		USolarFlareBatteryLiftEffectHandler::Trigger_OnDoubleInteractUsed(this);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (bPlayerOnLift[Player])
				Player.PlayForceFeedback(Rumble, false, false, this);

			Player.BlockCapabilities(CapabilityTags::Input, this);
			Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		}
		
		Ladder.Disable(this);
		DoubleInteractTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector Target = Start;

		if (bLiftIsOn)
		{
			Target = End;

			if (Target.Z < ActorLocation.Z && bMovingUp)
			{
				bMovingUp = false;
				USolarFlareBatteryLiftEffectHandler::Trigger_OnMovingDown(this);
			}
		}

		if (Target.Z > ActorLocation.Z && !bMovingUp)
		{
			bMovingUp = true;
			USolarFlareBatteryLiftEffectHandler::Trigger_OnMovingUp(this);
		}

		float DistanceToTarget = (ActorLocation - Target).Size();
		if (bUseDoubleInteract)
		{
			if (bLiftIsOn)
			{
				float Pct = Math::Saturate(Time::GetGameTimeSince(DoubleInteractTime) / 5.0);
				FVector EasedLocation = Math::Lerp(Start, Target, Math::EaseInOut(0, 1, Pct, 1.5));
				AccelVec.SnapTo(EasedLocation);
			}
		}
		else
		{
			AccelVec.AccelerateTo(Target, Acceleration*2.0, DeltaSeconds);
		}
		ActorLocation = AccelVec.Value; 

		if (DistanceToTarget <= NearTopRegisterEventThresholdDistance && bMovingUp && bRegisterNearTopEvent)
		{
			OnSolarFlareBatteryLiftNearTop.Broadcast(IsPlayerOnLift());
			bRegisterNearTopEvent = false;
		}
		else if (DistanceToTarget > NearTopRegisterEventThresholdDistance && !bRegisterNearTopEvent)
		{
			bRegisterNearTopEvent = true;
		}

		if (DistanceToTarget >= 50.0 && !bIsMoving)
		{
			bIsMoving = true;
			USolarFlareBatteryLiftEffectHandler::Trigger_OnStartMove(this);
		}
		else if (DistanceToTarget < 50.0 && bIsMoving)
		{
			bIsMoving = false;
			USolarFlareBatteryLiftEffectHandler::Trigger_OnStopMove(this);
			
			if (bUseDoubleInteract)
			{
				for (AHazePlayerCharacter Player : Game::Players)
				{
					Player.UnblockCapabilities(CapabilityTags::Input, this);
					Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
				}
			}

			if (bMovingUp)
			{
				USolarFlareBatteryLiftEffectHandler::Trigger_OnReachedTop(this);
				
				for (AHazePlayerCharacter Player : Game::Players)
				{
					if (bPlayerOnLift[Player])
						Player.PlayForceFeedback(Rumble, false, false, this);

						OnSolarFlareBatteryLiftReachedTop.Broadcast(IsPlayerOnLift());
					}
				}
			else
			{
				USolarFlareBatteryLiftEffectHandler::Trigger_OnReachedBottom(this);
			}
		}
	}

	UFUNCTION()
	void SetEndState()
	{
		SetActorTickEnabled(false);
		ActorLocation = End;
		DoubleInteract.AddActorDisable(this);
		Timer::SetTimer(this, n"DelayedCollisionRejig", 0.001, false);
	}

	bool IsPlayerOnLift() const
	{
		return bPlayerOnLift[0] == true || bPlayerOnLift[1] == true;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugLine(ActorLocation, ActorLocation + FVector(0,0,ZOffset), FLinearColor::Blue, 10.0);
		Debug::DrawDebugBox(ActorLocation + FVector(0,0,ZOffset), FVector(250.0, 250.0, 50.0), ActorRotation, FLinearColor::Green, Thickness = 10.0);
		
	}
#endif
};