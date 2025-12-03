USTRUCT()
struct FRemoteHackingLaunchEventParams
{
	UPROPERTY()
	float LaunchDuration = 0;

	UPROPERTY()
	float LaunchSpeed = 0;
}

event void FRemoteHackingLaunchEvent(FRemoteHackingLaunchEventParams LaunchParams);
event void FRemoteHackingEvent();

UCLASS(HideCategories = "Activation Debug Cooking Tags Collision")
class URemoteHackingResponseComponent : UTargetableComponent
{
	default TargetableCategory = n"RemoteHacking";

	UPROPERTY(EditAnywhere)
	float Range = 2500.0;

	UPROPERTY(EditAnywhere, Category = "Camera")
	bool bFindCameraOnOwner = true;
	UHazeCameraComponent CurrentCameraComp;

	UPROPERTY(EditInstanceOnly, Category = "Camera")
	AHazeCameraActor ExternalCamera;

	UPROPERTY(EditAnywhere, Category = "Camera")
	float CameraBlendInTime = 1.0;
	UPROPERTY(EditAnywhere, Category = "Camera")
	float CameraBlendOutTime = 1.0;

	UPROPERTY(EditAnywhere, Category = "Camera")
	bool bActivateCameraOnLaunch = false;

	UPROPERTY(EditAnywhere, Category = "Camera")
	bool bTriggerPostProcessTransition = true;

	UPROPERTY(EditAnywhere, Category = "Hacking")
	bool bCanBeDirectlyHacked = true;

	UPROPERTY(EditInstanceOnly, Category = "Hacking")
	TArray<AHazeActor> ConnectedActors;

	UPROPERTY(EditAnywhere, Category = "Hacking")
	UOutlineDataAsset OutlineData = nullptr;

	UPROPERTY(EditAnywhere, Category = "Hacking")
	TArray<FName> CompsToExcludeFromOutline;

	UPROPERTY()
	FRemoteHackingLaunchEvent OnLaunchStarted;

	UPROPERTY()
	FRemoteHackingEvent OnHackingStarted;

	UPROPERTY()
	FRemoteHackingEvent OnHackingStopped;

	UPROPERTY(EditAnywhere)
	bool bAllowHacking = true;

	UPROPERTY(EditAnywhere)
	bool bCanCancel = true;

	UPROPERTY(EditAnywhere)
	bool bTestCollision = false;

	UPROPERTY(EditAnywhere)
	bool bLinkInput = true;

	UPROPERTY(EditAnywhere)
	bool bCanDie = false;

	UPROPERTY(EditAnywhere)
	bool bBlockGameplayAction = true;

	UPROPERTY(EditAnywhere)
	bool bResetMovementOnExit = true;

	UPROPERTY(EditAnywhere)
	FVector ExitLaunchForce = FVector::ZeroVector;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem HackableSystem;

	UPROPERTY(NotEditable, NotVisible)
	UNiagaraComponent HackableSystemComp;

	AHazePlayerCharacter HackingPlayer;

	bool bHacked = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		HackingPlayer = Drone::GetSwarmDronePlayer();

		if (bLinkInput)
			Timer::SetTimer(this, n"LinkInput", 0.1);
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if (!bAllowHacking)
			return false;

		Targetable::ApplyVisibleRange(Query, Range);
		Targetable::ScoreLookAtAim(Query, true, false);

		if (bTestCollision)
			return Targetable::RequireNotOccludedFromCamera(Query);

		return true;
	}

	UFUNCTION()
	void LinkInput()
	{
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		if (HazeOwner != nullptr)
			CapabilityInput::LinkActorToPlayerInput(HazeOwner, HackingPlayer);
		
		for (AHazeActor Actor : ConnectedActors)
			CapabilityInput::LinkActorToPlayerInput(Actor, HackingPlayer);
	}

	void LaunchStarted()
	{
		if (bActivateCameraOnLaunch)
			ActivateCamera();
	}

	UFUNCTION()
	void HackStarted(bool bHackedViaConnectedActor)
	{
		bHacked = true;
		OnHackingStarted.Broadcast();

		if (bHackedViaConnectedActor)
			return;

		for (AHazeActor Actor : ConnectedActors)
		{
			URemoteHackingResponseComponent ResponseComp = URemoteHackingResponseComponent::Get(Actor);
			if (ResponseComp != nullptr)
				ResponseComp.HackStarted(true);
		}

		if (!bActivateCameraOnLaunch)
			ActivateCamera();
	}
	
	void ActivateCamera()
	{
		if (ExternalCamera != nullptr)
		{
			HackingPlayer.ActivateCamera(ExternalCamera, CameraBlendInTime, this, EHazeCameraPriority::High);
		}
		else if (bFindCameraOnOwner)
		{
			CurrentCameraComp = UHazeCameraComponent::Get(Owner);
			if (CurrentCameraComp != nullptr)
				HackingPlayer.ActivateCamera(CurrentCameraComp, CameraBlendInTime, this, EHazeCameraPriority::High);
		}
	}

	void HackStopped(bool bHackedViaConnectedActor)
	{
		bHacked = false;
		OnHackingStopped.Broadcast();

		if (bHackedViaConnectedActor)
			return;

		for (AHazeActor Actor : ConnectedActors)
		{
			URemoteHackingResponseComponent ResponseComp = URemoteHackingResponseComponent::Get(Actor);
			if (ResponseComp != nullptr)
				ResponseComp.HackStopped(true);
		}

		if (CurrentCameraComp != nullptr)
			HackingPlayer.DeactivateCamera(CurrentCameraComp, CameraBlendOutTime);
		else if (ExternalCamera != nullptr)
			HackingPlayer.DeactivateCamera(ExternalCamera, CameraBlendOutTime);

		if (CameraBlendOutTime == 0.0)
		{
			URemoteHackingPlayerComponent PlayerHackingComp = URemoteHackingPlayerComponent::Get(HackingPlayer);
			if (bTriggerPostProcessTransition)
				PlayerHackingComp.bTriggerPostProcessTransition = true;
			
			HackingPlayer.SnapCameraAtEndOfFrame(HackingPlayer.ViewRotation, EHazeCameraSnapType::World);
		}
	}

	UFUNCTION()
	void DeactivateCamera()
	{
		if (CurrentCameraComp != nullptr)
			HackingPlayer.DeactivateCamera(CurrentCameraComp, CameraBlendOutTime);
		else if (ExternalCamera != nullptr)
			HackingPlayer.DeactivateCamera(ExternalCamera, CameraBlendOutTime);
	}

	UFUNCTION(BlueprintCallable)
	void SetHackingAllowed(bool bAllow)
	{
		bAllowHacking = bAllow;
	}

	UFUNCTION()
	void ForceHack()
	{
		URemoteHackingPlayerComponent PlayerComp = URemoteHackingPlayerComponent::Get(Drone::SwarmDronePlayer);
		if (PlayerComp != nullptr)
		{
			PlayerComp.ForceHack(this);
			HackStarted(false);
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsHackingAllowed()
	{
		return bAllowHacking;
	}

	UFUNCTION(BlueprintCallable)
	void UpdateExternalCamera(AHazeCameraActor CameraActor)
	{
		if (bHacked)
		{
			HackingPlayer.DeactivateCamera(ExternalCamera, CameraBlendOutTime);
			HackingPlayer.ActivateCamera(CameraActor, CameraBlendInTime, this, EHazeCameraPriority::Medium);
		}

		ExternalCamera = CameraActor;
	}


	UFUNCTION(BlueprintCallable)
	void UpdateCancelableStatus(bool bCancelable)
	{
		bCanCancel = bCancelable;
	}

	UFUNCTION(BlueprintPure)
	bool IsHacked()
	{
		return bHacked;
	}
}

#if EDITOR
class URemoteHackingScriptVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = URemoteHackingResponseComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        URemoteHackingResponseComponent Comp = Cast<URemoteHackingResponseComponent>(Component);
        if (Comp == nullptr)
            return;

		DrawWireSphere(Comp.WorldLocation, Comp.Range, FLinearColor::Green, 2.0);
    }
}
#endif