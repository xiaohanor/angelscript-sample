
UCLASS(Abstract)
class UGameplay_Vehicle_Player_CoastBossDrone_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void ShieldChangeState(FCoastBossAeuronauticPlayerShieldData Params){}

	UFUNCTION(BlueprintEvent)
	void GotImpacted(FCoastBossAeuronauticPlayerReceiveDamageData Params){}

	UFUNCTION(BlueprintEvent)
	void Died(FCoastBossAeronauticPlayerDiedEffectData Params){}

	UFUNCTION(BlueprintEvent)
	void GotImpactDuringInvulnerable(){}

	UFUNCTION(BlueprintEvent)
	void OnDash(FCoastBossAeronauticDashEffectData Params){}

	UFUNCTION(BlueprintEvent)
	void OnShootBasicProjectile(FCoastBossPlayerBulletOnShootParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnShootBarrageProjectile(FCoastBossPlayerBulletOnShootParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnShootHomingProjectile(FCoastBossPlayerBulletOnShootParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerProjectileImpactBoss(FCoastBossAeuronauticBossReceiveDamageData Params){}

	UFUNCTION(BlueprintEvent)
	void OnPickupPowerup(FCoastBossAeronauticPowerupEffectData Params){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerLaserActivated(FCoastBossPlayerBulletOnShootParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly, NotVisible)
	UHazeAudioEmitter BossImpactEmitter;

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;

		if(EmitterName == n"BossImpactEmitter")		
			bUseAttach = false;	

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		ACoastBossActorReferences Refs = TListedActors<ACoastBossActorReferences>().GetSingle();
		BossImpactEmitter.AttachEmitterTo(Refs.Boss.BossMeshComp);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		FVector2D _;
		float X = 0.0;
		float _Y = 0.0;
		if(Audio::GetScreenPositionRelativePanningValue(PlayerOwner.ActorLocation, _, X, _Y))
		{
			DefaultEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, X, 0);
		}
		if(Audio::GetScreenPositionRelativePanningValue(BossImpactEmitter.GetEmitterLocation(), _, X, _Y))
		{
			BossImpactEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, X, 0);
		}
	}
}