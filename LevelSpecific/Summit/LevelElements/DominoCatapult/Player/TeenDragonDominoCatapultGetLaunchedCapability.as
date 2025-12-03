class UTeenDragonDominoCatapultGetLaunchedCapability : UHazePlayerCapability
{
	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 10;

	UTeenDragonDominoCatapultComponent CatapultComp;
	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonRollComponent RollComp;

	UPlayerMovementComponent MoveComp;
	UTeenDragonRollMovementData Movement;

	UMovementGravitySettings GravitySettings;

	FHazeAcceleratedQuat AccRotation;

	const float PlayerIgnoreCatapultDuration = 0.2;
	const float MaxDuration = 5.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CatapultComp = UTeenDragonDominoCatapultComponent::GetOrCreate(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = Cast<UTeenDragonRollMovementData>(MoveComp.SetupMovementData(UTeenDragonRollMovementData));

		GravitySettings = UMovementGravitySettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!CatapultComp.LaunchImpulse.IsSet())
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(MoveComp.HasAnyValidBlockingImpacts())
			return true;

		if(Player.IsPlayerDead())
			return true;

		if(ActiveDuration > MaxDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(RollComp == nullptr)
			RollComp = UTeenDragonRollComponent::Get(Player);

		if(DragonComp == nullptr)
			DragonComp = UPlayerTailTeenDragonComponent::Get(Player);

		Player.SetActorVelocity(CatapultComp.LaunchImpulse.Value);
		CatapultComp.LaunchImpulse.Reset();
		MoveComp.AddMovementIgnoresActor(this, CatapultComp.LaunchingCatapult);

		RollComp.RollingInstigators.Add(this);
		RollComp.RollUntilImpactInstigators.Add(this);
		
		UMovementGravitySettings NewGravitySettings = UMovementGravitySettings();
		NewGravitySettings.bOverride_GravityAmount = true;
		NewGravitySettings.GravityAmount = CatapultComp.LaunchingCatapult.LaunchGravityAmount;
		Player.ApplySettings(NewGravitySettings, this);

		Player.ApplyBlendToCurrentView(0.5);

		AccRotation.SnapTo(Player.ActorQuat);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		RollComp.RollingInstigators.RemoveSingleSwap(this);
		RollComp.RollUntilImpactInstigators.RemoveSingleSwap(this);

		Player.ClearSettingsByInstigator(this);

		MoveComp.RemoveMovementIgnoresActor(this);

		if(MoveComp.HasAnyValidBlockingImpacts())
		{
			auto Impacts = MoveComp.AllImpacts;
			for(auto Impact : Impacts)
			{
				auto RollResponseComp = UTeenDragonTailAttackResponseComponent::Get(Impact.Actor);
				if(RollResponseComp != nullptr)
				{
					RollResponseComp.bShouldStopPlayer = true;
					MoveComp.AddMovementIgnoresActor(this, Impact.Actor);

					Timer::SetTimer(this, n"RemoveIgnoredActor", 0.5);
				}
			}
		}
	}

	UFUNCTION()
	private void RemoveIgnoredActor()
	{
		MoveComp.RemoveMovementIgnoresActor(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.HasAnyValidBlockingContacts())
		{
			RollComp.RollUntilImpactInstigators.Reset();
		}

		if(ActiveDuration > PlayerIgnoreCatapultDuration)
			MoveComp.RemoveMovementIgnoresActor(this);

		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				Movement.AddOwnerVelocity();
				Movement.AddGravityAcceleration(false);

				FQuat TargetQuat = FQuat::MakeFromX(MoveComp.Velocity);
				AccRotation.AccelerateTo(TargetQuat, 0.5, DeltaTime);
				Movement.SetRotation(AccRotation.Value);
			}
			else
			{
				// Follow the crumb trail on the remote side
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::RollMovement);
		}
	}
};