UCLASS(Abstract)
class AAICoastTrainDrone : ABasicAIFlyingCharacter
{
	// Do not use pathfinding, just move straight to destination
	default MoveToComp.DefaultSettings = BasicAIFlyingIgnorePathfindingMoveToSettings;

	default CapsuleComponent.RelativeLocation = FVector::ZeroVector;
	default CapsuleComponent.CapsuleHalfHeight = 40.0;
	default CapsuleComponent.CapsuleRadius = 40.0;

	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIFlyingMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"CoastTrainDroneMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"CoastTrainDroneBehaviourCompoundCapability");

	default DisableComp.AutoDisableRange = 100000.0;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightAttach")
	UBasicAIProjectileLauncherComponent Weapon;
	default Weapon.LaunchOffset = FVector(60.0, 0.0, 0.0);

	UPROPERTY(DefaultComponent) 
	UBasicAICharacterMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent)
	UCoastShoulderTurretGunResponseComponent DamageResponseComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UAutoAimTargetComponent AutoAimTargetComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UBasicAISettings Settings;
	float BaseSpeed = 2000.0;
	float UpdateBaseSpeedTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
		Settings = UBasicAISettings::GetSettings(this);
		HealthComp.OnDie.AddUFunction(this, n"OnDroneDie");
		UBasicAIMovementSettings::SetTurnDuration(this, 2.0, this, EHazeSettingsPriority::Defaults);
	}

	UFUNCTION()
	private void OnDroneDie(AHazeActor ActorBeingKilled)
	{
		AActor AttachActor = (RespawnComp.Spawner != nullptr) ? RespawnComp.Spawner.AttachParentActor : nullptr;
		if(AttachActor == nullptr)
			AttachActor = this;
		UCoastTrainDroneEffectHandler::Trigger_OnDeath(this, FTrainDroneDeathParams(AttachActor));
	}

	UFUNCTION()
	private void OnReset()
	{
		MovementComponent.Reset();
	}
}
