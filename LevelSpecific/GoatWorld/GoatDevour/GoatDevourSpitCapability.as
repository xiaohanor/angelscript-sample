class UGoatDevourSpitCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 150;

	UGenericGoatPlayerComponent GoatComp;
	UGoatDevourPlayerComponent DevourComp;
	UPlayerAimingComponent AimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GoatComp = UGenericGoatPlayerComponent::Get(Player);
		DevourComp = UGoatDevourPlayerComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStopped(ActionNames::PrimaryLevelAbility))
			return false;

		if (DevourComp.CurrentDevourResponseComp == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= 0.4)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FGoatDevourSpitParams SpitParams;

		if (DevourComp.CurrentPlacementComp != nullptr)
		{
			FVector DirToPoint = (DevourComp.CurrentPlacementComp.WorldLocation - Player.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			float Dot = DirToPoint.DotProduct(Player.ActorForwardVector);
			if (Dot >= 0.8)
			{
				SpitParams.PlacementComp = DevourComp.CurrentPlacementComp;
			}
		}

		FVector AimTargetLoc = FVector::ZeroVector;
		AimComp.StartAiming(this, DevourComp.AimSettings);
		FAimingResult AimResult = AimComp.GetAimingTarget(this);
		if (AimResult.AutoAimTarget != nullptr)
		{
			AimTargetLoc = AimResult.AutoAimTargetPoint;
			UGoatDevourSpitImpactResponseComponent SpitResponseComp = UGoatDevourSpitImpactResponseComponent::Get(AimResult.AutoAimTarget.Owner);
			if (SpitResponseComp != nullptr)
				SpitParams.ResponseComp = SpitResponseComp;
		}

		SpitParams.TargetLocation = AimTargetLoc;
		
		DevourComp.CurrentDevourResponseComp.Owner.SetActorLocation(DevourComp.CurrentGoat.MouthComp.WorldLocation + (Player.ActorForwardVector * 100.0));

		SpitParams.Direction = Player.ActorForwardVector;
		DevourComp.CurrentDevourResponseComp.SpitOut(SpitParams);
		DevourComp.CurrentDevourResponseComp = nullptr;

		DevourComp.CurrentGoat.bMouthOpen = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DevourComp.CurrentGoat.bMouthOpen = false;

		AimComp.StopAiming(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}
}