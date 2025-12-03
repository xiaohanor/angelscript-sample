class AIslandWalkerDestroyedLeg : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComponent;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;
	default ProjectileComp.Friction = 0.01;
	default ProjectileComp.Gravity = 9.82;
	default ProjectileComp.bIgnoreDescendants = false;
	default ProjectileComp.TraceType = ETraceTypeQuery::WeaponTraceZoe;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaSeconds, Hit));

		if (Hit.bBlockingHit || Time::GetGameTimeSince(ProjectileComp.LaunchTime) > 3)
		{
			FBasicAiProjectileOnImpactData Data;
			Data.HitResult = Hit;
			UBasicAIProjectileEffectHandler::Trigger_OnImpact(this, Data);
			ProjectileComp.Expire();
		}
	}
}