class AAICoastJetSki : ABasicAICharacter
{
	default CapsuleComponent.bOffsetBottomToAttachParentLocation = false;
	default DisableComp.AutoDisableRange = 100000.0;

	default CapabilityComp.DefaultCapabilities.Add(n"CoastJetskiBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"CoastJetskiMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"CoastJetskiSplineTrackerCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"CoastJetskiDeathCapability");

	UPROPERTY(DefaultComponent, Attach = "MeshOffsetComponent")
	UStaticMeshComponent JetskiMesh;

	UPROPERTY(DefaultComponent, Attach = "JetskiMesh")
	UHazeCharacterSkeletalMeshComponent Driver;

	UPROPERTY(DefaultComponent, Attach = "JetskiMesh")
	UHazeCharacterSkeletalMeshComponent Passenger;

	UPROPERTY(DefaultComponent, Attach = "Passenger", AttachSocket = "RightAttach")
	UCoastJetskiWeaponComponent PassengerWeapon;

	UPROPERTY(DefaultComponent, Attach = "PassengerWeapon", AttachSocket = "Muzzle")
	UCoastJetskiWeaponMuzzleComponent MuzzleComp;

	UPROPERTY(DefaultComponent)
	UCoastJetskiComponent JetskiComp;

	UPROPERTY(DefaultComponent)
	UCoastShoulderTurretGunResponseComponent DamageResponseComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UAutoAimTargetComponent AutoAimTargetComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UCoastJetskiSettings Settings;
	bool bWaitingForDeployment = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		Settings = UCoastJetskiSettings::GetSettings(this);

		OnRespawn();
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");

		// Crowd avoidance
		UBasicAISettings::SetCrowdAvoidanceMinRange(this, 200, this, EHazeSettingsPriority::Defaults);
		UBasicAISettings::SetCrowdAvoidanceMaxRange(this, 800, this, EHazeSettingsPriority::Defaults);
		UBasicAISettings::SetCrowdAvoidanceForce(this, 2000.0, this, EHazeSettingsPriority::Defaults);
	}

	UFUNCTION()
	private void OnRespawn()
	{
		if(!Settings.bDeployEnabled)
			return;

		if (bWaitingForDeployment)
			return;

		BlockCapabilities(BasicAITags::Behaviour, this);
		BlockCapabilities(CapabilityTags::Movement, this);
		bWaitingForDeployment = true;
	}

	UFUNCTION(DevFunction)
	void Deploy()
	{
		if(!Settings.bDeployEnabled)
			return;

		if (!bWaitingForDeployment)
			return;

		UnblockCapabilities(BasicAITags::Behaviour, this);
		UnblockCapabilities(CapabilityTags::Movement, this);
		bWaitingForDeployment = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	}
}

class UCoastJetskiWeaponComponent : UHazeSkeletalMeshComponentBase
{
}

class UCoastJetskiWeaponMuzzleComponent : USceneComponent
{
}
