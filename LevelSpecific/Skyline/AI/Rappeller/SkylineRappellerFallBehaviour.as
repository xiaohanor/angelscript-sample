class USkylineRappellerFallBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	USkylineRappellerRopeCollisionComponent RopeCollision;
	UBasicAIHealthComponent HealthComp;
	UHazeMovementComponent MoveComp;
	float StartHeight;
	const float DeathDistance = 4000.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		RopeCollision = USkylineRappellerRopeCollisionComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)		
			return false;
		if (!RopeCollision.bIsCut)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (HealthComp.IsDead())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		HealthComp.SetStunned();
		StartHeight = Owner.ActorLocation.Z;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		HealthComp.ClearStunned();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Fall to your doom!
		AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::GravityWhippable, SubTagAIGravityWhippable::Grabbed, EBasicBehaviourPriority::High, this);
		if (IsDoomed())
			HealthComp.TakeDamage(HealthComp.MaxHealth, EDamageType::Impact, Game::Mio);
	}

	bool IsDoomed()
	{
		if ((StartHeight - Owner.ActorLocation.Z) > DeathDistance)
			return true;
		if (MoveComp.HasGroundContact())
			return true;
		if ((ActiveDuration > 0.5) && Math::IsNearlyZero(Owner.ActorVelocity.Z, 10.0))
			return true; // Ground impacts are not properly registering?
		return false;
	}
}