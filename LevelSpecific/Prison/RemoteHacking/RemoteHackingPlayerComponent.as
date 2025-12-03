class URemoteHackingPlayerComponent : UActorComponent
{
	AHazePlayerCharacter Player;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset LaunchCamSettings;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> LaunchCamShake;

	UPROPERTY()
	TSubclassOf<UTargetableWidget> TargetableWidget;

	UPROPERTY()
	FRemoteHackingAnimations Animations;

	UPROPERTY()
	UOutlineDataAsset OutlineAsset;

	UPROPERTY()
	UForceFeedbackEffect LaunchForceFeedback;

	UPROPERTY()
	UForceFeedbackEffect StartHackingForceFeedback;

	UPROPERTY()
	UForceFeedbackEffect StopHackingForceFeedback;

	bool bAiming = false;

	bool bHackActive = false;
	bool bTriggerPostProcessTransition = false;

	URemoteHackingResponseComponent CurrentHackingResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	void StartHacking(URemoteHackingResponseComponent ResponseComp)
	{
		if (bHackActive)
			return;

		CurrentHackingResponseComp = ResponseComp;
		bHackActive = true;
	}

	void StopHacking()
	{
		if (!bHackActive)
			return;

		bHackActive = false;
		if (CurrentHackingResponseComp != nullptr)
			CurrentHackingResponseComp.HackStopped(false);

		Player.PlayForceFeedback(StopHackingForceFeedback, false, true, this);

		Player.StopSlotAnimation(BlendTime = 0.0);

		auto PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
		if (PerspectiveModeComp.IsCameraBehaviorEnabled() && !Player.bIsControlledByCutscene)
			AlignPlayerWithCamera();
	}

	UFUNCTION()
	void AlignPlayerWithCamera()
	{
		FRotator Rot = Player.ViewRotation;
		Rot.Roll = 0.0;
		Rot.Pitch = 0.0;
		Player.SetActorRotation(Rot, true);
	}

	void ForceHack(URemoteHackingResponseComponent ResponseComp)
	{
		StartHacking(ResponseComp);
		Player.TeleportActor(ResponseComp.WorldLocation, ResponseComp.WorldRotation, FInstigator(this, n"ForceHack"));
	}

	void TriggerPostProcessTransition()
	{
		bTriggerPostProcessTransition = true;
	}
}