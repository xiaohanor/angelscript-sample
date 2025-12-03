class USkylineBossTankCenterCapability : USkylineBossTankChildCapability
{
	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankMovement);

	USkylineBossTankFollowTargetComponent FollowTargetComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		FollowTargetComp = USkylineBossTankFollowTargetComponent::Get(BossTank);	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BossTank.State.Get() != ESkylineBossTankState::Center)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FollowTargetComp.FindNewTarget(BossTank.ConstraintRadiusOrigin.ActorTransform, 5000.0);

		BossTank.OnEnrage.Broadcast();

		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankChase, this);
//		BossTank.BlockCapabilities(SkylineBossTankTags::Attacks::SkylineBossTankAttackCrusher, this);
//		BossTank.BlockCapabilities(SkylineBossTankTags::Attacks::SkylineBossTankAttackAutoCannon, this);
		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankSpotlight, this);
//		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankChangeTarget, this);
//		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankChangeTargetOnDamage, this);

		BossTank.MainAttackInterval.Apply(1.0, this, EInstigatePriority::High);
		BossTank.MainAttackAlternateTarget.Apply(true, this, EInstigatePriority::High);

		FSkylineBossTankLight LightSettings;
		LightSettings.Color = FLinearColor::Red * 1000.0;
		LightSettings.BlendTime = 1.0;
		LightSettings.Freq = 16.0;
		LightSettings.FreqAlpha = 1.5;
		BossTank.LightComp.ApplyLightSettings(LightSettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankChase, this);
//		BossTank.UnblockCapabilities(SkylineBossTankTags::Attacks::SkylineBossTankAttackCrusher, this);
//		BossTank.UnblockCapabilities(SkylineBossTankTags::Attacks::SkylineBossTankAttackAutoCannon, this);
		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankSpotlight, this);
//		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankChangeTarget, this);
//		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankChangeTargetOnDamage, this);

		BossTank.MainAttackInterval.Clear(this);
		BossTank.MainAttackAlternateTarget.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
			TickControl(DeltaTime);
		else
			TickRemote(DeltaTime);
	}

	void TickControl(float DeltaTime)
	{
//		Debug::DrawDebugPoint(FollowTargetComp.GetTarget(), 50.0, FLinearColor::Red, 0.0);

		FVector ToTarget = (FollowTargetComp.GetTarget() - BossTank.ActorLocation).ConstrainToPlane(FVector::UpVector);

		if (ToTarget.Size() < FollowTargetComp.TargetRadius)
			FollowTargetComp.FindNewTarget(BossTank.ConstraintRadiusOrigin.ActorTransform, 30000.0);

		// FVector Direction = ToTarget.SafeNormal;
		float Distance = ToTarget.Size();

		// float DistanceBasedSpeed = Math::GetMappedRangeValueClamped(FVector2D(5000.0, 20000.0), FVector2D(BossTank.MaxSpeed, BossTank.MaxSpeed * 1.8), Distance);

		float TurnSpeed = BossTank.MaxTurnSpeed * (1.0 - Math::Clamp(Math::NormalizeToRange(Distance, FollowTargetComp.TargetRadius, 20000.0), 0.0, 0.6));
				
		FVector TurnTorque = BossTank.ActorForwardVector.CrossProduct(ToTarget.SafeNormal) * TurnSpeed;

		BossTank.Torque += TurnTorque;
		BossTank.Force += BossTank.ActorForwardVector.VectorPlaneProject(FVector::UpVector) * BossTank.MaxSpeed;
	}

	void TickRemote(float DeltaTime)
	{

	}
}