UCLASS(Abstract)
class ACoastBossPlayerBullet : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent BulletTrail;

	const float MaxAliveTime = 2.2;
	float AliveDuration = 0.0;

	UPROPERTY(EditDefaultsOnly)
	FVector2D Velocity;
	float Gravity = 0.0;
	FVector2D ManualRelativeLocation;

	float Scale = 1.0;
	float TargetScale = 1.0;

	float DamageMultiplier = 1.0;
	bool bShouldDespawn = false;
	bool bIsHomingBullet = false;
	TArray<AHazeActor> HitActors;
};