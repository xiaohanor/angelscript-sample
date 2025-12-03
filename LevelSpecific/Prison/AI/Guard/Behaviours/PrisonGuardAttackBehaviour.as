
class UPrisonGuardAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 

	AAIPrisonGuard PrisonGuard;
	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	UPrisonGuardAnimationComponent GuardAnimComp;
	USceneComponent RightZapper;
	USceneComponent LeftZapper;
	float AttackDuration = 2.0;
	float PreAttackSettleDuration = 2.0;
	UPrisonGuardSettings Settings;
	bool bAttackStarted = false;
	float AttackTime;
	float AttackEndTime;
	AHazeActor Target;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		PrisonGuard = Cast<AAIPrisonGuard>(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		GuardAnimComp = UPrisonGuardAnimationComponent::Get(Owner);
		RightZapper = USceneComponent::Get(Owner, n"RightZapper");	
		LeftZapper = USceneComponent::Get(Owner, n"LeftZapper");	
		Settings = UPrisonGuardSettings::GetSettings(Owner);
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
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.AttackRange))
			return false;
		FVector AimDir = GetAimDirection();
		FVector FrontLoc = Owner.ActorCenterLocation + AimDir * Settings.AttackHitRadiusStart;
		FVector EndLoc = Owner.ActorCenterLocation + AimDir * (Settings.AttackRange - Settings.AttackHitRadiusEnd);
		if (!TargetComp.Target.ActorCenterLocation.IsInsideTeardrop(FrontLoc, EndLoc, Settings.AttackHitRadiusStart, Settings.AttackHitRadiusEnd))
			return false;	
		return true;
	}

	FVector GetAimDirection() const
	{
		return Owner.ActorForwardVector.RotateAngleAxis(GuardAnimComp.AccSpineYaw.Value, FVector::UpVector);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!WantsToAttack())
			return false;
		if(!GentCostQueueComp.IsNext(this) && (Settings.AttackGentlemanCost != EGentlemanCost::None))
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.AttackGentlemanCost))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Target = TargetComp.Target;
		GentCostComp.ClaimToken(this, Settings.AttackGentlemanCost);
		
		// We're testing not using regular anim comp for these things. Probably not a useful pattern.
		GuardAnimComp.Request = EPrisonGuardAnimationRequest::Attack;
		UAnimSequence AttackAnim = GuardAnimComp.GetAnimation(EPrisonGuardAnimationRequest::Attack);
		AttackDuration = AttackAnim.PlayLength; 
		PreAttackSettleDuration = 2.0; // Safety margin, calculated properly when attack animation has been started
		bAttackStarted = false;
		AttackTime = AttackAnim.GetAnimNotifyStateStartTime(UBasicAIActionAnimNotify);
		AttackEndTime = AttackAnim.GetAnimNotifyStateEndTime(UBasicAIActionAnimNotify);

		// Action playrate test, remove when we have tweaked anim
		FBasicAIAnimationActionDurations Durations;
		Durations.Telegraph = 1.6;
		Durations.Anticipation = 0.1;
		Durations.Action = 0.066;
		Durations.Recovery = 0.5;
		AnimComp.RequestAction(n"PrisonGuardAttack", EBasicBehaviourPriority::Medium, this, Durations);
		AttackDuration = Durations.GetTotal();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float AttackInProgressTime = GuardAnimComp.GetRequestedAnimCurrentPosition(EPrisonGuardAnimationRequest::Attack);
		if (!bAttackStarted && (AttackDuration > 0.0))
		{
			bAttackStarted = true;
			PreAttackSettleDuration = ActiveDuration - AttackInProgressTime; 
		}

		if ((AttackInProgressTime > AttackTime))
		{
			FVector AimDir = GetAimDirection();
			FVector AttackStartLoc = (RightZapper.WorldLocation + LeftZapper.WorldLocation) * 0.5 - AimDir * 100.0;; 
			FVector AttackEndLoc = AttackStartLoc + AimDir * (Settings.AttackRange + Settings.AttackHitExtraRange);
			FVector TargetLoc = Target.ActorLocation;
			TargetLoc.Z = AttackStartLoc.Z;
			if (TargetComp.IsValidTarget(Target) && TargetLoc.IsInsideTeardrop(AttackStartLoc, AttackEndLoc, Settings.AttackHitRadiusStart, Settings.AttackHitRadiusEnd))
				HitTarget();
			else 
				MissTarget();
			AttackTime = BIG_NUMBER; // Only hit once per attack

#if EDITOR
			if (Owner.bHazeEditorOnlyDebugBool)
			{
				FLinearColor Color = FLinearColor::Yellow;
				if (TargetComp.IsValidTarget(Target) && Target.ActorCenterLocation.IsInsideTeardrop(AttackStartLoc, AttackEndLoc, Settings.AttackHitRadiusStart, Settings.AttackHitRadiusEnd))
					Color = FLinearColor::Red;
				ShapeDebug::DrawTeardrop(AttackStartLoc, AttackEndLoc, Settings.AttackHitRadiusStart, Settings.AttackHitRadiusEnd, Color, 5.0, 2.0);			
			}
#endif			
		}

		if (AttackInProgressTime > AttackEndTime)
		{
			AttackEndTime = BIG_NUMBER;
			GuardAnimComp.Request = EPrisonGuardAnimationRequest::Stop;
			UPrisonGuardEffectHandler::Trigger_OnAttackStop(Owner, FPrisonGuardAttackParams(Target, 0.0));
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > PreAttackSettleDuration + AttackDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GuardAnimComp.Request = EPrisonGuardAnimationRequest::Stop;
		Cooldown.Set(Settings.AttackCooldown);
		GentCostComp.ReleaseToken(this, Settings.AttackTokenCooldown);
		UPrisonGuardEffectHandler::Trigger_OnAttackStop(Owner, FPrisonGuardAttackParams(Target, 0.0));
	}

	void HitTarget()
	{
		// No need to crumb this; player damage is already crumbed as is knockdown
		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(Target);
		FVector DamageDir = (PlayerTarget.ActorLocation - Owner.ActorLocation).GetSafeNormal();
		PlayerTarget.DamagePlayerHealth(Settings.AttackDamage, FPlayerDeathDamageParams(DamageDir), PrisonGuard.PlayerDamageEffect, PrisonGuard.PlayerDeathEffect);

		if (Settings.AttackKnockbackDuration > 0.0)
		{
			FKnockdown Knockdown;
			Knockdown.Move = (PlayerTarget.ActorCenterLocation - Owner.ActorCenterLocation).GetNormalized2DWithFallback(-PlayerTarget.ActorForwardVector) * Settings.AttackKnockbackDistance; 
			Knockdown.Duration = Settings.AttackKnockbackDuration;
			PlayerTarget.ApplyKnockdown(Knockdown);
		}

		// Effect is triggered locally, so we might get a hit effect for something that actually misses on remote side, but they are similar enough
		// Using crumb might make effect trigger at bad time, so that's less noticeable. 
		UPrisonGuardEffectHandler::Trigger_OnAttackStart(Owner, FPrisonGuardAttackParams(Target, AttackEndTime - AttackTime));
	}

	void MissTarget()
	{
		// Effect is triggered locally, so we might get a miss effect for something that actually hits on remote side, but they are similar enough
		// Using crumb might make effect trigger at bad time, so that's less noticeable. 
		UPrisonGuardEffectHandler::Trigger_OnAttackStart(Owner, FPrisonGuardAttackParams(nullptr, AttackEndTime - AttackTime));
	}
}

