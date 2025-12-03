class USummitKnightShieldBlockBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	default CapabilityTags.Add(SummitKnightTags::SummitKnightShield);
	default CapabilityTags.Add(SummitKnightTags::SummitKnightShieldBlocking);

	USummitMeltComponent MeltComp;
	UBasicAICharacterMovementComponent MovementComp;
	UBasicAIHealthComponent HealthComp;
	UBasicAIKnockdownComponent KnockdownComp;
	USummitKnightShieldComponent ShieldComp;
	USummitKnightCrystalFieldComponent CrystalFieldComp;

	AAISummitKnight SummitKnight;
	AHazePlayerCharacter Instigator;
	bool bHasHit;
	bool bBlockRoll;
	FVector HitLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SummitKnight = Cast<AAISummitKnight>(Owner);
		MeltComp = USummitMeltComponent::GetOrCreate(Owner);
		MovementComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::GetOrCreate(Owner);
		KnockdownComp = UBasicAIKnockdownComponent::GetOrCreate(Owner);
		ShieldComp = USummitKnightShieldComponent::GetOrCreate(Owner);
		CrystalFieldComp = USummitKnightCrystalFieldComponent::GetOrCreate(Owner);

		auto TailAttackResponseComp = UTeenDragonTailAttackResponseComponent::GetOrCreate(Owner);
		TailAttackResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if(MeltComp.bMelted)
			return;

		Instigator = Params.PlayerInstigator;
		HitLocation = Params.HitLocation;

		if(IsBlocked())
		{
			KnockdownComp.Knockdown(EBasicAIKnockdownType::Default, Params.RollDirection);
			CrystalFieldComp.Break();
		}
		else if(!IsActive())
			bBlockRoll = true;
	}

	bool WasRollAttacked() const
	{
		if(bBlockRoll)
			return true;
		if(MeltComp.bMelted)
			return false;

		auto Player = Game::Zoe;
		auto DragonComp = UTeenDragonRollComponent::Get(Player);
		if(!DragonComp.IsRolling())
			return false;
		if(Player.ActorForwardVector.DotProduct(Owner.ActorLocation - Player.ActorLocation) < 0)
			return false; // Dragon is moving away from Knight
		if(!Player.ActorLocation.IsWithinDist(Owner.ActorLocation, 500))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!WasRollAttacked())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > 0.5)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		//AnimComp.RequestFeature(FeatureTagSummitRubyKnight::Bash, EBasicBehaviourPriority::Medium, this);
		bHasHit = false;

		if(!bBlockRoll)
		{
			Instigator = Game::Zoe;
			HitLocation = (Game::Zoe.ActorCenterLocation + Owner.ActorCenterLocation) / 2;
		}
		bBlockRoll = false;

		Instigator = Game::Zoe;
		ShieldComp.OnRollBlock.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(Instigator.ActorLocation);
		
		auto DragonComp = UPlayerTeenDragonComponent::Get(Instigator);
		if(!bHasHit)
		{
			bHasHit = true;

			FVector Dir = (Owner.ActorLocation - Instigator.ActorLocation).GetSafeNormal2D();
			FTeenDragonStumble Stumble;
			Stumble.Duration = 0.73;
			Stumble.Move = Dir * -1000;
			Stumble.Apply(Instigator);
			Instigator.SetActorRotation((-Stumble.Move).ToOrientationQuat());

			FHazePointOfInterestFocusTargetInfo FocusTarget;
			FocusTarget.SetFocusToActor(Owner);

			FApplyPointOfInterestSettings PoiSettings;
			PoiSettings.Duration = 0.4;
			Instigator.ApplyPointOfInterest(this, FocusTarget, PoiSettings, 0.2);
		}
	}
}