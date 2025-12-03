struct FCoastBulletDataBall
{
	float CollisionRadius = 45.0;
	bool bHitSomething = false;
	float TargetScale = 1.2;
	float InitialScaleMultiplier = 0.4;
}

UCLASS(Abstract)
class ACoastBossBulletBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	FCoastBulletDataBall BallData;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ImpactVFX;

	UPROPERTY(EditDefaultsOnly)
	const float MaxAliveTime = 5.0;
	float AliveDuration = 0.0;

	UPROPERTY(EditDefaultsOnly)
	FVector2D Velocity;
	UPROPERTY(EditDefaultsOnly)
	FVector2D Acceleration;
	UPROPERTY(EditDefaultsOnly)
	float Gravity = 0.0;

	int ID = 0;

	bool bDangerous = true;

	FHazeAcceleratedFloat ExtraImpulse;
	FHazeAcceleratedFloat AccScale;
	float TargetScale = 1.0;

	FVector2D ManualRelativeLocation;
	FHazeAcceleratedVector2D InitialVelocity;

	void OnSpawned(ACoastBoss Boss, ACoastBossActorReferences References)
	{
		// FVector Vel = Boss.GetRawLastFrameTranslationVelocity();
		// Vel -= References.CoastBossPlane2D.GetRawLastFrameTranslationVelocity();
		// InitialVelocity.SnapTo(References.CoastBossPlane2D.GetDirectionOnPlane(Vel));
	}
};