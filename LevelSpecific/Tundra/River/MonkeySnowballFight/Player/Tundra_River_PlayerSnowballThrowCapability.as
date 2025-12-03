class UTundra_River_PlayerSnowballThrowCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	UTundra_River_PlayerSnowballComponent SnowballComp;
	UPlayerAimingComponent AimComp;

	float DeactivateTimer;
	float ThrowSnowballTimer;
	bool bThrowSnowballRequested;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SnowballComp = UTundra_River_PlayerSnowballComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SnowballComp.Snowball == nullptr)
			return false;

		if(!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(SnowballComp.Snowball == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SnowballComp.bIsThrowing = true;
		Player.SetAnimTrigger(n"ThrowSnowball");
		bThrowSnowballRequested = true;
		ThrowSnowballTimer = 0.15;
		Player.PlayForceFeedback(ForceFeedback::Default_Light, this, 0.1);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		if (bThrowSnowballRequested)
		{
			ThrowSnowballTimer -= DeltaTime;

			if (ThrowSnowballTimer <= 0)
			{
				if(AimComp.IsAiming(SnowballComp))
					CrumbThrowSnowball(AimComp.GetAimingTarget(SnowballComp));
				else
					SnowballComp.bIsThrowing = false;
					
				bThrowSnowballRequested = false;
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbThrowSnowball(FAimingResult AimResult)
	{	
		auto TargetComp = Cast<UTundra_River_SnowballAutoAimTargetComponent>(AimResult.AutoAimTarget);
		
		if(TargetComp != nullptr)
			SnowballComp.Snowball.CalculateTrajectory(TargetComp.WorldLocation);
		else
			InitializeNoAutoAim();

		SnowballComp.Throw();
	}

	void InitializeNoAutoAim()
	{
		FAimingRay Ray = UPlayerAimingComponent::Get(Player).GetPlayerAimingRay();

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic);
		TraceSettings.UseLine();
		TraceSettings.IgnoreActor(Player);

		const FVector Start = Player.ViewLocation;
		const FVector End = Start + Ray.Direction * 3000;
		FHitResult ForwardHit = TraceSettings.QueryTraceSingle(Start, End);


		if(ForwardHit.bBlockingHit)
		{
			SnowballComp.Snowball.CalculateTrajectory(ForwardHit.Location);
		}
		else
		{
			SnowballComp.Snowball.CalculateTrajectory(Start + Ray.Direction * 2000);
		}
	}
};