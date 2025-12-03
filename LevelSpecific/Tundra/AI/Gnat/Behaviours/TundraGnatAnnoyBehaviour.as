struct FTundraGnatAnnoyBehaviourParams
{
	AActor Host;
	AHazeActor AnnoyTarget;
}

class UTundraGnatAnnoyBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UBasicAICharacterMovementComponent MoveComp;
	UTundraGnatComponent GnatComp;
	UTundraGnatHostComponent HostComp;
	UTundraGnatSettings Settings;
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
		TargetAnnoyedComp = UTundraGnapeAnnoyedPlayerComponent::GetOrCreate(Game::Zoe); 
		Settings = UTundraGnatSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraGnatAnnoyBehaviourParams& OutParams) const
	{
		if (!Super::ShouldActivate())
			return false;
		if (GnatComp.TreeGuardianComp == nullptr)
			return false;
		if (Settings.bOnlyAnnoyTree && !GnatComp.TreeGuardianComp.bIsActive)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, GetAnnoyRange()))
			return false;
		if (GnatComp.Host == nullptr)
			return false;
		if (GnatComp.bGoBallistic)
			return false;
		if (GnatComp.bThrownByMonkey)
			return false;
		OutParams.Host = GnatComp.Host;
		OutParams.AnnoyTarget = TargetComp.Target;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.IsValidTarget(Target))
			return true;
		if (Settings.bOnlyAnnoyTree && !GnatComp.TreeGuardianComp.bIsActive)
			return true;
		if (GnatComp.bGoBallistic)
			return true;
		if (GnatComp.bThrownByMonkey)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraGnatAnnoyBehaviourParams Params)
	{
		Super::OnActivated();
		Target = Params.AnnoyTarget;
		GnatComp.Host = Params.Host;
		GnatComp.bLatchedOn = false;

		UTundraPlayerShapeshiftingComponent ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Target);
		if ((ShapeshiftComp != nullptr)	&& (ShapeshiftComp.ActiveShapeType != ETundraShapeshiftActiveShape::Big))
			AnimComp.RequestFeature(TundraGnatTags::GrabAttack, EBasicBehaviourPriority::Medium, this);
		else
			AnimComp.RequestFeature(TundraGnatTags::GrabAttack, EBasicBehaviourPriority::Medium, this);

		HostComp = UTundraGnatHostComponent::Get(GnatComp.Host);
		TargetMoveComp = UHazeMovementComponent::Get(Target);
		JumpDir = (Target.ActorLocation + Owner.ActorUpVector * 100.0 - Owner.ActorLocation).GetSafeNormal();

		UTundraGnatSettings::SetTurnDuration(Owner, 0.5, this);

		UTundraGnatEffectEventHandler::Trigger_OnTelegraphLatchOn(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (GnatComp.bLatchedOn)
			TargetAnnoyedComp.AnnoyingGnapes.RemoveSingleSwap(GnatComp);
		Owner.ClearSettingsByInstigator(this);
		GnatComp.bLatchedOn = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Target == nullptr)
			return;

		bool bInnerCircle = IsInnerCircle();
		if (GnatComp.bLatchedOn)
		{
			DestinationComp.RotateTowards(Target.ActorLocation);

			FVector Dest = GetAnnoyLocation(bInnerCircle);
			if (!Owner.ActorLocation.IsWithinDist2D(Dest, 40.0))
				DestinationComp.MoveTowardsIgnorePathfinding(Dest, 200.0);

			if (Settings.bAnnoyKillsHumansOtterFairy && Target.HasControl())
			{
				UTundraPlayerShapeshiftingComponent ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Target);
				if ((ShapeshiftComp != nullptr)	&& (ShapeshiftComp.ActiveShapeType != ETundraShapeshiftActiveShape::Big))
					Cast<AHazePlayerCharacter>(Target).DealTypedDamage(Owner, 1.0, EDamageEffectType::ObjectSmall, EDeathEffectType::ObjectSmall, false);
			}
			return;
		}

		// Pounce on target!
		FVector TargetLoc = Target.ActorLocation + Owner.ActorUpVector * 100.0;
		DestinationComp.MoveTowardsIgnorePathfinding(TargetLoc, Settings.AnnoyJumpSpeed);		

		// Latch onto target when near enough or passing by
		if (JumpDir.DotProduct(TargetLoc - Owner.ActorLocation) < GetLatchOnRange(bInnerCircle))
		{
			if (Target.HasControl())
				CrumbLatchOn();
			return;
		}
	}

	float GetAnnoyRange() const
	{
		if (TargetAnnoyedComp.AnnoyingGnapes.Num() > Settings.AnnoyInnerCircleNumber)
			return Settings.AnnoyRange + 150.0;
		return Settings.AnnoyRange;
	}

	float GetLatchOnRange(bool bInnerCircle)
	{
		if (bInnerCircle)
			return Settings.AnnoyLatchOnRange;
		return Settings.AnnoyLatchOnRange + 150.0;
	}

	bool IsInnerCircle()
	{
		if (TargetAnnoyedComp.AnnoyingGnapes.Num() < Settings.AnnoyInnerCircleNumber)
			return true;
		for (int i = 0; i < Settings.AnnoyInnerCircleNumber; i++)
		{
			if (TargetAnnoyedComp.AnnoyingGnapes[i] == GnatComp)
				return true;
		}
		return false;
	}

	FVector GetAnnoyLocation(bool bInnerCircle)
	{
		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = Target.ActorLocation;
		FVector TargetDir = (TargetLoc - OwnLoc).GetSafeNormal();
		float AnnoyRange = GetLatchOnRange(bInnerCircle);
		FVector AnnoyLoc = TargetLoc - TargetDir * AnnoyRange;	
		
		if (OwnLoc.IsWithinDist2D(TargetLoc, AnnoyRange * 0.75))
		{
			// Much too close, just push out from target.
			AnnoyLoc -= TargetDir * 100.0;
		}
		else
		{
			// Push away from others in our circle
			const float RepulseMaxDist = 200.0;
			FVector Repulse = FVector::ZeroVector;
			int Start = (bInnerCircle ? 0 : Settings.AnnoyInnerCircleNumber);
			int Max = TargetAnnoyedComp.AnnoyingGnapes.Num();
			if (bInnerCircle && (Max > Settings.AnnoyInnerCircleNumber))
				Max = Settings.AnnoyInnerCircleNumber;
			for (int i = Start; i < Max; i++)
			{
				if (TargetAnnoyedComp.AnnoyingGnapes[i] == GnatComp)
					continue; // Ourselves
				FVector OtherLoc = TargetAnnoyedComp.AnnoyingGnapes[i].Owner.ActorLocation;
				if (TargetDir.DotProduct(OtherLoc - TargetLoc) > 0.0)
					continue; // On the other side of target, ignore 
				if (!OtherLoc.IsWithinDist2D(AnnoyLoc, RepulseMaxDist))
					continue; // Too far away to consider
				FVector ToOther = (OtherLoc - AnnoyLoc);
				ToOther.Z = 0.0;
				float Dist = ToOther.Size2D();
				FVector Away = (Dist > 0.1) ? -ToOther / Dist : Owner.ActorRightVector;
				Repulse += Away * (RepulseMaxDist - Dist) * 2.5; 
			}
			if (!Repulse.IsNearlyZero(1.0))
			{
				TargetDir = (TargetLoc - (AnnoyLoc + Repulse)).GetSafeNormal();
				AnnoyLoc = TargetLoc - TargetDir * GetLatchOnRange(bInnerCircle);
			}
		}

		return AnnoyLoc;
	}

	UFUNCTION(CrumbFunction)
	void CrumbLatchOn()
	{
		if (!IsActive())
			return; // Can happen in network

		GnatComp.bLatchedOn = true;

		// Bog target down
		TargetAnnoyedComp.AnnoyingGnapes.AddUnique(GnatComp);

		UTundraGnatEffectEventHandler::Trigger_OnLatchOn(Owner);
	}
}
