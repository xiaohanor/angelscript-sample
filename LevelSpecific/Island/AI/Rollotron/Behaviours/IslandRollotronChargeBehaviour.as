class UIslandRollotronChargeBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	FVector Destination;
	bool bIsCharging;
	float TelegraphEndTime;
	AHazePlayerCharacter PlayerTarget;

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	UIslandRollotronSpikeComponent SpikeComp;
	UPoseableMeshComponent MeshComp;
	UIslandRollotronSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		SpikeComp = UIslandRollotronSpikeComponent::Get(Owner);
		MeshComp = UPoseableMeshComponent::Get(Owner);
		Settings = UIslandRollotronSettings::GetSettings(Owner);		
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive() && HealthComp.IsAlive() && !IsBlocked() && WantsToAttack())
			GentCostQueueComp.JoinQueue(this);
		else
			GentCostQueueComp.LeaveQueue(this);		
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.ChargeRange))
			return false;

		// Only attack when we're facing target
		FVector ToTarget = (TargetComp.Target.ActorCenterLocation - Owner.ActorCenterLocation);
		ToTarget.Z = 0.0;
		if (Owner.ActorForwardVector.DotProduct(ToTarget.GetSafeNormal()) < 0.707) // 45 deg
			return false;

		// Only start charge against players when in front and in camera direction
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if (Player != nullptr)
		{
			FVector ViewYawDir = FRotator(0.0, Player.ViewRotation.Yaw, 0.0).Vector();
			if (ViewYawDir.DotProduct(-ToTarget) < 0.707) // 45 deg
				return false;
		}
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!GentCostQueueComp.IsNext(this))
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.ChargeGentlemanCost))
			return false;
		if (!WantsToAttack())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ShouldEndCharge())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		if (Owner.ActorCenterLocation.IsWithinDist(Game::Players[0].ActorCenterLocation, Settings.DetonationRange) ||
		    Owner.ActorCenterLocation.IsWithinDist(Game::Players[1].ActorCenterLocation, Settings.DetonationRange))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, Settings.ChargeGentlemanCost);

		// Telegraph for a while, then charge in
		TelegraphEndTime = Time::GameTimeSeconds + Settings.ChargeTelegraphDuration;
		bIsCharging = false;
		UIslandRollotronEffectHandler::Trigger_OnTelegraphCharge(Owner);
		UIslandRollotronPlayerEffectHandler::Trigger_OnTelegraphCharge(Game::Zoe);
		UIslandRollotronPlayerEffectHandler::Trigger_OnTelegraphCharge(Game::Mio);

		PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this, Settings.ChargeTokenCooldown);
		UIslandRollotronEffectHandler::Trigger_OnChargeEnd(Owner);
		UIslandRollotronPlayerEffectHandler::Trigger_OnChargeEnd(Game::Mio);
		UIslandRollotronPlayerEffectHandler::Trigger_OnChargeEnd(Game::Zoe);

		UIslandRollotronEffectHandler::Trigger_OnDetonated(Owner);		
		UIslandRollotronPlayerEffectHandler::Trigger_OnDetonated(Game::Mio);
		UIslandRollotronPlayerEffectHandler::Trigger_OnDetonated(Game::Zoe);
		SpikeComp.bIsJumping = false;

		// Kill self
		HealthComp.TakeDamage(1.0, EDamageType::Explosion, Owner);

		// Deal damage		
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!Owner.ActorCenterLocation.IsWithinDist(Player.ActorCenterLocation, Settings.ExplosionDamageRange))
				continue;
			
			Player.DealTypedDamage(Owner, Settings.ExplosionDamage, EDamageEffectType::Explosion, EDeathEffectType::Explosion);
		}
		

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(Owner.ActorCenterLocation, Settings.ExplosionDamageRange, LineColor = FLinearColor::Red, Duration = 1.0);
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds < TelegraphEndTime)
			TelegraphCharge();
		else
			PerformCharge();
	}
	
	void TelegraphCharge()
	{
		// Move in front of target predicted location before starting attack run
		FVector PredictedTargetLoc = TargetComp.Target.ActorLocation + TargetComp.Target.ActorVelocity * 0.5;
		FVector OffsetDir = TargetComp.Target.ActorForwardVector;
		if (PlayerTarget != nullptr)
			OffsetDir = PlayerTarget.ViewRotation.Vector().GetSafeNormal2D();
		FVector TelegraphDestination = PredictedTargetLoc + OffsetDir * BasicSettings.ChargeRange;
		TelegraphDestination.Z = PredictedTargetLoc.Z + Settings.ChargeTelegraphHeight;

		float Speed = BasicSettings.ChargeMoveSpeed;
		float Threshold = BasicSettings.ChargeMoveSpeed * 0.2;
		if (TelegraphDestination.IsWithinDist(Owner.ActorLocation, Threshold))
			Speed *= (TelegraphDestination.Distance(Owner.ActorLocation) / Threshold); 
		DestinationComp.MoveTowards(TelegraphDestination, Speed);
		DestinationComp.RotateTowards(TargetComp.Target);
	}

	void PerformCharge()
	{		
		if (bIsCharging)
			return;

		FVector ToTarget = (TargetComp.Target.ActorCenterLocation) - Owner.ActorCenterLocation;
		ToTarget += ToTarget.GetSafeNormal() * Settings.ChargeOffsetDistance;
		Destination = Owner.ActorCenterLocation + ToTarget;
		UIslandRollotronEffectHandler::Trigger_OnChargeStart(Owner);
		UIslandRollotronPlayerEffectHandler::Trigger_OnChargeStart(Game::Mio);
		UIslandRollotronPlayerEffectHandler::Trigger_OnChargeStart(Game::Zoe);
		bIsCharging = true;
		FVector ToDestination = (Destination - Owner.ActorCenterLocation);		
		FVector ImpulseDir = ToDestination.GetSafeNormal().RotateTowards(FVector::UpVector, Settings.ChargeImpulseAngle);
		Owner.AddMovementImpulse(ImpulseDir * ToDestination.Size() * Settings.ChargeImpulseFactor);
		SpikeComp.bIsJumping = true;

	}

	bool ShouldEndCharge() const
	{
		// Past max duration?
		if (ActiveDuration > Settings.ChargeMaxDuration)
			return true;

		if (SpikeComp.bIsJumping)
		{
			// We have been going the right direction, have we passed destination? 
			if (Owner.ActorVelocity.DotProduct(Destination - Owner.ActorLocation) < 0.0)
				return true;
		}

		// Keep charging
		return false;
	}

}

