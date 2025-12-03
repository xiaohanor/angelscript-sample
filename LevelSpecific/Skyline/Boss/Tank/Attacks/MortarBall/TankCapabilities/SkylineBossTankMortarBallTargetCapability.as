class USkylineBossTankMortarBallTargetCapability : USkylineBossTankChildCapability
{
	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankAttack);

	TArray<USkylineBossTankMortarBallComponent> MortarBallComponents;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		BossTank.GetComponentsByClass(MortarBallComponents);
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
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto Target = BossTank.GetAttackTarget();
		if(Target == nullptr)
			return;

		auto OtherTarget = BossTank.GetOtherBike(Target);
		if(OtherTarget == nullptr)
			return;

		for (auto MortarBallComponent : MortarBallComponents)
		{
			FVector ToTargetDirection = (OtherTarget.ActorLocation - MortarBallComponent.WorldLocation).SafeNormal;
			ToTargetDirection = ToTargetDirection.VectorPlaneProject(FVector::UpVector);

			ToTargetDirection = Trajectory::CalculateVelocityForPathWithHeight(MortarBallComponent.WorldLocation, OtherTarget.ActorLocation, (-980.0 * 3.0 * 7.0), 3000.0);

			MortarBallComponent.ComponentQuat = FQuat::Slerp(MortarBallComponent.ComponentQuat, ToTargetDirection.ToOrientationQuat(), 5.0 * DeltaTime);
		}
	}
}