class ASkylineBallBossSmallBossProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ProjectileRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTelegraphDecalComponent TelegraphDecalComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY()
	UNiagaraSystem ExplosionVFX;

	UPROPERTY()
	float TargetRadius = 500.0;

	UPROPERTY()
	float DamageRadius = 50.0;

	UPROPERTY()
	float ArcHeight = 500.0;

	UPROPERTY()
	FHazeTimeLike ProjectileMovementTimeLike;
	default ProjectileMovementTimeLike.UseSmoothCurveZeroToOne();
	default ProjectileMovementTimeLike.Duration = 1.0;

	FVector TargetLocation;

	int TimesIveTriedToFindTheStupidTargetLocation = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjectileMovementTimeLike.BindUpdate(this, n"ProjectileMovementTimeLikeUpdate");
		ProjectileMovementTimeLike.BindFinished(this, n"ProjectileMovementTimeLikeFinished");
		ProjectileMovementTimeLike.Play();
		TelegraphDecalComp.SetWorldLocation(TargetLocation);
	}

	UFUNCTION()
	private void ProjectileMovementTimeLikeUpdate(float CurrentValue)
	{
		FVector Location = Math::Lerp(ActorLocation, TargetLocation, CurrentValue);
		Location.Z += Math::Sin(CurrentValue * PI) * ArcHeight;

		FVector Direction = (Location - ProjectileRoot.WorldLocation).GetSafeNormal(); 
		FRotator Rotation = Direction.Rotation();

		ProjectileRoot.SetWorldLocationAndRotation(Location, Rotation);
		
	}

	UFUNCTION()
	private void ProjectileMovementTimeLikeFinished()
	{
		for (auto Player : Game::GetPlayers())
		{
			if (Player.HasControl() && TargetLocation.Distance(Player.ActorLocation) < DamageRadius)
			{
				FVector DeathDir = (Player.ActorCenterLocation - ProjectileRoot.WorldLocation).GetSafeNormal();
				Player.DamagePlayerHealth(0.5, FPlayerDeathDamageParams(DeathDir), DamageEffect, DeathEffect);
			}
		}

		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFX, TargetLocation);
		USkylineBallBossSmallBossProjectileEventHandler::Trigger_OnProjectileImpact(this);
		BP_ProjectileImpact();
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_ProjectileImpact()
	{
	}
};

class USkylineBallBossSmallBossProjectileEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFireProjectile() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnProjectileImpact() {}

};