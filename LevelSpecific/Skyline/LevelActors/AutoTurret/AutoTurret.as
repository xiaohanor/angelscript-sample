class AAutoTurret : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USceneComponent FirePoint;

	UPROPERTY(EditAnywhere)
	TArray<AHazeActor> Targets;

	UPROPERTY(EditAnywhere)
	float Range = 10000.0;
	
	UPROPERTY(EditAnywhere)
	float RotationSpeed = 100.0;

	UPROPERTY(EditAnywhere)
	float FireRate = 1.0;

	UPROPERTY(EditAnywhere)
	float SpreadAngle = 3.0;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AHazeActor> ProjectileClass;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultCapabilities.Add(n"AutoTurretTargetingCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"AutoTurretShootCapability");

	AHazeActor CurrentTarget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Targets.Add(Game::Mio);
		Targets.Add(Game::Zoe);
	}

	void SpawnBullet() 
	{
		FVector LaunchDirection = Math::VRandCone(FirePoint.WorldRotation.ForwardVector, Math::DegreesToRadians(SpreadAngle));
		SpawnActor(ProjectileClass, FirePoint.WorldLocation, LaunchDirection.Rotation());
		FGameplayWeaponParams WeaponParams;
		WeaponParams.ShotsFiredAmount = 1;
		UAutoTurretEventHandler::Trigger_OnShotFired(this, WeaponParams);	
	}

}

UCLASS(Abstract)
class UAutoTurretEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void OnShotFired(FGameplayWeaponParams Params) {}
}