struct FCoastBulletDataMill
{
	TArray<UStaticMeshComponent> MillBlades;
	int HitTimes = 0;
	float RotationAngle;
	float TargetScale = 7.0;
	float WeakpointRadius = 100.0;
}

UCLASS(Abstract)
class ACoastBossBulletMill : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ImpactVFX;

	FCoastBulletDataBall BallData;

	FCoastBulletDataMill MillData;

	UPROPERTY(EditDefaultsOnly)
	const float MaxAliveTime = 10.0;
	float AliveDuration = 0.0;

	FHazeAcceleratedFloat ExtraImpulse;
	UPROPERTY(EditDefaultsOnly)
	FVector2D Velocity;
	UPROPERTY(EditDefaultsOnly)
	FVector2D Acceleration;
	UPROPERTY(EditDefaultsOnly)
	float Gravity = 0.0;

	int TimesToHit = 7;

	FHazeAcceleratedFloat AccScale;
	float TargetScale = 1.0;
	
	UPROPERTY(BlueprintReadOnly)
	float ScaleValue = 0.0;

	FVector2D ManualRelativeLocation;
};