struct FSkylineBossTankTurretFocusAttackActivateParams
{
	AHazeActor AttackTarget;
};

class USkylineBossTankTurretFocusAttackCapability : USkylineBossTankChildCapability
{
	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankAttack);

	FVector CurrentTargetLocation;
	FVector Velocity;

	FHazeAcceleratedVector AcceleratedVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		BossTank.TargetDecal.SetHiddenInGame(true, true);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBossTankTurretFocusAttackActivateParams& Params) const
	{
		if (!BossTank.HasAttackTarget())
			return false;

		Params.AttackTarget = BossTank.GetAttackTarget();

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
	void OnActivated(FSkylineBossTankTurretFocusAttackActivateParams Params)
	{
		FVector TargetLocation = Params.AttackTarget.ActorLocation;
		TargetLocation = FVector(TargetLocation.X, TargetLocation.Y, BossTank.ActorLocation.Z);

		CurrentTargetLocation = TargetLocation;

		BossTank.TargetDecal.SetHiddenInGame(true, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossTank.TargetDecal.SetHiddenInGame(true, true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto Target = BossTank.GetAttackTarget();
		if(Target == nullptr)
			return;

		FVector TargetLocation = Target.ActorLocation; // + BossTank.GetAttackTarget().ActorForwardVector * 1000.0;
		TargetLocation = FVector(TargetLocation.X, TargetLocation.Y, BossTank.ActorLocation.Z);

		FVector ToTarget = TargetLocation - CurrentTargetLocation;

	// ToTarget.SafeNormal * 10000.0

		FVector Acceleration = ToTarget * 18.0
							 - Velocity * 2.0;

		Velocity += Acceleration * DeltaTime;
		CurrentTargetLocation += Velocity * DeltaTime;

		FVector TurretToTarget = (CurrentTargetLocation - BossTank.TurretComp.WorldLocation);

		Debug::DrawDebugLine(BossTank.TurretComp.WorldLocation, BossTank.TurretComp.WorldLocation + TurretToTarget, FLinearColor::Red, 10.0, 0.0);
		Debug::DrawDebugPoint(CurrentTargetLocation, 50.0, FLinearColor::Yellow, 0.0);

		BossTank.TargetDecal.WorldLocation = CurrentTargetLocation;
	}
}