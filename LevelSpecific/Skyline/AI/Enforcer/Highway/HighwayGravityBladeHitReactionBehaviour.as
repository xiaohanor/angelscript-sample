class UHighwayGravityBladeHitReactionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAIHealthComponent HealthComp;
	UEnforcerDamageComponent DamageComp;
	USkylineEnforcerBoundsComponent BoundsComp;
	UGravityWhipTargetComponent WhipTarget;
	UGravityBladeCombatTargetComponent BladeTarget;

	float Radius = 0;
	float LastDamageTime = 0.0;
	float HurtCompleteTime = 0.0;
	float BladeGrappledTime = -BIG_NUMBER;
	FHazeAcceleratedFloat ForceAcc;
	FVector PushDirection;
	bool bMove;

	const float GrappleReactionInterval = 0.2;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		DamageComp = UEnforcerDamageComponent::GetOrCreate(Owner);
		BoundsComp = USkylineEnforcerBoundsComponent::GetOrCreate(Owner);
		WhipTarget = UGravityWhipTargetComponent::Get(Owner);
		BladeTarget = UGravityBladeCombatTargetComponent::Get(Owner);

		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		if(Character != nullptr)
			Radius = Character.CapsuleComponent.CapsuleRadius;

		BladeTarget.OnCombatGrappleActivation.AddUFunction(this, n"OnBladeGrapple");
	}

	UFUNCTION()
	private void OnBladeGrapple()
	{
		BladeGrappledTime = Time::GameTimeSeconds;
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
		UBasicAIMovementSettings::SetTurnDuration(Owner, 0.5, this, EHazeSettingsPriority::Override);
		OnNewDamage();
		WhipTarget.Disable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		HealthComp.ClearStunned();
		Owner.ClearSettingsByInstigator(this);
		WhipTarget.Enable(this);
	}

	void OnNewDamage()
	{
		LastDamageTime = HealthComp.LastDamageTime;

		if (HealthComp.IsDead())
			return; // We are beyond pain
			
		// Request hurt of suitable type. No mh expected, so single request will do.
		FName Tag = LocomotionFeatureAISkylineTags::GravityBladeHitReaction;
		bool bGrappleHit = ShouldReactToGrappleHit();
		if (bGrappleHit) // Note that this is guaranteed to sync in network, but that should not be very noticeable
			AnimComp.RequestFeature(Tag, SubTagGravityBladeHitReaction::Grapple, EBasicBehaviourPriority::High, this);
		else 
			AnimComp.RequestFeature(Tag, EBasicBehaviourPriority::High, this, BasicSettings.HurtDuration); // Normal damage
		HurtCompleteTime = Time::GameTimeSeconds + BasicSettings.HurtDuration;
		ForceAcc.SnapTo(4);
		bMove = !bGrappleHit;
		BladeGrappledTime = -BIG_NUMBER;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HealthComp.LastDamageTime > LastDamageTime)
			OnNewDamage();

		if (Time::GameTimeSeconds > HurtCompleteTime)
		{
			AnimComp.Reset();
			TargetComp.SetTarget(nullptr); // Select a new target
			HealthComp.ClearStunned();
			return;
		}

		DestinationComp.RotateTowards(FocusActor = HealthComp.LastAttacker);

		if(!bMove)
			return;
		bMove = CanMove(Owner.ActorLocation + DamageComp.PushDirection.GetSafeNormal2D() * 80);
		if(!bMove)
			return;

		ForceAcc.AccelerateTo(0, BasicSettings.HurtDuration, DeltaTime); // TODO: investigate frame rate dependency
		DestinationComp.AddCustomAcceleration(DamageComp.PushDirection.ConstrainToPlane(Owner.ActorUpVector) * ForceAcc.Value);
	}

	private bool CanMove(FVector PathDest)
	{
		if(!BoundsComp.LocationIsWithinBounds(PathDest + Owner.ActorUpVector * Radius, Radius))
			return false;
		return true;
	}
}