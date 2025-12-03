UCLASS(Abstract)
class UPrisonBossEffectEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	APrisonBoss Boss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<APrisonBoss>(Owner);
	}

	//Ground Trail
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GroundTrailEnter() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GroundTrailSpawnTrail() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GroundTrailExplode() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GroundTrailExit() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GroundTrailFinished() {}

	//Wave Slash
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WaveSlashEnter() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WaveSlashAttackSpawned() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WaveSlashExit() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WaveSlashFinished() {}

	//Spiral
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpiralEnter() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpiralStartTrail() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpiralExplode() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpiralExit() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpiralFinished() {}

	//Dash Slash
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DashSlashEnter() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DashSlashTelegraph() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DashSlashAttackStarted() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DashSlashAttackReachedEnd() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DashSlashExit() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DashSlashFinished() {}

	//Hackable Magnetic Projectile
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HackableMagneticProjectileEnter() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HackableMagneticProjectileSpawn() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HackableMagneticProjectileLaunch() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HackableMagneticProjectileHitBoss() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HackableMagneticProjectileExit() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HackableMagneticProjectileFinished() {}

	//Grab Player
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabPlayerEnter() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabPlayerExit() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabPlayerCatch() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabPlayerNoCatch() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabPlayerSlam() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabPlayerStartChoke() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabPlayerMagnetBlasted() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabPlayerSaved() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabPlayerGameOver() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabPlayerNeckSnap() {}

	//Clone
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CloneEnter() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CloneStartSpawning() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CloneSpawned() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ClonesFullySpawned() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CloneStartAttacks() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CloneAttack(FPrisonBossCloneAttackEventData Data) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CloneFinalAttackTelegraph() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CloneFinalAttackStarted() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CloneFinalAttackReachedEnd() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CloneExit() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CloneFinished() {}

	//Volley
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void VolleyEnter() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void VolleyExit() {}
	UFUNCTION(BlueprintEvent) 
	void SpawnVolley(FPrisonBossVolleySpawnData Data) {};
	UFUNCTION(BlueprintEvent) 
	void VolleyProjectileImpact(FPrisonBossVolleyImpactData Data) {};
	UFUNCTION(BlueprintEvent) 
	void VolleyWaveDispersed() {};

	//Donut
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DonutEnter() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DonutSpawnAttack() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DonutExit() {}

	//Rocket Fist
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RocketFistImpact() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RocketFistMioLanding() {}

	//Grab Debris
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabDebrisEnter() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabDebrisPull() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabDebrisThrow() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabDebrisDeflect() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabDebrisDeflectThrow() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabDebrisHit() {}

	//Hacked
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Hacked() {}

	//Horizontal Slash
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HorizontalSlashEnter() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HorizontalSlashAttackSpawned() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HorizontalSlashExit() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HorizontalSlashFinished() {}

	//Platform Danger Zone
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlatformDangerZoneEnter() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlatformDangerZoneSpawn() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlatformDangerZoneExit() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlatformDangerZoneInactiveZonesTriggered() {}

	//Magnetic Slam
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MagneticSlamEnter() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MagneticSlamImpact() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MagneticSlamExit() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MagneticSlamBlasted() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MagneticSlamFinalBlast() {}

	//Zig Zag
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ZigZagEnter() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ZigZagSpawnAttack() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ZigZagExit() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ZigZagFinished() {}

	//Scissors
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ScissorsEnter() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ScissorsAttackSpawned() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ScissorsExit() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ScissorsFinished() {}

	//Brain Stuff
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BrainEyeRippedOut() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BrainButtonCoverOpened() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BrainButtonPushed() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BrainOpened() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BrainHacked() {}

	//Take Control
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TakeControlEnter() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TakeControlPull() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TakeControlThrow() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TakeControlHitPlayer() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TakeControlHitBoss() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TakeControlExit() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TakeControlDeflect() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TakeControlDeflectThrow() {}

	//Finisher
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinisherSequenceStarted() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinisherButtonMashStarted() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinisherFail() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinisherSuccess() {}

	// VFX Trail
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ScytheTrailActivated() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ScytheTrailDeactivated() {}
}