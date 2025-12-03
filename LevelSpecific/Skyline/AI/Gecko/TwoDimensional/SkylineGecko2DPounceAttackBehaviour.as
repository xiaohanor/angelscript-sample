class USkylineGecko2DPounceAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	UWallclimbingComponent WallClimbingComp;
	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIRuntimeSplineComponent SplineComp;
	USkylineGeckoSettings Settings;
	UTargetTrailComponent TargetTrail;
	USkylineGeckoComponent GeckoComp;
	
	FVector TargetLocation;
	TArray<AHazePlayerCharacter> AvailableTargets;
	float Radius;
	bool bWasTelegraphing;
	float DoneSettlingTime;
	AHazeActor Target;
	FVector StartPounceLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		WallClimbingComp = UWallclimbingComponent::GetOrCreate(Owner);
		SplineComp = UBasicAIRuntimeSplineComponent::GetOrCreate(Owner);
		GeckoComp = USkylineGeckoComponent::GetOrCreate(Owner);
		Settings = USkylineGeckoSettings::GetSettings(Owner);

		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		if(Character != nullptr)
			Radius = Character.CapsuleComponent.CapsuleRadius;

		// We want trails!
		UTargetTrailComponent::GetOrCreate(Game::Mio);
		UTargetTrailComponent::GetOrCreate(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive() && HealthComp.IsAlive() && WantsToAttack() && !IsBlocked())
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
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.Pounce2DAttackRange))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!WantsToAttack())
			return false;
		if(!GentCostQueueComp.IsNext(this) && (Settings.Pounce2DAttackGentlemanCost != EGentlemanCost::None))
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.Pounce2DAttackGentlemanCost))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;

		if (ActiveDuration > Settings.Pounce2DAttackMaxDuration + Settings.Pounce2DAttackSettleDuration)
			return true;

		// End when we reach target destination
		if (ActiveDuration > DoneSettlingTime) 
			return true;

		if (!TargetComp.IsValidTarget(Target))
			return true;
	
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, Settings.Pounce2DAttackGentlemanCost);		
		Target = TargetComp.Target;
		TargetTrail = UTargetTrailComponent::Get(Target);
		TargetLocation = GetTargetLocation();
		AvailableTargets.Empty();
		bWasTelegraphing = true;
		SplineComp.Reset();
		DoneSettlingTime = BIG_NUMBER;

		AnimComp.RequestFeature(FeatureTagGecko::MeleeAttack, SubTagGeckoMeleeAttack::MeleeAttackTelegraph, EBasicBehaviourPriority::Medium, this, Settings.Pounce2DAttackTelegraphDuration);
		USkylineGeckoEffectHandler::Trigger_OnTelegraphPounce(Owner);

		WallClimbingComp.DestinationUpVector.Apply(Target.ActorUpVector, this, EInstigatePriority::Normal);
		GeckoComp.bAllowBladeHits.Apply(false, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this, Settings.Pounce2DAttackTokenCooldown);
		Cooldown.Set(Settings.Pounce2DAttackCooldownDuration);
		if (DoneSettlingTime == BIG_NUMBER)
			USkylineGeckoEffectHandler::Trigger_OnPounceEnd(Owner);
		SplineComp.Reset();
		Owner.ClearSettingsByInstigator(this);
		
		// Check for new target after completing attack
		if (ActiveDuration > Settings.Pounce2DAttackTelegraphDuration)
			TargetComp.Target = nullptr;

		WallClimbingComp.DestinationUpVector.Clear(this);
		GeckoComp.bAllowBladeHits.Clear(this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartAttack()
	{
		bWasTelegraphing = false;
		AvailableTargets = Game::Players;
		AnimComp.RequestFeature(FeatureTagGecko::MeleeAttack, SubTagGeckoMeleeAttack::MeleeAttack, EBasicBehaviourPriority::Medium, this);
		USkylineGeckoEffectHandler::Trigger_OnPounceStart(Owner);

		// Use direct movement from this point onwards
		UPathfollowingSettings::SetIgnorePathfinding(Owner, true, this, EHazeSettingsPriority::Gameplay);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < Settings.Pounce2DAttackTelegraphDuration)
		{
			WallClimbingComp.PreferredGravity = -Target.ActorUpVector;
			TargetLocation = GetTargetLocation();
		}

		if(ActiveDuration < Settings.Pounce2DAttackTelegraphDuration)
		{
			// Telegraphing repositioning
			// TODO...
			DestinationComp.RotateTowards(Target);
			return;
		}

		// Pounce!
		if (bWasTelegraphing && HasControl())
			CrumbStartAttack();

		if (DoneSettlingTime == BIG_NUMBER)	
			DestinationComp.MoveTowardsIgnorePathfinding(TargetLocation, Settings.Pounce2DAttackMoveSpeed);

		// We only have targets when attack is underway
		for(int i = AvailableTargets.Num() - 1; i >= 0; i--)
		{
			AHazePlayerCharacter Player = AvailableTargets[i];
			if (!Player.HasControl())
				continue;
			if(!Player.ActorLocation.IsWithinDist(Owner.ActorLocation, Settings.Pounce2DAttackHitRadius))
				continue;
			CrumbHitTarget(Player);
		}

		if (HasControl() && (DoneSettlingTime == BIG_NUMBER) && (SplineComp.IsNearEndOfSpline(100.0)))
			CrumbStopAttack();
	}

	UFUNCTION(CrumbFunction)
	void CrumbStopAttack()
	{
		DoneSettlingTime = ActiveDuration + Settings.Pounce2DAttackSettleDuration;
		USkylineGeckoEffectHandler::Trigger_OnPounceEnd(Owner);
	
		AnimComp.RequestFeature(FeatureTagGecko::MeleeAttack, SubTagGeckoMeleeAttack::MeleeAttackExit, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbHitTarget(AHazePlayerCharacter Victim)
	{
		AvailableTargets.RemoveSingleSwap(Victim);

#if TEST
		if(Victim.GetGodMode() == EGodMode::God)
			return;
#endif
		auto PlayerHealthComp = UPlayerHealthComponent::Get(Victim);
		if (PlayerHealthComp != nullptr)
			PlayerHealthComp.DamagePlayer(Settings.Pounce2DAttackDamagePlayer, nullptr, nullptr);

		FVector FwdDir = Owner.ActorForwardVector;
		FVector SideDir = Owner.ActorRightVector;
		if (!Owner.ActorVelocity.IsNearlyZero(1.0))
		{
			FwdDir = Owner.ActorVelocity.GetSafeNormal();
			if (Math::Abs(FwdDir.DotProduct(Victim.ActorUpVector)) < 0.99) 
				SideDir = FwdDir.CrossProduct(Victim.ActorUpVector);
		}
		if (SideDir.DotProduct(Victim.ActorLocation - Owner.ActorLocation) < 0.0)
			SideDir *= -1.0;	
		FVector PushDir = (FwdDir + SideDir) * Math::InvSqrt(2.0);

		FStumble Stumble;
		Stumble.Move = PushDir * Settings.PlayerKnockbackForce;
		Stumble.Duration = Settings.PlayerKnockbackDuration;
		Victim.ApplyStumble(Stumble);
	}

	private FVector GetTargetLocation() const
	{
		FVector OwnUpOffset = Owner.ActorUpVector * 60.0;
		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetUpOffset = Target.ActorUpVector * 60.0;
		FVector TargetLoc = TargetTrail.GetTrailLocation(Settings.Pounce2DAttackTrailAge).PointPlaneProject(Target.ActorLocation, Target.ActorUpVector);
		if (Settings.Pounce2DAttackPredictionDuration > 0.0)
		{
			float EstimatedHitTime = (TargetLoc - OwnLoc).Size() / Settings.Pounce2DAttackMoveSpeed;
			FVector EstimatedVelocity = (Target.ActorLocation - TargetTrail.GetTrailLocation(Settings.Pounce2DAttackPredictionDuration)) / Settings.Pounce2DAttackPredictionDuration;
			EstimatedVelocity = EstimatedVelocity.ConstrainToPlane(Target.ActorUpVector);
			TargetLoc += EstimatedVelocity * EstimatedHitTime;
		}

		FVector OctreeTargetLoc = TargetLoc + TargetUpOffset;
		Navigation::NavOctreeGetNearestLocationInTree(TargetLoc + TargetUpOffset, Radius, 0.0, OctreeTargetLoc);		
		if (Navigation::NavOctreeLineTrace(Owner.ActorCenterLocation, OctreeTargetLoc))
			return OwnLoc + Owner.ActorForwardVector * 100.0; // Can't get there!
		
		// We can reach target, check if we can go beyond
		FVector OvershootOffset = (OctreeTargetLoc - OwnLoc - OwnUpOffset).ConstrainToPlane(Target.ActorUpVector);
		FVector OvershootDir = OvershootOffset.GetSafeNormal();
		for (float Overshoot = Settings.Pounce2DAttackOvershootRange; Overshoot > 50.0; Overshoot -= 200.0)
		{
			FVector OvershootLoc = OctreeTargetLoc + OvershootDir * Overshoot;	
			if (!Navigation::NavOctreeLineTrace(OwnLoc + OwnUpOffset, OvershootLoc))
				return OvershootLoc - TargetUpOffset;
		}

		// Could not overshoot, settle for target location
		return TargetLoc;
	}
}