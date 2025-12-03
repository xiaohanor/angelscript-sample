event void FBearTrapEvent();
event void FBearTrapTriggeredEvent(TArray<AHazePlayerCharacter> PlayersInVolume);

class ATundra_River_BearTrap : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent VFX_Beartrap;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase BearTrapMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BearTrapTriggerVolume;
	default BearTrapTriggerVolume.CollisionProfileName = n"TriggerOnlyPlayer";

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BearTrapKillVolume;
	default BearTrapKillVolume.CollisionProfileName = n"TriggerOnlyPlayer";

	UPROPERTY(DefaultComponent, Attach = Root)
	UCameraShakeForceFeedbackComponent CamShakeFFComp;

	TArray<AHazePlayerCharacter> PlayersInKillVolume;
	TArray<AHazePlayerCharacter> PlayersInTriggerVolume;
	int NumPlayersInTriggerVolume;

	UPROPERTY()
	FHazePlaySlotAnimationParams PrepMHAnimation;
	UPROPERTY()
	FHazePlaySlotAnimationParams PrepAnimation;
	UPROPERTY()
	FHazePlaySlotAnimationParams OpenMHAnimation;
	UPROPERTY()
	TArray<FHazePlaySlotAnimationParams> TriggerAnimations;
	UPROPERTY()
	TArray<FHazePlaySlotAnimationParams> OpenAnimations;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SpawnTimeLike;
	default SpawnTimeLike.Duration = 1;
	default SpawnTimeLike.Curve.AddDefaultKey(0, 0);
	default SpawnTimeLike.Curve.AddDefaultKey(1, 1);

	UPROPERTY()
	FBearTrapTriggeredEvent OnBearTrapTriggered;
	UPROPERTY()
	FBearTrapEvent OnBearTrapSpawned;

	UPROPERTY()
	float KillTimeSeconds = 0.43;

	UPROPERTY(EditInstanceOnly)
	float TimeToClose = 0.4;

	UPROPERTY(EditInstanceOnly)
	bool bPrepBeartrap = false;

	UPROPERTY()
	bool bPrimed = true;
	
	float KillTimer = 0;
	float ResetTimer = 0;
	float TriggeringTimer = 0;
	int LastTriggerAnimationUsed = -1;
	bool bPlayersHaveClearedAfterTrigger = true;
	bool bResetting = false;
	bool bSpawned = false;
	FVector SpawnedLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BearTrapTriggerVolume.OnComponentBeginOverlap.AddUFunction(this, n"OnPlayerEnterTrigger");
		BearTrapTriggerVolume.OnComponentEndOverlap.AddUFunction(this, n"OnPlayerLeaveTrigger");
		BearTrapKillVolume.OnComponentBeginOverlap.AddUFunction(this, n"OnPlayerEnterKillVolume");
		BearTrapKillVolume.OnComponentEndOverlap.AddUFunction(this, n"OnPlayerLeaveKillVolume");
		OnBearTrapSpawned.AddUFunction(this, n"BearTrapSpawn");
		SpawnTimeLike.BindUpdate(this, n"SpawnTimeLikeUpdate");
		SpawnTimeLike.BindFinished(this, n"SpawnTimeLikeFinished");

		if(bPrepBeartrap)
		{
			PlaySlotAnimation(PrepMHAnimation);
		}
		else
		{
			PlaySlotAnimation(OpenMHAnimation);
		}
	}

	UFUNCTION()
	private void SpawnTimeLikeUpdate(float CurrentValue)
	{
		FVector TargetLocation = Math::VLerp(SpawnedLocation, SpawnedLocation + (FVector::DownVector * 500), FVector(CurrentValue, CurrentValue, CurrentValue));
		SetActorRelativeLocation(TargetLocation);
	}

	UFUNCTION()
	private void SpawnTimeLikeFinished()
	{
		// TODO: Change to disable pooled actor

		DestroyActor();
	}

	UFUNCTION()
	private void BearTrapSpawn()
	{
		SpawnedLocation = ActorLocation;
		KillTimeSeconds = 0.15;
		TriggerBearTrap();
	}

	UFUNCTION()
	private void OnPlayerEnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, const FHitResult&in HitResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		NumPlayersInTriggerVolume += 1;
		PlayersInTriggerVolume.AddUnique(Player);
	}

	UFUNCTION()
	private void OnPlayerLeaveTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                        UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		NumPlayersInTriggerVolume -= 1;
		PlayersInTriggerVolume.RemoveSingleSwap(Player);

		if(NumPlayersInTriggerVolume == 0)
			bPlayersHaveClearedAfterTrigger = true;
	}

	UFUNCTION()
	void OnPlayerEnterKillVolume(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, const FHitResult&in HitResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		PlayersInKillVolume.AddUnique(Player);
	}

	UFUNCTION()
	void OnPlayerLeaveKillVolume(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		PlayersInKillVolume.Remove(Player);
	}

	UFUNCTION(BlueprintCallable)
	void TriggerBearTrap()
	{
		if(TriggeringTimer > 0.0)
			return;

		bPrimed = false;
		bPlayersHaveClearedAfterTrigger = false;

		int RandomTriggerAnim = Math::RandRange(0, TriggerAnimations.Num() - 1);
		LastTriggerAnimationUsed = RandomTriggerAnim;

		if(bSpawned)
		{
			TriggerAnimations[RandomTriggerAnim].StartTime = 0.35;
		}

		PlaySlotAnimation(TriggerAnimations[RandomTriggerAnim]);

		UTundra_River_BearTrap_EffectHandler::Trigger_Trigger(this);

		TriggeringTimer = TriggerAnimations[RandomTriggerAnim].PlayLength;
		KillTimer = KillTimeSeconds;

		OnBearTrapTriggered.Broadcast(PlayersInTriggerVolume);
	}

	UFUNCTION()
	void ResetBearTrap()
	{
		bResetting = true;

		if(LastTriggerAnimationUsed == -1)
			return;

		ResetTimer = OpenAnimations[LastTriggerAnimationUsed].PlayLength;

		PlaySlotAnimation(OpenAnimations[LastTriggerAnimationUsed]);
		UTundra_River_BearTrap_EffectHandler::Trigger_Reset(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bPrimed && NumPlayersInTriggerVolume > 0 && bPlayersHaveClearedAfterTrigger)
		{
			TriggerBearTrap();
		}

		if(TriggeringTimer > 0)
		{
			TriggeringTimer -= DeltaSeconds;
		}
		else
		{
			if(!bPrimed)
			{
				if(!bResetting && NumPlayersInTriggerVolume == 0)
				{
					ResetBearTrap();
				}

				if(ResetTimer > 0)
				{
					ResetTimer -= DeltaSeconds;
				}
				else
				{
					if(bResetting)
					{
						bPrimed = true;
						bResetting = false;
					}
				}
			}
		}

		if(KillTimer > 0)
		{
			KillTimer -= DeltaSeconds;
			if(KillTimer <= 0)
			{
				CamShakeFFComp.ActivateCameraShakeAndForceFeedback();
				if(PlayersInKillVolume.Num() != 0)
				{
					KillPlayer();
				}

				if(bSpawned)
				{
					if(!SpawnTimeLike.IsPlaying())
						SpawnTimeLike.Play();
				}
			}
		}
	}

	UFUNCTION()
	void KillPlayer()
	{
		VFX_Beartrap.Activate();

		bool bKilledAPlayer = false;
		for(auto Player : PlayersInKillVolume)
		{
			Player.KillPlayer();
			bKilledAPlayer = true;
		}

		if(bKilledAPlayer)
		{
			UTundra_River_BearTrap_EffectHandler::Trigger_KillPlayer(this);
		}
	}

	UFUNCTION()
	void TriggerPrep()
	{
		if(bPrepBeartrap)
		{
			bPrepBeartrap = false;
			PlaySlotAnimation(PrepAnimation);
			UTundra_River_BearTrap_EffectHandler::Trigger_AnimationFromFirstMonkeyPrepping(this);
			ResetTimer = PrepAnimation.PlayLength;
		}
	}
};