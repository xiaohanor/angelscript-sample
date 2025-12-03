class USummitSmasherKnockbackBehaviour : UBasicBehaviour
{
	USummitMeltComponent MeltingComp;
	UBasicAIHealthComponent HealthComp;
	UBasicAICharacterMovementComponent MoveComp;
	bool bHit;
	bool bStopped;
	FVector HitDirection;
	FVector HitLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MeltingComp = USummitMeltComponent::GetOrCreate(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		auto TailAttack = UTeenDragonTailAttackResponseComponent::GetOrCreate(Owner);
		TailAttack.OnHitByRoll.AddUFunction(this, n"OnRollAttack");
	}

	UFUNCTION()
	private void OnRollAttack(FRollParams Params)
	{
		if(MeltingComp.bMelted)
			return;
		bHit = true;
		HitDirection = Params.RollDirection.ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal();
		HitLocation = Params.HitLocation;

		//auto DragonComp = UPlayerTailTeenDragonComponent::Get(Params.PlayerInstigator);
		FTeenDragonStumble Stumble;
		Stumble.Duration = 1;
		Stumble.Move = Params.RollDirection * -1500;
		Stumble.Apply(Params.PlayerInstigator);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!bHit)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > 0.25)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bHit = false;
		bStopped = false;
		UMovementGravitySettings::SetGravityScale(Owner, 10, this);
		USmasherEventHandler::Trigger_OnRollAttackKnockback(Owner, FSmasherEventOnRollAttackKnockbackParams(HitLocation));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bStopped)
			return;

		bStopped = !CanMove(Owner.ActorLocation + HitDirection * 200);

		if(DoAddAcceleration())
			DestinationComp.AddCustomAcceleration(HitDirection * 12000);
	}

	private bool DoAddAcceleration()
	{
		if(bStopped)
			return false;
		return true;
	}

	private bool CanMove(FVector PathDest)
	{
		if(MoveComp.HasWallContact())
			return false;
		FVector NavMeshDest;
		if(!Pathfinding::FindNavmeshLocation(PathDest, 0.0, 200.0, NavMeshDest))
			return false;
		if(!Pathfinding::StraightPathExists(Owner.ActorLocation, NavMeshDest))
			return false;
		return true;
	}
}