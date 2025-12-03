class USummitKnightSweepBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	
	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USummitCameraShakeComponent CameraShakeComp; 
	USummitMeltComponent MeltComp; 
	USummitKnightSwordComponent WeaponComp;
	UFitnessUserComponent FitnessComp;
	USummitKnightShieldComponent ShieldComp;

	AAISummitKnight SummitKnight;
	USummitKnightDeprecatedSettings KnightSettings;
	TArray<AHazeActor> HitTargets;
	FBasicAIAnimationActionDurations Durations;
	FHazeAcceleratedFloat SpeedAcc;
	FRotator StartRotation;
	FVector PreviousSweepLocation;

	bool bSetupSecondSweep;
	bool bIsFit;
	float UnfitTimer;
	float UnfitDuration = 1;
	bool bImmediate;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SummitKnight = Cast<AAISummitKnight>(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		CameraShakeComp = USummitCameraShakeComponent::GetOrCreate(Owner);
		MeltComp = USummitMeltComponent::GetOrCreate(Owner);
		WeaponComp = USummitKnightSwordComponent::GetOrCreate(Owner);
		FitnessComp = UFitnessUserComponent::GetOrCreate(Owner);		
		KnightSettings = USummitKnightDeprecatedSettings::GetSettings(Owner);

		ShieldComp = USummitKnightShieldComponent::GetOrCreate(Owner);
		ShieldComp.OnRollBlock.AddUFunction(this, n"OnRollBlock");
		ShieldComp.OnAcidDodgeCompleted.AddUFunction(this, n"OnAcidDodgeCompleted");

		Durations.Telegraph = KnightSettings.SweepTelegraphDuration;
		Durations.Anticipation = KnightSettings.SweepAnticipationDuration;
		Durations.Action = KnightSettings.SweepAttackDuration;
		Durations.Recovery = KnightSettings.SweepRecoveryDuration;
	}

	UFUNCTION()
	private void OnAcidDodgeCompleted()
	{
		bImmediate = true;
		Cooldown.Reset();
	}

	UFUNCTION()
	private void OnRollBlock()
	{
		Cooldown.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive() && HealthComp.IsAlive() && WantsToAttack() && IsInRange() && !IsBlocked())
		{
			GentCostQueueComp.JoinQueue(this);
			SetFitness(DeltaTime);
		}
		else
		{
			if(UnfitTimer > 0)
				UnfitTimer -= DeltaTime;
			GentCostQueueComp.LeaveQueue(this);
		}
	}

	private void SetFitness(float DeltaTime)
	{
		// Just return false if we don't even have a valid target
		if(!TargetComp.HasValidTarget())
			return;
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if(Player == nullptr)
			return;
		
		bIsFit = FitnessComp.IsFitnessOptimalAtLocation(Player, Owner.ActorCenterLocation);
		if(!bIsFit)
		{
			UnfitTimer += DeltaTime;
			if(UnfitTimer > UnfitDuration)
				bIsFit = true;
			else 
				bIsFit = false;
		}
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (MeltComp.bMelted)
			return false;
		if(WeaponComp.bShattered)
			return false;

		return true;
	}

	bool IsInRange() const
	{
		if (TargetComp.GetDistanceToTarget() > KnightSettings.SweepMaxRange)
			return false;
		if (TargetComp.GetDistanceToTarget() < KnightSettings.SweepMinRange)
			return false;
		return true;
	}

	bool ImmediateAttack() const
	{
		if(!bImmediate)
			return false;
		if(!WantsToAttack())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(ImmediateAttack())
			return true;
		if(!WantsToAttack())
			return false;
		if(!IsInRange())
			return false;
		if(!bIsFit)
			return false;
		if(!GentCostQueueComp.IsNext(this))
			return false;
		if(!GentCostComp.IsTokenAvailable(KnightSettings.SweepGentlemanCost))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (MeltComp.bMelted)
			return true;
		if (WeaponComp.bShattered)
			return true;
		if (ActiveDuration > Durations.GetTotal())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, KnightSettings.SweepGentlemanCost);
		SpeedAcc.Value = 0;
		HitTargets.Empty();
		PreviousSweepLocation = FVector::ZeroVector;
		StartRotation = Owner.ActorRotation;
		bSetupSecondSweep = false;
		//AnimComp.RequestAction(FeatureTagSummitRubyKnight::Attacks, SubTagSummitRubyKnightAttack::SwordAttackSlashes, EBasicBehaviourPriority::Medium, this, Durations);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this, KnightSettings.SweepTokenCooldown);
		Cooldown.Set(KnightSettings.SweepCooldown);
		bImmediate = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Durations.IsInTelegraphRange(ActiveDuration))
		{
			DestinationComp.RotateTowards(TargetComp.Target.ActorLocation);
			StartRotation = Owner.ActorRotation;
		}
		
		if(Durations.IsInActionRange(ActiveDuration))
		{			
			if(!bSetupSecondSweep && Durations.GetActionRangeAlpha(ActiveDuration) > 0.5)
			{
				bSetupSecondSweep = true;
				HitTargets.Empty();
				PreviousSweepLocation = FVector::ZeroVector;
			}

			FVector TargetLoc = Owner.ActorLocation + StartRotation.ForwardVector * 100;
			float Speed = KnightSettings.SweepMoveSpeed;
			if(bImmediate)
				Speed *= 2;
			DestinationComp.MoveTowards(TargetLoc, Speed);

			UpdateHitTargets();
		}
	}
	
	void UpdateHitTargets()
	{
		for(AHazePlayerCharacter Player: Game::Players)
		{
			if (HitTargets.Contains(Player))
				continue;

			if (HasHitTarget(Player))
			{
				HitTargets.Add(Player);
				CrumbHitTarget(Player);
			}
		}
	}

	bool HasHitTarget(AHazePlayerCharacter Target)
	{
		if (!Target.HasControl())
			return false;

		auto DragonComp = UPlayerTeenDragonComponent::Get(Target);
		if(DragonComp == nullptr)
			return false;

		UHazeCapsuleCollisionComponent Collision = Target.CapsuleComponent;

		FVector Delta;
		if(!PreviousSweepLocation.IsZero())
			Delta = PreviousSweepLocation - WeaponComp.GetTransform().Location;
		PreviousSweepLocation = WeaponComp.GetTransform().Location;
		
		bool bHit = Overlap::QueryShapeSweep(WeaponComp.GetCollisionShape(), WeaponComp.GetTransform(), Delta, Collision.GetCollisionShape(), Collision.WorldTransform);
		return bHit;
	}

	UFUNCTION(CrumbFunction)
	void CrumbHitTarget(AHazePlayerCharacter Target)
	{
		auto DragonComp = UPlayerTeenDragonComponent::Get(Target);

		FTeenDragonStumble Stumble;
		Stumble.Duration = 1;
		Stumble.Move = Owner.ActorRightVector * 1000;
		Stumble.Apply(Target);
		Target.SetActorRotation((-Stumble.Move).ToOrientationQuat());

		auto PlayerHealthComp = UPlayerHealthComponent::Get(Target);
		if(PlayerHealthComp != nullptr)
			PlayerHealthComp.DamagePlayer(0.4, nullptr, nullptr);
		
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Target);
		if(Player != nullptr)
			Player.PlayCameraShake(CameraShakeComp.CameraShake, this);
	}

}