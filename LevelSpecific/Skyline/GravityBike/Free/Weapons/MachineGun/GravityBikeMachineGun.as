UCLASS(Abstract)
class AGravityBikeMachineGun : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY(DefaultComponent)
	UArrowComponent LeftMuzzle;

	UPROPERTY(DefaultComponent)
	UArrowComponent RightMuzzle;

	UPROPERTY(EditDefaultsOnly)
	FTransform GravityBikeRelativeTransform;

	UPROPERTY(EditDefaultsOnly)
	float FireInterval = 0.05;

	UPROPERTY(EditDefaultsOnly)
	int ShotsPerMaxCharge = 30;

	UPROPERTY(EditDefaultsOnly)
	float AimingAngle = 25.0;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AGravityBikeMachineGunBullet> BulletClass;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem MuzzleFlash;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorCollisionBlock(this);
	}

	float GetChargePerShot() const
	{
		return 1.0 / ShotsPerMaxCharge;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnWeaponFire(AActor Instigator)
	{

	}
}