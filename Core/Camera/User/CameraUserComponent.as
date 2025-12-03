//#restrict usage allow Core.Camera.*

event void FOnCameraSnapEvent();
event void FOnOtherPlayerFullscreenCutscene();
event void FOnCameraUserReset();
event void FOnUpdateHideOnOverlap();

enum EHazeCameraSnapType
{
	None,		// Do not snap camera
	World,		// Snap camera in given world direction
	BehindUser, // Snap camera in given direction in user's owner space
};



class UCameraUserComponent : UHazeCameraUserComponent
{
	access CameraControl = protected, UCameraControlCapability;

	UPROPERTY(Category = "Debug")
	TSubclassOf<UDebugCameraControlsWidget> DebugCameraWidgetClass;

	UPROPERTY(EditAnywhere, Category = "Settings")
	protected UCameraUserSettings DefaultUserSettings;

	UCameraUserSettings UserSettings;
	UCameraImpulseSettings ImpulseSettings;
	UControlRotationSettings ControlRotationSettings;

	TArray<FInstigator> ReplicatedCameraInstigators;
	UCameraComponent UsedCameraForControlSync;
	bool bCameraSyncBlocked = false;

	FOnOtherPlayerFullscreenCutscene OnOtherPlayerFullscreenCutscene;
	FOnCameraUserReset OnReset;
	FOnCameraSnapEvent OnSnapped;
	FOnUpdateHideOnOverlap UpdateHideOnOverlap;

	FHazeAcceleratedFloat TurnRatePitch;
	FHazeAcceleratedFloat TurnRateYaw;

	int32 DisableTicksLeft = 5;

	TArray<UObject> ControlCameraWithoutScreenSizeAllower;

	AHazePlayerCharacter PlayerOwner;

	private FHazeAcceleratedRotator AcceleratedSyncedRotation;
	
	EHazeCameraSnapType DeferredSnap = EHazeCameraSnapType::None;
	FVector DeferredSnapCameraDirection = FVector::ZeroVector;
	private bool bSnapOnFirstUpdate = true;
	
	private TArray<FInstigator> WantToAimSet;
	private FInstigator CameraYawAxisInstigator;

	private uint OverrideParentLocationFrame = 0;
	private FVector OverrideParentLocation = FVector::ZeroVector;
	private FInstigator OverrideParentLocationInstigator;

	//private FRotator PrevPoiRotation = FRotator::ZeroRotator;
	//private bool bHasPrevPoiRotation = false;

	private FVector2D InputDuration = FVector2D::ZeroVector;
	private bool bUserHasAppliedInput = false;
	private bool bHasAppliedDesiredRotation = false;
	
	private FInstigator InputInstigator;
	private TArray<FInstigator> DebugDesiredRotationInstigator;

	#if !RELEASE
	FString DebugInputInstigator = "";
	FString DebugDesiredRotationInstigators = "";
	#endif

	private UHazeCrumbSyncedCameraComponent CameraSyncComponent;
	private UCameraFollowMovementFollowDataComponent MovementFollowData;
	
	#if !RELEASE
	private bool bDebugValidateCanReceiveInput = true;
	private UHazeCameraScrubbableDebugComponent ScrubbableComponent;
	#endif

	private FRotator PreviousLocalDesiredRotation;
	private bool bDesiredRotationChangedLastFrame;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		CameraSyncComponent = UHazeCrumbSyncedCameraComponent::Get(PlayerOwner);
		MovementFollowData = UCameraFollowMovementFollowDataComponent::Get(PlayerOwner);
		PlayerOwner.ApplySettings(DefaultUserSettings, this, EHazeSettingsPriority::Defaults);
		UserSettings = UCameraUserSettings::GetSettings(PlayerOwner);

		const FRotator TargetRate = DefaultCameraTurnRate;
		TurnRatePitch.Value = TargetRate.Pitch;
		TurnRateYaw.Value = TargetRate.Yaw;

		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		ImpulseSettings = UCameraImpulseSettings::GetSettings(HazeOwner);
		ControlRotationSettings = UControlRotationSettings::GetSettings(HazeOwner);
	
		#if !RELEASE
		ScrubbableComponent = UHazeCameraScrubbableDebugComponent::GetOrCreate(PlayerOwner);
		#endif

		#if EDITOR
		if(CanRerunFrames())
		{
			TemporalLog::RegisterExtender(this, HazeOwner, "Camera", n"CameraUserDebugTemporalLogRerunExtender");
		}
		#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraComponent Camera)
	{
		// Every time we activate a new camera, we make the desired rotation to be the current camera view	
		// so we feel the transition less
		SetDesiredRotation(GetViewRotation(), Camera);
	}

    UFUNCTION(BlueprintOverride)
    void OnPreUpdate(EHazeTickGroup TickGroup, float DeltaTime)
    {
		// We need to snap the camera after the initial movement has happen
		// so we guarantee that the camera end up at the correct location and rotation 
		if(bSnapOnFirstUpdate && TickGroup == PostMovementTickGroup)
		{
			bSnapOnFirstUpdate = false;
			SnapCamera(false);
		}

		// Apply the deferred snap
		if (DeferredSnap != EHazeCameraSnapType::None && TickGroup == EndOfFrameTickGroup)
		{
			// Snap camera before updating. This means all other capabilities etc has had a chance to position the user,
			// apply settings, desired rotation and anything else which can influence the camera before snap takes place.
			FVector Direction = DeferredSnapCameraDirection;
			if ((DeferredSnap == EHazeCameraSnapType::BehindUser) && (Owner != nullptr))
				Direction = Owner.ActorTransform.TransformVector(Direction);

			SnapCamera(Direction);
		}

        // if(HasControl())
        // {
        //     bHasPrevPoiRotation = false;
        //     if(GetPointOfInterestTargetRotation(PrevPoiRotation))
        //     {
        //         bHasPrevPoiRotation = true;
		// 		DebugDesiredRotationInstigator.Add(n"POI");
        //         SetDesiredRotationInternal(PrevPoiRotation);
        //     }
        // }

		#if !RELEASE
		{
			// We need to ensure that all camera input is made before the we move
			// else, that input will not be applied to the camera this frame
			if(TickGroup == PostMovementTickGroup)
				bDebugValidateCanReceiveInput = false;
			else
				bDebugValidateCanReceiveInput = true;
		}
		#endif
    }

	UFUNCTION(BlueprintOverride)
	void OnPostUpdate(EHazeTickGroup TickGroup, float DeltaTime)
	{
		// The follow movement is now applied to the current view
		// so we reset it here.
		MovementFollowData.CameraFollowMovementData = FHazeFollowMovementData();

		// Before gameplay
		if (TickGroup == PostMovementTickGroup)
		{
			const float BlendDuration = IsAiming() ? 0.0 : 1.0;
			const FRotator TargetRate = GetTargetTurnRate();
			TurnRatePitch.AccelerateTo(TargetRate.Pitch, BlendDuration, DeltaTime);
			TurnRateYaw.AccelerateTo(TargetRate.Yaw, BlendDuration, DeltaTime);
		}
		
		// End of Frame
		else if (TickGroup == EndOfFrameTickGroup)
		{
			// If nothing has updated the desired rotation this frame,
			// we update the desired rotation to match the current view
			//if(CanControlCamera() && HasControl())
			if(HasControl())
			{
				SetDesiredRotation(GetActiveCameraRotation(), n"Internal Non Controlled");
			}

			// clear nullptr for custom aim sensitivity
			for (int32 i = WantToAimSet.Num() - 1; i >= 0; --i)
			{
				if (!WantToAimSet[i].IsValid())
				{
					WantToAimSet.RemoveAtSwap(i);
				}
			}

			// Clear the user input
			if(!bUserHasAppliedInput)
				InputDuration = FVector2D::ZeroVector;
			bUserHasAppliedInput = false;
			bHasAppliedDesiredRotation = false;

			PreviousLocalDesiredRotation = InternalLocalDesiredRotation;

			// Update the network synced values
			if(HasControl())
			{
				// When the active camera changes, we need to transition the synced desired rotation
				// This prevents the new camera's desired rotation values being used while the previous camera
				// is still active on the remote side
				UCameraComponent CurrentActiveCamera = GetActiveCamera();
				if (UsedCameraForControlSync != CurrentActiveCamera)
				{
					CrumbTransitionCameraPosition();
					UsedCameraForControlSync = CurrentActiveCamera;
				}

				// Send updated desired rotation values for network sync
				InternalLocalDesiredRotation = GetClampedLocalRotation(InternalLocalDesiredRotation);
				if (ReplicatedCameraInstigators.Num() > 0 && (CanControlCamera() || CurrentActiveCamera.HasTag(n"AllowSyncStaticCameraRotation")))
				{
					CameraSyncComponent.UpdateValues(InternalLocalDesiredRotation, PlayerOwner.ViewRotation);
					if (bCameraSyncBlocked)
					{
						bCameraSyncBlocked = false;
						CameraSyncComponent.UnblockSync(n"NonControlledCamera");
					}
				}
				else
				{
					if (!bCameraSyncBlocked)
					{
						bCameraSyncBlocked = true;
						CameraSyncComponent.BlockSync(n"NonControlledCamera");
					}
				}
			}
			else
			{
				if (CanControlCamera())
				{
					// User controlled camera folows desired rotation synced from the control side
					FRotator ReplicatedRotation = InternalLocalDesiredRotation;
					bool bHasDesiredRotation = CameraSyncComponent.GetDesiredRotation(ReplicatedRotation);
					InternalLocalDesiredRotation = ReplicatedRotation;

#if !RELEASE
					TEMPORAL_LOG(CameraSyncComponent).Section(f"{TickGroup :n}")
						.Value("bHasDesiredRotation", bHasDesiredRotation)
					;
#endif
				}
				else
				{
					// Other cameras have desired rotation set to the view rotation
					SetDesiredRotation(GetActiveCameraRotation(), n"Internal Remote No Sync");
				}

#if !RELEASE
				TEMPORAL_LOG(CameraSyncComponent).Section(f"{TickGroup :n}")
					.Value("CanControlCamera", CanControlCamera())
					.Value("CrumbCount", CameraSyncComponent.DebugGetCrumbsInTrail())
					.Value("HasUsableData", CameraSyncComponent.HasUsableDataInCrumbTrail())
					.Value("DesiredRotation", InternalLocalDesiredRotation)
				;
#endif
			}

			bDesiredRotationChangedLastFrame = PreviousLocalDesiredRotation != InternalLocalDesiredRotation;

			// Debug
			#if !RELEASE
			{
				DebugInputInstigator = InputInstigator.ToString();
				
				DebugDesiredRotationInstigators = "None";
				if(DebugDesiredRotationInstigator.Num() > 0)
				{
					DebugDesiredRotationInstigators = "";
					for(auto It : DebugDesiredRotationInstigator)
					{
						DebugDesiredRotationInstigators += It.ToString() + " | ";
					}
					
				}
			}
			#endif
			
			InputInstigator = FInstigator();
			DebugDesiredRotationInstigator.Reset();

			// Ignore input for a few ticks while when starting up, since we can get delayed input 
			// e.g. from mouse when starting PIE with the "game gets mouse control" setting.
			if (DisableTicksLeft > 0)
				DisableTicksLeft--;

			// Clear last frame's teleportation info
			if (bTeleportedLastFrame)
			{
				if (LastTeleportFrame < Time::FrameNumber)
				{
					LastTeleportFrame = 0;
					bTeleportedLastFrame = false;
				}
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbTransitionCameraPosition()
	{
		CameraSyncComponent.TransitionSync(n"CameraChanged");
	}

	UFUNCTION(BlueprintOverride, NotBlueprintCallable)
	protected void PrepareForUpdater(const UHazeCameraComponent Camera, FHazeCameraUpdaterInitInfo& UpdaterInfo) const
	{
		const FHazeFollowMovementData& CameraFollow = MovementFollowData.CameraFollowMovementData;
		UpdaterInfo.InheritMovementDelta = CameraFollow.MovementDelta;
		UpdaterInfo.InheritMovementTeleportationDelta = CameraFollow.TeleportationDelta;
		UpdaterInfo.InheritMovementRotationDelta = CameraFollow.DeltaRotation;
	}

	UFUNCTION(BlueprintOverride, NotBlueprintCallable)
	protected void GetInternalControlRotationOverride(FHazeCameraControlRotation& TargetRotation) const
	{
		if (ControlRotationSettings.bOverrideControlRotation)
		{
			TargetRotation.Rotation = ControlRotationSettings.ControlRotationOverride;
			TargetRotation.InterpSpeed = -1;
		}
		else
		{
			TargetRotation.InterpSpeed = ControlRotationSettings.ControlRotationInterpSpeed;
		}
	}

	/** Returns the diff from what you wanted it to be. 
	 * It can diff if you try to set the desired rotation outside what clamps allows it to be.
	 * but when you stop setting the desired rotation, it will snap to the closest valid clamped rotation
	 */
	void SetDesiredRotation(const FRotator& WorldRotation, FInstigator Instigator)
	{	
		DebugDesiredRotationInstigator.Add(Instigator);
		SetDesiredRotationInternal(WorldRotation);
	}

	void SetInputRotation(const FRotator& WorldRotation, FInstigator Instigator)
	{	
		InputInstigator = Instigator;
		bUserHasAppliedInput = true;
		DebugDesiredRotationInstigator.Add(Instigator);
		SetDesiredRotationInternal(WorldRotation);
	}

	void SetDesiredLocalRotation(const FRotator& LocalRotation, FInstigator Instigator)
	{	
		DebugDesiredRotationInstigator.Add(Instigator);
		
		bHasAppliedDesiredRotation = true;
		InternalLocalDesiredRotation = GetPitchClampedLocalRotation(LocalRotation);
	}

	// bool GetPreviousPointOfInterestRotation(FRotator& Out) const
    // {
    //     if(!bHasPrevPoiRotation)
    //         return false;
        
    //     Out = PrevPoiRotation;
    //     return true;
    // }

	private void SetDesiredRotationInternal(FRotator WorldRotation)
	{	
		bHasAppliedDesiredRotation = true;
		InternalLocalDesiredRotation = WorldToLocalRotation(WorldRotation);
		InternalLocalDesiredRotation = GetPitchClampedLocalRotation(InternalLocalDesiredRotation);
	}

	void AddUserInputDeltaRotation(FRotator LocalDeltaRotation, FInstigator Instigator)
	{
		#if !RELEASE
		devCheck(!HasAppliedUserInput(), f"AddUserInputDeltaRotation has already been called by {InputInstigator}. Make sure you check 'CanApplyUserInput'");
		devCheck(bDebugValidateCanReceiveInput, f"AddUserInputDeltaRotation by {InputInstigator}. is not allowed here. Make sure you call it in a tick group before gameplay");
		#endif

		InputInstigator = Instigator;
		bUserHasAppliedInput = true;

		AddDesiredRotationInternal(LocalDeltaRotation);
	}

	void AddDesiredRotation(FRotator LocalDeltaRotation, FInstigator Instigator)
	{
		DebugDesiredRotationInstigator.Add(Instigator);
		AddDesiredRotationInternal(LocalDeltaRotation);
	}

	private void AddDesiredRotationInternal(FRotator DesiredLocalRotationDelta)
	{
		FRotator LocalRotationDelta = DesiredLocalRotationDelta;

		// We always have to clamp pitch
		const FRotator WantedRot = InternalLocalDesiredRotation + LocalRotationDelta;
		const FRotator ClampedRot = GetPitchClampedLocalRotation(WantedRot);
		FRotator Diff = WantedRot - ClampedRot;
		LocalRotationDelta -= Diff;

		// You need to apply pitch in camera space and yaw in base rotation space when using quats 
		FQuat NewQuatRot = FQuat(FRotator(0.0, LocalRotationDelta.Yaw,0.)) * FQuat(InternalLocalDesiredRotation) * FQuat(FRotator(LocalRotationDelta.Pitch,0.0, LocalRotationDelta.Roll));
		
		InternalLocalDesiredRotation = FRotator::MakeFromXZ(NewQuatRot.ForwardVector, ActiveCameraYawAxis);
		bHasAppliedDesiredRotation = true;
	}

	/** This will get the cameras turn rate from from the active settings */
	FRotator GetCameraTurnRate() const property
	{		
		FRotator TurnRate = FRotator(TurnRatePitch.Value, TurnRateYaw.Value, 0.0);	
		auto Settings = GetCameraSettings();
		TurnRate *= Settings.SensitivityFactor.Value;
		if(PlayerOwner == nullptr)
			return TurnRate;

		if (IsAiming())
		{
			TurnRate.Yaw *= PlayerOwner.GetSensitivity(EHazeSensitivityType::AimYaw) * Settings.SensitivityFactorYaw.Value;
			TurnRate.Pitch *= PlayerOwner.GetSensitivity(EHazeSensitivityType::AimPitch) * Settings.SensitivityFactorPitch.Value;
		}
		else
		{
			TurnRate.Yaw *= PlayerOwner.GetSensitivity(EHazeSensitivityType::Yaw) * Settings.SensitivityFactorYaw.Value;
			TurnRate.Pitch *= PlayerOwner.GetSensitivity(EHazeSensitivityType::Pitch) * Settings.SensitivityFactorPitch.Value;
		}

		if (!PlayerOwner.IsUsingGamepad())
		{
			TurnRate.Yaw *= PlayerOwner.GetSensitivity(EHazeSensitivityType::MouseYaw);
			TurnRate.Pitch *= PlayerOwner.GetSensitivity(EHazeSensitivityType::MousePitch);
		}

		return TurnRate;
	}

	/**
	 * Get the base sensitivity factor for anything that wants to obey camera sensitivity but is not using the player camera.
	 */
	FRotator GetCameraBaseSensitivity() const
	{
		auto Settings = GetCameraSettings();
		FRotator TurnRate = FRotator(TurnRatePitch.Value, TurnRateYaw.Value, 0.0);	

		if (IsAiming())
		{
			TurnRate.Yaw *= PlayerOwner.GetSensitivity(EHazeSensitivityType::AimYaw) * Settings.SensitivityFactorYaw.Value;
			TurnRate.Pitch *= PlayerOwner.GetSensitivity(EHazeSensitivityType::AimPitch) * Settings.SensitivityFactorPitch.Value;
		}
		else
		{
			TurnRate.Yaw *= PlayerOwner.GetSensitivity(EHazeSensitivityType::Yaw) * Settings.SensitivityFactorYaw.Value;
			TurnRate.Pitch *= PlayerOwner.GetSensitivity(EHazeSensitivityType::Pitch) * Settings.SensitivityFactorPitch.Value;
		}

		if (!PlayerOwner.IsUsingGamepad())
		{
			TurnRate.Yaw *= PlayerOwner.GetSensitivity(EHazeSensitivityType::MouseYaw);
			TurnRate.Pitch *= PlayerOwner.GetSensitivity(EHazeSensitivityType::MousePitch);
		}

		return TurnRate;
	}

	/**
	 * Get the target sensitivity factor for anything that wants to obey camera sensitivity but is not using the player camera.
	 */
	FRotator GetCameraTargetSensitivity() const
	{
		FRotator TurnRate = GetNonControlledTargetTurnRate();

		if (IsAiming())
		{
			TurnRate.Yaw *= PlayerOwner.GetSensitivity(EHazeSensitivityType::AimYaw);
			TurnRate.Pitch *= PlayerOwner.GetSensitivity(EHazeSensitivityType::AimPitch);
		}
		else
		{
			TurnRate.Yaw *= PlayerOwner.GetSensitivity(EHazeSensitivityType::Yaw);
			TurnRate.Pitch *= PlayerOwner.GetSensitivity(EHazeSensitivityType::Pitch);
		}

		if (!PlayerOwner.IsUsingGamepad())
		{
			TurnRate.Yaw *= PlayerOwner.GetSensitivity(EHazeSensitivityType::MouseYaw);
			TurnRate.Pitch *= PlayerOwner.GetSensitivity(EHazeSensitivityType::MousePitch);
		}

		return TurnRate;
	}

	/**
	 * Get the base delta rotation from the given input, based on current camera sensitivity.
	 */
	FRotator CalculateBaseDeltaRotationFromSensitivity(FVector2D AxisInput, float DeltaTime, float SensitivityFactor = 1.0, bool bUseTargetSensitivity = false) const
	{
		FRotator BaseSensitivity;
		if (bUseTargetSensitivity)
			BaseSensitivity = GetCameraTargetSensitivity();
		else
			BaseSensitivity = GetCameraBaseSensitivity();

		FRotator DeltaRotation = FRotator::ZeroRotator;
		if (PlayerOwner.IsUsingGamepad())
		{
			DeltaRotation.Yaw = AxisInput.X * DeltaTime * BaseSensitivity.Yaw * SensitivityFactor;
			DeltaRotation.Pitch = AxisInput.Y * DeltaTime * BaseSensitivity.Pitch * SensitivityFactor;
		}
		else
		{
			// We cant use delta time on mouse input. But without this, the input becomes to big.
			const float MouseMultiplier = 0.01;
			
			DeltaRotation.Yaw = AxisInput.X * BaseSensitivity.Yaw * MouseMultiplier * SensitivityFactor;
			DeltaRotation.Pitch = AxisInput.Y * BaseSensitivity.Pitch * MouseMultiplier * SensitivityFactor;
		}

		return DeltaRotation;
	}

	protected FRotator GetTargetTurnRate() const property
	{
		if (!CanControlCamera())
		  	return FRotator::ZeroRotator;

		// if (InputControllers.Num() == 0)
		// 	return FRotator::ZeroRotator;	

		bool bIsUsingGamepad = PlayerOwner.IsUsingGamepad();

		FRotator TurnRate;
		if (IsAiming())
		{
			TurnRate = DefaultAimCameraTurnRate;
			if (!bIsUsingGamepad)
				TurnRate.Pitch = TurnRate.Yaw; // same base turn rate in pitch and yaw when using mouse
		}
		else
		{
			TurnRate = DefaultCameraTurnRate;
			if (!bIsUsingGamepad)
				TurnRate.Pitch = TurnRate.Yaw; // same base turn rate in pitch and yaw when using mouse
		}

		TurnRate.Roll = 0.0;
		return TurnRate;	
	}

	protected FRotator GetNonControlledTargetTurnRate() const property
	{
		bool bIsUsingGamepad = PlayerOwner.IsUsingGamepad();

		FRotator TurnRate;
		if (IsAiming())
		{
			TurnRate = DefaultAimCameraTurnRate;
			if (!bIsUsingGamepad)
				TurnRate.Pitch = TurnRate.Yaw; // same base turn rate in pitch and yaw when using mouse
		}
		else
		{
			TurnRate = DefaultCameraTurnRate;
			if (!bIsUsingGamepad)
				TurnRate.Pitch = TurnRate.Yaw; // same base turn rate in pitch and yaw when using mouse
		}

		TurnRate.Roll = 0.0;
		return TurnRate;	
	}

	void SetYawAxis(FVector Axis, FInstigator Instigator, FVector RightVector = FVector::ZeroVector)
	{
		if (!RightVector.IsZero())
		{
			FQuat NewRotation = FQuat::MakeFromYZ(RightVector, Axis);
			UpdateInternalBaseRotation(NewRotation, Instigator);
			return;
		}

		FQuat NewRotation = CalculateBaseRotationFromYawAxis(Axis);
		UpdateInternalBaseRotation(NewRotation, Instigator);
	}

	FQuat CalculateBaseRotationFromYawAxis(FVector NewYawAxis) const
	{
		const FVector CurrentYawAxis = InternalBaseRotation.UpVector;

		// Check if angle is the same (within ~0.08 degrees)
		if(CurrentYawAxis.DotProduct(NewYawAxis) > 0.999999)
			return InternalBaseRotation;

		FVector PrevFwd = InternalBaseRotation.Vector();
		FVector NewFwd = PrevFwd.VectorPlaneProject(NewYawAxis);
		if (NewFwd.IsNearlyZero())
		{
			// Axis is parallel with previous fwd vector, new fwd should be previous up or down vector
			FVector PrevUp = CurrentYawAxis;
			NewFwd = (PrevFwd.DotProduct(NewYawAxis) >= 0.0) ? -PrevUp : PrevUp;
		}

		FQuat Rotation = FQuat::MakeFromXZ(NewFwd, NewYawAxis);
		return Rotation;
	}

	void ClearYawAxis(FInstigator Instigator)
	{
		if(CameraYawAxisInstigator != Instigator)
			return;
		
		SetYawAxis(FVector::UpVector, FInstigator());
	}

	UFUNCTION(BlueprintOverride)
	bool CanReplicateRotation() const
	{
		return DeferredSnap == EHazeCameraSnapType::None;
	}

	private void UpdateInternalBaseRotation(FQuat NewInternalBaseRotation, FInstigator Instigator)
	{
		CameraYawAxisInstigator = Instigator;
		InternalBaseRotation = NewInternalBaseRotation;
	}

	FRotator WorldToLocalRotation(FRotator WorldRotation) const
	{
		return (InternalBaseRotation.Inverse() * FQuat(WorldRotation)).Rotator();
	}

	FRotator LocalToWorldRotation(FRotator LocalRotation) const
	{
		return (InternalBaseRotation * FQuat(LocalRotation)).Rotator();
	}

	void OnTeleportOwner()
	{
		// The camera transition sync must always trigger so we don't de-sync.
		CameraSyncComponent.TransitionSync(this);

		if (DeferredSnap != EHazeCameraSnapType::None)
			return; // We already have deferred snap, don't interrupt that

		DisableTicksLeft = 5;

		bTeleportedLastFrame = true;
		LastTeleportFrame = Time::FrameNumber;

		auto CurrentActiveCamera = GetActiveCamera();
		if(CurrentActiveCamera == nullptr)
			return;

		if(!CurrentActiveCamera.bSnapOnTeleport)
			return;

		const FQuat SnapRotation = Owner.ActorQuat * UserSettings.SnapOffset.Quaternion();
		const FVector CameraDirection = SnapRotation.Vector();

		SnapCamera(CameraDirection);

		// Since overlap end are triggering after this function if you die inside a camera volume
		// and re-spawn outside of it, we need to snap the camera both when the teleport happens,
		// and at the end of the frame.
		SnapCameraAtEndOfFrame(CameraDirection);

		TriggerCameraCutThisFrame();
	}

	// Don't mess with bool param, unles you know what you're doing
	void SnapCamera(bool bShouldClearDeferredSnap = true)
	{
		FQuat SnapRotation = Owner.ActorQuat * UserSettings.SnapOffset.Quaternion();
		SnapCamera(SnapRotation.Vector(), bShouldClearDeferredSnap);
	}

	// Don't mess with bool param, unles you know what you're doing
	void SnapCamera(const FVector& Direction, bool bShouldClearDeferredSnap = true)
	{
		// Clear any deferred snap, so that won't override this
		if (bShouldClearDeferredSnap)
			DeferredSnap = EHazeCameraSnapType::None;

		const FRotator TargetRate = GetTargetTurnRate();
		TurnRatePitch.SnapTo(TargetRate.Pitch);
		TurnRateYaw.SnapTo(TargetRate.Yaw);

		// Snap desired rotation.
		// The internal functions will remove any form of potential roll
		SetDesiredRotationInternal(Direction.Rotation());

		// This will apply the 'OnCameraSnap' on all the camera parent components and snap all settings
		ApplyCameraSnap();

		if(CameraSyncComponent != nullptr)
		{
			CameraSyncComponent.UpdateValues(InternalLocalDesiredRotation, ViewRotation);
		}

		// Broadcast delegate
		OnSnapped.Broadcast();
	}

	void SnapCameraAtEndOfFrame(FVector Direction, EHazeCameraSnapType SnapType = EHazeCameraSnapType::World)
	{
		DeferredSnap = SnapType;
		DeferredSnapCameraDirection = Direction;
	}

	bool IsAiming() const
	{
		return WantToAimSet.Num() > 0;
	}

	void SetAiming(FInstigator Instigator)
	{
		WantToAimSet.AddUnique(Instigator);
	}

	void ClearAiming(FInstigator Instigator)
	{
		WantToAimSet.Remove(Instigator);
	}

	void ResetAiming()
	{
		WantToAimSet.Empty();
	}

	const TArray<FInstigator>& GetAimingInstigators() const
	{
		return WantToAimSet;
	}

	bool IsUsingDefaultCamera()
	{
		UCameraComponent CurCam = GetActiveCamera();
		return (CurCam != nullptr) && (CurCam.Owner == Owner);
	}

	// Return true if we're controlling part of the screen. False if other player has full screen (or there are non-player controlled screens covering the entire screen)
	bool HasScreenSize() const
	{
		FVector2D Res = SceneView::GetPlayerViewResolution(PlayerOwner);
		return (Res.X > 1.0) && (Res.Y > 1.0);
	}

	bool HasDisableTicks() const
	{
		return DisableTicksLeft > 0;
	}

	bool HasAppliedDesiredRotation() const
	{
		return bHasAppliedDesiredRotation;
	}

	bool CanApplyUserInput() const
	{
		if(bUserHasAppliedInput)
			return false;
		if(HasDisableTicks())
			return false;
		return true;
	}

	bool HasAppliedUserInput() const
	{
		return bUserHasAppliedInput;
	}

	// Returns true if there are any currently active cameras that will respond to user input and we have screen space
	bool CanControlCamera() const
	{
		if(HasDisableTicks())
			return false;
		
		if (!HasScreenSize() && (ControlCameraWithoutScreenSizeAllower.Num() == 0))
		 	return false;

		if (IsControlledByInput())
			return true;

		return false;
	}

	bool IsCameraAttachedToPlayer() const
	{
		UHazeCameraComponent Camera = GetActiveCamera();
		if (Camera != nullptr && Camera.IsAttachedTo(PlayerOwner))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void ApplyCameraImpulseClamps(FVector& InOutTranslation, FRotator& InOutRotation)
	{
		if (!ensure(ImpulseSettings != nullptr))
			return;
		ImpulseSettings.ApplyClamps(InOutTranslation, InOutRotation);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldControlCameraWithoutScreenSize() const
	{
		return ControlCameraWithoutScreenSizeAllower.Num() != 0;
	}

	bool IsControlledByInput() const
	{
		auto Cam = GetActiveCamera();
		if(Cam == nullptr)
			return false;
		return Cam.IsControlledByInput();
	}

	UFUNCTION(BlueprintOverride)
	void OnComponentsShown(TArray<UPrimitiveComponent> ShownComps)
	{
		for(auto It : ShownComps)
		{
			if (It != nullptr)
				It.SetBasePassRenderedForPlayer(PlayerOwner, true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnComponentsHide(TArray<UPrimitiveComponent> HideComps)
	{
		for(auto It : HideComps)
		{
			if (It != nullptr)
				It.SetBasePassRenderedForPlayer(PlayerOwner, false);
		}
	}

	FRotator CalculateAndUpdateInputDeltaRotation(FVector2D AxisInput, FRotator TurnRate, bool bAffectInputDuration = true)
	{
		const float AccelerationThreshold = 0.001;

		// The input never includes the debug delta time
		float DeltaTime = Time::GetCameraDeltaSeconds(false);
		
		FRotator DeltaRotation = FRotator::ZeroRotator;
		if (PlayerOwner.IsUsingGamepad())
		{
			// Accelerate input over time, using curve (e.g. Blueprints/Input/Curve_CameraAcceleration_Yaw)
			float InputDeltaX = DeltaTime;
			if (Math::Abs(AxisInput.X) < AccelerationThreshold) 
			{
				if (bAffectInputDuration)
					InputDuration.X = 0.0;
				InputDeltaX = 0.0;
			}

			float YawMovement = EvaluateDiscretizedAccelerationCurve(UserSettings.InputAccelerationCurveYaw, InputDuration.X, InputDeltaX);
			float InputDeltaY = DeltaTime;
			if (Math::Abs(AxisInput.Y) < AccelerationThreshold) 
			{
				if (bAffectInputDuration)
					InputDuration.Y = 0.0;
				InputDeltaY = 0.0;
			}

			float PitchMovement = EvaluateDiscretizedAccelerationCurve(UserSettings.InputAccelerationCurvePitch, InputDuration.Y, InputDeltaY);
	
			if (bAffectInputDuration)
			{
				InputDuration.X += InputDeltaX;
				InputDuration.Y += InputDeltaY;
			}

			DeltaRotation.Yaw = AxisInput.X * YawMovement * TurnRate.Yaw;
			DeltaRotation.Pitch = AxisInput.Y * PitchMovement * TurnRate.Pitch;
		}
		else
		{
			// We cant use delta time on mouse input. But without this, the input becomes to big.
			const float MouseMultiplier = 0.01;
			
			DeltaRotation.Yaw = AxisInput.X * TurnRate.Yaw * MouseMultiplier;
			DeltaRotation.Pitch = AxisInput.Y * TurnRate.Pitch * MouseMultiplier;

			if (bAffectInputDuration)
				InputDuration = FVector2D::ZeroVector;
		}

		return DeltaRotation;
	}


	private float EvaluateDiscretizedAccelerationCurve(UCurveFloat Curve, float StartTime, float DeltaTime)
	{
		/**
		 * This discretized and substep the acceleration curve in smaller increments.
		 * If we don't do this the camera movement during acceleration is framerate dependent.
		 * That means it will move faster at lower framerate, and slower at higher framerate.
		 * 
		 * To illustrate, if our first two 60fps frames look like this:
		 * Frame 0: 0s -> 0.016s
		 * Velocity from curve at 0.016s = 1
		 * Frame movement: 1 * 0.016 = 0.016
		 * 
		 * Frame 1: 0.016s -> 0.033s
		 * Velocity from curve at 0.033s = 2
		 * Frame movement: 2 * 0.016 = 0.033
		 * 
		 * Total movement after 0.033s = 0.016 + 0.033 = 0.049
		 * 
		 * 
		 * But at 30fps:
		 * Frame 0: 0s -> 0.033s
		 * Velocity from curve at 0.033s = 2
		 * Frame movement: 2 * 0.033 = 0.066
		 * 
		 * Total movement after 0.033s = 0.066
		 * 
		 * 
		 * So the 30 fps one is faster!
		 * Instead we do an analytical integration of the area underneath the curve over some substeps.
		 */

		const float Substep = (1.0 / 120.0);
		float FrameMovement = 0.0;

		float ChunkStart = Math::FloorToFloat(StartTime / Substep) * Substep;
		float ChunkEnd = ChunkStart + Substep;
		float ChunkStartSpeed = GetCurveValue(Curve, ChunkStart, 1);

		float EvalTime = StartTime;
		float EndTime = StartTime + DeltaTime;
		while (true)
		{	
			float ChunkEndSpeed = GetCurveValue(Curve, ChunkEnd, 1);

			float StartInChunk = Math::Max(ChunkStart, EvalTime);
			float EndInChunk = Math::Min(ChunkEnd, EndTime);

			float DurationInChunk = EndInChunk - StartInChunk;
			float SpeedAtEvalTime = ChunkStartSpeed + (ChunkEndSpeed - ChunkStartSpeed) * ((StartInChunk - ChunkStart) / Substep);

			FrameMovement += SpeedAtEvalTime * DurationInChunk;
			FrameMovement += 0.5 * (ChunkEndSpeed - SpeedAtEvalTime) * DurationInChunk;

			if (ChunkEnd >= EndTime)
				break;

			EvalTime = ChunkEnd;

			ChunkStart += Substep;
			ChunkEnd += Substep;
			ChunkStartSpeed = ChunkEndSpeed;
		}

		return FrameMovement;
	}

	private float GetCurveValue(UCurveFloat Curve, float Time, float DefaultValue) const
	{
		if(Curve == nullptr)
			return DefaultValue;

		return Curve.GetFloatValue(Time);
	}

	FInstigator GetDebugCameraYawAxisInstigator() const property
	{
		return CameraYawAxisInstigator;
	}

	bool DesiredRotationChangedLastFrame() const
	{
		return PreviousLocalDesiredRotation != InternalLocalDesiredRotation;
	}
}

