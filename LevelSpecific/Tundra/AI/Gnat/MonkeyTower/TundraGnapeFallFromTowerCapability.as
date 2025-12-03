class UTundraGnapeFallFromTowerCapabilty : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"GnapeThrow");
	default TickGroup = EHazeTickGroup::InfluenceMovement;

	UBasicAICharacterMovementComponent MoveComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIDestinationComponent DestComp;
	UTundraGnatComponent GnapeComp;
	UBasicAIAnimationComponent AnimComp;
	UTundraGnatHostComponent HostComp;
	UBasicAIHealthComponent HealthComp;

	UTundraGnatSettings Settings;
	UTeleportingMovementData Movement;

	FVector PrevLocation;
	FRotator HackMeshRot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::Get(Owner); 
		DestComp = UBasicAIDestinationComponent::Get(Owner);
		GnapeComp = UTundraGnatComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		Settings = UTundraGnatSettings::GetSettings(Owner);
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraGnatMovementParams& OutParams) const
	{
		if (!GnapeComp.bFallFromTower)
			return false;
		if (DestComp.bHasPerformedMovement)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > Settings.ThrownMaxDuration) 
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraGnatMovementParams Params)
	{
		Owner.BlockCapabilities(BasicAITags::Behaviour, this);
		AnimComp.RequestFeature(TundraGnatTags::HitByThrownMonkey, EBasicBehaviourPriority::Medium, this);

		GnapeComp.bFallFromTower = true;

		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;

		// Initial impulse away from Zoe, with some scatter
		FVector Impulse = (Owner.ActorLocation - Game::Zoe.ActorLocation).GetSafeNormal2D() * Math::RandRange(0.7, 1.2) * 7000.0;
		Impulse = Impulse.RotateAngleAxis(Math::RandRange(-1.0, 1.0) * 30.0, FVector::UpVector);
		Impulse += FVector::UpVector * Math::RandRange(0.5, 1.0) * 3000.0;
		Owner.AddMovementImpulse(Impulse);
	
		UMovementGravitySettings::SetGravityAmount(Owner, Settings.ThrownGravity, this, EHazeSettingsPriority::Gameplay);
		UMovementGravitySettings::SetGravityScale(Owner, 2.0, this, EHazeSettingsPriority::Gameplay);

		HackMeshRot = Cast<AHazeCharacter>(Owner).Mesh.RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
		GnapeComp.bFallFromTower = false;

		Owner.ClearSettingsByInstigator(this);

		// Die at end of fall, regardless of where we end up for now
		HealthComp.TakeDamage(HealthComp.MaxHealth, EDamageType::MeleeBlunt, Game::Zoe);
		
		Cast<AHazeCharacter>(Owner).Mesh.RelativeRotation = FRotator::ZeroRotator;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
		{
			ComposeMovement(DeltaTime);
		}
		else
		{
			FVector Velocity = (DeltaTime > 0.0) ? (Owner.ActorLocation - PrevLocation) / DeltaTime : Owner.ActorVelocity;
			Movement.ApplyCrumbSyncedAirMovementWithCustomVelocity(Velocity);
			PrevLocation = Owner.ActorLocation;
		}

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, TundraGnatTags::HitByThrownMonkey);
		DestComp.bHasPerformedMovement = true;

		// HACK rotate until we have proper anim
		auto Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		HackMeshRot.Pitch += DeltaTime * -480.0;
		Mesh.RelativeRotation = HackMeshRot;
	}

	void ComposeMovement(float DeltaTime)
	{
		// Fall 
		Movement.AddVelocity(MoveComp.Velocity);
		Movement.AddGravityAcceleration();
		Movement.AddPendingImpulses();
	}
}
