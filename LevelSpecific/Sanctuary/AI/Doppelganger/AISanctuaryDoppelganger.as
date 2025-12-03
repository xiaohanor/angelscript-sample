UCLASS(Abstract)
class AAISanctuaryDoppelganger : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDoppelgangerMimicMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDoppelgangerBehaviourCompoundCapability");

	UPROPERTY(DefaultComponent, ShowOnActor)
	USanctuaryDoppelgangerComponent DoppelComp;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = RightAttach)
	UBasicAIMeleeWeaponComponent Weapon;

	UPROPERTY(DefaultComponent)
	UPlayerFloorMotionComponent MimicFloorMotionComp;
	UPROPERTY(DefaultComponent)
	UPlayerFloorSlowdownComponent MimicFloorSlowdownComp;
	UPROPERTY(DefaultComponent)
	UPlayerSprintComponent MimicSprintComp;
	UPROPERTY(DefaultComponent)
	UPlayerLandingComponent MimicLandingComp;
	UPROPERTY(DefaultComponent)
	UPlayerJumpComponent MimicJumpComponent;
	UPROPERTY(DefaultComponent)
	UPlayerAirMotionComponent MimicAirMovementComp;

	USanctuaryDoppelgangerSettings DoppelSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		DoppelSettings = USanctuaryDoppelgangerSettings::GetSettings(this);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnDoppelSpawn");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnDoppelSpawn()
	{
		DoppelComp.StartCreepyTime = Time::GameTimeSeconds + DoppelSettings.CreepynessDelay;	
	}
}
