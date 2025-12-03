class ASummitGeyserRunes : ASummitGeyser
{
	UPROPERTY(EditAnywhere, Category = "Settings")
	float StatueMoveUpAmount = 625.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float StatueMoveUpDuration = 2.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float StatueMoveDownDuration = 2.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float RuneOpeningStiffness = 80.0;
	
	UPROPERTY(EditAnywhere, Category = "Settings")
	float RuneClosingStiffness = 30.0;

	UPROPERTY(EditAnywhere, Category = "Shakes & Rumbles")
	float InnerFeedbackRadius = 1500.0;

	UPROPERTY(EditAnywhere, Category = "Shakes & Rumbles")
	float OuterFeedbackRadius = 3000.0;

	UPROPERTY(EditAnywhere, Category = "Shakes & Rumbles")
	TSubclassOf<UCameraShakeBase> MovingCameraShake;

	UPROPERTY(EditAnywhere, Category = "Shakes & Rumbles")
	UForceFeedbackEffect MovingRumble;

	FVector StatueDeactivatedLocation;
	FVector StatueActivatedLocation;

	FRotator RuneClosedRotation = FRotator::ZeroRotator; 
	FRotator RuneOpenRotation = FRotator(90.0, 0.0, 0.0);
	FRotator RuneTargetRotation;
	bool bRuneOpening = false;
	bool bRuneMoving = false;
	bool bStatueMovingDown = false;
	bool bStatueMovingUp = false;

	FHazeAcceleratedRotator AccRuneRotation;
	FHazeAcceleratedVector AccStatueLocation;

	const float RuneOpeningMovingThreshold = 4.0;
	const float RuneClosingMovingThreshold = 1.0;

	UMaterialInstanceDynamic DynamicMat;
	FLinearColor Color;

	bool bIsPlayingShakes = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		StatueDeactivatedLocation = ActorLocation;
		StatueActivatedLocation = StatueDeactivatedLocation + ActorUpVector * StatueMoveUpAmount;

		RuneTargetRotation = RuneClosedRotation;
		AccRuneRotation.SnapTo(RuneTargetRotation);
		AccStatueLocation.SnapTo(StatueDeactivatedLocation);

		OnBecameBlocked.AddUFunction(this, n"OnBecameBlocked");
		OnBecameUnblocked.AddUFunction(this, n"OnBecameUnblocked");
	}

	void SetMeshDefaultEmissive(UStaticMeshComponent MeshComp)
	{
		DynamicMat = MeshComp.CreateDynamicMaterialInstance(0);
		Color = DynamicMat.GetVectorParameterValue(n"Tint_D_Emissive");
		DynamicMat.SetVectorParameterValue(n"Tint_D_Emissive", Color * 15.0);
	}

	UFUNCTION()
	private void OnBecameBlocked()
	{
		USummitGeyserRunesEventHandler::Trigger_OnGeyserBecameBlocked(this);
	}

	UFUNCTION()
	private void OnBecameUnblocked()
	{
		USummitGeyserRunesEventHandler::Trigger_OnGeyserStoppedBeingBlocked(this);
	}

	UFUNCTION(BlueprintCallable)
	void PressurePlateActivated()
	{
		RuneTargetRotation = RuneOpenRotation;
		bRuneOpening = true;
		bRuneMoving = true;
		bStatueMovingUp = true;
		bStatueMovingDown = false;
		USummitGeyserRunesEventHandler::Trigger_OnLidStartedOpening(this);
		USummitGeyserRunesEventHandler::Trigger_OnStatueStartedMovingUp(this);

		ToggleShakes(true);
	}

	UFUNCTION(BlueprintCallable)
	void PressurePlateDeactivated()
	{
		RuneTargetRotation = RuneClosedRotation;
		bRuneOpening = false;
		bRuneMoving = true;
		bStatueMovingUp = false;
		bStatueMovingDown = true;
		USummitGeyserRunesEventHandler::Trigger_OnLidStartedClosing(this);
		USummitGeyserRunesEventHandler::Trigger_OnStatueStartedMovingDown(this);

		ToggleShakes(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		
		float Stiffness = bRuneOpening 
			? RuneOpeningStiffness 
			: RuneClosingStiffness;

		AccRuneRotation.SpringTo(RuneTargetRotation, Stiffness, 0.3, DeltaSeconds);
		BP_RuneRotated(AccRuneRotation.Value);

		if(bRuneMoving)
		{
			if(bRuneOpening
			&& AccRuneRotation.Velocity.IsNearlyZero(RuneOpeningMovingThreshold))
			{
				USummitGeyserRunesEventHandler::Trigger_OnLidStoppedOpening(this);
				bRuneMoving = false;
			}
			else if(!bRuneOpening
			&& AccRuneRotation.Velocity.IsNearlyZero(RuneClosingMovingThreshold))
			{
				USummitGeyserRunesEventHandler::Trigger_OnLidStoppedClosing(this);
				bRuneMoving = false;
			}
		}
		if(bStatueMovingUp)
		{
			AccStatueLocation.AccelerateTo(StatueActivatedLocation, StatueMoveUpDuration, DeltaSeconds);
			BP_StatueMoved(AccStatueLocation.Value);
			if((StatueActivatedLocation - AccStatueLocation.Value).IsNearlyZero(5.0))
			{
				USummitGeyserRunesEventHandler::Trigger_OnStatueStoppedMovingUp(this);
				bStatueMovingUp = false;
				ToggleShakes(false);
			}
		}
		if(bStatueMovingDown)
		{
			AccStatueLocation.AccelerateTo(StatueDeactivatedLocation, StatueMoveDownDuration, DeltaSeconds);
			BP_StatueMoved(AccStatueLocation.Value);
			if((StatueDeactivatedLocation - AccStatueLocation.Value).IsNearlyZero(5.0))
			{
				USummitGeyserRunesEventHandler::Trigger_OnStatueStoppedMovingDown(this);
				bStatueMovingDown = false;
				ToggleShakes(false);
			}
		}
	}

	void ToggleShakes(bool bToggleOn)
	{
		if(bToggleOn)
		{
			if(bIsPlayingShakes)
			{
				for(auto Player : Game::Players)
				{
					Player.StopCameraShakeByInstigator(this);
					Player.StopForceFeedback(this);
				}
				bIsPlayingShakes = false;
			}

			for(auto Player : Game::Players)
			{
				Player.PlayWorldCameraShake(MovingCameraShake, this, ActorLocation, InnerFeedbackRadius, OuterFeedbackRadius);

				float DistToPlayer = ActorLocation.Distance(Player.ActorLocation);
				float DistAlpha = Math::GetPercentageBetweenClamped(OuterFeedbackRadius, InnerFeedbackRadius, DistToPlayer);
				Player.PlayForceFeedback(MovingRumble, false, false, this, DistAlpha);
			
				bIsPlayingShakes = true;
			}
		}
		else
		{
			if(!bIsPlayingShakes)
				return;

			for(auto Player : Game::Players)
			{
				Player.StopCameraShakeByInstigator(this);
				Player.StopForceFeedback(this);
			}

			bIsPlayingShakes = false;
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_StatueMoved(FVector NewStatueLocation) {}

	UFUNCTION(BlueprintEvent)
	void BP_RuneRotated(FRotator NewRuneRotation) {}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugSphere(ActorLocation, InnerFeedbackRadius);
		Debug::DrawDebugSphere(ActorLocation, OuterFeedbackRadius);
	}
#endif
};