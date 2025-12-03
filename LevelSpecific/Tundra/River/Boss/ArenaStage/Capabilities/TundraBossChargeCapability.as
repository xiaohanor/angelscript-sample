class UTundraBossChargeCapability : UTundraBossChildCapability
{
	float Duration = 10;

	bool bShouldTickInitiateChargeTimer = false;
	float InitiateChargeTimer = 0;
	float InitiateChargeTimerDuration = 0;
	float InitiateChargeTimerAddition = 2.0;

	bool bIsInLastPhase = false;
	bool bCapabilityIsFinished = false;

	bool bShouldTickDeactivationTimer = false;
	float DeactivationTimer = 0;
	float DeactivationTimerDuration = 10;

	ETundraBossLocation StartLocation;
	ETundraBossLocation TargetLocation;

	ATundraBossBossPlatform PlatformToShow;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		Duration = 5.166667 + InitiateChargeTimerAddition;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraBossChargeParams& Params) const
	{
		if(Boss.State != ETundraBossStates::ChargeAttack)
			return false;

		Params.StartLocation = Boss.CurrentBossLocation;
		Params.TargetLocation = SetTargetLocation();
		Params.bIsInLastPhase = Boss.IsInLastPhase();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bCapabilityIsFinished)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraBossChargeParams Params)
	{
		Boss.RequestAnimation(ETundraBossAttackAnim::ChargeAttack, true);
		Boss.Mesh.SetAnimBoolParam(n"EnteringCharge", true);

		StartLocation = Params.StartLocation;
		InitiateChargeTimer = 0;
		InitiateChargeTimerDuration = Boss.FallingIceBlocksManager.StartDroppingIceBlocks();
		InitiateChargeTimerDuration += InitiateChargeTimerAddition;
		bShouldTickInitiateChargeTimer = true;
		TargetLocation = Params.TargetLocation;
		bIsInLastPhase = Params.bIsInLastPhase;

		Duration = 5.166667 + InitiateChargeTimerDuration + 0.5;

		if(StartLocation == ETundraBossLocation::Front)
			TargetLocation = ETundraBossLocation::Left;
		else if(StartLocation == ETundraBossLocation::Left)
			TargetLocation = ETundraBossLocation::Right;
		else
			TargetLocation = ETundraBossLocation::Front;

		SetNewChargeRootLocAndRot();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.Mesh.SetAnimBoolParam(n"ExitIceKingAnimation", true);
		Boss.CurrentBossLocation = TargetLocation;
		Boss.CapabilityStopped(ETundraBossStates::ChargeAttack);
		bCapabilityIsFinished = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bShouldTickInitiateChargeTimer)
		{
			InitiateChargeTimer += DeltaTime;
			if(InitiateChargeTimer >= InitiateChargeTimerDuration)
			{
				bShouldTickInitiateChargeTimer = false;
				Charge();
			}
		}

		if(bShouldTickDeactivationTimer)
		{
			DeactivationTimer += DeltaTime;
			if(DeactivationTimer >= DeactivationTimerDuration)
			{
				bCapabilityIsFinished = true;
				bShouldTickDeactivationTimer = false;
			}
		}
	}

	void Charge()
	{
		Boss.ChargeKillCollisionActor.ShowChargeDecal();
		Boss.Mesh.SetAnimBoolParam(n"StartActualCharge", true);

		DeactivationTimer = 0;
		DeactivationTimerDuration = Boss.AnimInstance.GetTundraBossAnimationDuration(ETundraBossAttackAnim::ChargeAttack);
		bShouldTickDeactivationTimer = true;
		
		switch(TargetLocation)
		{
			case ETundraBossLocation::Front:
				PlatformToShow = Boss.Phase02FrontPlatform;
				break;

			case ETundraBossLocation::Left:
				PlatformToShow = Boss.Phase02LeftPlatform;
				break;

			case ETundraBossLocation::Right:
				PlatformToShow = Boss.Phase02RightPlatform;
				break;
		}
		
		Timer::SetTimer(this, n"ActivateNextBossPlatform", 2);
	}

	UFUNCTION()
	void ActivateNextBossPlatform()
	{
		Boss.ActivateNextBossPlatform(PlatformToShow, bIsInLastPhase);
	}

	void SetNewChargeRootLocAndRot()
	{
		FVector ChargeRootLoc;
		FRotator ChargeRootRot;
		AHazeTargetPoint TargetPoint;

		switch(StartLocation)
		{
			case ETundraBossLocation::Front:
				TargetPoint = Boss.FrontTargetPoint;
				break;
			
			case ETundraBossLocation::Left:
				TargetPoint = Boss.LeftTargetPoint;
				break;

			case ETundraBossLocation::Right:
				TargetPoint = Boss.RightTargetPoint;
				break;
		}

		ChargeRootLoc = TargetPoint.ActorLocation;
		ChargeRootLoc.Z = Boss.ChargeRoot.ActorLocation.Z;
		ChargeRootRot = TargetPoint.ActorRotation;

		Boss.ChargeRoot.SetActorLocationAndRotation(ChargeRootLoc, ChargeRootRot);
	}

	ETundraBossLocation SetTargetLocation() const
	{
		if(Boss.CurrentBossLocation == ETundraBossLocation::Front)
			return ETundraBossLocation::Left;
		else if(Boss.CurrentBossLocation == ETundraBossLocation::Left)
			return ETundraBossLocation::Right;
		else
			return ETundraBossLocation::Front;
	}
};

struct FTundraBossChargeParams
{
	ETundraBossLocation StartLocation;
	ETundraBossLocation TargetLocation;
	bool bIsInLastPhase;
}