struct FSkylineBallBossPositionActionBouncyTearOffData
{
	FVector EnterLocation;
}

class USkylineBallBossPositionActionBouncyTearOffCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(SkylineBallBossTags::BallBoss);
	default CapabilityTags.Add(SkylineBallBossTags::Position);

	// Ball boss movement must tick before UGravityBladeGrappleGravityAlignCapability
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 98;

	AHazeActor Zoe;
	UGravityWhipUserComponent WhipComponent;
	ASkylineBallBoss BallBoss;
	USkylineBallBossActionsComponent BossComp;
	FHazeAcceleratedVector AccLocation;

	FSkylineBallBossPositionActionBouncyTearOffData ActivatedParams;

	float NoGrabbyDuration = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Zoe = Game::Zoe;
		BossComp = USkylineBallBossActionsComponent::GetOrCreate(Owner);
		BallBoss = Cast<ASkylineBallBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (WhipComponent == nullptr)
			WhipComponent = UGravityWhipUserComponent::Get(Zoe);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossPositionActionBouncyTearOffData& Params) const
	{
		if (BallBoss.FreezeLocationRequesters.Num() > 0)
			return false;

		if (BallBoss.GetPhase() != ESkylineBallBossPhase::TopMioIn)
			return false;

		if (WhipComponent == nullptr)
			return false;

		if (!WhipComponent.IsGrabbingAny())
			return false;
		
		Params.EnterLocation = BallBoss.ActorLocation;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BallBoss.GetPhase() == ESkylineBallBossPhase::TopDeath)
			return true;

		if (ActiveDuration < 0.5)
			return false;

		if (WhipComponent.IsGrabbingAny())
			return false;

		if (!AccLocation.Value.Equals(ActivatedParams.EnterLocation, 1.0))
			return false;

		if (NoGrabbyDuration < 1.0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossPositionActionBouncyTearOffData Paramsy)
	{
		// BossComp.PositionActionQueue.Reset();
		// BossComp.ActionQueue.Reset();

		BallBoss.bIsInTearOffPositioning = true;
		ActivatedParams = Paramsy;
		Owner.BlockCapabilities(SkylineBallBossTags::PositionSelection, this);
		Owner.BlockCapabilities(SkylineBallBossTags::PositionDash, this);
		AccLocation.SnapTo(Paramsy.EnterLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// BossComp.PositionActionQueue.Reset();
		// BossComp.ActionQueue.Reset();
		BallBoss.bIsInTearOffPositioning = false;
		Owner.UnblockCapabilities(SkylineBallBossTags::PositionSelection, this);
		Owner.UnblockCapabilities(SkylineBallBossTags::PositionDash, this);
		BallBoss.SetActorLocation(ActivatedParams.EnterLocation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// position away from local zoe compared to enter location. Just to make it look nice and ensure ripped off charge lasers don't clip with platform
		const FVector FromZoeToEnter = ActivatedParams.EnterLocation - Zoe.ActorLocation;
		const float Offset = 1500;
		const FVector Backwards = FromZoeToEnter.GetSafeNormal() * Offset;
		const FVector TargetLocation = ActivatedParams.EnterLocation + Backwards;

		if (WhipComponent.IsGrabbingAny())
			AccLocation.AccelerateTo(TargetLocation, 2.0, DeltaTime);
		else if (NoGrabbyDuration < 0.3)
		{
			// wait
		}
		else
			AccLocation.SpringTo(ActivatedParams.EnterLocation, 20, 0.7, DeltaTime);

		BallBoss.SetActorLocation(AccLocation.Value);

		// const FVector CapsuleCenter = TargetLocation + Backwards * 0.5;
		// Debug::DrawDebugCapsule(CapsuleCenter, Offset * 0.5, 100, FRotator::MakeFromZX(Backwards.GetSafeNormal(), FVector::UpVector), ColorDebug::Lavender, 5.0, 0.0, true);
		// Debug::DrawDebugString(BallBoss.ActorLocation, "Is Grabbing " + WhipComponent.IsGrabbingAny());

		NoGrabbyDuration += DeltaTime;
		if (WhipComponent.IsGrabbingAny())
			NoGrabbyDuration = 0.0;
	}
}