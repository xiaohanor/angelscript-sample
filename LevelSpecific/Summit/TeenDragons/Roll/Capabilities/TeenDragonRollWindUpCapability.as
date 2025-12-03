class UTeenDragonRollWindUpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonRoll);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 20;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonRollComponent RollComp;

	UHazeMovementComponent MoveComp;
	UTeenDragonRollMovementData Movement;

	UCameraUserComponent CameraUser;

	UTeenDragonRollSettings RollSettings;
	
	float Speed = 0.0;
	float OriginalMoveSpeed = 0.0;

	bool bHaveHadInput = false;
	bool bHasHitStoppingWall = false;
	FQuat StartFlatCameraRotation;
	FQuat StartRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = Cast<UTeenDragonRollMovementData>(MoveComp.SetupMovementData(UTeenDragonRollMovementData));

		RollSettings = UTeenDragonRollSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(RollComp.IsRolling())
			return false;

		if (!WasActionStartedDuringTime(RollSettings.RollInputActionName, RollSettings.RollCooldown))
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (DeactiveDuration < RollSettings.RollCooldown)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > RollSettings.RollWindUpTime)
			return true;
		
		if (!IsActioning(RollSettings.RollInputActionName)
		&& ActiveDuration >= RollSettings.RollMinDuration)
			return true;

		if (MoveComp.HasMovedThisFrame())
		 	return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FVector MovementInput = MoveComp.GetMovementInput().GetSafeNormal();

		if(!SceneView::IsFullScreen())
		{
			bHaveHadInput = !MovementInput.IsNearlyZero();
			if(!bHaveHadInput)
			{
				StartRotation = Player.ActorRotation.Quaternion();

				FRotator CameraRotator = CameraUser.ViewRotation;
				CameraRotator.Pitch = 0;

				StartFlatCameraRotation = CameraRotator.Quaternion();
			}
		}
		else
		{
			if (MovementInput.IsNearlyZero())
				MovementInput = Player.ActorForwardVector;
			Player.SetActorRotation(MovementInput.ToOrientationQuat());
		}

		OriginalMoveSpeed = MoveComp.GetHorizontalVelocity().Size();
		RollComp.PreviousMovementInput = Player.ActorForwardVector;
		Speed = OriginalMoveSpeed;
		bHasHitStoppingWall = false;

		if (Math::IsNearlyZero(Speed, 5))
			DragonComp.AnimationState.Apply(ETeenDragonAnimationState::TailRoll, this, EInstigatePriority::High);
		else
			DragonComp.AnimationState.Apply(ETeenDragonAnimationState::TailRollFromRun, this, EInstigatePriority::High);

		UTeenDragonRollEventHandler::Trigger_RollWindupStarted(Player);
		UTeenDragonRollVFX::Trigger_OnWindUpStarted(Player);

		RollComp.TimeLastStartedRoll = Time::GameTimeSeconds;
		RollComp.RollingInstigators.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{	
		if(!bHaveHadInput
			&& !SceneView::IsFullScreen())
		{
			Player.SetActorRotation(StartFlatCameraRotation);
		}

		RollComp.bRollIsStarted = true;
		RollComp.RollingInstigators.RemoveSingleSwap(this);
		RollComp.PreviousMovementInput = Player.ActorForwardVector;

		UTeenDragonRollVFX::Trigger_OnWindUpStopped(Player);
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{	
			if (HasControl())
			{
				float WindUpAlpha = ActiveDuration / RollSettings.RollWindUpTime;
				float CurveAlpha = RollSettings.RollStartSpeedCurve.GetFloatValue(WindUpAlpha);
				Speed = Math::Lerp(
					OriginalMoveSpeed,
					RollSettings.RollStartSpeed, 
					CurveAlpha
				);

				
				FVector Steering;

				FVector MovementInput = MoveComp.GetMovementInput().GetSafeNormal();

				if(!bHaveHadInput
				 && !SceneView::IsFullScreen())
				{
					if(!MovementInput.IsNearlyZero())
						bHaveHadInput = true;

					FQuat SteeringQuat = Player.ActorForwardVector.ToOrientationQuat();
					SteeringQuat = FQuat::Slerp(StartRotation, StartFlatCameraRotation, WindUpAlpha);
					
					Steering = SteeringQuat.GetForwardVector();
				}
				else
				{
					if (MovementInput.IsNearlyZero())
						MovementInput = RollComp.PreviousMovementInput;
					else
						RollComp.PreviousMovementInput = MovementInput;
					Steering = Math::VInterpNormalRotationTo(Player.ActorForwardVector, MovementInput, DeltaTime, RollSettings.WindUpTurnRate);
				}
				FRotator Rotation = FRotator::MakeFromXZ(Steering, MoveComp.WorldUp);
				FVector Velocity = Steering * Speed;

				Movement.AddHorizontalVelocity(Velocity);
				Movement.SetRotation(Rotation);
				Movement.AddPendingImpulses();
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();

				if(MoveComp.IsOnAnyGround())
					RollComp.ApplyRollHaptic(Speed);
			}
			// Remote
			else
			{
				if(MoveComp.IsInAir())
					Movement.ApplyCrumbSyncedAirMovement();
				else
					Movement.ApplyCrumbSyncedGroundMovement();
			}
			
			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::RollMovement);
		}
	}
};