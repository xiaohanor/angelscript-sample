event void FRobotMouseBiteCable();

UCLASS(Abstract)
class ARemoteHackableRobotMouse : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeOffsetComponent OffsetComp;

	UPROPERTY(DefaultComponent, Attach = OffsetComp)
	USceneComponent MouseRoot;

	UPROPERTY(DefaultComponent, Attach = MouseRoot)
	UHazeSkeletalMeshComponentBase SkelMeshComp;

	UPROPERTY(DefaultComponent, Attach = MouseRoot)
	URemoteHackingResponseComponent HackableComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedSplinePositionComponent SyncedSplinePosComp;
	default SyncedSplinePosComp.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableRobotMouseCapability");

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 5000.0;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor FallCamera;

	UPROPERTY()
	FRemoteHackingEvent OnHackLaunchStarted;

	UPROPERTY()
	FRemoteHackingEvent OnHackStarted;

	UPROPERTY()
	FRobotMouseBiteCable OnBiteStarted;
	
	UPROPERTY()
	FRemoteHackingEvent OnHackStopped;

	UPROPERTY(EditInstanceOnly)
	ASplineActor FollowSpline;
	UHazeSplineComponent FollowSplineComp;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence FallAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence UnhackedAnim;

	bool bIdling = true;
	float IdleSplineDist = 0.0;

	bool bSideScrolling = true;

	bool bFallen = false;
	bool bFullyFallen = false;

	bool bForwardBlocked = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		if (FollowSpline != nullptr)
			FollowSplineComp = FollowSpline.Spline;

		HackableComp.OnLaunchStarted.AddUFunction(this, n"HackLaunch");
		HackableComp.OnHackingStarted.AddUFunction(this, n"Hacked");
		HackableComp.OnHackingStopped.AddUFunction(this, n"HackStopped");
	}

	UFUNCTION()
	private void HackLaunch(FRemoteHackingLaunchEventParams LaunchParams)
	{
		OnHackLaunchStarted.Broadcast();
	}

	UFUNCTION()
	private void Hacked()
	{
		bIdling = false;
		OnHackStarted.Broadcast();

		URemoteHackableMouseEffectEventHandler::Trigger_Hacked(this);
	}
	
	UFUNCTION()
	private void HackStopped()
	{
		HackableComp.SetHackingAllowed(false);
		Game::Mio.DeactivateCamera(FallCamera, 1.0);
		Game::Mio.RemoveCancelPromptByInstigator(this);

		OnHackStopped.Broadcast();
		
		bIdling = true;

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = UnhackedAnim;
		AnimParams.bLoop = true;
		SkelMeshComp.PlaySlotAnimation(AnimParams);

		URemoteHackableMouseEffectEventHandler::Trigger_UnHacked(this);
	}

	UFUNCTION()
	void SetSideScrollerMode(bool bActive)
	{
		bSideScrolling = bActive;
	}

	UFUNCTION()
	void Fall()
	{
		if (HasControl())
			CrumbFall();
	}

	UFUNCTION(CrumbFunction)
	void CrumbFall()
	{
		bFallen = true;

		HackableComp.DeactivateCamera();
		Game::Mio.ActivateCamera(FallCamera, 1.0, this, EHazeCameraPriority::High);

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = FallAnim;
		PlaySlotAnimation(AnimParams);

		Timer::SetTimer(this, n"FallFinished", 1.5);

		URemoteHackableMouseEffectEventHandler::Trigger_Fall(this);
	}

	UFUNCTION()
	private void FallFinished()
	{
		HackableComp.UpdateCancelableStatus(true);
		Game::Mio.ShowCancelPrompt(this);
		bFullyFallen = true;
	}

	UFUNCTION()
	void SetForwardBlocked(bool bBlocked)
	{
		bForwardBlocked = bBlocked;
		if (!bForwardBlocked)
			OnBiteStarted.Broadcast();
	}

	UFUNCTION()
	void BiteCable()
	{
		SetAnimBoolParam(n"BiteCable", true);

		URemoteHackableMouseEffectEventHandler::Trigger_BiteCable(this);
	}

	UFUNCTION(BlueprintPure)
	bool IsStruggling() const
	{
		if (!HackableComp.bHacked)
			return false;

		if (!bFullyFallen)
			return false;

		UHazeMovementComponent MioMoveComp = UHazeMovementComponent::Get(Game::Mio);
		return MioMoveComp.SyncedLocalSpaceMovementInputForAnimationOnly.Size() > 0.2;
	}
}