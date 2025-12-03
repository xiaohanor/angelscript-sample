
UCLASS(Abstract)
class UGameplay_Vehicle_Player_SwarmDrone_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnLand_SwarmBots(){}

	UFUNCTION(BlueprintEvent)
	void OnJump(){}

	UFUNCTION(BlueprintEvent)
	void OnTransformToBall(){}

	UFUNCTION(BlueprintEvent)
	void OnTransformToSwarm(){}

	UFUNCTION(BlueprintEvent)
	void StartSwarmDroneMovement(){}

	UFUNCTION(BlueprintEvent)
	void StopSwarmDroneMovement(){}

	UFUNCTION(BlueprintEvent)
	void StartSwarmBotMovement(){}

	UFUNCTION(BlueprintEvent)
	void StopSwarmBotMovement(){}

	UFUNCTION(BlueprintEvent)
	void OnExitVentilation(){}

	UFUNCTION(BlueprintEvent)
	void OnEnterVentilation(){}

	UFUNCTION(BlueprintEvent)
	void OnStartSwarmHover(){}

	UFUNCTION(BlueprintEvent)
	void OnStopSwarmHover(){}

	UFUNCTION(BlueprintEvent)
	void OnHackInitiated(){}

	UFUNCTION(BlueprintEvent)
	void OnHackDive(FSwarmDroneHijackDiveParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnHackStart(){}

	UFUNCTION(BlueprintEvent)
	void OnHackStop(){}

	UFUNCTION(BlueprintEvent)
	void OnBounce(){}

	UFUNCTION(BlueprintEvent)
	void OnLand_Drone(){}

	UFUNCTION(BlueprintEvent)
	void OnParachuteCatchWind(){}

	UFUNCTION(BlueprintEvent)
	void OnSwarmDash(){}

	UFUNCTION(BlueprintEvent)
	void OnSwarmLand(){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PlayerOwner.IsPlayerDead())
			return false;

		if(IsInBoatForm())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PlayerOwner.IsPlayerDead())
			return true;

		if(IsInBoatForm())
			return true;

		return false;
	}

	UPlayerSwarmDroneComponent SwarmDroneComp;
	UPlayerSwarmDroneHijackComponent SwarmDroneHijackComp;
	UHazeMovementComponent MoveComp;

	private FVector LastDroneInput;
	private FRotator LastRotation;	

	float Acceleration;
	private float LastRotationSpeed;
	private float LastElevation;
	private float ElevationSign;

	UPROPERTY(BlueprintReadWrite, Category = "Event Instances")
	FHazeAudioPostEventInstance SwarmDroneRotatingEventInstance;

	UPROPERTY(BlueprintReadWrite, Category = "Event Instances")
	FHazeAudioPostEventInstance SwarmDroneRollingEventInstance;

	UPROPERTY(BlueprintReadWrite, Category = "Event Instances")
	FHazeAudioPostEventInstance SwarmDroneEngineEventInstance;

	UPROPERTY(BlueprintReadWrite, Category = "Event Instances")
	FHazeAudioPostEventInstance SwarmDroneIdleEventInstance;

	UPROPERTY(BlueprintReadWrite, Category = "Event Instances")
	FHazeAudioPostEventInstance SwarmDroneMaterialEventInstance;

	UPROPERTY(BlueprintReadWrite, Category = "Event Instances")
	FHazeAudioPostEventInstance SwarmBotsMovementInstance;

	/*
	The range over which change in acceleration is normalized to
	Small value = reacting to change faster
	Large value = reacting to change slower 
	*/ 
	UPROPERTY(Category = "Rotation", Meta = (UIMin = 0.0, UIMax = 1.0))
	float AccelerationNormalizationRange = 0.3;

	// Needs to be set when we are jumping, we only want to call OnGrounded when landing in ball form
	UPROPERTY(BlueprintReadWrite, Category = "Logic|Drone")
	bool bIsJumping = false;

	private bool bWasGrounded = true;
	private bool bShouldQueryJumpApex = false;

	private float RotationSpeed = 0.0;
	private bool bHadWallImpact = false;

	private FVector LastAirborneLocation;
	private FVector JumpApexLocation;

	private UPhysicalMaterialAudioAsset FramePhysMat = nullptr;
	private UPhysicalMaterialAudioAsset LastPhysMat = nullptr;

	const float ROTATION_SPEED_NORMALIZATION_RANGE = 15.0;
	const float MAX_GROUNDED_IMPACT_VERTICAL_DELTA_TRACKING_DISTANCE = 250.0;

	UFUNCTION(BlueprintEvent)
	void OnStartRotating() {};

	UFUNCTION(BlueprintEvent)
	void OnStopRotating() {};
	
	UFUNCTION(BlueprintEvent)
	void OnContactMaterialChanged(const UPhysicalMaterialAudioAsset NewPhysMat) {};

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		SwarmDroneComp = UPlayerSwarmDroneComponent::Get(PlayerOwner);
		SwarmDroneHijackComp = UPlayerSwarmDroneHijackComponent::Get(PlayerOwner);
		MoveComp = UHazeMovementComponent::Get(PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(SwarmDroneComp.bSwarmModeActive)
		{
			if(!SwarmDroneComp.bDeswarmifying)
				StartSwarmBotMovement();
		}
		else
		{
			StartSwarmDroneMovement();
		}
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Rotation Speed"))
	float GetRotationSpeedNormalized()
	{
		return Math::Saturate(RotationSpeed / ROTATION_SPEED_NORMALIZATION_RANGE);
	}

	UFUNCTION(BlueprintEvent)
	void OnGrounded(float ImpactSpeed) {};

	UFUNCTION(BlueprintPure)
	bool IsGrounded()
	{
		return MoveComp.IsOnWalkableGround();
	}

	UFUNCTION(BlueprintPure)
	bool IsInDroneForm()
	{
		return !SwarmDroneComp.bSwarmModeActive;
	}

	UFUNCTION(BlueprintPure)
	bool IsInBotsForm()
	{
		return SwarmDroneComp.bSwarmModeActive;
	}

	UFUNCTION(BlueprintPure)
	bool IsInBoatForm() const
	{
		return SwarmDroneComp.IsInsideFloatZone();
	}

	UFUNCTION(BlueprintPure)
	bool IsHovering()
	{
		return SwarmDroneComp.bHovering;
	}

	UFUNCTION(BlueprintPure)
	float IsHackingMultiplier()
	{
		return SwarmDroneHijackComp.IsHijackActive() ? 0.0 : 1.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(IsInDroneForm())
			QueryMovingInput();
			
		// Nullptr the first frame when loading in from another level.
		if (SwarmDroneComp.DroneMesh == nullptr)
			return;

		const FRotator CurrRotation = SwarmDroneComp.DroneMesh.GetWorldRotation();

		RotationSpeed = CurrRotation.Quaternion().AngularDistance(LastRotation.Quaternion()) / DeltaSeconds;		
		Acceleration = RotationSpeed - LastRotationSpeed;

		const float AccelSign = Math::Sign(Acceleration);
		Acceleration = Math::GetMappedRangeValueClamped(FVector2D(0, AccelerationNormalizationRange), FVector2D(0, 1), Math::Abs(Acceleration));
		Acceleration = Acceleration * AccelSign;

		LastRotation = CurrRotation;
		LastRotationSpeed = RotationSpeed;	

		const float CurrElevation = DefaultEmitter.AudioComponent.GetWorldLocation().Z;
		ElevationSign = Math::Sign(CurrElevation - LastElevation);
		LastElevation = CurrElevation;

		if(IsInDroneForm())
		{
			bool bIsGrounded = MoveComp.HasImpactedGround();

			// Stay grounded while dead, prevents a landing on respawn
			if(PlayerOwner.IsPlayerDead())
				bIsGrounded = true;

			QueryOnGrounded(bIsGrounded);
			bWasGrounded = bIsGrounded;

			LastAirborneLocation = SwarmDroneComp.DroneCenterLocation;

			const bool bHasWallImpact = MoveComp.HasImpactedWall();
			if(!bHadWallImpact && bHasWallImpact)
			{	
				auto Speed = MoveComp.PreviousVelocity.Size();
				if(!Math::IsNearlyZero(Speed, 5))
				{
					const float Velo = Math::Clamp(Speed / 850, 0.0, 1.0);
					OnGrounded(Velo);
				}
			}

			bHadWallImpact = bHasWallImpact;

			FramePhysMat = nullptr;
			QueryContactMaterial();
			LastPhysMat = FramePhysMat;
		}
	}

	private void QueryMovingInput()
	{
		const FVector InputWorldUp = MoveComp.GroundContact.ImpactNormal;
		const FVector MoveInput = SwarmDroneComp.GetMoveInput(MoveComp.MovementInput, InputWorldUp);

		if(LastDroneInput.IsNearlyZero() && !MoveInput.IsNearlyZero())
			OnStartRotating();

		else if(!LastDroneInput.IsNearlyZero() && MoveInput.IsNearlyZero())
			OnStopRotating();

		LastDroneInput = MoveInput;
	}

	private void QueryContactMaterial()
	{
		FramePhysMat = GetPhysMat();

		if(LastPhysMat != nullptr && FramePhysMat != LastPhysMat)
		{
			OnContactMaterialChanged(FramePhysMat);
		}
	}

	private void QueryOnGrounded(const bool bInIsGrounded)
	{
		if(bWasGrounded && !bInIsGrounded)
		{
			bShouldQueryJumpApex = true;
		}
		else if((!bWasGrounded && bInIsGrounded) && !bIsJumping)
		{
			const float VerticalDelta = JumpApexLocation.Z - SwarmDroneComp.DroneCenterLocation.Z;
			const float ImpactSpeed = Math::Clamp(VerticalDelta / MAX_GROUNDED_IMPACT_VERTICAL_DELTA_TRACKING_DISTANCE, 0.0, 1.0);
			OnGrounded(ImpactSpeed);
		}
		
		if(bShouldQueryJumpApex)
		{
			const bool bHasStartedFalling = (SwarmDroneComp.DroneCenterLocation.Z < LastAirborneLocation.Z) && !MoveComp.IsOnWalkableGround();
			if(bHasStartedFalling)
			{
				bShouldQueryJumpApex = false;
				JumpApexLocation = SwarmDroneComp.DroneCenterLocation;
			}
		}
	}

	UFUNCTION(BlueprintPure)
	float GetAcceleration()
	{
		return Acceleration;
	}

	UFUNCTION(BlueprintPure)
	float GetElevationSignValue()
	{
		return ElevationSign;
	}

	
	UFUNCTION(BlueprintPure)
	float GetHasStickInputMultiplier()
	{
		const FVector StickInput = SwarmDroneComp.MoveComp.GetSyncedMovementInputForAnimationOnly();
		return StickInput.IsNearlyZero() ? 0.0 : 1.0;
	}

	// The Audio-phys mat that the drone is rolling on
	UFUNCTION(BlueprintPure, Meta = (DisplayName = "Audio Phys Mat"))
	UPhysicalMaterialAudioAsset GetPhysMat()
	{
		if(FramePhysMat == nullptr)
			FramePhysMat = Cast<UPhysicalMaterialAudioAsset>(AudioTrace::GetPhysMaterialFromHit(SwarmDroneComp.MoveComp.GroundContact.ConvertToHitResult(), FHazeTraceSettings()).AudioAsset);

		return FramePhysMat; 
	}
}