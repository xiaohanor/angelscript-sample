class ASummitDarkCaveMetalSlowProjectile : ANightQueenMetal
{
	default CapabilityComp.DefaultCapabilities.Add(n"MetalSlowProjectileCapability");

	AHazeActor Target;

	float DamageRadius = 250.0;

	float SlowDownRadius = 5000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnNightQueenMetalMelted.AddUFunction(this, n"MetalDestroyed");
	}

	UFUNCTION()
	private void MetalDestroyed()
	{
		FDarkCaveMetalSlowProjectileParams Params;
		Params.ImpactLocation = ActorLocation;
		Params.ImpactRotation = (Target.ActorLocation - ActorLocation).Rotation();
		USummitDarkCaveMetalSlowProjectileEffectHandler::Trigger_Melted(this, Params);
		DestroyActor();
	}

	void InitiateTarget(AHazePlayerCharacter Player)
	{
		Target = Player;
	}

	void ProjectileImpact()
	{
		FDarkCaveMetalSlowProjectileParams Params;
		Params.ImpactLocation = ActorLocation;
		Params.ImpactRotation = (Target.ActorLocation - ActorLocation).Rotation();
		USummitDarkCaveMetalSlowProjectileEffectHandler::Trigger_Impact(this, Params);
		DestroyActor();
	}
};