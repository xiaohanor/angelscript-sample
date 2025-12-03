class UTundraGnapeBallisticCapabilty : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"GnapeThrow");
	default TickGroup = EHazeTickGroup::InfluenceMovement;

	UBasicAICharacterMovementComponent MoveComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UTundraGnatComponent GnapeComp;
	UBasicAIDestinationComponent DestComp;
	UBasicAIAnimationComponent AnimComp;
	UTundraGnatHostComponent HostComp;
	UBasicAIHealthComponent HealthComp;
	UPlayerSnowMonkeyThrowGnapeComponent ThrowerComp;
	UTundraGnapeAnnoyedPlayerComponent ZoeAnnoyedComp;

	UTundraGnatSettings Settings;
	USimpleMovementData Movement;

	FVector PrevLocation;
	FRotator HackMeshRot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::Get(Owner); 
		GnapeComp = UTundraGnatComponent::Get(Owner);
		DestComp = UBasicAIDestinationComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		ZoeAnnoyedComp = UTundraGnapeAnnoyedPlayerComponent::GetOrCreate(Game::Zoe);
		Settings = UTundraGnatSettings::GetSettings(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraGnatMovementParams& OutParams) const
	{
		if (!GnapeComp.bGoBallistic)
			return false;
		if (DestComp.bHasPerformedMovement)
			return false;
		OutParams.HostComp = UTundraGnatHostComponent::Get(GnapeComp.Host);
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

		GnapeComp.bGoBallistic = true;
		GnapeComp.Host = Params.HostComp.Owner;
		HostComp = Params.HostComp;
		ThrowerComp = UPlayerSnowMonkeyThrowGnapeComponent::Get(Game::Mio);

		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;
		MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled);
		if (HostComp.Body != nullptr)
			MoveComp.FollowComponentMovement(HostComp.Body, this, EMovementFollowComponentType::ReferenceFrame, EInstigatePriority::Normal);
		else 
			MoveComp.FollowComponentMovement(HostComp.Mesh, this, EMovementFollowComponentType::ReferenceFrame, EInstigatePriority::Normal, n"Hips");
	
		UMovementGravitySettings::SetGravityAmount(Owner, Settings.ThrownGravity, this, EHazeSettingsPriority::Gameplay);
		UMovementGravitySettings::SetGravityScale(Owner, 1.0, this, EHazeSettingsPriority::Gameplay);

		HackMeshRot = Cast<AHazeCharacter>(Owner).Mesh.RelativeRotation;

		// We can go ballistic when moving locally, if thrown accurately enough. Make sure we crumb movement as soon as we do.
		MoveComp.bResolveMovementLocally.Apply(false, this, EInstigatePriority::High);

		UTundraGnatEffectEventHandler::Trigger_OnHitByThrownGnape(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
		GnapeComp.bGoBallistic = false;

		MoveComp.UnFollowComponentMovement(this);
		MoveComp.ClearFollowEnabledOverride(this);
		Owner.ClearSettingsByInstigator(this);

		// Die at end of fall, regardless of where we end up for now
		HealthComp.TakeDamage(HealthComp.MaxHealth, EDamageType::MeleeBlunt, Game::Mio);

		MoveComp.bResolveMovementLocally.Clear(this);
		
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

		if (Settings.GnapeThrownChainReaction)
			GnapeComp.CheckGnapeImpacts(ThrowerComp, ZoeAnnoyedComp); 

		// HACK rotate until we have proper anim
		auto Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		HackMeshRot.Pitch += DeltaTime * -480.0;
		Mesh.RelativeRotation = HackMeshRot;
	}

	void ComposeMovement(float DeltaTime)
	{
		// Fall and bounce
		if (MoveComp.AllGroundImpacts.Num() > 0)
		{
			float BounceSpeed = MoveComp.Velocity.Size() * 0.5;
			Movement.AddVelocity(MoveComp.AllGroundImpacts[0].ImpactNormal * BounceSpeed);	
		}

		Movement.AddVelocity(MoveComp.Velocity);
		Movement.AddGravityAcceleration();
		Movement.AddPendingImpulses();
	}
}
