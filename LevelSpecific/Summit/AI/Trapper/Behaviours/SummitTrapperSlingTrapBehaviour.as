class USummitTrapperSlingTrapBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	AAISummitTrapper SummitTrapper;

	UAcidTailBreakableComponent AcidTailBreakComp; 
	UGentlemanCostComponent GentCostComp;
	USummitTrapperTrapComponent TrapComp;

	float MaxSpeed = 2500.0;
	float SpeedMultiplier = 4.0;
	FHazeAcceleratedVector TrapAccelVelocity;
	bool bInitializedVelocity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SummitTrapper = Cast<AAISummitTrapper>(Owner);
		AcidTailBreakComp = UAcidTailBreakableComponent::Get(Owner);
		TrapComp = USummitTrapperTrapComponent::GetOrCreate(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSlingParams& Params) const
	{
		if (!Super::ShouldActivate())
			return false;

		if (!TargetComp.HasValidTarget())
			return false;

		if (AcidTailBreakComp.IsWeakened())
			return false;

		Params.TargetLocation = TargetComp.Target.ActorCenterLocation;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;

		if (AcidTailBreakComp.IsWeakened())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSlingParams Params)
	{
		Super::OnActivated();
		TrapComp.TrapTargetLocation = Params.TargetLocation;
		TrapComp.SpawnTrap();		
		GentCostComp.CancelPendingReleaseToken(TrapComp);
		bInitializedVelocity = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.PendingReleaseToken(TrapComp);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (TrapComp.Trap == nullptr)
			return;
		
		if(!bInitializedVelocity)
		{
			TrapAccelVelocity.SnapTo(GetSlingTargetVelocity());
			bInitializedVelocity = true;
		}
		
		TrapAccelVelocity.AccelerateTo(GetSlingTargetVelocity(), 0.5, DeltaTime);
		FVector DeltaVelocity = TrapAccelVelocity.Value * DeltaTime;
		TrapComp.Trap.ActorLocation += DeltaVelocity;

		if (TrapAccelVelocity.Value.Size() <= 400.0)
			DeactivateBehaviour();
		
		//Convert this for dragons
		for (AHazePlayerCharacter Player : Game::Players)
		{
			//UPlayerTeenDragonComponent PlayerDragonComp = UPlayerTeenDragonComponent::Get(Player);
			UCapsuleComponent PlayerCapsule = Player.CapsuleComponent;

			bool bIsIntersecting = Overlap::QueryShapeOverlap(
				FCollisionShape::MakeSphere(180.0), TrapComp.Trap.ActorTransform,
				FCollisionShape::MakeCapsule(PlayerCapsule.CapsuleRadius, PlayerCapsule.CapsuleHalfHeight), PlayerCapsule.WorldTransform, 0.0
			);

			if (bIsIntersecting)
			{
				TrapComp.TrapDragon(Player);
				DeactivateBehaviour();
			}
		}

		DestinationComp.RotateTowards(TrapComp.TrapTargetLocation);
	}	

	FVector GetSlingTargetVelocity()
	{
		float Distance = (TrapComp.TrapTargetLocation - TrapComp.Trap.ActorLocation).Size();
		float Speed = Distance * 4.0;
		Speed = Math::Clamp(Speed, 100.0, 5000);

		FVector DirToTarget = (TrapComp.TrapTargetLocation - TrapComp.Trap.ActorLocation).GetSafeNormal(); 
		FVector TargetVelocity = DirToTarget.GetSafeNormal() * Speed;
		return TargetVelocity;
	}
}