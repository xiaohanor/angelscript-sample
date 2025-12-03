struct FTundraRiver_GrowingFlowerAnimData
{
	TOptional<uint> LandFrame;
	TOptional<uint> SmashFrame;
	bool bTreeGuardianInteracting = false;
	float HeightAlpha;

	bool LandedThisFrame() const
	{
		if(!LandFrame.IsSet())
			return false;

		return Time::FrameNumber == LandFrame.Value;
	}

	bool SmashedThisFrame() const
	{
		if(!SmashFrame.IsSet())
			return false;

		return Time::FrameNumber - 1 <= SmashFrame.Value;
	}
}

event void UpdateCurrentHeight(float CurrentHeight);

class ATundraRiver_GrowingFlower : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent GroundSlamResponseComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent FauxPhysicsPlayerWeightComp;

	UPROPERTY(DefaultComponent)
	UTundraLifeReceivingComponent TundraLifeReceivingComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedCurrentHeight;
	
	UPROPERTY(EditInstanceOnly)
	float RestingHeight = 800;
	
	UPROPERTY(EditInstanceOnly)
	float MaxHeight = 3600;

	UPROPERTY(EditInstanceOnly)
	float GroundSlamHeightNegation = -600;

	UPROPERTY(EditInstanceOnly)
	float MovementImpactHeightNegation = -150;

	UPROPERTY(EditInstanceOnly)
	float GroundSlamPauseDuration = 1.5;

	UPROPERTY(EditInstanceOnly)
	float MovementImpactPauseDuration = 1.5;

	UPROPERTY(EditInstanceOnly)
	float EndInteractPauseDuration = 2.5;

	bool bMoving;

	UPROPERTY()
	UpdateCurrentHeight EventUpdateCurrentHeight; 

	default PrimaryActorTick.bStartWithTickEnabled = false;
	float PauseDuration = 0;
	float TargetHeight = RestingHeight;
	//float CurrentHeight = RestingHeight;
	bool bTreeGuardianInteracting = false;
	float GroundPoundOffset = 0.0;
	float TargetGroundPoundOffset = 0.0;
	float GroundPoundPauseTimer = 0.0;
	float MovementImpactOffset = 0.0;
	float TargetMovementImpactOffset = 0.0;
	float MovementImpactPauseTimer = 0.0;
	FTundraRiver_GrowingFlowerAnimData AnimData;
	bool bPetalCollisionEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TundraLifeReceivingComp.OnInteractStart.AddUFunction(this, n"OnInteractionStarted");
		TundraLifeReceivingComp.OnInteractStop.AddUFunction(this, n"OnInteractionStopped");
		GroundSlamResponseComp.OnGroundSlam.AddUFunction(this, n"OnGroundSlam");
		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"OnGroundImpact");
		SyncedCurrentHeight.Value = RestingHeight;


		EventUpdateCurrentHeight.Broadcast(SyncedCurrentHeight.Value);

		SetActorControlSide(Game::GetZoe());
	}

	UFUNCTION()
	void OnInteractionStarted(bool bForced)
	{
		bTreeGuardianInteracting = true;
		AnimData.bTreeGuardianInteracting = true;
		StartMove();
	}

	UFUNCTION()
	void OnInteractionStopped(bool bForced)
	{
		bTreeGuardianInteracting = false;
		SetPauseResetDuration(EndInteractPauseDuration);
	}

	UFUNCTION()
	void OnGroundSlam(ETundraPlayerSnowMonkeyGroundSlamType SlamType, FVector PlayerLocation)
	{
		TargetGroundPoundOffset += GroundSlamHeightNegation;
		GroundPoundPauseTimer = GroundSlamPauseDuration;
		StartMove();
		if(SyncedCurrentHeight.Value + TargetGroundPoundOffset < 0)
		{
			TargetGroundPoundOffset = -SyncedCurrentHeight.Value;
		}

		AnimData.SmashFrame.Set(Time::FrameNumber);
	}

	UFUNCTION()
	void OnGroundImpact(AHazePlayerCharacter Player)
	{
		TargetMovementImpactOffset += MovementImpactHeightNegation;
		MovementImpactPauseTimer = MovementImpactPauseDuration;
		StartMove();
		if(SyncedCurrentHeight.Value + TargetMovementImpactOffset < 0)
		{
			TargetMovementImpactOffset = -SyncedCurrentHeight.Value;
		}

		AnimData.LandFrame.Set(Time::FrameNumber);
	}

	UFUNCTION()
	void OffsetTargetHeight(float Delta)
	{
		TargetHeight = Math::Clamp(TargetHeight + Delta, 0, MaxHeight);
		
		StartMove();
	}

	UFUNCTION()
	void SetPauseResetDuration(float Time)
	{
		if(Time > PauseDuration)
		{
			PauseDuration = Time;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bTreeGuardianInteracting)
		{
			/*if(SyncedCurrentHeight.Value >= 3200)
				return;*/
			
			if(PauseDuration <= 0)
			{
				TargetHeight = Math::FInterpConstantTo(TargetHeight, RestingHeight, DeltaSeconds, MaxHeight*0.15);
			}

			else
			{
				PauseDuration -= DeltaSeconds;
				if(PauseDuration <= 0)
				{
					AnimData.bTreeGuardianInteracting = false;
					if(bPetalCollisionEnabled)
					{
						OnSetPetalCollisionActive(false);
						bPetalCollisionEnabled = false;
					}
				}
			}
		}

		float RawInput = TundraLifeReceivingComp.RawVerticalInput;

		if(bTreeGuardianInteracting)
		{
			if(TargetHeight < RestingHeight && RawInput < 0.0)
				RawInput = 0.0;

			TargetHeight = Math::Clamp(TargetHeight + (RawInput*DeltaSeconds*MaxHeight*0.15), 0, MaxHeight);
		}

		if(HasControl())
		{
			SyncedCurrentHeight.Value = Math::FInterpTo(SyncedCurrentHeight.Value, TargetHeight, DeltaSeconds, 2.0);
		}

		if(GroundPoundPauseTimer <= 0)
		{
			TargetGroundPoundOffset = Math::FInterpConstantTo(TargetGroundPoundOffset, 0, DeltaSeconds, MaxHeight*0.15);
		}
		else
		{
			GroundPoundPauseTimer -= DeltaSeconds;
		}

		GroundPoundOffset = Math::FInterpTo(GroundPoundOffset, TargetGroundPoundOffset, DeltaSeconds, 2.0);

		if(SyncedCurrentHeight.Value + GroundPoundOffset < 0)
		{
			GroundPoundOffset = -SyncedCurrentHeight.Value;
			TargetGroundPoundOffset = GroundPoundOffset;
		}

		if(MovementImpactPauseTimer <= 0)
		{
			TargetMovementImpactOffset = Math::FInterpConstantTo(TargetMovementImpactOffset, 0, DeltaSeconds, MaxHeight*0.15);
		}
		else
		{
			MovementImpactPauseTimer -= DeltaSeconds;
		}

		MovementImpactOffset = Math::FInterpTo(MovementImpactOffset, TargetMovementImpactOffset, DeltaSeconds, 2.0);

		if(SyncedCurrentHeight.Value + MovementImpactOffset < 0)
		{
			MovementImpactOffset = -SyncedCurrentHeight.Value;
			TargetMovementImpactOffset = MovementImpactOffset;
		}

		float CurrentHeight = SyncedCurrentHeight.Value + GroundPoundOffset + MovementImpactOffset;
		CurrentHeight = Math::Clamp(CurrentHeight, 0.0, MaxHeight);
		AnimData.HeightAlpha = CurrentHeight / MaxHeight;
		if(!bPetalCollisionEnabled && bTreeGuardianInteracting && AnimData.HeightAlpha > 0.9)
		{
			OnSetPetalCollisionActive(true);
			bPetalCollisionEnabled = true;
		}
		
		EventUpdateCurrentHeight.Broadcast(CurrentHeight);

		if(Math::IsNearlyEqual(TargetHeight, SyncedCurrentHeight.Value, 0.1)  && Math::IsNearlyEqual(RestingHeight, SyncedCurrentHeight.Value, 0.1) && !bTreeGuardianInteracting && GroundPoundOffset == 0)
		{
			StopMove();
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnSetPetalCollisionActive(bool State) {}

	void StartMove()
	{
		if(!bMoving)
		{
			SetActorTickEnabled(true);
			bMoving = true;
			UTundraRiver_GrowingFlower_EffectHandler::Trigger_StartMoving(this);
		}
	}

	void StopMove()
	{
		if(bMoving)
		{
			SetActorTickEnabled(false);
			bMoving = false;
			UTundraRiver_GrowingFlower_EffectHandler::Trigger_StopMoving(this);
		}
	}
}