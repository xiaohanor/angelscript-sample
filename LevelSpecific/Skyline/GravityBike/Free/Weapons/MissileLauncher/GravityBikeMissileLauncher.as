UCLASS(Abstract)
class AGravityBikeMissileLauncher : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UArrowComponent LeftMuzzle;

	UPROPERTY(DefaultComponent)
	UArrowComponent RightMuzzle;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY(EditDefaultsOnly)
	FTransform GravityBikeRelativeTransform;

	UPROPERTY(EditDefaultsOnly)
	float FireInterval = 0.8;

	UPROPERTY(EditDefaultsOnly)
	int ShotsPerMaxCharge = 20;

	UPROPERTY(EditDefaultsOnly)
	int MaxTargets = 5;

	UPROPERTY(EditDefaultsOnly)
	float AimingAngle = 25.0;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UTargetableWidget> TargetWidgetClass;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AGravityBikeMissileLauncherProjectile> MissileClass;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem MuzzleFlash;

	UPROPERTY(EditAnywhere)
	bool bInheritVelocityInLaunchDirection = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorCollisionBlock(this);
	}

	float GetChargePerShot() const
	{
		return 1.0 / ShotsPerMaxCharge;
	}
}