
struct FPrisonBossVolleyProjectileWaveData
{
	bool bIsActive = false;
	TArray<APrisonBossVolleyProjectile> Projectiles;
}

UCLASS(Abstract)
class UCharacter_Boss_Prison_DarkMio_VolleyProjectile_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void VolleyProjectileImpact(FPrisonBossVolleyImpactData Data){}

	UFUNCTION(BlueprintEvent)
	void VolleyWaveDispersed(){}

	/* END OF AUTO-GENERATED CODE */

	APrisonBoss DarkMio;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter VolleyMultiEmitter;

	TArray<FPrisonBossVolleyProjectileWaveData> ProjectileWaveDatas;
	default ProjectileWaveDatas.SetNum(2);

	UPROPERTY(BlueprintReadOnly)
	int ProjectileWaveIndex = 0;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		DarkMio = Cast<APrisonBoss>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = DarkMio;
		
		if(EmitterName == n"VolleyMultiEmitter")
			bUseAttach = false;
		
		return true;
	}	

	UFUNCTION(BlueprintEvent)
	void SpawnVolley(FPrisonBossVolleySpawnData Data)
	{
		ProjectileWaveDatas[ProjectileWaveIndex].bIsActive = true;
		ProjectileWaveDatas[ProjectileWaveIndex].Projectiles = Data.Projectiles;

		const bool bIsLargeCluster = Data.Projectiles.Num() > 10;
		OnVolleySpawned(ProjectileWaveIndex, bIsLargeCluster);
		++ProjectileWaveIndex;

		ProjectileWaveIndex %= 2;
	}

	UFUNCTION(BlueprintEvent)
	void OnVolleySpawned(int WaveIndex, bool bIsLargeCluster) {};

	UFUNCTION(BlueprintEvent)
	void OnVolleyEnded(int WaveIndex) {};

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		for(int i = 0; i < 2; ++i)
		{
			FPrisonBossVolleyProjectileWaveData& ProjectileWaveData = ProjectileWaveDatas[i];
			if(ProjectileWaveData.bIsActive)
			{	
				for(int j = ProjectileWaveData.Projectiles.Num() - 1; j >= 0; --j)
				{
					APrisonBossVolleyProjectile Projectile = ProjectileWaveData.Projectiles[j];
					if(!IsValid(Projectile))			
						ProjectileWaveData.Projectiles.RemoveAtSwap(j);				
				}

				const int NumProjectiles = ProjectileWaveData.Projectiles.Num();
				if(NumProjectiles == 0)
				{
					ProjectileWaveData.bIsActive = false;
					OnVolleyEnded(i);
					return;
				}

				TArray<FAkSoundPosition> VolleyProjectilePositions;
				VolleyProjectilePositions.SetNum(NumProjectiles);

				for(int j = 0; j < NumProjectiles; ++j)
				{
					APrisonBossVolleyProjectile Projectile = ProjectileWaveData.Projectiles[j];
					VolleyProjectilePositions[j].SetPosition(Projectile.ActorLocation);		
				}

				VolleyMultiEmitter.SetMultiplePositions(VolleyProjectilePositions, AkMultiPositionType::MultiSources);
			}
		}
			
	}
}