enum ESkylineGeckoConstrainAttackState
{
	Anticipating,
	Attacking,
	Constraining,
	Recovering,
	None
}

class USkylineGeckoConstrainAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	USkylineGeckoSettings Settings;
	USkylineGeckoComponent GeckoComp;
	UHazeMovementComponent MoveComp;
	UBasicAIHealthComponent HealthComp;
	UGravityWhipTargetComponent WhipTarget;
	UHazeAnimSlopeAlignComponent AnimSlopeAlignComp;
	UAnimInstanceAIBase	AnimInstance;

	AHazeCharacter Character;
	AHazePlayerCharacter Target;
	USkylineGeckoConstrainedPlayerComponent TargetConstrainComp;
	FBasicAIAnimationActionDurations Durations;

	ESkylineGeckoConstrainAttackState AttackState = ESkylineGeckoConstrainAttackState::None;
	float InViewDuration = 0;
	float ConstrainSpeed = 3000;
	FHazeAcceleratedFloat AccConstrainSpeed;
	float PrevDodgeTime;
	float RecoverTime;	
	float AttackStateTimer;
	const float AttackStateDuration = 3;
	float ConstrainTimer;

	FVector AttackStart;
	float AttackDistance;

	bool bIsWhipBlocked = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Character = Cast<AHazeCharacter>(Owner);
		GeckoComp = USkylineGeckoComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		WhipTarget = UGravityWhipTargetComponent::Get(Owner);
		AnimSlopeAlignComp = UHazeAnimSlopeAlignComponent::GetOrCreate(Owner);
		Settings = USkylineGeckoSettings::GetSettings(Owner);

		HealthComp.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
		AnimInstance = Cast<UAnimInstanceAIBase>(Cast<AHazeCharacter>(Owner).Mesh.AnimInstance);

		GeckoComp.Initialize(); 
	}

	UFUNCTION()
	private void OnTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType)
	{
		// Reduce cooldown when hit by gravity blade for immediate retribution
		if (!IsActive() && Cooldown.IsSet() && (DamageType == EDamageType::MeleeSharp))
			Cooldown.Set(0.0);	// Note that we don't reset, we don't want to affect current tick.
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!Cooldown.IsOver())
		{
			if (GeckoComp.bOverturned)
				Cooldown.Set(1.0);
			else if (PrevDodgeTime < GeckoComp.LastDodgeStartTime)
				Cooldown.Set(0.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;

		// Only constrain targets on our control side or we may get capabilities blocked after breaking constrainment
		if (TargetComp.Target.HasControl() != Owner.HasControl())
			return false;	

		USkylineGeckoConstrainedPlayerComponent ConstrainComp = USkylineGeckoConstrainedPlayerComponent::Get(TargetComp.Target);	
		if (ConstrainComp == nullptr)
			return false;
		if (ConstrainComp.IsConstrained())
			return false;

		if (TargetComp.Target.IsAnyCapabilityActive(GravityWhipTags::GravityWhipSling))
			return false;

		ConstrainComp.InitialConstrainCooldown();
		if (!TargetComp.GentlemanComponent.CanClaimToken(GeckoComp.PounceToken, this))
			return false;
		if (!TargetComp.GentlemanComponent.CanClaimToken(GeckoComp.ConstrainToken, this))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if (RecoverTime > SMALL_NUMBER && Time::GetGameTimeSince(RecoverTime) > Durations.Recovery)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		GeckoComp.HealthComp.SetInvulnerable();

		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		TargetConstrainComp = USkylineGeckoConstrainedPlayerComponent::Get(Target);	
		TargetComp.GentlemanComponent.ClaimToken(GeckoComp.PounceToken, this);
		TargetComp.GentlemanComponent.ClaimToken(GeckoComp.ConstrainToken, this);

		Durations.Telegraph = Settings.ConstrainTelegraphDuration;
		Durations.Anticipation = Settings.ConstrainAnticipationDuration;
		Durations.Action = Settings.ConstrainAttackDuration;
		Durations.Recovery = Settings.ConstrainRecoverDuration;

		GeckoComp.StartTelegraph();

		AnimInstance.FinalizeDurations(FeatureTagGecko::ConstrainPlayer, NAME_None, Durations);		
		AnimComp.RequestAction(FeatureTagGecko::ConstrainPlayer, EBasicBehaviourPriority::Medium, this, Durations);

		USkylineGeckoEffectHandler::Trigger_OnConstrainPlayerTelegraph(Owner, FSkylineGeckoEffectHandlerOnPounceData(Target));
		PrevDodgeTime = GeckoComp.LastDodgeStartTime;

		AccConstrainSpeed.SnapTo(0);

		GeckoComp.bAllowBladeHits.Apply(false, this);

		RecoverTime = 0;

		AttackState = ESkylineGeckoConstrainAttackState::Anticipating;

		WhipTarget.Disable(this);
		HealthComp.SetInvulnerable();

		AnimSlopeAlignComp.bIgnoreSlope.Apply(true, this);
		GeckoComp.bShouldConstrainAttackLeap.Apply(true, this);
	
		GeckoComp.Team.LastAttackTime = Time::GameTimeSeconds;

		if (!bIsWhipBlocked)
		{
			UGravityWhipUserComponent WhipUserComp = UGravityWhipUserComponent::Get(Target);
			if (WhipUserComp != nullptr)
			{
				Target.BlockCapabilities(GravityWhipTags::GravityWhipSling, this);
				Target.BlockCapabilities(GravityWhipTags::GravityWhipGrabAnimation, this);
				Target.BlockCapabilities(GravityWhipTags::GravityWhip, this);
				bIsWhipBlocked = true;
			}
		}

		AttackStateTimer = 0;
		ConstrainTimer = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		
		UGentlemanComponent::Get(Target).ReleaseToken(GeckoComp.PounceToken, this);

		Cooldown.Set(Settings.ConstrainAttackCooldownDuration);
		if (!IsAttackState(ESkylineGeckoConstrainAttackState::Recovering))
			USkylineGeckoEffectHandler::Trigger_OnConstrainPlayerEnd(Owner);
		Owner.ClearSettingsByInstigator(this);
		
		GeckoComp.bAllowBladeHits.Clear(this);

		GeckoComp.FocusOffset = 0;
		GeckoConstrainingPlayer::StopConstraining(GeckoComp);
		GeckoComp.StopTelegraph();
		Character.MeshOffsetComponent.RelativeLocation = FVector::ZeroVector;

		WhipTarget.Enable(this);
		HealthComp.RemoveInvulnerable();

		if(GeckoComp.bThrownOff)
			HealthComp.TakeDamage(1, EDamageType::Default, Cast<AHazeActor>(TargetConstrainComp.Owner));

		AnimSlopeAlignComp.bIgnoreSlope.Clear(this);
		GeckoComp.bShouldConstrainAttackLeap.Clear(this);

		if (bIsWhipBlocked)
		{
			UGravityWhipUserComponent WhipUserComp = UGravityWhipUserComponent::Get(Target);
			if (WhipUserComp != nullptr)
			{
				Target.UnblockCapabilities(GravityWhipTags::GravityWhipSling, this);
				Target.UnblockCapabilities(GravityWhipTags::GravityWhipGrabAnimation, this);
				Target.UnblockCapabilities(GravityWhipTags::GravityWhip, this);
			}
		}
		bIsWhipBlocked = false;

		if(GeckoComp.bIsConstrainingTarget)
		{
			float CooldownMultiplier = 1 + TargetConstrainComp.ConstrainNum * 0.5;
			TargetConstrainComp.ConstrainNum++;
			UGentlemanComponent::Get(Target).ReleaseToken(GeckoComp.ConstrainToken, this, Math::RandRange(10, 15) * CooldownMultiplier);
		}
		GeckoComp.bIsConstrainingTarget = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Cooldown.IsSet())
			return;

		if (IsAttackState(ESkylineGeckoConstrainAttackState::Recovering))
			return;

		if (IsAttackState(ESkylineGeckoConstrainAttackState::Constraining))
			DestinationComp.RotateTowards(TargetConstrainComp.Owner.ActorLocation - TargetConstrainComp.Owner.ActorForwardVector * 100);
		else
			DestinationComp.RotateTowards(Target.ActorLocation);

		if(Target.IsPlayerDead())
		{
			Recover();
			return;
		}

		if (IsAttackState(ESkylineGeckoConstrainAttackState::Attacking))
		{
			
			FVector Destination = Target.ActorLocation;
			if (Owner.ActorLocation.Dist2D(Destination) < 50)
			{
				// Takedown part, after jump knocks down player
				ConstrainTarget();
				float Speed = Math::GetMappedRangeValueClamped(FVector2D(10, 150), FVector2D(250, AccConstrainSpeed.Value), Owner.ActorLocation.Dist2D(Destination));
				DestinationComp.MoveTowardsIgnorePathfinding(Destination, Speed);
				if (!UPlayerMovementComponent::Get(Target).IsInAir())
					EnterConstrainingState();
			}
			else
			{
				// Speedy part of jump
				float Speed = 3000;
				DestinationComp.MoveTowardsIgnorePathfinding(Destination, Speed);
			}

			AttackStateTimer += DeltaTime;
			if(AttackStateTimer > AttackStateDuration)
				DeactivateBehaviour();
		}
		else if(Owner.ActorLocation.Dist2D(Target.ActorLocation) > 500)
		{
			float Distance = Owner.ActorLocation.Dist2D(Target.ActorLocation);
			DestinationComp.MoveTowards(Target.ActorLocation, Distance);
		}

		else if (IsAttackState(ESkylineGeckoConstrainAttackState::Constraining))
		{
			ConstrainTimer += DeltaTime;
			StartConstraining();

			if ((Target.IsPlayerDead() || !TargetConstrainComp.ConstrainingGeckos.Contains(GeckoComp)))
				Recover();
			if(GeckoComp.bThrownOff)
				ThrowOff();
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetConstrainComp.Owner);
			FVector AlignLocation = Player.Mesh.GetSocketLocation(n"Align");

			// Go from slow to very fast quickly, since align location moves during this stage and we want to reach it and stay there
			float Speed = Math::GetMappedRangeValueClamped(FVector2D(0.0, 0.5), FVector2D(0.0, 500.0), ConstrainTimer);

			// If we for any reason end up far from player we should zip over there quickly
			if (!Owner.ActorLocation.IsWithinDist(AlignLocation, 250.0))
				Speed = Owner.ActorLocation.Distance(AlignLocation) * 4.0; 

			DestinationComp.MoveTowardsIgnorePathfinding(AlignLocation, Speed);
		}

		if (IsAttackState(ESkylineGeckoConstrainAttackState::Anticipating))
		{
			if (Durations.IsInTelegraphRange(ActiveDuration))
			{
				GeckoComp.UpdateTelegraph(FLinearColor::Red, 45);
				
				// Target is constrained by another gecko
				if(TargetConstrainComp.IsConstrained())
					DeactivateBehaviour();
				
				// Target is whipping
				UGravityWhipUserComponent WhipUserComp = UGravityWhipUserComponent::Get(Target);
				if (WhipUserComp != nullptr && WhipUserComp.HasActiveGrab())
					DeactivateBehaviour();
			}
			else if (Durations.IsInAnticipationRange(ActiveDuration))
			{
				GeckoComp.StopTelegraph();
				GeckoComp.SetEmissiveColor(FLinearColor::Red);
				AttackState = ESkylineGeckoConstrainAttackState::Attacking;
				USkylineGeckoEffectHandler::Trigger_OnConstrainPlayerStart(Owner, FSkylineGeckoEffectHandlerOnPounceData(Target));
				AttackDistance = Owner.ActorLocation.Distance(Target.ActorLocation);
				AttackStart = Owner.ActorLocation;
				GeckoComp.FocusOffset = -1000;
			}
		}
	}

	void Recover()
	{
		AttackState = ESkylineGeckoConstrainAttackState::Recovering;
		USkylineGeckoEffectHandler::Trigger_OnConstrainPlayerEnd(Owner);
		AnimComp.RequestSubFeature(SubTagGeckoConstrainPlayer::AfterKill, this);
		RecoverTime = Time::GameTimeSeconds;
	}

	void ThrowOff()
	{
		AttackState = ESkylineGeckoConstrainAttackState::Recovering;
		USkylineGeckoEffectHandler::Trigger_OnConstrainPlayerEnd(Owner);
		AnimComp.RequestSubFeature(SubTagGeckoConstrainPlayer::ThrownOff, this);
		RecoverTime = Time::GameTimeSeconds;
	}

	// Target's constrained capability and take down animation will activate.
	void ConstrainTarget()
	{
		GeckoComp.FocusOffset = -1000;
		TargetConstrainComp.Constrain(GeckoComp);
	}

	// Call when attack jump is finished
	void EnterConstrainingState()
	{
		AttackState = ESkylineGeckoConstrainAttackState::Constraining;
	}
	
	void StartConstraining()
	{
		// Only need to run on first tick of constraining attack state
		if (GeckoComp.bIsConstrainingTarget)
			return;
		AnimComp.RequestSubFeature(SubTagGeckoConstrainPlayer::Constrain, this);
		Character.MeshOffsetComponent.RelativeLocation = FVector::ZeroVector;
		HealthComp.RemoveInvulnerable();
		WhipTarget.Enable(this);
		GeckoComp.bShouldConstrainAttackLeap.Clear(this);
		GeckoComp.bIsConstrainingTarget = true;
	}

	bool IsAttackState(ESkylineGeckoConstrainAttackState State)
	{
		return AttackState == State;
	}
}
