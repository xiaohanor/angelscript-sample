
struct FSkylineBallBossGrabbedOffsetActivationParams
{
}

class USkylineBallBossGrabbedOffsetCapability: UHazeCapability
{
	default CapabilityTags.Add(SkylineBallBossTags::Rotation);
	default CapabilityTags.Add(SkylineBallBossTags::RotationOffset);

	// Ball boss movement must tick before UGravityBladeGrappleGravityAlignCapability
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90;

	// default NetworkMode = EHazeCapabilityNetworkMode::Crumb; // No crumb! is local, run on both sides, for maximum snappiness

	ASkylineBallBoss BallBoss;

	bool bHasScrew = true;
	FVector StartOffset;
	FVector LastDragDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallBoss = Cast<ASkylineBallBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossGrabbedOffsetActivationParams & Params) const
	{
		auto GrabbedScrew = GetGrabbedScrew();
		if (GrabbedScrew == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bHasScrew)
			return false;
		if (BallBoss.AcceleratedOffsetVector.Velocity.Size() > 10.0)
			return false;
		return true;
	}

	USceneComponent GetGrabbedScrew() const
	{
		if (BallBoss.NumRotationTargets() == 0)
			return nullptr;

		FBallBossAlignRotationData Target = BallBoss.GetCurrentRotationTarget();
		if (Target.PartComp == nullptr)
			return nullptr;

		auto ChargeLaser = Cast<ASkylineBallBossChargeLaser>(Target.PartComp.Owner);
		if (ChargeLaser == nullptr)
			return nullptr;

		return Target.PartComp;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossGrabbedOffsetActivationParams Params)
	{
		StartOffset = BallBoss.AcceleratedOffsetVector.Value;
		BallBoss.BlockCapabilities(SkylineBallBossTags::RotationOffsetIdle, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BallBoss.UnblockCapabilities(SkylineBallBossTags::RotationOffsetIdle, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bool bResist = ActiveDuration < 0.6;
		USceneComponent GrabbedScrew = GetGrabbedScrew();
		bool bCurrentHasScrew = GrabbedScrew != nullptr;

		if (bCurrentHasScrew)
			LastDragDirection = (GrabbedScrew.WorldLocation - BallBoss.FakeRootComp.WorldLocation).GetSafeNormal();
		
		if (!bCurrentHasScrew && bHasScrew)
			BallBoss.AcceleratedOffsetVector.SnapTo(BallBoss.AcceleratedOffsetVector.Value, LastDragDirection * 2500.0);

		bHasScrew = bCurrentHasScrew;
		float Stiffness = 20.0;
		float Dampening = 0.35;

		if (bHasScrew)
		{
			float Direction = bResist ? -1.0 : 1.0;
			BallBoss.AcceleratedOffsetVector.AccelerateTo(StartOffset + LastDragDirection * 100.0 * Direction, 0.1, DeltaTime);
		}
		else
			BallBoss.AcceleratedOffsetVector.SpringTo(StartOffset, Stiffness, Dampening, DeltaTime);

		FVector LocalSpace = BallBoss.ActorQuat.UnrotateVector(BallBoss.AcceleratedOffsetVector.Value);
		BallBoss.ImpactLocationOffsetComp.SetRelativeLocation(LocalSpace);

	}
}