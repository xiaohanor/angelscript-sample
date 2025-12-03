
UCLASS(Abstract)
class UCharacter_Boss_Sanctuary_Hydra_Laser_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnLaserStart(FSanctuaryBossMedallionHydraGhostLaserData NewData){}

	UFUNCTION(BlueprintEvent)
	void OnTelegraphLaser(FSanctuaryBossMedallionHydraGhostLaserData NewData){}

	UFUNCTION(BlueprintEvent)
	void OnMoveToSidescrollerLaser(FSanctuaryBossMedallionHydraEventPlayerAttackData NewData){}

	UFUNCTION(BlueprintEvent)
	void OnLaserStop(FSanctuaryBossMedallionHydraGhostLaserData NewData){}

	UFUNCTION(BlueprintEvent)
	void OnLaserImpactWater(FSanctuaryBossMedallionHydraGhostLaserData NewData){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadWrite)
	float AttenuationScaling = 25000;

	UPROPERTY(BlueprintReadWrite)
	TMap<AMedallionHydraGhostLaser, FHazeAudioPostEventInstance> ActiveLasers;

	UPROPERTY(BlueprintReadWrite)
	TArray<AMedallionHydraGhostLaser> SweepLasers;

	UPROPERTY(BlueprintReadOnly)
	float DefaultLaserTelegraphTime = 1.0;

	UFUNCTION(BlueprintEvent)
	void TickActiveLaser(AMedallionHydraGhostLaser Laser, const float ClosestPlayerDist, const float ClosestPlayerVerticalDist) {};

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;
		bUseAttach = false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		for(auto& Elem : ActiveLasers)
		{
			AMedallionHydraGhostLaser Laser = Elem.Key;
			UHazeAudioEmitter LaserEmitter = Laser.GetGhostLaserAudioEmitter();

			const float AttenuationScalingMultiplier = !IsSidescroller() ? 2.0 : 1.0;
			LaserEmitter.SetAttenuationScaling(AttenuationScaling * AttenuationScalingMultiplier);

			TArray<FAkSoundPosition> LaserSoundPositions;
			LaserSoundPositions.SetNum(2);

			const FVector LaserStart = Laser.OwningHydra.SkeletalMesh.GetSocketLocation(n"LaserSocket");

			FRotator LaserRot = Laser.OwningHydra.SkeletalMesh.GetSocketRotation(n"LaserSocket");
			LaserRot.Pitch -= 27; // Rotation needs to be offset, this seems good enough
			const FVector LaserDir = LaserRot.ForwardVector;

			for(auto Player : Game::Players)
			{
				const FVector ClosestLaserPlayerPos = Math::ClosestPointOnInfiniteLine(LaserStart, LaserStart + LaserDir, Player.ActorLocation);
				LaserSoundPositions[int(Player.Player)].SetPosition(ClosestLaserPlayerPos);
			}

			LaserEmitter.SetMultiplePositions(LaserSoundPositions);	

		}

		for(int i = SweepLasers.Num() - 1; i >= 0; --i)
		{
			if (!SweepLasers.IsValidIndex(i))
				continue;

			auto Laser = SweepLasers[i];
			if (Laser == nullptr)
				continue;

			auto LaserEmitter = Laser.GetGhostLaserAudioEmitter();

			AHazePlayerCharacter ClosestPlayer = LaserEmitter.AudioComponent.GetClosestPlayer();
			const FVector ClosestPlayerLocation = ClosestPlayer.ActorLocation;		
			const FVector ClosestPlayerLaserPos = LaserEmitter.GetEmitterLocation();

			const float DistToClosestPlayer = ClosestPlayerLocation.Distance(ClosestPlayerLaserPos);
			const float VerticalDist = Math::Abs(ClosestPlayerLocation.Z - ClosestPlayerLaserPos.Z);

			TickActiveLaser(Laser, DistToClosestPlayer, VerticalDist);
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsSidescroller() 
	{
		return Game::Mio.GetCurrentGameplayPerspectiveMode() == EPlayerMovementPerspectiveMode::SideScroller;
	}
}