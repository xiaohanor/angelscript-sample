
UCLASS(Abstract)
class UIsland_Rift_RedBlueForceField_GrenadeLock_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	AIslandGrenadeLock RootLock;
	AIslandGrenadeLockListener LockListener;

	TArray<AIslandGrenadeLock> Locks;
	TArray<UHazeAudioEmitter> LockEmitters;
	TArray<FAkSoundPosition> LocksMultiPositions;

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;
		bUseAttach = false;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		RootLock = Cast<AIslandGrenadeLock>(HazeOwner);
		LockListener = RootLock.GrenadeListener;		
		LockListener.GetLocksUsableByPlayer(RootLock.UsableByPlayer, Locks);
		
		LocksMultiPositions.SetNum(Locks.Num());

		for(auto _ : Locks)
		{
			FHazeAudioEmitterAttachmentParams Params;
			Params.Owner = HazeOwner;
			Params.Attachment = RootLock.Root;
			Params.Instigator = this;
			Params.bCanAttach = false;
			
			auto LockEmitter = Audio::GetPooledEmitter(Params);
			LockEmitters.Add(LockEmitter);

			LockEmitter.SetAttenuationScaling(10000);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for(auto Lock : Locks)
		{
			Lock.OnActivated.AddUFunction(this, n"OnLockActivatedInternal");
			Lock.OnDeactivated.AddUFunction(this, n"OnLockDeactivatedInternal");

			Lock.ReflectComp.OnBulletReflect.AddUFunction(this, n"OnBulletImpactInternal");
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		LocksMultiPositions.Reset(Locks.Num());
		for(int i = 0; i < Locks.Num(); ++i)
		{
			if(!Locks[i].IsForceFieldDeactivated())
			{
				LocksMultiPositions.Add(FAkSoundPosition(Locks[i].ActorLocation));
				LockEmitters[i].AudioComponent.SetWorldLocation(Locks[i].ActorLocation);
			}
		}

		DefaultEmitter.AudioComponent.SetMultipleSoundPositions(LocksMultiPositions);
	}

	UFUNCTION()
	void OnLockActivatedInternal(AIslandGrenadeLock Lock)
	{
		int LockIndex = Locks.FindIndex(Lock);
		auto LockEmitter = LockEmitters[LockIndex];	

		OnLockActivated(LockEmitter);
	}

	UFUNCTION()
	void OnLockDeactivatedInternal(AIslandGrenadeLock Lock)
	{
		int LockIndex = Locks.FindIndex(Lock);
		auto LockEmitter = LockEmitters[LockIndex];
	
		OnLockDeactivated(LockEmitter);
	}

	UFUNCTION()
	void OnBulletImpactInternal(AIslandRedBlueWeaponBullet Bullet, AActor Actor, FVector ReflectionPoint)
	{	
		AIslandGrenadeLock Lock = Cast<AIslandGrenadeLock>(Actor);
		int LockIndex = Locks.FindIndex(Lock);
		auto LockEmitter = LockEmitters[LockIndex];	

		OnBulletImpact(LockEmitter);
	}

	UFUNCTION(BlueprintEvent)
	void OnLockActivated(UHazeAudioEmitter LockEmitter) {};

	UFUNCTION(BlueprintEvent)
	void OnLockDeactivated(UHazeAudioEmitter LockEmitter) {};

	UFUNCTION(BlueprintEvent)
	void OnBulletImpact(UHazeAudioEmitter LockEmitter) {};

	UFUNCTION(BlueprintPure)
	bool IsRedLock()
	{
		return RootLock.UsableByPlayer == EHazePlayer::Mio;
	}

	UFUNCTION(BlueprintPure)
	bool AnyLockActive()
	{
		for(auto& Lock : Locks)
		{
			if(Lock.IsForceFieldDeactivated())
				return true;
		}

		return false;
	}

}