class USanctuaryDodgerChargeBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(SanctuaryDodgerTags::SanctuaryDodgerDarkPortalBlock);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	FVector StartLocation;
	FVector Destination;
	bool bTrackTarget;
	bool bWasHeadingTowardsDestination;
	bool bWasCharging;
	float TelegraphEndTime;
	AHazePlayerCharacter PlayerTarget;

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USanctuaryDodgerGrabComponent GrabComp;
	USanctuaryDodgerSettings DodgerSettings;

	TArray<AHazeActor> AvailableTargets;
	

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		GrabComp = USanctuaryDodgerGrabComponent::Get(Owner);
		DodgerSettings = USanctuaryDodgerSettings::GetSettings(Owner);
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
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, BasicSettings.ChargeRange))
			return false;
		if(!GrabComp.CanGrab(TargetComp.Target))
			return false;

		// Only attack when we're facing target
		FVector ToTarget = (TargetComp.Target.ActorCenterLocation - Owner.ActorCenterLocation);
		ToTarget.Z = 0.0;
		if (Owner.ActorForwardVector.DotProduct(ToTarget.GetSafeNormal()) < 0.707) 
			return false;

		// Only start charge against players when in front and in camera direction
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if (Player != nullptr)
		{
			FVector ViewYawDir = FRotator(0.0, Player.ViewRotation.Yaw, 0.0).Vector();
			if (ViewYawDir.DotProduct(-ToTarget) < 0.707)
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
		if(!GentCostComp.IsTokenAvailable(DodgerSettings.ChargeGentlemanCost))
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
		if (!TargetComp.HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Owner.BlockCapabilities(SanctuaryDodgerTags::SanctuaryDodgerChargeBlock, this);

		GentCostComp.ClaimToken(this, DodgerSettings.ChargeGentlemanCost);

		// Telegraph for a while, then charge in
		TelegraphEndTime = Time::GameTimeSeconds + DodgerSettings.ChargeTelegraphDuration;
		bWasCharging = false;
		AnimComp.RequestFeature(FeatureTagDodger::Default, SubTagDodger::ChargeTelegraph, EBasicBehaviourPriority::Medium, this);

		bTrackTarget = true;
		bWasHeadingTowardsDestination = false;
		USanctuaryDodgerEventHandler::Trigger_OnTelegraphCharge(Owner);

		PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);

		// We can only hit our designated target
		AvailableTargets.Empty(1);
		AvailableTargets.Add(TargetComp.Target);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.UnblockCapabilities(SanctuaryDodgerTags::SanctuaryDodgerChargeBlock, this);

		GentCostComp.ReleaseToken(this, DodgerSettings.ChargeTokenCooldown);
		USanctuaryDodgerEventHandler::Trigger_OnChargeEnd(Owner);

		AnimComp.RequestFeature(FeatureTagDodger::Default, SubTagDodger::Fly, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds < TelegraphEndTime)
			TelegraphCharge();
		else
			PerformCharge();
	}

	void StartCharge()
	{
		AnimComp.RequestFeature(FeatureTagDodger::Default, SubTagDodger::ChargeFly, EBasicBehaviourPriority::Medium, this);
		StartLocation = Owner.ActorLocation;
		Destination = TargetComp.Target.ActorTransform.TransformPosition(BasicSettings.ChargeOffset);
		USanctuaryDodgerEventHandler::Trigger_OnChargeStart(Owner);
		bWasCharging = true;
	}

	void TelegraphCharge()
	{
		// Move in front of target predicted location before starting attack run
		FVector PredictedTargetLoc = TargetComp.Target.ActorLocation + TargetComp.Target.ActorVelocity * 0.5;
		FVector OffsetDir = TargetComp.Target.ActorForwardVector;
		if (PlayerTarget != nullptr)
			OffsetDir = PlayerTarget.ViewRotation.Vector().GetSafeNormal2D();
		FVector TelegraphDestination = PredictedTargetLoc + OffsetDir * BasicSettings.ChargeRange;
		TelegraphDestination.Z = PredictedTargetLoc.Z + DodgerSettings.ChargeTelegraphHeight;

		float Speed = BasicSettings.ChargeMoveSpeed;
		float Threshold = BasicSettings.ChargeMoveSpeed * 0.2;
		if (TelegraphDestination.IsWithinDist(Owner.ActorLocation, Threshold))
			Speed *= (TelegraphDestination.Distance(Owner.ActorLocation) / Threshold); 
		DestinationComp.MoveTowardsIgnorePathfinding(TelegraphDestination, Speed);
		DestinationComp.RotateTowards(TargetComp.Target);

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::EnemyCharacter);
		Trace.IgnoreActor(Owner);
		Trace.IgnoreActor(TargetComp.Target);
		Trace.UseLine();
		FHitResult Hit = Trace.QueryTraceSingle(Owner.FocusLocation, TargetComp.Target.FocusLocation);
		if (Hit.bBlockingHit)
		{
			// Note that we do this after movement, to preserve velocity
			Cooldown.Set(BasicSettings.ChargeCooldown);
		}
	}

	void PerformCharge()
	{
		if (!bWasCharging)
			StartCharge();

		// Stay in charge anim (when we stop requesting it we will play end anim)
		AnimComp.RequestFeature(FeatureTagDodger::Default, SubTagDodger::ChargeFly, EBasicBehaviourPriority::Medium, this);

		FVector OwnLoc = Owner.ActorLocation;
		if (bTrackTarget)
		{
			// Update destination
			Destination = TargetComp.Target.ActorTransform.TransformPosition(BasicSettings.ChargeOffset);

			// Should we stop following target?
			if (OwnLoc.IsWithinDist(Destination, BasicSettings.ChargeTrackTargetRange))
				bTrackTarget = false;
		}

		// Move beyond destination, so we won't stop when coming close
		FVector ToDestDir = (Destination - OwnLoc).GetSafeNormal();
		FVector BeyondDest = Destination + ToDestDir * (DestinationComp.MinMoveDistance + 80.0);
		DestinationComp.MoveTowardsIgnorePathfinding(BeyondDest, BasicSettings.ChargeMoveSpeed);
		DestinationComp.RotateTowards(BeyondDest);

		if (!bWasHeadingTowardsDestination && (ToDestDir.DotProduct(Owner.ActorVelocity) > 0.0))
			bWasHeadingTowardsDestination = true;

		// Check if we're hitting anything
		for (int i = AvailableTargets.Num() - 1; i >= 0; i--)
		{
			auto AvailableTarget = AvailableTargets[i];
			if (AvailableTarget.HasControl() && IsChargeHit(AvailableTarget))
				CrumbHitTarget(AvailableTarget);
		}

		if (ShouldEndCharge())
		{
			// Note that we do this after movement, to preserve velocity
			Cooldown.Set(BasicSettings.ChargeCooldown);
			return;	
		}
	}

	bool ShouldEndCharge()
	{
		// Past max duration?
		if (ActiveDuration > BasicSettings.ChargeMaxDuration)
			return true;

		if (bWasHeadingTowardsDestination)
		{
			// We have been going the right direction, have we passed destination? 
			if (Owner.ActorVelocity.DotProduct(Destination - Owner.ActorLocation) < 0.0)
				return true;
		}

		// Any targets left?
		if (AvailableTargets.Num() == 0)
			return true;

		if(GrabComp.bGrabbing)
			return true;

		// Keep charging
		return false;
	}

	bool IsChargeHit(AHazeActor Target)
	{
		// We can't hit targets if dead 
		if (HealthComp.IsDead())
			return false;

        // Project target location on our predicted movement to see if we'll be passing target soon.
		float PredictionTime = 0.1;
		float Radius = DodgerSettings.ChargeHitRadius;
        FVector ProjectedTargetLocation;
        float ProjectedFraction = 1.0;
        FVector OwnLocation = Owner.GetActorCenterLocation();
        FVector Vel = Owner.GetActorVelocity();
#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			Debug::DrawDebugCapsule(OwnLocation + Vel * PredictionTime * 0.5, Radius + Vel.Size() * PredictionTime * 0.5, Radius, FRotator(90,0,0).Compose(Owner.ActorForwardVector.Rotation()), FLinearColor::Red);
#endif
        if (Vel.IsNearlyZero(100.0))
			return false; // Too slow to hurt
			
        if (!Math::ProjectPositionOnLineSegment(OwnLocation, OwnLocation + Vel * PredictionTime, Target.ActorCenterLocation, ProjectedTargetLocation, ProjectedFraction))
        {
            if (ProjectedFraction == 0.0)
                return false; // We've passed target
        }

        if (ProjectedTargetLocation.DistSquared(Target.ActorCenterLocation) > Math::Square(Radius))
            return false; // Passing target, but too far away

        // Close enough to hit target!
        return true;
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbHitTarget(AHazeActor Target)
	{
		// We only strike each target once
		AvailableTargets.Remove(Target);

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Target);
		if (Player != nullptr)
			Player.DamagePlayerHealth(DodgerSettings.ChargeDamage);

		USanctuaryDodgerEventHandler::Trigger_OnChargeHit(Owner, FSanctuaryDodgerChargeHitParams(Target));

		GrabComp.Grab(Target);
	}
}

