event void FTundraBossSetupEvent();
event void FOnIceKingBrokeFloor(int FloorIndexToBreak);
event void FOnTundraBossSetupAttackStarted(ETundraBossSetupAttackAnim Attack);

enum ETundraBossSetupStates
{
	Available,
	NotSpawned,
	Appear,
	Wait,
	ClawAttack,
	ClawAttackSlow,
	DynamicClaw,
	Smash,
	BreakIceFloor,
	SpawnWall,
	SpawnSilhouetteWall,
	Pounce,
	ActivateCameraSEQ,
	Disappear,
	ShrinkArena,
	BreakFromUnderIce
}

class ATundraBossSetup : AHazeActor
{
	//Default Comps
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovingScene;

	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent MovementAudioComp;

	UPROPERTY(DefaultComponent, Attach = MovingScene)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent SmashForeShadowVFX;
	default SmashForeShadowVFX.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"TundraBossSetupCompoundCapability");

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent SmashDamageVolumeRightPaw;
	default SmashDamageVolumeRightPaw.CollisionProfileName = n"TriggerOnlyPlayer";
	default SmashDamageVolumeRightPaw.CollisionEnabled = ECollisionEnabled::NoCollision;
	default SmashDamageVolumeRightPaw.BoxExtent = FVector(615, 225, 150);
	default SmashDamageVolumeRightPaw.RelativeLocation = FVector(910, 0, 0);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent SmashDamageVolumeLeftPaw;
	default SmashDamageVolumeLeftPaw.CollisionProfileName = n"TriggerOnlyPlayer";
	default SmashDamageVolumeLeftPaw.CollisionEnabled = ECollisionEnabled::NoCollision;
	default SmashDamageVolumeLeftPaw.BoxExtent = FVector(260, 225, 150);
	default SmashDamageVolumeLeftPaw.RelativeLocation = FVector(570, -450, 0);
	
	UPROPERTY(DefaultComponent)
	UHazeVoxCharacterTemplateComponent HazeVoxCharacterTemplateComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bStartDisabled = true;

	UPROPERTY()
	TSubclassOf<UDamageEffect> SmashAttackDamageEffect;
	UPROPERTY()
	TSubclassOf<UDeathEffect> SmashAttackDeathEffect;

	//Internal variables
	bool bHasEnteredArena = false;
	UAnimInstanceTundraBossSetupPhase AnimInstance;
	float SmashDamageWindowDuration = 0.25;
	float SmashDamageWindowTimer = 0;
	bool bShouldTickSmashDamageWindowTimer = false;

	UPROPERTY()
	int FloorIndexToBreak = 0;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> PounceLong;
	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> PounceImpact;

	UPROPERTY(EditDefaultsOnly)
	UCameraPointOfInterestClearOnInputSettings ClearOnInputSettings;

	//State manager
	UPROPERTY()
	ETundraBossSetupStates State = ETundraBossSetupStates::NotSpawned;
	UPROPERTY(EditInstanceOnly)
	TArray<ETundraBossSetupStates> AttackQueue;

	int QueueIndex = 0;

	//Events
	UPROPERTY()
	FTundraBossSetupEvent OnSetupPhaseCompleted;
	UPROPERTY()
	FTundraBossSetupEvent VO_PlayWithMe;
	UPROPERTY()
	FTundraBossEvent OnBreachAnimationTriggered;

	//References
	UPROPERTY(EditInstanceOnly)
	ADeathVolume DeathVolume;
	UPROPERTY(EditInstanceOnly)
	ATundraBossSetupIceBreachActor IceBreachActor;
	UPROPERTY()
	ETundraBossSetupAttackAnim CurrentAnimationState;
	UPROPERTY(EditAnywhere)
	AMaterialTransform MaterialTransformReference;
	UPROPERTY(EditInstanceOnly)
	ATundraBossSetupIceFloorNew IceFloorNew;

	//AnimNotifies
	UPROPERTY()
	FOnIceKingBrokeFloor OnTundraBossBrokeFloor;
	UPROPERTY()
	FOnIceKingBrokeFloor OnTundraBossSetupBrokeIceFromUnderIce;
	UPROPERTY()
	FTundraBossSetupEvent OnTundraBossSetupSmashAttackImpact;
	UPROPERTY()
	FTundraBossSetupEvent OnTundraBossSetupClawAttack01Impact;
	UPROPERTY()
	FTundraBossSetupEvent OnTundraBossSetupClawAttack02Impact;
	UPROPERTY()
	FOnTundraBossSetupAttackStarted OnTundraBossSetupAttackStarted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AnimInstance = Cast<UAnimInstanceTundraBossSetupPhase>(SkelMesh.GetAnimInstance());

		OnTundraBossSetupSmashAttackImpact.AddUFunction(this, n"OnTundraBossSmashAttackImpact");
		SmashDamageVolumeRightPaw.OnComponentBeginOverlap.AddUFunction(this, n"HandlePlayerBeginOverlap");
		SmashDamageVolumeLeftPaw.OnComponentBeginOverlap.AddUFunction(this, n"HandlePlayerBeginOverlap");
	}

	UFUNCTION(CrumbFunction)
	void CrumbProgressQueue()
	{
		QueueIndex++;
		if(AttackQueue.IsValidIndex(QueueIndex))
			State = AttackQueue[QueueIndex];
		else
		{
			OnSetupPhaseCompleted.Broadcast();
			State = ETundraBossSetupStates::NotSpawned;
			//SetActorHiddenInGame(true);
		}
	}

	UFUNCTION()
	void SetAnimationState(ETundraBossSetupAttackAnim AnimationState)
	{
		CurrentAnimationState = AnimationState;
	}

	UFUNCTION()
	void SetTundraBossHiddenInGame(bool bTundraBossHidden)
	{
		SetActorHiddenInGame(bTundraBossHidden);

		if(bTundraBossHidden)
		{
			PostProcessing::RemoveInfluencePointsForMesh(SkelMesh);
		}
		else
		{
			PostProcessing::AddInfluencePointsForMesh(SkelMesh);
		}

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bShouldTickSmashDamageWindowTimer)
			return;

		SmashDamageWindowTimer += DeltaSeconds;
		if (SmashDamageWindowTimer >= SmashDamageWindowDuration)
		{
			bShouldTickSmashDamageWindowTimer = false;
			DeactivateDamageVolume();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerSmashAttackVO(FTundraBossPhase01AttackEventData Data)
	{
		UTundraBossSetup_EffectHandler::Trigger_OnSmashAttack(this, Data);
	}

	UFUNCTION()
	private void HandlePlayerBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		if(!Player.HasControl())
			return;

		FPlayerDeathDamageParams DeathParams;
		DeathParams.ImpactDirection = ActorForwardVector;
		Player.DamagePlayerHealth(0.5, DeathParams, SmashAttackDamageEffect, SmashAttackDeathEffect);

		FKnockdown Knockdown;
		Knockdown.Move = ActorForwardVector * 1000;
		Knockdown.Duration = 1;
		Player.ApplyKnockdown(Knockdown);
	}

	UFUNCTION()
	void OnTundraBossSmashAttackImpact()
	{
		ActivateSmashDamageVolumes(0.35);
	}

	void ActivateSmashDamageVolumes(float NewDamageWindowDuration)
	{
		SmashDamageVolumeRightPaw.CollisionEnabled = ECollisionEnabled::QueryOnly;
		SmashDamageVolumeLeftPaw.CollisionEnabled = ECollisionEnabled::QueryOnly;
		SmashDamageWindowTimer = 0;
		bShouldTickSmashDamageWindowTimer = true;
		SmashDamageWindowDuration = NewDamageWindowDuration;
	}

	void DeactivateDamageVolume()
	{
		SmashDamageVolumeRightPaw.CollisionEnabled = ECollisionEnabled::NoCollision;
		SmashDamageVolumeLeftPaw.CollisionEnabled = ECollisionEnabled::NoCollision;
	}

	UFUNCTION(CrumbFunction)
	void CrumbActivateAppear()
	{
		SetAnimationState(ETundraBossSetupAttackAnim::Appear);

		for(auto Player : Game::GetPlayers())
		{
			FHazePointOfInterestFocusTargetInfo TargetInfo;
			TargetInfo.SetFocusToActor(this);
			TargetInfo.WorldOffset = FVector(0, 1000, -1000);
			FApplyPointOfInterestSettings Settings;
			Settings.BlendInAccelerationType = ECameraPointOfInterestAccelerationType::Slow;
			Settings.Duration = 3;
			Settings.ClearOnInput = ClearOnInputSettings;
			Player.ApplyPointOfInterest(this, TargetInfo, Settings, 2, EHazeCameraPriority::High);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbActivateSmashAttack(ETundraBossSetupAttackAnim AttackAnim, FVector AttackLocation, FRotator AttackRotation)
	{
		SmashForeShadowVFX.Activate(true);
		SkelMesh.SetAnimBoolParam(n"SmashReset", true);
		SetActorLocationAndRotation(AttackLocation, AttackRotation);
		SetAnimationState(AttackAnim);
	}

	UFUNCTION(CrumbFunction)
	void CrumbActivateBreakIceAttack(ETundraBossSetupAttackAnim AttackAnim, FTransform AttackTransform, int NewFloorIndexToBreak)
	{
		FloorIndexToBreak = NewFloorIndexToBreak;
		SkelMesh.SetAnimBoolParam(n"BreakFromUnderIceReset", true);
		SetActorTransform(AttackTransform);
		SetAnimationState(AttackAnim);
	}

	UFUNCTION(CrumbFunction)
	void CrumbActivatePounceAttack(ETundraBossSetupAttackAnim AttackAnim, FTransform AttackTransform)
	{
		OnBreachAnimationTriggered.Broadcast();
	}

	UFUNCTION(CrumbFunction)
	void CrumbActivateBreakFromUnderIceAttack(FTransform AttackTransform, int NewFloorIndexToBreak, ETundraBossSetupAttackAnim AnimToPlay)
	{
		FloorIndexToBreak = NewFloorIndexToBreak;
		SkelMesh.SetAnimBoolParam(n"BreakFromUnderIceReset", true);
		SetActorTransform(AttackTransform);
		SetAnimationState(AnimToPlay);
	}
};