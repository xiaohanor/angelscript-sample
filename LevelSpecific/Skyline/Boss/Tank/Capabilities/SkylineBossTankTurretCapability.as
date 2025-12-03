class USkylineBossTankTurretCapability : USkylineBossTankChildCapability
{
	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankAttack);

	FHazeAcceleratedFloat TurnSpeed;
	FHazeAcceleratedQuat AccQuat;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!BossTank.HasAttackTarget())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!BossTank.HasAttackTarget())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossTank.TurretComp.RelativeRotation = FRotator::ZeroRotator;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto Target = BossTank.GetAttackTarget();
		if(Target == nullptr)
			return;

		FVector ToTargetDirection = (Target.ActorLocation - BossTank.TurretComp.WorldLocation).SafeNormal;

		FVector NewDirection = BossTank.TurretComp.ComponentQuat.ForwardVector.RotateTowards(ToTargetDirection.SafeNormal, BossTank.TurretComp.MaxTurnSpeedDeg * 8.0 * DeltaTime);

//		Debug::DrawDebugLine(BossTank.TurretComp.WorldLocation, BossTank.TurretComp.WorldLocation + NewDirection * 100000.0, FLinearColor::Green, 20.0, 0.0);

		FQuat Rotation = FQuat::Slerp(BossTank.TurretComp.ComponentQuat, NewDirection.ToOrientationQuat(), 5.0 * DeltaTime);
		BossTank.TurretComp.ComponentQuat = BossTank.TurretComp.ClampAndSetRotation(Rotation);
	}
}