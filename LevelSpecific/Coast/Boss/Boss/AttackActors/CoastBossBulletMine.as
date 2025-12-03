struct FCoastBulletDataMine
{
	float CollisionRadius = 100.0;
	bool bDetonated = false;
	bool bPlayerBulletHit = false;
	float DetonatedFeedbackDuration = 0.0;
	float TargetScale = 1.5;
}

UCLASS(Abstract)
class ACoastBossBulletMine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase MeshComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent AreaFeedbackMeshComp;
	default AreaFeedbackMeshComp.SetWorldScale3D(FVector::OneVector * CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_MineExplosionRadius * 0.01);
	default AreaFeedbackMeshComp.SetVisibility(false);

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLogger;
#endif

	FCoastBulletDataMine MineData;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem DetonateVFX;

	UPROPERTY(EditDefaultsOnly)
	const float MaxAliveTime = 8.0;
	float AliveDuration = 0.0;
	const float SlowBeepInterval = 1.0;
	const float FastBeepInterval = 0.1;
	float BeepInterval = SlowBeepInterval;
	float BeepCooldown = 0.0;

	float FollowSpeed = 600.0;
	UPROPERTY(EditDefaultsOnly)
	FVector2D Velocity;
	UPROPERTY(EditDefaultsOnly)
	FVector2D Acceleration;
	UPROPERTY(EditDefaultsOnly)
	float Gravity = 0.0;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams RetractedMHAnim;
	default RetractedMHAnim.bLoop = true;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams ExtendAnim;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams ExtendedMHAnim;
	default ExtendedMHAnim.bLoop = true;

	FHazeAcceleratedFloat AccBlinkDangerous;
	FHazeAcceleratedFloat AccScale;
	FHazeAcceleratedRotator AccRot;
	float TargetScale = 1.0;

	FVector2D ManualRelativeLocation;
	FHazeAcceleratedVector2D InitialVelocity;

	AHazePlayerCharacter TargetPlayer;

	float Health = 1.0;

	bool bIsDangerous = false;
	float TimeOfDangerous = -100.0;
	bool bExtended = false;
	int ID = 0;

	private bool bHasDangerousMaterial = true;

	float DelayBeforeExtend;

	const float MaxRotationAmount = 30.0;

	void OnSpawn()
	{
		AccScale.SnapTo(0.2);
		AccRot.SnapTo(FRotator(Math::RandRange(-MaxRotationAmount, MaxRotationAmount), Math::RandRange(-MaxRotationAmount, MaxRotationAmount), Math::RandRange(-MaxRotationAmount, MaxRotationAmount)));
	}

	void SetDangerous(bool bDangerousness)
	{
		bIsDangerous = bDangerousness;
		if(!bDangerousness)
			return;

		DelayBeforeExtend = Math::RandRange(0.3, 0.8);
		bExtended = false;
		TimeOfDangerous = Time::GetGameTimeSeconds();
		MeshComp.PlaySlotAnimation(RetractedMHAnim);
	}

	private void SetMaterial(bool bDangerous)
	{
		if (bHasDangerousMaterial == bDangerous)
			return;
		bHasDangerousMaterial = bDangerous;
		BP_MineSetMaterial(bHasDangerousMaterial);
	}

	void Beep()
	{
		AccBlinkDangerous.SnapTo(1.0);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_MineSetMaterial(bool bDangerous) {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AccBlinkDangerous.AccelerateTo(0.0, BeepInterval, DeltaSeconds);
		FVector EmissiveTint = FVector(400 * AccBlinkDangerous.Value, 0, 0);
		MeshComp.SetVectorParameterValueOnMaterialIndex(0, n"EmissiveTint", EmissiveTint);

		float TimeSince = Time::GetGameTimeSince(TimeOfDangerous);
		if(!bExtended && TimeSince > DelayBeforeExtend)
		{
			MeshComp.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"OnExtendAnimFinished"), ExtendAnim);
			bExtended = true;
		}
	}

	UFUNCTION()
	private void OnExtendAnimFinished()
	{
		MeshComp.PlaySlotAnimation(ExtendedMHAnim);
	}
};