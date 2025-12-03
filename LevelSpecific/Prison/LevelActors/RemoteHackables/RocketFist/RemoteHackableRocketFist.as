event void FRemoteHackableRocketFistPunchedEvent();

UCLASS(Abstract)
class ARemoteHackableRocketFist : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase FistRoot;

	UPROPERTY(DefaultComponent, Attach = FistRoot, AttachSocket = "Base")
	URemoteHackingResponseComponent RemoteHackingResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableRocketFistCapability");

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedFloatComp;
	default SyncedFloatComp.SyncRate = EHazeCrumbSyncRate::High;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence SpawnAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence HackEnterAnim;

	UPROPERTY(EditDefaultsOnly)
	UBlendSpace HackBS;
	
	UPROPERTY(EditDefaultsOnly)
	FText ChargeTutorialText;

	UPROPERTY(EditDefaultsOnly)
	FText ReleaseTutorialText;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset IdleCamSettings;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset ChargeCamSettings;

	UPROPERTY()
	FRemoteHackableRocketFistPunchedEvent OnPunched;

	FHazeAcceleratedFloat AccSpeed;

	bool bLaunched = false;

	bool bFullySpawned = false;

	UPROPERTY(BlueprintReadOnly)
	float CurrentChargeAlpha = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		RemoteHackingResponseComp.OnHackingStarted.AddUFunction(this, n"HackStarted");

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = SpawnAnim;
		AnimParams.BlendTime = 0.0;
		AnimParams.PlayRate = 0.0;
		FistRoot.PlaySlotAnimation(AnimParams);
	}

	UFUNCTION()
	void Spawn()
	{
		FHazeAnimationDelegate SpawnDelegate;
		SpawnDelegate.BindUFunction(this, n"SpawnAnimFinished");

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = SpawnAnim;
		AnimParams.BlendTime = 0.0;
		FistRoot.PlaySlotAnimation(FHazeAnimationDelegate(), SpawnDelegate, AnimParams);

		SetActorHiddenInGame(false);

		Timer::SetTimer(this, n"EnableHacking", 2.8);

		URemoteHackableRocketFistEffectEventHandler::Trigger_Spawn(this);
	}

	UFUNCTION()
	private void EnableHacking()
	{
		RemoteHackingResponseComp.SetHackingAllowed(true);
	}

	UFUNCTION()
	private void SpawnAnimFinished()
	{
		bFullySpawned = true;

		if (RemoteHackingResponseComp.bHacked)
			HackStarted();
	}

	UFUNCTION()
	private void HackStarted()
	{
		if (!bFullySpawned)
			return;

		FHazeAnimationDelegate HackEnterDelegate;
		HackEnterDelegate.BindUFunction(this, n"HackEnterAnimFinished");

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = HackEnterAnim;
		AnimParams.BlendTime = 0.0;
		FistRoot.PlaySlotAnimation(FHazeAnimationDelegate(), HackEnterDelegate, AnimParams);

		URemoteHackableRocketFistEffectEventHandler::Trigger_Hacked(this);
	}

	UFUNCTION()
	private void HackEnterAnimFinished()
	{
		FHazePlayBlendSpaceParams Params;
		Params.BlendSpace = HackBS;
		Params.BlendTime = 0.0;
		FistRoot.PlayBlendSpace(Params);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bLaunched)
			return;

		FistRoot.SetBlendSpaceValues(0.0, SyncedFloatComp.Value, false);

		CurrentChargeAlpha = SyncedFloatComp.Value;
	}

	void Launch()
	{
		if (bLaunched)
			return;

		bLaunched = true;
		BP_Launched();

		OnPunched.Broadcast();

		URemoteHackableRocketFistEffectEventHandler::Trigger_Punch(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Launched() {}
}