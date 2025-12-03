class USummitKnightChargeBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	
	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USummitCameraShakeComponent CameraShakeComp; 
	USummitMeltComponent MeltComp; 
	USummitKnightSpearComponent WeaponComp;
	USummitKnightShieldComponent ShieldComp;
	UFitnessUserComponent FitnessComp;

	USummitKnightDeprecatedSettings KnightSettings;
	FVector ChargeToLoc;
	FVector ChargeToDir;
	TArray<AHazeActor> HitTargets;
	FBasicAIAnimationActionDurations Durations;

	FHazeAcceleratedFloat SpeedAcc;
	bool bIsFit;
	float UnfitTimer;
	float UnfitDuration = 1;
	bool bImmediate;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		CameraShakeComp = USummitCameraShakeComponent::GetOrCreate(Owner);
		MeltComp = USummitMeltComponent::GetOrCreate(Owner);
		WeaponComp = USummitKnightSpearComponent::GetOrCreate(Owner);		
		FitnessComp = UFitnessUserComponent::GetOrCreate(Owner);		
		KnightSettings = USummitKnightDeprecatedSettings::GetSettings(Owner);

		ShieldComp = USummitKnightShieldComponent::GetOrCreate(Owner);
		ShieldComp.OnRollBlock.AddUFunction(this, n"OnRollBlock");
		ShieldComp.OnAcidDodgeCompleted.AddUFunction(this, n"OnAcidDodgeCompleted");

		Durations.Telegraph = KnightSettings.ChargeTelegraphDuration;
		Durations.Anticipation = KnightSettings.ChargeAnticipationDuration;
		Durations.Action = KnightSettings.ChargeAttackDuration;
		Durations.Recovery = KnightSettings.ChargeRecoveryDuration;
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
		if (WeaponComp.bShattered)
			return false;
		return true;
	}

	bool IsInRange() const
	{
		if (TargetComp.GetDistanceToTarget() > KnightSettings.ChargeMaxRange)
			return false;
		if (TargetComp.GetDistanceToTarget() < KnightSettings.ChargeMinRange)
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
		if(!GentCostComp.IsTokenAvailable(KnightSettings.ChargeGentlemanCost))
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
		GentCostComp.ClaimToken(this, KnightSettings.ChargeGentlemanCost);

		if(!GetMeshDestination(TargetComp.Target.ActorLocation, ChargeToLoc))
			DeactivateBehaviour();

		bImmediate = false;
		ChargeToDir = (ChargeToLoc - Owner.ActorLocation).ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal();
		SpeedAcc.Value = 0;
		HitTargets.Empty();

		Durations.Action = ChargeToLoc.Distance(Owner.ActorLocation) / 3000;

		//AnimComp.RequestAction(FeatureTagSummitRubyKnight::Attacks, SubTagSummitRubyKnightAttack::SpearAttack, EBasicBehaviourPriority::Medium, this, Durations);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this, KnightSettings.ChargeTokenCooldown);
		Cooldown.Set(KnightSettings.ChargeCooldown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(ChargeToLoc + ChargeToDir * 100);

		if (Durations.IsInTelegraphRange(ActiveDuration))
			return;
		
		if(Durations.IsInActionRange(ActiveDuration))
		{			
			SpeedAcc.AccelerateTo(KnightSettings.ChargeMoveSpeed, 0.2, DeltaTime);
			DestinationComp.MoveTowards(ChargeToLoc, SpeedAcc.Value);

			for(AHazePlayerCharacter Player: Game::Players)
			{
				CrumbHitTarget(Player);
			}			
		}
	}	

	UFUNCTION(CrumbFunction)
	bool CrumbHitTarget(AHazePlayerCharacter Target)
	{		
		if(HitTargets.Contains(Target))
			return false;

		auto DragonComp = UPlayerTeenDragonComponent::Get(Target);
		if(DragonComp == nullptr)
			return false;
		
		UHazeCapsuleCollisionComponent Collision = Target.CapsuleComponent;
		if(!Overlap::QueryShapeOverlap(WeaponComp.GetCollisionShape(), WeaponComp.GetTransform(), Collision.GetCollisionShape(), Collision.WorldTransform))
			return false;

		HitTargets.Add(Target);

		// UPlayerTailTeenDragonComponent TailDragon = UPlayerTailTeenDragonComponent::Get(Target);
		// if(TailDragon != nullptr && TailDragon.IsRolling() && TailDragon.TeenDragon.ActorForwardVector.DotProduct(Owner.ActorForwardVector) < 0)
		// {
		// 	WeaponComp.Shatter();
		// 	DeactivateBehaviour();
		// }
		// else
		// {
			FTeenDragonStumble Stumble;
			Stumble.Duration = 1;
			Stumble.Move = Owner.ActorForwardVector * 2000;
			Stumble.Apply(Target);
			Target.SetActorRotation((-Stumble.Move).ToOrientationQuat());

			auto PlayerHealthComp = UPlayerHealthComponent::Get(Target);
			if(PlayerHealthComp != nullptr)
				PlayerHealthComp.DamagePlayer(0.4, nullptr, nullptr);
			// return true;
		// }		

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Target);
		if(Player != nullptr)
			Player.PlayCameraShake(CameraShakeComp.CameraShake, this);

		return false;
	}

	private bool GetMeshDestination(FVector PathDest, FVector& MeshDest)
	{
		if(!Pathfinding::FindNavmeshLocation(PathDest, 0.0, 500.0, MeshDest))
			return false;
		if(!Pathfinding::StraightPathExists(Owner.ActorLocation, MeshDest))
			return false;
		return true;
	}
}