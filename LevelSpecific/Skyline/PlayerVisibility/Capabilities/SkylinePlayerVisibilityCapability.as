class USkylinePlayerVisibilityCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(Skyline::PlayerVisibility);
	
	default TickGroup = EHazeTickGroup::Gameplay;

	USkylinePlayerVisibilityComponent UserComp;

	UHazeSphereComponent HazeSphere;
	UPointLightComponent PointLight;
	USpotLightComponent SpotLight;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USkylinePlayerVisibilityComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
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

/*
		HazeSphere = Cast<UHazeSphereComponent>(Owner.CreateComponent(UserComp.HazeSphereClass));
		HazeSphere.AttachToComponent(Player.Mesh, UserComp.AttachSocket);
		PointLight = Cast<UPointLightComponent>(Owner.CreateComponent(UPointLightComponent));
		PointLight.AttachToComponent(Player.Mesh, UserComp.WeaponAttachSocket);

		SpotLight = Cast<USpotLightComponent>(Owner.CreateComponent(USpotLightComponent));
		SpotLight.AttachToComponent(Player.Mesh, UserComp.AttachSocket);
		SpotLight.SetRelativeLocation(FVector::UpVector * 200.0);
		SpotLight.SetRelativeRotation(FRotator(-90, 0.0, 0.0));

		HazeSphere.SetRelativeScale3D(FVector::OneVector * UserComp.HazeSphereRadius * 0.01);
		HazeSphere.SetColor(UserComp.HazeSphereOpacity, 1.0, UserComp.HazeSphereColor);
		PointLight.SetAttenuationRadius(UserComp.LightRadius);
		PointLight.SetIntensity(UserComp.LightIntensity);
		PointLight.SetLightColor(UserComp.LightColor);
		PointLight.SetCastShadows(false);
		PointLight.SetUseInverseSquaredFalloff(false);
		PointLight.SetSourceRadius(UserComp.LightRadius);

		SpotLight.SetIntensity(0.0);
		SpotLight.SetLightFalloffExponent(2.0);
		SpotLight.SetOuterConeAngle(30.0);
		SpotLight.SetAttenuationRadius(300.0);
		SpotLight.SetLightColor(UserComp.LightColor);
		SpotLight.SetCastShadows(false);
		SpotLight.SetUseInverseSquaredFalloff(false);
		SpotLight.SetSourceRadius(1000.0);

		HazeSphere.ConstructionScript_Hack();

		HazeSphere.SetRenderedForPlayer(Player, UserComp.bRenderedForOwner);
*/	

		UserComp.ApplyMaterialOverrides();
//		UserComp.CreateFootDecals();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
/*
		HazeSphere.DestroyComponent(Owner);
		PointLight.DestroyComponent(Owner);
		SpotLight.DestroyComponent(Owner);
*/

		UserComp.ClearMaterialOverrides();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};