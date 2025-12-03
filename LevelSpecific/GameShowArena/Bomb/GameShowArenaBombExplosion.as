class UGameShowArenaBombExplosionCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AGameShowArenaBombExplosion ExplosionActor;
	TPerPlayer<UGameShowArenaBombTossPlayerComponent> PlayerComps;

	float TimeBeforeKill = 1.2; // based on time of VFX

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ExplosionActor = Cast<AGameShowArenaBombExplosion>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration < TimeBeforeKill)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerComps[Game::Mio] = UGameShowArenaBombTossPlayerComponent::Get(Game::Mio);
		PlayerComps[Game::Zoe] = UGameShowArenaBombTossPlayerComponent::Get(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FPlayerDeathDamageParams MioDeathParams;
		MioDeathParams.ImpactDirection = (Game::Mio.ActorLocation - ExplosionActor.ActorLocation).GetSafeNormal();
		MioDeathParams.ForceScale = 15;
		Game::Mio.KillPlayer(MioDeathParams, ExplosionActor.BombDeathEffect);

		FPlayerDeathDamageParams ZoeDeathParams;
		ZoeDeathParams.ImpactDirection = (Game::Zoe.ActorLocation - ExplosionActor.ActorLocation).GetSafeNormal();
		ZoeDeathParams.ForceScale = 15;
		Game::Zoe.KillPlayer(ZoeDeathParams, ExplosionActor.BombDeathEffect);
		ExplosionActor.DestroyActor();
	}
}

class AGameShowArenaBombExplosion : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.CollisionResponseToAllChannels = ECollisionResponse::ECR_Ignore;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"GameShowArenaBombExplosionCapability");

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY()
	TSubclassOf<UDeathEffect> BombDeathEffect;
};