struct FDentistBossToolDenturesJumpActivationParams
{
	AHazePlayerCharacter TargetPlayer;
	float RotateDuration;
}

struct FDentistBossToolDenturesJumpDeactivationParams
{
	bool bHitTheGround = false;
}

class UDentistBossToolDenturesJumpCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBossToolDentures Dentures;
	ADentistBoss Dentist;
	
	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	UDentistBossSettings Settings;
	UMovementGravitySettings GravitySettings;

	FRotator StartRotation;
	bool bHasJumped = false;
	bool bIsRotatingToLandDownwards = false;
	
	FQuat StartJumpRotation;
	FQuat TargetJumpRotation;

	AHazePlayerCharacter TargetPlayer;
	float RotateDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentures = Cast<ADentistBossToolDentures>(Owner);
		Dentist = TListedActors<ADentistBoss>().GetSingle();

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();

		Settings = UDentistBossSettings::GetSettings(Dentist);
		GravitySettings = UMovementGravitySettings::GetSettings(Dentures);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDentistBossToolDenturesJumpActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(Dentures.bDestroyed)
			return false;

		if(!Dentures.bActive)
			return false;

		if(Dentures.bIsAttachedToJaw)
			return false;

		if(!Dentures.bHasLandedOnGround)
			return false;

		if(Dentures.HealthComp.IsDead())
			return false;

		const float TimeSinceLandedOnGroundLast = Time::GetGameTimeSince(Dentures.LastTimeLandedOnGround);
		if(TimeSinceLandedOnGroundLast < Settings.DenturesInitialCooldownLandingOnGround)
			return false;

		if(!Dentures.TargetPlayer.IsSet())
			return false;

		if(Dentures.bIsRechargingJumps)
			return false;

		if(DentistBossDevToggles::DenturesDontJump.IsEnabled())
			return false;
		
		const float CurrentRotateDuration = Settings.DenturesJumpRotateDuration.Lerp(Dentures.EnergyAlpha);
		const float CurrentJumpCooldown = Settings.DenturesJumpCooldown.Lerp(Dentures.EnergyAlpha); 
		if(DeactiveDuration >= CurrentJumpCooldown - CurrentRotateDuration)
		{
			Params.TargetPlayer = Dentures.TargetPlayer.Value;
			Params.RotateDuration = CurrentRotateDuration;
			return true;
		}


		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FDentistBossToolDenturesJumpDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(Dentures.bDestroyed)
			return true;

		if(!Dentures.bActive)
			return true;

		if(Dentures.bIsAttachedToJaw)
			return true;

		if(!Dentures.bHasLandedOnGround)
			return true;
		
		if(!bHasJumped
		&& Dentures.HealthComp.IsDead())
			return true;

		if(bHasJumped
		&& MoveComp.HasImpactedGround())
		{
			Params.bHitTheGround = true;
			return true;
		}

		if(Dentures.bIsRechargingJumps)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDentistBossToolDenturesJumpActivationParams Params)
	{
		TargetPlayer = Params.TargetPlayer;
		RotateDuration = Params.RotateDuration;

		StartRotation = Dentures.ActorRotation;
		bHasJumped = false;
		bIsRotatingToLandDownwards = false;
		Dentures.GroundPoundAutoAimComp.Disable(this);
		Dentures.KnockAwayPlayersStandingOnDentures();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FDentistBossToolDenturesJumpDeactivationParams Params)
	{
		if(Params.bHitTheGround)
		{
			FDentistBossEffectHandlerOnDenturesFreeJumpParams EventParams;
			EventParams.Dentures = Dentures;
			UDentistBossEffectHandler::Trigger_OnDenturesFreeJumpLand(Dentist, EventParams);
			Dentures.SetActorVelocity(FVector::ZeroVector);
		}
		else
		{
			FDentistBossEffectHandlerOnDenturesFreeJumpParams EventParams;
			EventParams.Dentures = Dentures;
			UDentistBossEffectHandler::Trigger_OnDenturesFreeJumpedOffCake(Dentist, EventParams);
		}

		if(bHasJumped)
			Dentures.bShouldTraceForPlayerInFront = false;

		++Dentures.JumpsSinceRecharge;

		if(bIsRotatingToLandDownwards)
		{
			Dentures.MeshOffsetComp.RelativeRotation = TargetJumpRotation.Rotator();
			FDentistBossEffectHandlerOnDenturesFlipParams EventParams;
			EventParams.Dentures = Dentures;
			UDentistBossEffectHandler::Trigger_OnDenturesFlipOver(Dentist, EventParams);
		}
		
		Dentures.bIsJumping = false;

		ForceFeedback::PlayWorldForceFeedback(ForceFeedback::Default_Medium_Short,Dentures.ActorLocation,false, this, InnerRadius = 800, FalloffRadius = 2500);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration <= RotateDuration)
		{
			bool bBothPlayersStandingOnDentures = true;
			for(auto Player : Game::Players)
			{
				if(!Dentures.IsStandingOnDentures[Player])
				{
					bBothPlayersStandingOnDentures = false;
					break;
				}
			}

			if(!bBothPlayersStandingOnDentures)
			{
				float RotationAlpha = ActiveDuration / RotateDuration;
				
				FVector FlatDeltaToPlayer = (TargetPlayer.ActorLocation - Dentures.ActorLocation).VectorPlaneProject(FVector::UpVector);
				FVector DirToPlayer = FlatDeltaToPlayer.GetSafeNormal();
				FRotator RotationTowardsPlayer = FRotator::MakeFromXZ(DirToPlayer, FVector::UpVector);

				Dentures.ActorRotation = Math::LerpShortestPath(StartRotation, RotationTowardsPlayer, RotationAlpha);
			}	
		}
		else if(!bHasJumped)
		{
			JumpTowardsTargetPlayer();
		}

		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				Movement.AddPendingImpulses();
				Movement.AddGravityAcceleration();
				Movement.AddOwnerVelocity();
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
		}

	}

	void JumpTowardsTargetPlayer()
	{
		Dentures.KnockAwayPlayersStandingOnDentures();

		FVector FlatDeltaToPlayer = (TargetPlayer.ActorLocation - Dentures.ActorLocation).VectorPlaneProject(FVector::UpVector);
		FVector DirToPlayer = FlatDeltaToPlayer.GetSafeNormal();

		float EnergyAlpha = Dentures.EnergyAlpha;

		float JumpHeight = Settings.DenturesJumpHeight.Lerp(EnergyAlpha);
		float JumpLength = Settings.DenturesJumpLength.Lerp(EnergyAlpha);
		if(Dentures.JumpsSinceRecharge == Settings.DenturesJumpsBeforeRecharge - 1)
		{
			bIsRotatingToLandDownwards = true;
			Dentures.bFallingOverJump = true;

			FDentistBossEffectHandlerOnDenturesFlipParams EventParams;
			EventParams.Dentures = Dentures;
			UDentistBossEffectHandler::Trigger_OnDenturesFlipJumpStart(Dentist, EventParams);

			Dentures.EyesSpringinessEnabled.Apply(false, Dentures);

			JumpHeight = Settings.DenturesLastJumpHeight;
			JumpLength = Settings.DenturesLastJumpLength;
		}
		else
		{
			FDentistBossEffectHandlerOnDenturesFreeJumpParams EventParams;
			EventParams.Dentures = Dentures;
			UDentistBossEffectHandler::Trigger_OnDenturesFreeJumpStart(Dentist, EventParams);
		}

		FVector TargetLocation = Dentures.ActorLocation + (DirToPlayer * JumpLength);
		auto Params = Trajectory::CalculateParamsForPathWithHeight(Dentures.ActorLocation, TargetLocation, 
			GravitySettings.GravityAmount * GravitySettings.GravityScale, JumpHeight);
		Dentures.TimeLastJumpStarted = Time::GameTimeSeconds;
		FVector Impulse = Params.Velocity;
		MoveComp.AddPendingImpulse(Impulse);

		TEMPORAL_LOG(Dentures)
			.Sphere("Jump Target Location", TargetLocation, 50, FLinearColor::White, 10)
			.DirectionalArrow("Impulse", Dentures.ActorLocation, Impulse, 5, 20,  FLinearColor::White)
		;

		Dentures.GroundPoundAutoAimComp.Enable(this);

		Dentures.bShouldTraceForPlayerInFront = true;
		Dentures.OnJump.Broadcast();

		bHasJumped = true;
		Dentures.bIsJumping = true;
	}
};