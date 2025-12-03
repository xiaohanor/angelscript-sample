struct FSkylineBallBossRotateDontLookAtZoeActivationParams
{
	FRotator TargetRot;
}

class USkylineBallBossRotateDontLookAtZoeCapability : USkylineBallBossChildCapability
{
	default CapabilityTags.Add(SkylineBallBossTags::Rotation);
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	AHazeActor Zoe;
	UGravityWhipUserComponent WhipComponent;

	FRotator RotTarget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Zoe = Game::Zoe;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (WhipComponent == nullptr)
			WhipComponent = UGravityWhipUserComponent::Get(Zoe);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossRotateDontLookAtZoeActivationParams& Params) const
	{
		if (BallBoss.GetPhase() >= ESkylineBallBossPhase::TopMioIn)
			return false;

		if (WhipComponent == nullptr)
			return false;

		if (!WhipComponent.IsGrabbingAny() && !WhipComponent.bIsSlingThrowing)
			return false;

		if (SkylineBallBossDevToggles::DontLookAway.IsEnabled())
			return false;

		if (BallBoss.HealthComp.GetHealthFraction() > 1.0 - KINDA_SMALL_NUMBER)
			return false;

		Params.TargetRot = PickDirection();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BallBoss.GetPhase() == ESkylineBallBossPhase::TopMioIn)
			return true;

		if (!WhipComponent.IsGrabbingAny() && !WhipComponent.bIsSlingThrowing)
			return true;

		if (ActiveDuration > Settings.ZoeThrowDetonatorSwitchRotationTargetCooldown)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossRotateDontLookAtZoeActivationParams Params)
	{
		RotTarget = Params.TargetRot;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BallBoss.ResetTarget();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (SkylineBallBossDevToggles::DrawRotationTarget.IsEnabled())
			Debug::DrawDebugCoordinateSystem(BallBoss.ActorLocation, RotTarget, 2000.0);

		BallBoss.AcceleratedTargetRotation.AccelerateTo(RotTarget.Quaternion(), 2.0, DeltaTime);
		BallBoss.SetActorRotation(BallBoss.AcceleratedTargetRotation.Value);
	}

	private FRotator PickDirection() const
	{
		FVector ToZoeDir = (Zoe.ActorLocation - BallBoss.ActorLocation).GetSafeNormal();
		float RandomAngle = Math::RandRange(0.0, 360.0);
		FVector RandomOutwardDirection = Math::RotatorFromAxisAndAngle(ToZoeDir, RandomAngle).ForwardVector;
		float RandomOffsetAngle = Math::RandBool() ? -Settings.ZoeThrowDetonatorSwitchRotationLookAwayAngle : Settings.ZoeThrowDetonatorSwitchRotationLookAwayAngle;
		FVector RandomOffet = Math::RotatorFromAxisAndAngle(RandomOutwardDirection, RandomOffsetAngle).RightVector;
		return FRotator::MakeFromXZ(RandomOffet.GetSafeNormal(), BallBoss.ActorUpVector);
	}
}