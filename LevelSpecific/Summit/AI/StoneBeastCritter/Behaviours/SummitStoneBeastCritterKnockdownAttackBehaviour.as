class USummitStoneBeastCritterKnockdownAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	AAISummitStoneBeastCritter Critter;
	USummitStoneBeastCritterSettings Settings;

	private float AttackTelegraphDuration = 3.0;
	private float AdjustedTelegraphDuration;
	private float AttackDuration = 1.25;
	private float AttackRecoveryDuration = 0.25;
	private float AttackCooldownDuration = 2.0;
	private bool bHit = false;
	private bool bWasInAttackRange = false;

	private FVector AttackLocation;
	private FVector AttackStartLocation;
	private FHazeAcceleratedVector AccAttack;

	private FHazeAcceleratedFloat HackPitchMesh;

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USummitStoneBeastCritterAttackManagerComponent CurrentManager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Critter = Cast<AAISummitStoneBeastCritter>(Owner);
		Settings = USummitStoneBeastCritterSettings::GetSettings(Owner);
		auto Respawn = UHazeActorRespawnableComponent::GetOrCreate(Critter);
		Respawn.OnRespawn.AddUFunction(this, n"OnReset");
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		TargetComp.OnChangeTarget.AddUFunction(this, n"OnChangeTarget");
		HealthComp.OnDie.AddUFunction(this, n"OnDie");
	}

	UFUNCTION()
	private void OnDie(AHazeActor ActorBeingKilled)
	{
		if (CurrentManager != nullptr)
			CurrentManager.RemoveFromManager(Owner);
		bWasInAttackRange = false;
	}

	UFUNCTION()
	private void OnChangeTarget(AHazeActor NewTarget, AHazeActor OldTarget)
	{
		if (CurrentManager != nullptr)
			CurrentManager.RemoveFromManager(Owner);

		if (TargetComp.IsValidTarget(NewTarget))
			CurrentManager = SummitStoneBeastCritter::GetManager(NewTarget);
		else
			CurrentManager = nullptr;
		bWasInAttackRange = false;
	}

	UFUNCTION()
	private void OnReset()
	{
		if (CurrentManager != nullptr)
			CurrentManager.RemoveFromManager(Owner);
		bWasInAttackRange = false;
	}

	
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive() && HealthComp.IsAlive() && WantsToAttack() && !IsBlocked())
			GentCostQueueComp.JoinQueue(this);
		else
			GentCostQueueComp.LeaveQueue(this);

		if (!TargetComp.HasValidTarget())
			return;
		
		if (CurrentManager == nullptr)
			return;

		// Update AttackManager on whether within range
		// not networked yet.
		if (bWasInAttackRange && !Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.AttackAbortRange))
		{
			CurrentManager.RemoveInAttackRange(Owner);
			bWasInAttackRange = false;
		}
		else if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.AttackRange))
		{
			CurrentManager.AddInAttackRange(Owner);
			bWasInAttackRange = true;
		}		
		
		if (!IsActive())
		{
			// Restore pitch after telegraphing
			UHazeOffsetComponent MeshOffsetComp = Cast<AHazeCharacter>(Owner).MeshOffsetComponent;
			FRotator MeshRot = MeshOffsetComp.RelativeRotation;
			float Pitch = HackPitchMesh.AccelerateTo(10.0, 0.6, DeltaTime); // Not the original pitch, but looks better for the time being.
			MeshOffsetComp.SetRelativeRotation(FRotator(Pitch, MeshRot.Yaw, MeshRot.Roll));
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
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.AttackRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!WantsToAttack())
			return false;
		if(!GentCostQueueComp.IsNext(this) && (Settings.AttackGentlemanCost != EGentlemanCost::None))
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.AttackGentlemanCost))
			return false;
		if (CurrentManager == nullptr)
			return false;
		if (CurrentManager.IsOtherPlayerBeingAttacked())
			return false;
		if (!CurrentManager.CanAttack(Owner))
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
		if (!CurrentManager.CanAttack(Owner) && ActiveDuration < AttackTelegraphDuration) // temp
			return true;
		if (!bHit && ActiveDuration > AttackTelegraphDuration + AttackDuration + AttackRecoveryDuration)
		  	return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		//GentCostComp.ClaimToken(this, Settings.AttackGentlemanCost);
		bHit = false;
		AttackLocation = TargetComp.Target.ActorCenterLocation;
		AttackStartLocation = Critter.ActorLocation;

		// Notify manager that attacker becomes active 
		if (!CurrentManager.HasActiveAttackers())
			CurrentManager.SaveStartedAttackTime();
		AdjustedTelegraphDuration = Math::Max( CurrentManager.GetStartedAttackTime() - Time::GameTimeSeconds, Settings.MinAdjustedKnockdownTelegraphDuration);
			
		CurrentManager.AddAttackerActive(Owner);

		USummitStoneBeastCritterEffectHandler::Trigger_OnStartTelegraphing(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(BasicSettings.AttackCooldown);
		//GentCostComp.ReleaseToken(this, Settings.AttackTokenCooldown);
		
		if (CurrentManager != nullptr)
		{
			CurrentManager.RemoveAttackerActive(Owner);
			CurrentManager.RemoveAttackerEngaged(Owner);
		}

		bWasInAttackRange = false;

		USummitStoneBeastCritterEffectHandler::Trigger_OnStopTelegraphing(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//Debug::DrawDebugSphere(Owner.ActorLocation, 50, 12, FLinearColor::Blue);

		// Telegraphing
		UHazeOffsetComponent MeshOffsetComp = Cast<AHazeCharacter>(Owner).MeshOffsetComponent;
		FRotator MeshRot = MeshOffsetComp.RelativeRotation;

		if(ActiveDuration < AdjustedTelegraphDuration)
		{
			// Pitch mesh upwards
			float Pitch = HackPitchMesh.AccelerateTo(60.0, 0.3, DeltaTime);
			MeshOffsetComp.SetRelativeRotation(FRotator(Pitch, MeshRot.Yaw, MeshRot.Roll));
			
			DestinationComp.RotateTowards(TargetComp.Target);

			// Update attack target location
			AttackLocation = TargetComp.Target.ActorCenterLocation;
			return;
		}
		else
		{
			// Restore pitch
			float Pitch = HackPitchMesh.AccelerateTo(0.0, 0.6, DeltaTime);
			MeshOffsetComp.SetRelativeRotation(FRotator(Pitch, MeshRot.Yaw, MeshRot.Roll));
		}

		// Jumping towards attack location
		AccAttack.Value = Critter.ActorLocation;
		AccAttack.AccelerateTo(AttackLocation, AttackDuration, DeltaTime);
		Critter.ActorLocation = AccAttack.Value;

		// Hit the target
		if(!bHit && Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, BasicSettings.AttackRange))
		{
			// Update attack location after hitting the target player
			AttackLocation = TargetComp.Target.ActorCenterLocation;
			
			AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);	
			if (PlayerTarget != nullptr)
			{
				PlayerTarget.DamagePlayerHealth(0.1); // TODO: damage over time?
				// If this is the first attacker, then apply knockdown.
				if (!CurrentManager.HasAttackHit()) // TODO: this will currently permit a single attacker to perform knockdown if telegraphing started before swarming critters got defeated.
					PlayerTarget.ApplyKnockdown(Owner.ActorForwardVector, 1000000.0);
			}

			// Tell the manager that we are engaged and attack is in progress
			CurrentManager.AddAttackerEngaged(Owner);

			bHit = true;
		}
	}
}

