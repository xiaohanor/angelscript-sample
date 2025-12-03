struct FPrisonBossGrabPlayerEnterDeactivationParams
{
	bool bGrabbedPlayer = false;
}

class UPrisonBossGrabPlayerEnterCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	AHazePlayerCharacter TargetPlayer;

	bool bGrabbedPlayer = false;

	bool bDistancingFromPlayer = false;
	FVector DistancingLocation = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		TargetPlayer = Game::Mio;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Boss.CurrentAttackType != EPrisonBossAttackType::GrabPlayer)
			return false;

		if (TargetPlayer.IsPlayerDead())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPrisonBossGrabPlayerEnterDeactivationParams& Params) const
	{
		if (bGrabbedPlayer)
		{
			Params.bGrabbedPlayer = true;
			return true;
		}

		if (TargetPlayer.IsPlayerDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bGrabbedPlayer = false;
		bDistancingFromPlayer = false;

		Boss.AnimationData.bGrabbingPlayer = true;

		if (Boss.GetHorizontalDistanceTo(TargetPlayer) <= PrisonBoss::GrabPlayerMinStartDistance)
		{
			FVector DirToPlayer = (Game::Mio.ActorLocation - Boss.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			DistancingLocation = Game::Mio.ActorLocation -(DirToPlayer * PrisonBoss::GrabPlayerMinStartDistance);
			DistancingLocation.Z = Boss.ActorLocation.Z;
			bDistancingFromPlayer = true;
		}

		UPrisonBossEffectEventHandler::Trigger_GrabPlayerEnter(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPrisonBossGrabPlayerEnterDeactivationParams Params)
	{
		if (Params.bGrabbedPlayer)
		{
			Boss.OnGrabbedPlayer.Broadcast();
			UPrisonBossEffectEventHandler::Trigger_GrabPlayerCatch(Boss);
		}
		else
		{
			Boss.CurrentAttackType = EPrisonBossAttackType::None;
			UPrisonBossEffectEventHandler::Trigger_GrabPlayerNoCatch(Boss);
		}

		Boss.AnimationData.bGrabbingPlayer = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector DirToPlayer = (Game::Mio.ActorLocation - Boss.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		FRotator Rot = Math::RInterpTo(Boss.ActorRotation, DirToPlayer.Rotation(), DeltaTime, 6.0);
		Boss.SetActorRotation(Rot);

		if (bDistancingFromPlayer)
		{
			FVector Loc = Math::VInterpTo(Boss.ActorLocation, DistancingLocation, DeltaTime, 3.0);
			Boss.SetActorLocation(Loc);
		}

		if (ActiveDuration <= PrisonBoss::GrabPlayerEnterDuration)
			return;

		bDistancingFromPlayer = false;

		FVector TargetLoc = TargetPlayer.ActorLocation;
		FVector Loc = Math::VInterpConstantTo(Boss.ActorLocation, TargetLoc, DeltaTime, PrisonBoss::GrabPlayerFlySpeed);
		Boss.SetActorLocation(Loc);

		float HorizontalDist = Boss.GetHorizontalDistanceTo(TargetPlayer);

		if (HorizontalDist <= PrisonBoss::GrabPlayerDistance)
			bGrabbedPlayer = true;
	}
}