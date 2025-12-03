class UDentistBossToolDenturesRidingIdleMovementCapability : UHazeCapability
{
	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 70;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBossToolDentures Dentures;
	ADentistBoss Dentist;

	UHazeMovementComponent MoveComp;
	USimpleMovementData Movement;

	UDentistBossSettings Settings;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentures = Cast<ADentistBossToolDentures>(Owner);
		Dentist = TListedActors<ADentistBoss>().GetSingle();

		MoveComp = UHazeMovementComponent::Get(Dentures);
		Movement = MoveComp.SetupSimpleMovementData();

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(Dentures.bDestroyed)
			return false;

		if(!Dentures.ControllingPlayer.IsSet())
			return false;

		if(Dentures.IsBitingHand())
			return false;

		return true;
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

		if(Dentures.IsBitingHand())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player = Dentures.ControllingPlayer.Value;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				Movement.AddGravityAcceleration();

				FVector Velocity = MoveComp.Velocity;
				if(MoveComp.HasGroundContact())
					Velocity = FVector::ZeroVector;

				Movement.AddPendingImpulses();
				Movement.AddGravityAcceleration();
				Movement.AddVelocity(Velocity);
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