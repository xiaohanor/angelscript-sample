class UTundraGroundGnatAnnoyBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UBasicAICharacterMovementComponent MoveComp;
	UTundraGnatComponent GnatComp;
	UTundraGnatSettings Settings;
	bool bLatchedOn = false;
	AHazeActor Target;
	UHazeMovementComponent TargetMoveComp;	
	UTundraGnapeAnnoyedPlayerComponent TargetAnnoyedComp;	
	FVector JumpDir;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		GnatComp = UTundraGnatComponent::Get(Owner);
		Settings = UTundraGnatSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (Settings.bDontAnnoyMonkey)
		{
			UTundraPlayerSnowMonkeyComponent MonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(TargetComp.Target);
			if (MonkeyComp != nullptr)
			{
				UTundraPlayerShapeshiftingComponent ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(TargetComp.Target);
				if ((ShapeshiftComp != nullptr)	&& ShapeshiftComp.ActiveShapeType == ETundraShapeshiftActiveShape::Big)
					return false; // Monkey!
			}
		}
		if (!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.AnnoyRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.IsValidTarget(Target))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		Target = TargetComp.Target;
		UTundraPlayerShapeshiftingComponent ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Target);
		if ((ShapeshiftComp != nullptr)	&& (ShapeshiftComp.ActiveShapeType != ETundraShapeshiftActiveShape::Big))
			AnimComp.RequestFeature(TundraGnatTags::Attack, EBasicBehaviourPriority::Medium, this);
		else
			AnimComp.RequestFeature(TundraGnatTags::GrabAttack, EBasicBehaviourPriority::Medium, this);
		bLatchedOn = false;
		TargetMoveComp = UHazeMovementComponent::Get(Target);
		TargetAnnoyedComp = UTundraGnapeAnnoyedPlayerComponent::GetOrCreate(Target); 
		JumpDir = (Target.ActorLocation + Owner.ActorUpVector * 100.0 - Owner.ActorLocation).GetSafeNormal();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (bLatchedOn)
		{
			Owner.UnblockCapabilities(CapabilityTags::Movement, this);
			Owner.DetachRootComponentFromParent();
			TargetAnnoyedComp.AnnoyingGnapes.RemoveSingleSwap(GnatComp);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bLatchedOn)
		{
			if (Settings.bAnnoyKillsHumansOtterFairy && Target.HasControl())
			{
				UTundraPlayerShapeshiftingComponent ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Target);
				if ((ShapeshiftComp != nullptr)	&& (ShapeshiftComp.ActiveShapeType != ETundraShapeshiftActiveShape::Big))
					Cast<AHazePlayerCharacter>(Target).DamagePlayerHealth(1.0);
			}
			return;
		}

		FVector TargetLoc = Target.ActorLocation + Owner.ActorUpVector * 100.0;

		// Pounce on target!
		DestinationComp.MoveTowardsIgnorePathfinding(TargetLoc, Settings.AnnoyJumpSpeed);		

		// Latch onto target when near enough or passing by
		if (JumpDir.DotProduct(TargetLoc - Owner.ActorLocation) < Settings.AnnoyLatchOnRange)
		{
			if (Target.HasControl())
				CrumbLatchOn();	
			return;
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbLatchOn()
	{
		if (!IsActive())
			return; // Can happen in network

		bLatchedOn = true;
		Owner.BlockCapabilities(CapabilityTags::Movement, this);
		Owner.AttachToActor(Target, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);

		// Bog target down
		TargetAnnoyedComp.AnnoyingGnapes.AddUnique(GnatComp);
	}
}
