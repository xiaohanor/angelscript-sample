struct FTeenDragonBallistaGetLaunchedActivationParams
{
	FVector LaunchImpulse;
	ASummitBallista LaunchingBallista;
}

class UTeenDragonBallistaGetLaunchedCapability : UHazePlayerCapability
{
	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 10;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTeenDragonBallistaComponent BallistaComp;
	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonRollComponent RollComp;

	UPlayerMovementComponent MoveComp;
	UTeenDragonRollMovementData Movement;

	UMovementGravitySettings GravitySettings;

	FHazeAcceleratedQuat AccRotation;

	const float PlayerIgnoreCatapultDuration = 0.2;
	const float MaxDuration = 5.0;

	ASummitBallista LaunchingBallista;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallistaComp = UTeenDragonBallistaComponent::GetOrCreate(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = Cast<UTeenDragonRollMovementData>(MoveComp.SetupMovementData(UTeenDragonRollMovementData));

		GravitySettings = UMovementGravitySettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTeenDragonBallistaGetLaunchedActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(BallistaComp.LaunchingBallista == nullptr)
			return false;

		if(BallistaComp.LaunchImpulse.IsSet())
		{
			Params.LaunchImpulse = BallistaComp.LaunchImpulse.Value;
			Params.LaunchingBallista = BallistaComp.LaunchingBallista;
			return true;
		}
		
		return false;
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
	void OnActivated(FTeenDragonBallistaGetLaunchedActivationParams Params)
	{
		if(RollComp == nullptr)
			RollComp = UTeenDragonRollComponent::Get(Player);

		if(DragonComp == nullptr)
			DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		
		LaunchingBallista = Params.LaunchingBallista;

		Player.SetActorVelocity(Params.LaunchImpulse);
		BallistaComp.LaunchImpulse.Reset();
		MoveComp.AddMovementIgnoresActor(this, LaunchingBallista);

		RollComp.RollingInstigators.Add(this);
		RollComp.RollUntilImpactInstigators.Add(this);
		
		UMovementGravitySettings NewGravitySettings = UMovementGravitySettings();
		NewGravitySettings.bOverride_GravityAmount = true;
		NewGravitySettings.GravityAmount = LaunchingBallista.LaunchGravity;
		Player.ApplySettings(NewGravitySettings, this);

		Player.ApplyBlendToCurrentView(0.5);

		AccRotation.SnapTo(Player.ActorQuat);

		FHazePointOfInterestFocusTargetInfo POI;
		POI.SetFocusToActor(LaunchingBallista.Target);
		FApplyPointOfInterestSettings ApplyPOI;
		ApplyPOI.Duration = 1.25;
		ApplyPOI.BlendInAccelerationType = ECameraPointOfInterestAccelerationType::Slow;

		LaunchingBallista.OnSummitBallistaZoeLaunched.Broadcast();

		Player.ApplyPointOfInterest(this, POI, ApplyPOI);
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

				// Audio
				AStaticMeshActor HitDragonWingActor = Cast<AStaticMeshActor>(Impact.Actor);
				if(HitDragonWingActor != nullptr)
				{
					AHazeActor DragonWingsAudioActor = nullptr;
					TArray<AActor> AttachedActors;
					HitDragonWingActor.GetAttachParentActor().GetAttachedActors(AttachedActors);

					for(auto& Child : AttachedActors)
					{
						if(Child.IsA(AHazeActor))
						{
							DragonWingsAudioActor = Cast<AHazeActor>(Child);
							break;
						}
					}

					if(DragonWingsAudioActor != nullptr)
					{
						USummitBallistaEventHandler::Trigger_OnDragonImpactSpinningBlocker(DragonWingsAudioActor);
					}
				}
			}
		}

		Player.ClearPointOfInterestByInstigator(this);
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