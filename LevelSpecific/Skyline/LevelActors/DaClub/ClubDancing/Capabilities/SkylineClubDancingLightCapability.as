class USkylineClubDancingLightCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SkylineClubDancing");
	default CapabilityTags.Add(n"SkylineClubDancingLight");

	default TickGroup = EHazeTickGroup::Gameplay;

	USkylineClubDancingUserComponent UserComp;

	USpotLightComponent SpotLightA;
	USpotLightComponent SpotLightB;

	FHazeAcceleratedFloat AccFloat;
	FRotator Spin;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USkylineClubDancingUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.bIsCameraSpinning)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.bIsCameraSpinning)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SpotLightA = USpotLightComponent::Create(Player);
		SpotLightA.SetInverseSquaredFalloff(false);
		SpotLightA.SetIntensity(0.0);
		SpotLightA.SetAttenuationRadius(500.0);
		SpotLightA.SetOuterConeAngle(60.0);
		SpotLightA.SetLightColor(UserComp.SpotLightA_Color);
		SpotLightA.SetCastShadows(false);
//		SpotLightA.SetLightFunctionMaterial(UserComp.LightFunctionMaterialA);
//		SpotLightA.SetLightFunctionScale(FVector::OneVector * 1.0);

		SpotLightB = USpotLightComponent::Create(Player);
		SpotLightB.SetInverseSquaredFalloff(false);
		SpotLightB.SetIntensity(0.0);
		SpotLightB.SetAttenuationRadius(500.0);
		SpotLightB.SetOuterConeAngle(60.0);
		SpotLightB.SetLightColor(UserComp.SpotLightB_Color);
		SpotLightB.SetCastShadows(false);
		SpotLightB.SetLightFunctionMaterial(UserComp.LightFunctionMaterialB);
		SpotLightB.SetLightFunctionScale(FVector::OneVector * 1.0);
		SpotLightB.SetLightFunctionDisabledBrightness(0.1);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SpotLightA.DestroyComponent(Player);
		SpotLightB.DestroyComponent(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Spin.Roll += 100.0 * DeltaTime;
		AccFloat.AccelerateTo(1.0, 6.0, DeltaTime);

		SpotLightA.SetWorldLocationAndRotation(Player.ViewLocation, Player.ViewRotation);
		SpotLightA.SetIntensity(AccFloat.Value * UserComp.SpotLightA_Intensity);

		SpotLightB.SetWorldLocationAndRotation(Player.ViewLocation, Player.ViewRotation + Spin);
		SpotLightB.SetIntensity(AccFloat.Value * UserComp.SpotLightB_Intensity);
	}
};