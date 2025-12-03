
class UGravityBladeHitReactionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAIHealthComponent HealthComp;
	UEnforcerDamageComponent DamageComp;
	UTargetableOutlineComponent OutlineComp;
	UGravityBladeCombatTargetComponent BladeTarget;
	UGravityWhipTargetComponent WhipTarget;

	float LastDamageTime = 0.0;
	float HurtCompleteTime = 0.0;
	float BladeGrappledTime = -BIG_NUMBER;
	FHazeAcceleratedFloat ForceAcc;
	FVector PushDirection;
	bool bMove;
	float bRemoteBladeDamageTime;
	float bRemoteWhipHitDamageTime;
	float PreDeathTime;
	
	const float GrappleReactionInterval = 0.2;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		DamageComp = UEnforcerDamageComponent::GetOrCreate(Owner);
		OutlineComp = UTargetableOutlineComponent::Get(Owner);
		BladeTarget = UGravityBladeCombatTargetComponent::Get(Owner);
		WhipTarget = UGravityWhipTargetComponent::Get(Owner);

		BladeTarget.OnCombatGrappleActivation.AddUFunction(this, n"OnBladeGrapple");
		DamageComp.OnBladeDamage.AddUFunction(this, n"BladeDamage");
		DamageComp.OnWhipHitDamage.AddUFunction(this, n"WhipDamage");
		
		UHazeActorRespawnableComponent::Get(Owner).OnUnspawn.AddUFunction(this, n"Unspawn");
		HealthComp.OnRemotePreDeath.AddUFunction(this, n"RemotePreDeath");
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Clean up the remote 
		if(bRemoteBladeDamageTime > SMALL_NUMBER && Time::GetGameTimeSince(bRemoteBladeDamageTime) > 1)
		{
			AnimComp.ClearFeature(this);
			bRemoteBladeDamageTime = 0;
		}
		if(bRemoteWhipHitDamageTime > SMALL_NUMBER && Time::GetGameTimeSince(bRemoteWhipHitDamageTime) > 1)
		{
			AnimComp.ClearFeature(this);
			bRemoteWhipHitDamageTime = 0;
		}
		if(PreDeathTime > SMALL_NUMBER && Time::GetGameTimeSince(PreDeathTime) > 1)
		{
			AnimComp.ClearFeature(this);
			PreDeathTime = 0;
		}
	}

	UFUNCTION()
	private void Unspawn(AHazeActor RespawnableActor)
	{
		AnimComp.ClearFeature(this);
		bRemoteBladeDamageTime = 0;
		bRemoteWhipHitDamageTime = 0;
		PreDeathTime = 0;
	}

	UFUNCTION()
	private void RemotePreDeath()
	{
		if(HasControl())
			return;
		if(HealthComp.LastAttacker == Game::Mio && HealthComp.LastDamageType == EDamageType::MeleeSharp)
		{
			AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::GravityBladeHitReactionDeath, EBasicBehaviourPriority::Maximum, this);
			PreDeathTime = Time::GameTimeSeconds;
			bRemoteBladeDamageTime = 0;
			bRemoteWhipHitDamageTime = 0;
		}
	}

	UFUNCTION()
	private void OnBladeGrapple()
	{
		BladeGrappledTime = Time::GameTimeSeconds;
	}

	UFUNCTION()
	private void BladeDamage(float Damage, EDamageType DamageType, AHazeActor Instigator)
	{
		if(HasControl())
			return;
		if(HealthComp.IsDead())
			return;

		FName Tag = LocomotionFeatureAISkylineTags::GravityBladeHitReaction;
		AnimComp.RequestFeature(Tag, EBasicBehaviourPriority::Maximum, this, BasicSettings.HurtDuration);
		bRemoteBladeDamageTime = Time::GameTimeSeconds;
	}

	UFUNCTION()
	private void WhipDamage(float Damage, EDamageType DamageType, AHazeActor Instigator)
	{
		if(HasControl())
			return;
		if(HealthComp.IsDead())
			return;

		FName Tag = LocomotionFeatureAISkylineTags::GravityWhipHitReaction;
		AnimComp.RequestFeature(Tag, EBasicBehaviourPriority::Maximum, this, BasicSettings.HurtDuration);
		bRemoteWhipHitDamageTime = Time::GameTimeSeconds;
	}

	bool ShouldReactToGrappleHit() const
	{
		return Time::GetGameTimeSince(BladeGrappledTime) < GrappleReactionInterval;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)		
			return false;
		if (ShouldReactToGrappleHit())
			return true; 
		if (!HealthComp.ShouldReactToDamage(BasicSettings.HurtDamageTypes, Math::Min(0.5, BasicSettings.HurtDuration * 0.5)))
			return false;
		if (HealthComp.IsDead())
			return false;	
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!HealthComp.IsStunned())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();	
		HealthComp.SetStunned();
		OutlineComp.BlockOutline(this);
		BladeTarget.AddWidgetBlocker(this);
		UBasicAIMovementSettings::SetTurnDuration(Owner, 0.5, this, EHazeSettingsPriority::Override);
		OnNewDamage();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		HealthComp.ClearStunned();
		OutlineComp.UnblockOutline(this);
		BladeTarget.ClearWidgetBlocker(this);
		Owner.ClearSettingsByInstigator(this);
	}

	void OnNewDamage()
	{
		LastDamageTime = HealthComp.LastDamageTime;

		if (HealthComp.IsDead())
			return; // We are beyond pain

		// Request hurt of suitable type. No mh expected, so single request will do.
		FName Tag = LocomotionFeatureAISkylineTags::GravityBladeHitReaction;
		if (HealthComp.LastDamageType != EDamageType::MeleeSharp)
			Tag = LocomotionFeatureAISkylineTags::GravityWhipHitReaction;

		bool bGrappleHit = ShouldReactToGrappleHit();
		if (bGrappleHit && (bRemoteWhipHitDamageTime < SMALL_NUMBER || Time::GetGameTimeSince(bRemoteWhipHitDamageTime) > 1)) // Note that this is guaranteed to sync in network, but that should not be very noticeable
			AnimComp.RequestFeature(Tag, SubTagGravityBladeHitReaction::Grapple, EBasicBehaviourPriority::High, this);
		else if(bRemoteBladeDamageTime < SMALL_NUMBER || Time::GetGameTimeSince(bRemoteBladeDamageTime) > 1)
			AnimComp.RequestFeature(Tag, EBasicBehaviourPriority::High, this, BasicSettings.HurtDuration); // Normal damage

		HurtCompleteTime = Time::GameTimeSeconds + BasicSettings.HurtDuration;

		ForceAcc.SnapTo(20.0 / EmilTweak);

		bMove = !bGrappleHit;
		BladeGrappledTime = -BIG_NUMBER;
	}

	const float EmilTweak = 0.1;
	const bool bIsEmilTesting = false;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HealthComp.LastDamageTime > LastDamageTime)
			OnNewDamage();

		if (Time::GameTimeSeconds > HurtCompleteTime)
		{
			TargetComp.SetTarget(nullptr); // Select a new target
			HealthComp.ClearStunned();
			return;
		}

		
		DestinationComp.RotateTowards(FocusActor = HealthComp.LastAttacker);

		if(!bIsEmilTesting)
		{
			if(!bMove)
				return;
			bMove = CanMove(Owner.ActorLocation + DamageComp.PushDirection.GetSafeNormal2D() * 80);
			if(!bMove)
				return;
		}

		ForceAcc.AccelerateTo(0, BasicSettings.HurtDuration * EmilTweak, DeltaTime); // TODO: investigate frame rate dependency
		DestinationComp.AddCustomAcceleration(DamageComp.PushDirection.ConstrainToPlane(Owner.ActorUpVector) * ForceAcc.Value);
	}

	private bool CanMove(FVector PathDest)
	{
		FVector NavMeshDest;
		if(!Pathfinding::FindNavmeshLocation(PathDest, 0.0, 100.0, NavMeshDest))
			return false;
		if(!Pathfinding::StraightPathExists(Owner.ActorLocation, NavMeshDest))
			return false;
		return true;
	}
}