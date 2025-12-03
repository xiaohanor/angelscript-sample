
UCLASS(Abstract)
class UCharacter_Boss_Sanctuary_Hydra_Projectiles_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnShootProjectile(FSanctuaryBossMedallionManagerEventProjectileData NewData){}

	UFUNCTION(BlueprintEvent)
	void OnAttackStarted(FSanctuaryBossMedallionManagerEventAttackData NewData){}

	UFUNCTION(BlueprintEvent)
	void OnStartRainAttack(FSanctuaryBossMedallionManagerEventPlayerAttackData NewData){}

	UFUNCTION(BlueprintEvent)
	void OnRainAttackStartFall(FSanctuaryBossMedallionManagerEventPlayerAttackData NewData){}

	UFUNCTION(BlueprintEvent)
	void OnSplitProjectileSplit(FSanctuaryBossMedallionManagerEventSplitProjectileData NewData){}

	UFUNCTION(BlueprintEvent)
	void OnMoveToSidescrollerSpamAttack(FSanctuaryBossMedallionManagerEventPlayerAttackData NewData){}

	UFUNCTION(BlueprintEvent)
	void OnSpamAttackStart(FSanctuaryBossMedallionManagerEventPlayerAttackData NewData){}

	UFUNCTION(BlueprintEvent)
	void OnSpamAttackStop(FSanctuaryBossMedallionManagerEventPlayerAttackData NewData){}

	UFUNCTION(BlueprintEvent)
	void OnProjectileHitWater(FSanctuaryBossMedallionManagerEventProjectileData NewData){}

	UFUNCTION(BlueprintEvent)
	void OnMeteorAttackStart(FSanctuaryBossMedallionManagerEventPlayerAttackData NewData){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditAnywhere)
	int ProjectileEmitterPoolSize = 40;

	UPROPERTY(BlueprintReadWrite)
	FHazeAudioEmitterRotationPool ProjectileEmitterPool;

	AMedallionHydraAttackManager HydraManager;
	ASanctuaryBossMedallionHydraReferences HydraRefManager;

	UPROPERTY(BlueprintReadWrite)
	TMap<AHazeActor, UHazeAudioEmitter> ProjectileEmitters;

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;
		bUseAttach = false;
		return true;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnProjectileImpact(FSanctuaryBossMedallionManagerEventProjectileData Params)
	{
		UHazeAudioEmitter ProjectileEmitter;
		if(ProjectileEmitters.RemoveAndCopyValue(Params.Projectile, ProjectileEmitter))
		{
			ProjectileEmitter.SetEmitterLocation(Params.Projectile.ActorLocation, true);
			BP_OnProjectileImpact(ProjectileEmitter, Params.ProjectileType);		
		}
	}

	const TArray<ASanctuaryBossMedallionHydra>& GetHydras() const property
	{
		return HydraRefManager.Hydras;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		HydraManager = Cast<AMedallionHydraAttackManager>(HazeOwner);
		HydraRefManager = TListedActors<ASanctuaryBossMedallionHydraReferences>().GetSingle();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnProjectileImpact(UHazeAudioEmitter Emitter, EMedallionHydraProjectileType Type) {};

	UFUNCTION(BlueprintCallable)
	void CreatePooledProjectileEmitter(AHazeActor Projectile)
	{
		InternalCreatePooledProjectileEmitter(Projectile);
	}

	private UHazeAudioEmitter InternalCreatePooledProjectileEmitter(AHazeActor Projectile)
	{
		UHazeAudioEmitter Emitter;
		int _ = 0;
		AudioEmitterRotationPool::GetNext(ProjectileEmitterPool, Emitter, _, Projectile.ActorLocation);
		Emitter.AttachEmitterTo(Projectile.RootComponent);
		ProjectileEmitters.Add(Projectile, Emitter);
		return Emitter;
	}
	

	UFUNCTION(BlueprintPure)
	void GetPooledProjectileEmitter(AHazeActor Projectile, UHazeAudioEmitter&out Emitter)
	{
		if (Projectile == nullptr)
			return;

		if(!ProjectileEmitters.Find(Projectile, Emitter))		
			Emitter = InternalCreatePooledProjectileEmitter(Projectile);		
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		ProcessPooledEmitters();
	}

	private void ProcessPooledEmitters()
	{
		for(auto& Elem : ProjectileEmitters)
		{
			UHazeAudioEmitter Emitter = Elem.Value;
			Emitter.SetSpatialPanning(Emitter.AudioComponent.GetClosestPlayer());		
		}
	}
}