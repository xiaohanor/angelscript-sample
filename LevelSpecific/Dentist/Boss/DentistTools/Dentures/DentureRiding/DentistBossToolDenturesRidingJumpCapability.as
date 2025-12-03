class UDentistBossToolDenturesRidingJumpCapability : UHazeCapability
{
	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 70;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBossToolDentures Dentures;
	ADentistBoss Dentist;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	UDentistBossSettings Settings;

	const float JumpGracePeriod = 0.2;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentures = Cast<ADentistBossToolDentures>(Owner);
		Dentist = TListedActors<ADentistBoss>().GetSingle();

		MoveComp = UHazeMovementComponent::Get(Dentures);
		Movement = MoveComp.SetupSteppingMovementData();

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(Dentures.bDestroyed)
			return false;

		if(!MoveComp.IsOnAnyGround())
			return false;

		if(!Dentures.ControllingPlayer.IsSet())
			return false;

		if(Dentures.IsBitingHand())
			return false;

		if(WasActionStartedDuringTime(ActionNames::MovementJump, JumpGracePeriod))
			return true;
			
		if(WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, JumpGracePeriod))
			return true;	

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(Dentures.bDestroyed)
			return true;

		if(!Dentures.ControllingPlayer.IsSet())
			return true;

		if(MoveComp.HasImpactedGround())
			return true;

		if(Dentures.IsBitingHand())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player = Dentures.ControllingPlayer.Value;

		FVector Impulse = 
			Dentures.ActorForwardVector * Settings.DenturesRidingJumpForwardSize
			+ Dentures.ActorUpVector * Settings.DenturesRidingJumpUpwardsSize;

		Dentures.bShouldTraceForPlayerInFront = true;
		Dentures.OnJump.Broadcast();
		Dentures.AddMovementImpulse(Impulse);

		Dentures.bIsJumping = true;

		FDentistBossEffectHandlerOnDenturesRiddenJumpParams EventParams;
		EventParams.Dentures = Dentures;
		EventParams.RidingPlayer = Player;
		UDentistBossEffectHandler::Trigger_OnDenturesRiddenJumpStart(Dentist, EventParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(MoveComp.HasGroundContact())
			Dentures.ActorVelocity = FVector::ZeroVector;

		Dentures.bShouldTraceForPlayerInFront = false;
		
		Dentures.bIsJumping = false;

		FDentistBossEffectHandlerOnDenturesRiddenJumpParams EventParams;
		EventParams.Dentures = Dentures;
		EventParams.RidingPlayer = Player;
		UDentistBossEffectHandler::Trigger_OnDenturesRiddenJumpLand(Dentist, EventParams);

		ForceFeedback::PlayWorldForceFeedback(ForceFeedback::Default_Medium_Short,Dentures.ActorLocation,false, this, InnerRadius = 800, FalloffRadius = 2500);

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				Movement.AddOwnerVelocity();
				Movement.AddGravityAcceleration();
				Movement.AddPendingImpulses();
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
		}
	}
};