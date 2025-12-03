class UAdultDragonExitLandingSiteCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default TickGroupOrder = 2;

	default TickGroup = EHazeTickGroup::ActionMovement;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerAdultDragonComponent DragonComp;
	UPlayerTargetablesComponent TargetablesComp;
	UPlayerMovementComponent MoveComp;
	UAdultDragonLandingSiteComponent LandingSiteComp;
	UAdultDragonLandingSiteSettings Settings;
	USimpleMovementData Movement;

	float Speed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
		LandingSiteComp = UAdultDragonLandingSiteComponent::Get(Player);
		Settings = UAdultDragonLandingSiteSettings::GetSettings(Player);
		DragonComp = UPlayerAdultDragonComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!LandingSiteComp.bAtLandingSite)
			return false;

		if(LandingSiteComp.bBlowingHorn)
			return false;

		if(!WasActionStarted(ActionNames::Cancel) && !LandingSiteComp.bForceExitLandingSite)
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Settings.DelayBeforeTakingOff + Settings.TakeOffDuration)
			return true;

		if(MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Speed = Settings.TakeOffImpulse;
		DragonComp.WantedRotation = Player.ActorRotation;
		DragonComp.AccRotation.SnapTo(Player.ActorRotation);
		LandingSiteComp.bForceExitLandingSite = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LandingSiteComp.CurrentLandingSite.LandingPlayer = nullptr;
		LandingSiteComp.ExitLandingSite();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				if(ActiveDuration > Settings.DelayBeforeTakingOff)
				{
					Movement.AddVelocity(FVector::UpVector * Speed);
					Speed -= Settings.TakeOffDeceleration * DeltaTime;
					Speed = Math::Max(0.0, Speed);
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AdultDragonFlying");
		}
	}
}