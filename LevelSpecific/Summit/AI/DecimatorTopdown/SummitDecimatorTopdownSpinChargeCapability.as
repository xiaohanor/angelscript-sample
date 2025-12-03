struct FStructSummitDecimatorTopdownSpinChargeCooldownEntry
{
	bool bHasSetDealDelayedDamageCooldown = false;
	float CooldownTimer = 0;
}

class USummitDecimatorTopdownSpinChargeCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	default DebugCategory = CapabilityTags::Movement;

	AAISummitDecimatorTopdown Decimator;

	USummitDecimatorTopdownSettings Settings;

	// Movecomp and movement data
	UBasicAICharacterMovementComponent MoveComp; // Need UBasicAICharacterMovementComponent, can use UHazeMovementComponent?
	USteppingMovementData Movement;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIAnimationComponent AnimComp;
	USummitDecimatorTopdownPhaseComponent PhaseComp;
	USummitDecimatorTopdownPlayerTargetComponent TargetComp;

	AHazeActor Target;
	bool bTargetPlayers = true;
	bool bAlternateTarget = true;
	float MirrorCooldownTime = 0;

	bool bHadWallContact = false;	

	FVector PrevLocation;

	FVector ChargeDir;
	float CurrentSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USummitDecimatorTopdownSettings::GetSettings(Owner);

		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner, n"SpinChargeSyncedPosition"); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
		UMovementSteppingSettings::SetStepUpSize(Cast<AHazeActor>(Owner), FMovementSettingsValue::MakeValue(0), this);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		PhaseComp = USummitDecimatorTopdownPhaseComponent::Get(Owner);
		TargetComp = USummitDecimatorTopdownPlayerTargetComponent::Get(Owner);

		Decimator = Cast<AAISummitDecimatorTopdown>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PhaseComp.CurrentState != ESummitDecimatorState::RunningAttackSequence)
			return false;
		if(PhaseComp.GetCurrentAttackState() != ESummitDecimatorAttackState::ChargingAndSpawningSpikeBombs)
			return false;
		if (MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PhaseComp.CurrentState != ESummitDecimatorState::RunningAttackSequence)
			return true;
		if(PhaseComp.GetCurrentAttackState() != ESummitDecimatorAttackState::ChargingAndSpawningSpikeBombs)
			return true;
		if (ActiveDuration > Settings.SpinChargeDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PrevLocation = Owner.ActorLocation;
		bHadWallContact = false;
		
		Target = TargetComp.Target;
		ChargeDir = (Target.ActorLocation - Owner.ActorLocation).GetSafeNormal2D();
		CurrentSpeed = Settings.SpinChargeMaxSpeed;
		DecimatorTopdown::Animation::RequestFeatureSpinStart(AnimComp, this);

		DecimatorTopdown::Collision::SetPlayerIgnoreCollision(Decimator);
		
		USummitDecimatorTopdownEffectsHandler::Trigger_OnSpinChargeStart(Owner);
		
		MoveComp.Reset(true);
#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			PrintToScreen("Activated Substate: SpinCharge", 5.0, Color=FLinearColor::Yellow);
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CurrentSpeed = 0;

		PhaseComp.TryActivateNextAttackState();
		
		// Switch target for next time
		TargetComp.SwitchTarget();
		Owner.SetActorEnableCollision(true);
		//USummitDecimatorTopdownEffectsHandler::Trigger_OnSpinChargeStop(Owner);		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			
		if (ActiveDuration < Settings.SpinChargeAnimationTelegraphDuration)
			return;

		AddSpikebombImpactImpulse();

		if(!PrepareMove())
			return;

		// Resolve and apply movement
		if(HasControl())
		{
			ComposeMovement(DeltaTime);
		}
		else
		{
			// From BasicAIMovementCapability:
			// Since we normally don't want to replicate velocity, we use move since last frame instead.
			// This can fluctuate wildly, introduce smoothing/velocity replication if necessary
			FVector Velocity = (DeltaTime > 0.0) ? (Owner.ActorLocation - PrevLocation) / DeltaTime : Owner.ActorVelocity;
			ApplyCrumbSyncedMovement(Velocity);
			PrevLocation = Owner.ActorLocation;
		}
		MoveComp.ApplyMove(Movement);
		
		if(MoveComp.HasImpactedWall())
		{
			FDecimatorTopDownSpinChargeImpactParams Params;
			Params.Strength = MoveComp.PreviousVelocity.Size();
			USummitDecimatorTopdownEffectsHandler::Trigger_OnSpinChargeImpactWall(Decimator, Params);
		}

#if EDITOR
		// Debug info
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			PrintToScreen("Remaining spin charge time: " + (Settings.SpinChargeDuration - ActiveDuration), Color=FLinearColor::Green);
#endif
	}

	bool PrepareMove()
	{
		return MoveComp.PrepareMove(Movement);
	}

	void ApplyCrumbSyncedMovement(FVector Velocity)
	{
		Movement.ApplyCrumbSyncedGroundMovementWithCustomVelocity(Velocity);			
	}

	void ComposeMovement(float DeltaTime)
	{	
		FHitResult Hit = MoveComp.GetWallContact().ConvertToHitResult();		
		FVector Velocity = MoveComp.Velocity;
		MirrorCooldownTime-=DeltaTime;

		if (Hit.bBlockingHit && MirrorCooldownTime <= 0 && Hit.ImpactNormal.DotProduct(ChargeDir) < 0)
		{
			// Default to mirror charge dir
			ChargeDir = ChargeDir.MirrorByVector(Hit.ImpactNormal);
			ChargeDir.Z = 0;
			ChargeDir.Normalize();

			if (bTargetPlayers)
			{
				// If we have a target, change charge dir towards the target
				AHazeActor NextTarget = GetNextTarget();
				if (NextTarget != nullptr)
				{
					Target = NextTarget;
					ChargeDir = (NextTarget.ActorLocation - Owner.ActorLocation).GetSafeNormal2D();
				}
			}

			Velocity = ChargeDir * Settings.SpinChargeAcceleration * Settings.SpinChargeBounceFrictionFactor;
			MirrorCooldownTime = 1.0;
		}

		float Friction = 0.001;
		if (ActiveDuration < Settings.SpinChargeDuration - 1.5)
			Velocity += ChargeDir * Settings.SpinChargeAcceleration * DeltaTime; // full throttle
		else
			Friction *= 1000; // time to break
		
		float FrictionFactor = Math::Pow(Math::Exp(-Friction), DeltaTime);
		
		Velocity *= FrictionFactor;
		Velocity = Velocity.GetClampedToMaxSize(Settings.SpinChargeMaxSpeed); // not too fast

		Movement.AddPendingImpulses();
		Movement.AddHorizontalVelocity(Velocity);
		Movement.AddGravityAcceleration();
#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			PrintToScreen("Activated Substate: Spawn Spikebombs", 5.0, Color=FLinearColor::Yellow);
			PrintScaled("MoveComp.Velocity: " + MoveComp.Velocity.Size(), Duration = 0.0f);
			PrintScaled("Velocity: " + Velocity.Size(), Duration = 0.0f);

			Debug::DrawDebugArrow(Owner.ActorCenterLocation, Owner.ActorCenterLocation + Velocity, LineColor=FLinearColor::Green);
			Debug::DrawDebugArrow(Owner.ActorCenterLocation, Owner.ActorCenterLocation + ChargeDir * 1000, LineColor=FLinearColor::Blue);
		}
#endif
	}

	// prototype hack
	void AddSpikebombImpactImpulse()
	{
		if (Decimator.bHasBeenHit && Decimator.SpikeBombHitDirection != FVector::ZeroVector)
		{
			Decimator.AddMovementImpulse(Decimator.SpikeBombHitDirection * 1000.0);
			Decimator.SpikeBombHitDirection = FVector::ZeroVector; // Cancel out for next hit, if consecutive.
		}
	}

	AHazeActor GetNextTarget()
	{
		AHazeActor TargetCandidate;
		if (bAlternateTarget)
		{
			// Select other target, if alive
			TargetCandidate = TargetComp.Target == Target ? TargetComp.Target.OtherPlayer : TargetComp.Target;
			if (TargetComp.IsTargetAlive(TargetCandidate))
				return TargetCandidate;
		}
		else
		{
			// Keep current target, if alive
			if (TargetComp.IsTargetAlive(TargetComp.Target))
				return TargetCandidate;
		}
		
		return nullptr; // no valid target		
	}
};