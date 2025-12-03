class USkylineSentryBossTunnelCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"BossTunnelCamera");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	USkylineSentryBossPlayerLandedComponent LandedComp;	
	ASKylineSentryBoss Boss;

	FHazeAcceleratedRotator AccRot;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{	
		if(Boss == nullptr)
			return false;

		if(!Player.ActorCenterLocation.IsWithinDist(Boss.ActorLocation, 1550))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Player.ActorCenterLocation.IsWithinDist(Boss.ActorLocation, 1600))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	
		FRotator Rotation = LandedComp.TunnelCamera.WorldTransform.InverseTransformRotation(FQuat(Player.ViewRotation)).Rotator();
		Rotation.Pitch = 0;
		Rotation.Yaw = 0;
		Rotation = LandedComp.TunnelCamera.WorldTransform.TransformRotation(FQuat(Rotation)).Rotator();
		LandedComp.TunnelCamera.WorldRotation = Rotation;
		AccRot.SnapTo(Rotation);
		Player.ActivateCamera(LandedComp.TunnelCamera, 2.0, this, EHazeCameraPriority::Medium);

		Player.BlockCapabilities(GravityBladeTags::GravityBladeAim, this);
		Player.BlockCapabilities(n"BossCamera", this);

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DeactivateCameraByInstigator(this, 0.75);

		Player.UnblockCapabilities(GravityBladeTags::GravityBladeAim, this);
		Player.UnblockCapabilities(n"BossCamera", this);

		Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(Boss == nullptr)
		{
			LandedComp = USkylineSentryBossPlayerLandedComponent::Get(Owner);
			if(LandedComp != nullptr)
				Boss = Cast<ASKylineSentryBoss>(LandedComp.Boss);

		}
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FRotator TargetRotation =FRotator::MakeFromZX(Player.ActorUpVector, LandedComp.TunnelCamera.ForwardVector);
		float AccelerationDuration = Math::GetMappedRangeValueClamped(FVector2D(10, 70), FVector2D(20, 2), Math::Abs((AccRot.Value - TargetRotation).GetNormalized().Roll));
		//PrintToScreenScaled("" + (AccRot.Value - TargetRotation).GetNormalized().Roll);
		LandedComp.TunnelCamera.WorldRotation = AccRot.AccelerateTo(TargetRotation, AccelerationDuration, DeltaTime);
		LandedComp.TunnelCamera.WorldLocation = LandedComp.Boss.ActorLocation - LandedComp.TunnelCamera.ForwardVector * ((Boss.ActorLocation - Player.ActorCenterLocation).DotProduct(LandedComp.TunnelCamera.ForwardVector) + 1400);
	}

	
}