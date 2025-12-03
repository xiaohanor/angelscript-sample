class UTeenDragonAirGlideCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonAirGlide);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 80;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTeenDragonAirGlideComponent AirGlideComp;
	UPlayerAcidTeenDragonComponent DragonComp;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	UTeenDragonAirGlideSettings AirGlideSettings;

	FVector ImpulseVelocity;

	const float ImpulseVelocityInterpSpeed = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		AirGlideComp = UTeenDragonAirGlideComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		DragonComp = UPlayerAcidTeenDragonComponent::Get(Player);

		AirGlideSettings = UTeenDragonAirGlideSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(DeactiveDuration < AirGlideSettings.GlideCooldown)
			return false;
		
		if (MoveComp.IsOnAnyGround())
			return false;

		if(AirGlideComp.ActiveRingParams.IsSet())
		{
			auto RingParams = AirGlideComp.ActiveRingParams.Value;
			if(RingParams.BoostTimer < RingParams.ForceGlideDuration)
				return true;
		}

		if(AnyAirCurrentAutoActivatesGlide())
			return true;

		if(DragonComp.AimMode == ETeenDragonAcidAimMode::LeftTriggerMode)
		{
			if (IsActioning(ActionNames::MovementJump))
				return true;
		}
		else
		{
			if (IsActioning(ActionNames::SecondaryLevelAbility))
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(AirGlideComp.ActiveRingParams.IsSet())
		{
			auto RingParams = AirGlideComp.ActiveRingParams.Value;
			if(RingParams.BoostTimer < RingParams.ForceGlideDuration)
				return false;
		}

		if(AnyAirCurrentAutoActivatesGlide())
			return false;

		if (MoveComp.HasGroundContact())
			return true;

		if (MoveComp.HasCeilingContact())
			return true;
		
		if(ActiveDuration >= AirGlideSettings.GlideMinimumDuration)
		{
			if(DragonComp.AimMode == ETeenDragonAcidAimMode::LeftTriggerMode)
			{
				if (!IsActioning(ActionNames::MovementJump))
					return true;
			}
			else
			{
				if (!IsActioning(ActionNames::SecondaryLevelAbility))
					return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UTeenDragonAirGlideEventHandler::Trigger_StartedGliding(Player);

		AHazeActor DragonActor = Cast<AHazeActor>(DragonComp.DragonMesh.Outer);
		UDragonMovementAudioEventHandler::Trigger_AcidTeenGlideStart(DragonActor);

		DragonComp.AnimationState.Apply(ETeenDragonAnimationState::Gliding, this);

		if(AirGlideComp.bInitialAirBoostAvailable)
			AirGlideComp.bActivatedWithInitialBoost = true;
		else
			AirGlideComp.bActivatedWithInitialBoost = false;

		AirGlideComp.SetGlideVerticalSpeed(MoveComp.VerticalSpeed);

		if (!SceneView::IsFullScreen())
		{
			Player.PlayCameraShake(AirGlideComp.RingBoostStartCameraShake, this, 0.35);
			Player.PlayForceFeedback(AirGlideComp.StartGlideForceFeedback, false, true, this, 0.5);
		}

		AirGlideComp.bIsAirGliding = true;

		Player.BlockCapabilities(TeenDragonCapabilityTags::BlockedWhileInTeenDragonAirGlide, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.AnimationState.Clear(this);

		UTeenDragonAirGlideEventHandler::Trigger_StoppedGliding(Player);

		AHazeActor DragonActor = Cast<AHazeActor>(DragonComp.DragonMesh.Outer);
		UDragonMovementAudioEventHandler::Trigger_AcidTeenGlideStop(DragonActor);

		Player.StopCameraShakeByInstigator(this);
	
		Player.StopForceFeedback(this);

		AirGlideComp.bIsAirGliding = false;
		Player.UnblockCapabilities(TeenDragonCapabilityTags::BlockedWhileInTeenDragonAirGlide, this);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector Input = MoveComp.MovementInput;

				auto TempLog = TEMPORAL_LOG(Player, "Air Glide");

				HandleImpulses(DeltaTime);
				Movement.AddVelocity(ImpulseVelocity);

				float BoostSpeed = 0.0;
				if(AirGlideComp.ActiveRingParams.IsSet())
				{
					BoostSpeed = AirGlideComp.BoostRingSpeed;
					Movement.AddHorizontalVelocity(Player.ActorForwardVector * BoostSpeed);
				}

				Movement.InterpRotationToTargetFacingRotation(AirGlideSettings.FacingDirectionInterpSpeed, false);

				float GlideSpeed = MoveComp.HorizontalVelocity.Size() - BoostSpeed;
				GlideSpeed = UpdateHorizontalSpeed(GlideSpeed, Input, DeltaTime);
				Movement.AddHorizontalVelocity(Player.ActorForwardVector * GlideSpeed);

				float VerticalSpeed = AirGlideComp.GetGlideVerticalSpeed();
				FVector VerticalVelocity = -MoveComp.GravityDirection * VerticalSpeed;
				TempLog.Page("Vertical Speed")
					.Value("Vertical Speed", VerticalSpeed)
					.DirectionalArrow("Vertical Velocity", Player.ActorLocation, VerticalVelocity, 20, 40, FLinearColor::Blue)
				;

				Movement.AddVerticalVelocity(VerticalVelocity);

				AirGlideComp.ApplyGlideHaptic(GlideSpeed);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
			
			auto LocomotionTag = TeenDragonLocomotionTags::AcidTeenHover;
			if(AirGlideComp.ActiveRingParams.IsSet()
			&& AirGlideComp.ActiveRingParams.Value.BoostTimer < AirGlideComp.BoostRingAnimationDuration)
				LocomotionTag = TeenDragonLocomotionTags::AcidTeenSpeedRing;
			DragonComp.RequestLocomotionDragonAndPlayer(LocomotionTag);
		}
	}


	float UpdateHorizontalSpeed(float InGlideSpeed, FVector Input, float DeltaTime) const 
	{
		float GlideSpeed = InGlideSpeed;
		float InputSize;
		if(AirGlideComp.ActiveRingParams.IsSet())
		{
			InputSize = 1.0;
		}
		else
		{
			InputSize = Input.DotProduct(Player.ActorForwardVector);
			InputSize = Math::Max(InputSize, 0);
		}

		float TargetGlideSpeed = InputSize * AirGlideSettings.GlideHorizontalMaxMoveSpeed;
		GlideSpeed = Math::FInterpTo(GlideSpeed, TargetGlideSpeed, DeltaTime, AirGlideSettings.HorizontalSpeedInterpSpeed);

		TEMPORAL_LOG(Player, "Air Glide")
			.Value("Glide Speed", GlideSpeed)
		;
		return GlideSpeed;
	}

	void HandleImpulses(float DeltaTime)
	{
		FVector Impulse = Movement.GetPendingImpulse();
		ImpulseVelocity += Impulse;
		ImpulseVelocity = Math::VInterpTo(ImpulseVelocity, FVector::ZeroVector, DeltaTime, ImpulseVelocityInterpSpeed);
	}

	bool AnyAirCurrentAutoActivatesGlide() const
	{
		for(auto AirCurrent : AirGlideComp.ActiveAirCurrents)
		{
			if(AirCurrent.bAutoActivateGlide)
				return true;
		}
		return false;
	}
}