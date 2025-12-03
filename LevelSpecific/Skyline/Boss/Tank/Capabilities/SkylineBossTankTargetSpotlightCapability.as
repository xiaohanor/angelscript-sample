class USkylineBossTankTargetSpotlightCapability : USkylineBossTankChildCapability
{
//	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankAttack);
	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankSpotlight);

	float InitialSpotlightIntensity = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		BossTank.TargetSpotlightVisualPivot.SetHiddenInGame(true, true);
		BossTank.TargetDecal.SetHiddenInGame(true, true);
		BossTank.TargetSpotLight.SetHiddenInGame(true, true);

		InitialSpotlightIntensity = BossTank.TargetSpotLight.Intensity;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return false;

		// if (!BossTank.HasAttackTarget())
		// 	return false;

		// return true;
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
		FSkylineBossTankLight Settings;
		Settings.BlendTime = 2.0;
		Settings.Color = FLinearColor::White * 100.0;
		BossTank.SensorLightComp.ApplyLightSettings(Settings, this);

		BossTank.TargetSpotlightVisualPivot.SetHiddenInGame(false, true);
		BossTank.TargetDecal.SetHiddenInGame(true, true);
		BossTank.TargetSpotLight.SetHiddenInGame(false, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossTank.TargetSpotlightVisualPivot.SetHiddenInGame(true, true);
		BossTank.TargetDecal.SetHiddenInGame(true, true);
		BossTank.TargetSpotLight.SetHiddenInGame(true, true);

		BossTank.SensorLightComp.ClearLightSettings(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto Target = BossTank.GetAttackTarget();
		if(Target == nullptr)
			return;

		FVector ToTargetDirection = (Target.ActorLocation - BossTank.TargetSpotlightPivot.WorldLocation).SafeNormal;
//		ToTargetDirection = ToTargetDirection.VectorPlaneProject(FVector::UpVector);

		float Alpha = Math::Max(0.0, BossTank.TargetSpotlightPivot.WorldRotation.ForwardVector.DotProduct(ToTargetDirection));

		Alpha = Math::GetMappedRangeValueClamped(FVector2D(0.92, 1.0), FVector2D(0.0, 1.0), Alpha);

		BossTank.TargetSpotLight.SetIntensity(InitialSpotlightIntensity * Alpha);

//		Debug::DrawDebugLine(BossTank.TargetSpotlightPivot.WorldLocation, BossTank.TargetSpotlightPivot.WorldLocation + BossTank.TargetSpotlightPivot.ForwardVector * 3000.0, FLinearColor::Green, 10.0, 0.0);
//		Debug::DrawDebugLine(BossTank.TargetSpotlightPivot.WorldLocation, BossTank.TargetSpotlightPivot.WorldLocation + ToTargetDirection * 3000.0, FLinearColor::Blue, 10.0, 0.0);

//		PrintToScreen("Alpha: " + Alpha, 0.0, FLinearColor::Green);

		BossTank.TargetSpotlightPivot.ComponentQuat = FQuat::Slerp(BossTank.TargetSpotlightPivot.ComponentQuat, ToTargetDirection.ConstrainToCone(BossTank.TargetSpotlightPivot.AttachParent.ForwardVector, Math::DegreesToRadians(20.0)).ToOrientationQuat(), 20.0 * DeltaTime);
		BossTank.TargetDecal.WorldLocation = Target.ActorLocation;
		BossTank.TargetDecal.ComponentQuat = FQuat::MakeFromZX(ToTargetDirection, FVector::UpVector);
		BossTank.TargetSpotLight.WorldLocation = Target.ActorLocation - ToTargetDirection.SafeNormal * 800.0;
		BossTank.TargetSpotLight.ComponentQuat = ToTargetDirection.ToOrientationQuat();
	}
}