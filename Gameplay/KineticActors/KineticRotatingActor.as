event void FOnStartRotatingForward();
event void FOnStartRotatingBackward();

event void FKineticRotatingEvent();

enum EKineticRotatingMode
{
	// Manually trigger rotating forward and backward
	Manual,

	// Automatically rotate back and forth while the actor exists
	AlwaysMoveBackAndForth,

	// Rotate infinitely
	AlwaysSpinAround,
};

enum EKineticRotatingNetwork
{
	// Default behavior is to use local movement in Manual mode, and predicted movement in permanent movement modes
	Default,
	// No syncing happens, all movement happens locally and can be desynced.
	Local,
	// Rotation is synced from the host.
	SyncedFromHost,
	// Rotation is synced always from Mio's side.
	SyncedFromMioControl,
	// Rotation is synced always from Zoe's side.
	SyncedFromZoeControl,
	// Position is predicted to match up more closely to the other side
	PredictedSyncPosition,
	// Position is controlled by Mio, and predicted on the Zoe side
	PredictedToMioControl,
	// Position is controlled by Zoe, and predicted on the Mio side
	PredictedToZoeControl,
};

enum EKineticRotationCurve
{
	// S curve with smooth in and out.
	EaseInOut,
	// Slow start and fast end.
	EaseIn,
	// Fast start and slow end.
	EaseOut,
	// Fully linear movement, always constant speed
	Linear,
};

class AKineticRotatingActor : AHazeActor
{
	access EditOnly = protected, * (editdefaults);
	access VisualizerOnly = protected, UKineticRotatingActorEditorComponentVisualizer, VisualizeSingle;

	default PrimaryActorTick.bStartWithTickEnabled = false;
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_HazeInput;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(DefaultComponent)
	USoundDefContextComponent SoundDefComp;

	FOnStartRotatingForward OnStartForward;
	FOnStartRotatingBackward OnStartBackward;

	UPROPERTY()
	FKineticRotatingEvent OnFinishedForward;

	UPROPERTY()
	FKineticRotatingEvent OnFinishedBackward;


#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.bSelectable = false;

	UPROPERTY(DefaultComponent)
	UKineticRotatingActorEditorComponent EditorComp;
#endif

	/** When to move the actor. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Rotation")
	access:EditOnly
	EKineticRotatingMode MovementMode = EKineticRotatingMode::Manual;

	EKineticRotatingMode GetRotationMode() const property
	{
		return MovementMode;
	}

	/** Target rotation to reach when fully rotated. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Rotation", Meta = (EditCondition = "MovementMode != EKineticRotatingMode::AlwaysSpinAround", EditConditionHides))
	access:EditOnly
	FRotator TargetRotation;

	/**
	 * Because of how we lerp during "Manual" and "Always Move Back and Forth", winding rotations are not possible.
	 * This setting changes the lerping to not be quaternion based, allowing winding but it will not lerp over the shortest path.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Rotation", Meta = (EditCondition = "MovementMode != EKineticRotatingMode::AlwaysSpinAround", EditConditionHides))
	access:EditOnly
	bool bSupportWinding = false;

	/** Rotation speed per second to spin around. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Rotation", Meta = (EditCondition = "MovementMode == EKineticRotatingMode::AlwaysSpinAround", EditConditionHides))
	access:EditOnly
	FRotator RotationSpeed;

	/** How long it takes to rotate the actor forward. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Rotation", Meta = (EditCondition = "MovementMode != EKineticRotatingMode::AlwaysSpinAround", EditConditionHides))
	access:EditOnly
	float ForwardMovementDuration = 2.25;

	/** How long it takes to retract the actor backward. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Rotation", Meta = (EditCondition = "MovementMode != EKineticRotatingMode::AlwaysSpinAround", EditConditionHides))
	access:EditOnly
	float BackwardMovementDuration = 2.75;

	/** How long after rotating forward should we start rotating backward. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Rotation", Meta = (EditCondition = "MovementMode == EKineticRotatingMode::AlwaysMoveBackAndForth", EditConditionHides))
	access:EditOnly
	float DelayAfterMovingForward = 0.0;

	/** How long after rotating backward should we start rotating forward. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Rotation", Meta = (EditCondition = "MovementMode == EKineticRotatingMode::AlwaysMoveBackAndForth", EditConditionHides))
	access:EditOnly
	float DelayAfterMovingBackward = 0.0;

	/** Whether to automatically retract back to the starting rotation after extending. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Rotation", Meta = (EditCondition = "MovementMode == EKineticRotatingMode::Manual", EditConditionHides))
	access:EditOnly
	bool bRetractAutomatically = false;

	/** How long after extending to retract. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Rotation", Meta = (EditCondition = "bRetractAutomatically && MovementMode == EKineticRotatingMode::Manual", EditConditionHides))
	access:EditOnly
	float AutoRetractDelay = 0.0;

	/** Offset the start time of the movement by this duration, so different actors can move at different timings. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Rotation", Meta = (EditCondition = "MovementMode == EKineticRotatingMode::AlwaysMoveBackAndForth || MovementMode == EKineticRotatingMode::AlwaysSpinAround", EditConditionHides))
	access:EditOnly
	float StartOffsetTime = 0.0;

	/**
	  * Disable the PlatformMesh component completely. Ideally we would remove that component, but it might be used somewhere.
	  * Will simply hide the mesh in Editor, and block Visuals, Ticking and Collision in BeginPlay.
	  */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Rotation")
	bool bDisablePlatformMesh = false;

	/** Which player controls the moving actor in network. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Network")
	access:EditOnly
	EKineticRotatingNetwork NetworkMode = EKineticRotatingNetwork::Default;

	/** Pause the actor instead of starting movement immediately. Pause instigator is the actor itself. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Rotation", Meta = (EditCondition = "MovementMode != EKineticRotatingMode::Manual", EditConditionHides))
	access:EditOnly
	bool bPausedFromStart = false;

	/** What kind of curve to use on the rotation. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Rotation", Meta = (EditCondition = "MovementMode == EKineticRotatingMode::Manual || MovementMode == EKineticRotatingMode::AlwaysMoveBackAndForth", EditConditionHides))
	access:EditOnly
	EKineticRotationCurve RotationCurve = EKineticRotationCurve::EaseOut;

	/** Smoothing factor to use for the smoothed rotation curve. 1 is fully linear, with larger values meaning more pronounced motion. <1 is invalid and will be clamped. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Rotation", Meta = (EditCondition = "(MovementMode == EKineticRotatingMode::Manual || MovementMode == EKineticRotatingMode::AlwaysMoveBackAndForth) && RotationCurve != EKineticRotationCurve::Linear", EditConditionHides))
	access:EditOnly
	float RotationSmoothingFactor = 2.5;

#if EDITOR
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Visualize")
	access:VisualizerOnly
	bool bVisualize = true;

	/**
	 * If true, all attached actors will have their bounds drawn.
	 * You can change this to draw their meshes as a wireframes by changing KineticActorVisualizer::VisualizeAttachedActors in KineticActorVisualizer.as
	 */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Visualize", Meta = (EditCondition = "bVisualize"))
	access:VisualizerOnly
	bool bVisualizeAttachedActors = true;

	/**
	 * If true, we will not simulate the movement of any attached kinetic actors, only the main one that is currently selected.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Visualize", Meta = (EditCondition = "bVisualize"))
	access:VisualizerOnly
	bool bSimulateOnlySelected = false;

	/**
	 * If true, the actor wireframe will be drawn at the destination rotation.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Visualize", Meta = (EditCondition = "bVisualize && MovementMode == EKineticRotatingMode::Manual || MovementMode == EKineticRotatingMode::AlwaysMoveBackAndForth"))
	access:VisualizerOnly
	bool bVisualizeTargetRotation = true;

	UPROPERTY(EditAnywhere, Category = "Kinetic Rotation", AdvancedDisplay)
	bool bTemporalLogTransforms = true;
#endif

	private FRotator OriginRotation;
	private bool bIsActive = false;
	private bool bPaused = false;
	private float StartCrumbTime = 0.0;
	private float PauseCrumbTime = 0.0;
	private bool bStartForward = true;
	private bool bActivatedForward = false;
	private bool bActivatedBackward = false;
	private TArray<FInstigator> ControlPauseInstigators;

	private float GetRelevantCrumbTime() const
	{
		switch(NetworkMode)
		{
			case EKineticRotatingNetwork::Default:
				if (MovementMode == EKineticRotatingMode::Manual)
					return Time::GameTimeSeconds;
				else
					return Time::GetPredictedGlobalCrumbTrailTime();

			case EKineticRotatingNetwork::Local:
				return Time::GameTimeSeconds;

			case EKineticRotatingNetwork::SyncedFromHost:
			case EKineticRotatingNetwork::SyncedFromMioControl:
			case EKineticRotatingNetwork::SyncedFromZoeControl:
				return Time::GetActorControlCrumbTrailTime(this);

			case EKineticRotatingNetwork::PredictedSyncPosition:
				return Time::GetPredictedGlobalCrumbTrailTime();

			case EKineticRotatingNetwork::PredictedToMioControl:
			{
				if(Game::Mio.HasControl())
					return Time::ThisSideCrumbTrailSendTime;
				else
					return Time::OtherSideCrumbTrailSendTimePrediction;
			}

			case EKineticRotatingNetwork::PredictedToZoeControl:
			{
				if(Game::Zoe.HasControl())
					return Time::ThisSideCrumbTrailSendTime;
				else
					return Time::OtherSideCrumbTrailSendTimePrediction;
			}
		}
	}

	private bool IsLocalMovement() const
	{
		switch(NetworkMode)
		{
			case EKineticRotatingNetwork::Local:
				return true;
			case EKineticRotatingNetwork::Default:
				return MovementMode == EKineticRotatingMode::Manual;
			default:
				return false;
		}
	}
	
	bool WasPausedFromStart() const
	{
		if(MovementMode == EKineticRotatingMode::Manual)
			return false;

		return bPausedFromStart;
	}

	bool IsPaused() const
	{
		return bPaused;
	}

	bool IsActive() const
	{
		return bIsActive;
	}

	/** Rotate forward to the target rotation. */
	UFUNCTION()
	void ActivateForward()
	{
		if (MovementMode != EKineticRotatingMode::Manual)
		{
			devError("Cannot manually activate a kinetic rotating actor set to always move.");
			return;
		}

		float NewStartTime = GetRelevantCrumbTime() - (InverseMovementCurve(GetCurrentAlpha()) * ForwardMovementDuration);
		if (IsLocalMovement())
			InternalSetMovement(true, NewStartTime);
		else if (HasControl())
			CrumbSetMovement(true, NewStartTime);
	}

	/** Move backward to the original location. */
	UFUNCTION()
	void ReverseBackwards()
	{
		if (MovementMode != EKineticRotatingMode::Manual)
		{
			devError("Cannot manually reverse a kinetic rotating actor set to always move.");
			return;
		}

		float NewStartTime = GetRelevantCrumbTime() - (InverseMovementCurve(1.0 - GetCurrentAlpha()) * BackwardMovementDuration);
		if (IsLocalMovement())
			InternalSetMovement(false, NewStartTime);
		else if (HasControl())
			CrumbSetMovement(false, NewStartTime);
	}

	/** Pause any movement we might be doing. */
	UFUNCTION()
	void PauseMovement(FInstigator Instigator)
	{
		if (HasControl() || IsLocalMovement())
		{
			ControlPauseInstigators.AddUnique(Instigator);
			if (!bPaused)
			{
				if (IsLocalMovement())
					InternalPauseMovement();
				else
					CrumbPauseMovement();
			}
		}
	}

	/** Unpause a previously instigated pause. */
	UFUNCTION()
	void UnpauseMovement(FInstigator Instigator)
	{
		if (HasControl() || IsLocalMovement())
		{
			ControlPauseInstigators.Remove(Instigator);
			if (bPaused && ControlPauseInstigators.Num() == 0)
			{
				if (IsLocalMovement())
					InternalResumeMovement();
				else
					CrumbResumeMovement();
			}
		}
	}

	/** Change the constant rotation speed, only available when set to mode AlwaysSpinAround. */
	UFUNCTION()
	void ChangeConstantRotationSpeed(FRotator NewRotationSpeed)
	{
		if (MovementMode != EKineticRotatingMode::AlwaysSpinAround)
		{
			devError("Cannot change constant rotation speed on a kinetic rotating actor not set to always spin around.");
			return;
		}

		UpdatePosition();

		float NewStartTime = GetRelevantCrumbTime();
		FRotator NewOriginRotation = GetActorRelativeRotation();

		if (IsLocalMovement())
			InternalSetRotationSpeed(NewOriginRotation, NewRotationSpeed.Euler(), NewStartTime);
		else if (HasControl())
			CrumbSetRotationSpeed(NewOriginRotation, NewRotationSpeed.Euler(), NewStartTime);
	}

	/**
	 * Snap this actor to be at the target rotation.
	 * Only works for Manual movement.
	 * @param bInitial Is this our initial value? Set to true if called from BeginPlay or a Progress Point. This will skip networking, saving on RPC calls.
	 */
	UFUNCTION()
	void SnapToEnd(bool bInitial)
	{
		switch(MovementMode)
		{
			case EKineticRotatingMode::Manual:
				break;

			case EKineticRotatingMode::AlwaysMoveBackAndForth:
				return;

			case EKineticRotatingMode::AlwaysSpinAround:
				return;
		}

		if (IsLocalMovement() || bInitial)
			InternalSnapToEnd();
		else if (HasControl())
			CrumbSnapToEnd();
	}

#if EDITORONLY_DATA
	UPROPERTY(NotEditable, BlueprintHidden)
	float AutoRetractTimer = -1.0;
	UPROPERTY(NotEditable, BlueprintHidden)
	EMoveSettingsPrototypeGenericRotatingActor MoveSettingsPlatform = EMoveSettingsPrototypeGenericRotatingActor::Normal;
#endif

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITORONLY_DATA
		if (AutoRetractTimer != -1.0)
		{
			bRetractAutomatically = true;
			AutoRetractDelay = AutoRetractTimer;
			AutoRetractTimer = -1.0;
		}

		if (MoveSettingsPlatform == EMoveSettingsPrototypeGenericRotatingActor::AlwaysMoveBackAndForth)
		{
			MovementMode = EKineticRotatingMode::AlwaysMoveBackAndForth;
			MoveSettingsPlatform = EMoveSettingsPrototypeGenericRotatingActor::Normal;
		}
		else if (MoveSettingsPlatform == EMoveSettingsPrototypeGenericRotatingActor::AlwaysSpinAround)
		{
			MovementMode = EKineticRotatingMode::AlwaysSpinAround;
			MoveSettingsPlatform = EMoveSettingsPrototypeGenericRotatingActor::Normal;
		}

		if(RotationSmoothingFactor < 1.0)
			RotationSmoothingFactor = 1.0;
#endif
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		PlatformMesh.SetVisibility(!bDisablePlatformMesh);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		switch (NetworkMode)
		{
			case EKineticRotatingNetwork::Default:
			case EKineticRotatingNetwork::Local:
			case EKineticRotatingNetwork::SyncedFromHost:
			case EKineticRotatingNetwork::PredictedSyncPosition:
				// Host control is the default
				break;

			case EKineticRotatingNetwork::SyncedFromMioControl:
			case EKineticRotatingNetwork::PredictedToMioControl:
				SetActorControlSide(Game::Mio);
				break;

			case EKineticRotatingNetwork::SyncedFromZoeControl:
			case EKineticRotatingNetwork::PredictedToZoeControl:
				SetActorControlSide(Game::Zoe);
				break;
		}

		OriginRotation = GetActorRelativeRotation();
		StartCrumbTime = 0;

		if (MovementMode == EKineticRotatingMode::Manual)
		{
			bIsActive = false;
			bStartForward = false;
			StartCrumbTime = -BackwardMovementDuration;
		}
		else
		{
			StartCrumbTime += StartOffsetTime;
			SetActorTickEnabled(true);
			bIsActive = true;
		}

		if (WasPausedFromStart())
		{
			if (HasControl() || IsLocalMovement())
				ControlPauseInstigators.AddUnique(this);
			bPaused = true;
			PauseCrumbTime = StartCrumbTime;
			SetActorTickEnabled(false);
		}

		if(bDisablePlatformMesh)
		{
			PlatformMesh.AddComponentCollisionBlocker(this);
			PlatformMesh.AddComponentTickBlocker(this);
			PlatformMesh.AddComponentVisualsBlocker(this);
		}

#if EDITOR
		if(bTemporalLogTransforms)
			UTemporalLogTransformLoggerComponent::GetOrCreate(this);
#endif
	}

	private float EvaluateMovementCurve(float Alpha) const
	{
		switch (RotationCurve)
		{
			case EKineticRotationCurve::EaseInOut:
				return Math::EaseInOut(0, 1, Alpha, RotationSmoothingFactor);
			case EKineticRotationCurve::EaseIn:
				return Math::EaseIn(0, 1, Alpha, RotationSmoothingFactor);
			case EKineticRotationCurve::EaseOut:
				return Math::EaseOut(0, 1, Alpha, RotationSmoothingFactor);
			case EKineticRotationCurve::Linear:
				return Alpha;
		}
	}

	private float InverseMovementCurve(float Alpha) const
	{
		switch (RotationCurve)
		{
			case EKineticRotationCurve::EaseInOut:
				return InverseEaseInOut(Alpha);
			case EKineticRotationCurve::EaseIn:
				return InverseEaseIn(Alpha);
			case EKineticRotationCurve::EaseOut:
				return InverseEaseOut(Alpha);
			case EKineticRotationCurve::Linear:
				return Alpha;
		}
	}

	private float InverseEaseInOut(float Alpha) const
	{
		if (Alpha < 0.5)
			return InverseEaseIn(Alpha * 2) * 0.5;
		else
			return InverseEaseOut(Alpha * 2 - 1) * 0.5 + 0.5;
	}

	private float InverseEaseIn(float Alpha) const
	{
		return Math::Pow(Alpha, 1.0 / RotationSmoothingFactor);
	}

	private float InverseEaseOut(float Alpha) const
	{
		return 1.0 - Math::Pow(1.0 - Alpha, 1.0 / RotationSmoothingFactor);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsActive && !bPaused)
			UpdatePosition();
		else
			SetActorTickEnabled(false);
	}

	float GetCurrentAlpha() const
	{
		return GetAlphaAtTime(GetCurrentTime());
	}

	float GetCurrentTime() const
	{
		if (bPaused)
			return PauseCrumbTime - StartCrumbTime;
		else
			return GetRelevantCrumbTime() - StartCrumbTime;
	}

	private float GetAlphaAtTime(float InTime) const
	{
		float Alpha = 0.0;
		if (MovementMode == EKineticRotatingMode::AlwaysMoveBackAndForth)
		{
			float CycleDuration = ForwardMovementDuration + DelayAfterMovingForward + BackwardMovementDuration + DelayAfterMovingBackward;
			float Time = InTime % CycleDuration;

			if (Time < ForwardMovementDuration)
			{
				Alpha = EvaluateMovementCurve(Time / Math::Max(ForwardMovementDuration, 0.001));
			}
			else
			{
				Time -= ForwardMovementDuration;
				if (Time < DelayAfterMovingForward)
				{
					Alpha = 1.0;
				}
				else
				{
					Time -= DelayAfterMovingForward;
					if (Time < BackwardMovementDuration)
					{
						Alpha = 1.0 - EvaluateMovementCurve(Time / Math::Max(BackwardMovementDuration, 0.001));
					}
					else
					{
						Alpha = 0.0;
					}
				}
			}
		}
		else if (MovementMode == EKineticRotatingMode::AlwaysSpinAround)
		{
			Alpha = InTime;
		}
		else if (MovementMode == EKineticRotatingMode::Manual)
		{
			if (bRetractAutomatically && bStartForward)
			{
				if (InTime < ForwardMovementDuration)
					Alpha = EvaluateMovementCurve(InTime / Math::Max(ForwardMovementDuration, 0.001));
				else if (InTime < ForwardMovementDuration + AutoRetractDelay)
					Alpha = 1.0;
				else if (InTime < ForwardMovementDuration + AutoRetractDelay + BackwardMovementDuration)
					Alpha = 1.0 - EvaluateMovementCurve((InTime - AutoRetractDelay - ForwardMovementDuration) / Math::Max(BackwardMovementDuration, 0.001));
				else
					Alpha = 0.0;
			}
			else if (bStartForward)
			{
				if (InTime < ForwardMovementDuration)
					Alpha = EvaluateMovementCurve(InTime / Math::Max(ForwardMovementDuration, 0.001));
				else
					Alpha = 1.0;
			}
			else
			{
				if (InTime < BackwardMovementDuration)
					Alpha = 1.0 - EvaluateMovementCurve(InTime / Math::Max(BackwardMovementDuration, 0.001));
				else
					Alpha = 0.0;
			}
		}

		return Alpha;
	}

 	bool IsMovingBackwardAtTime(float InTime)
	{
		if (MovementMode == EKineticRotatingMode::AlwaysMoveBackAndForth)
		{
			float CycleDuration = ForwardMovementDuration + DelayAfterMovingForward + BackwardMovementDuration + DelayAfterMovingBackward;
			float Time = InTime % CycleDuration;

			if (Time < ForwardMovementDuration + DelayAfterMovingForward)
				return false;
			else
				return true;
		}
		else if (MovementMode == EKineticRotatingMode::Manual)
		{
			if (bRetractAutomatically && bStartForward)
			{
				if (InTime < ForwardMovementDuration + AutoRetractDelay)
					return false;
				else
					return true;
			}
			else if (bStartForward)
			{
				return false;
			}
			else
			{
				return true;
			}
		}

		return false;
	}

	private void UpdatePosition()
	{
		SetActorRelativeRotation(GetRotationAtAlpha(OriginRotation, TargetRotation, GetCurrentAlpha()));

		// Update what direction we're moving in
		if (bIsActive)
		{
			bool bMovingBackward = IsMovingBackwardAtTime(GetCurrentTime());
			if (bMovingBackward)
			{
				bActivatedForward = false;
				if (!bActivatedBackward)
				{
					bActivatedBackward = true;
					OnBackwardsActivated();

					OnStartBackward.Broadcast();
				}
			}
			else
			{
				bActivatedBackward = false;
				if (!bActivatedForward)
				{
					bActivatedForward = true;
					OnForwardActivated();

					OnStartForward.Broadcast();
				}
			}
		}

		// Stop moving after we're done
		if (MovementMode == EKineticRotatingMode::Manual)
		{
			float Time = GetCurrentTime();
			if (bRetractAutomatically && bStartForward)
			{
				if (Time > ForwardMovementDuration + AutoRetractDelay + BackwardMovementDuration)
				{
					bIsActive = false;
					OnFinishedForward.Broadcast();
				}
			}
			else if (bStartForward)
			{
				if (Time > ForwardMovementDuration)
				{
					bIsActive = false;
					OnFinishedForward.Broadcast();
				}
			}
			else
			{
				if (Time > BackwardMovementDuration)
				{
					bIsActive = false;
					OnFinishedBackward.Broadcast();
				}
			}
		}
	}

	FRotator GetRotationAtAlpha(FRotator Origin, FRotator Target, float Alpha) const
	{
		switch(MovementMode)
		{
			case EKineticRotatingMode::Manual:
			case EKineticRotatingMode::AlwaysMoveBackAndForth:
			{
				if(bSupportWinding)
				{
					return FRotator(
						Math::Lerp(Origin.Pitch, Target.Pitch, Alpha),
						Math::Lerp(Origin.Yaw, Target.Yaw, Alpha),
						Math::Lerp(Origin.Roll, Target.Roll, Alpha)
					);
				}
				else
				{
					return Math::LerpShortestPath(
						Origin,
						Target,
						Alpha,
					);
				}
			}

			case EKineticRotatingMode::AlwaysSpinAround:
			{
				const FRotator Offset = RotationSpeed * Alpha;
				return Origin + Offset;
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPauseMovement()
	{
		InternalPauseMovement();
	}

	private void InternalPauseMovement()
	{
		bPaused = true;
		PauseCrumbTime = GetRelevantCrumbTime();

		UpdatePosition();
		SetActorTickEnabled(false);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetMovement(bool bForward, float NewStartTime)
	{
		InternalSetMovement(bForward, NewStartTime);
	}

	private void InternalSetMovement(bool bForward, float NewStartTime)
	{
		StartCrumbTime = NewStartTime;
		bStartForward = bForward;
		bIsActive = true;
		if (bPaused)
			PauseCrumbTime = GetRelevantCrumbTime();
		else
			SetActorTickEnabled(true);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetRotationSpeed(FRotator NewOriginRotation, FVector NewRotationSpeed, float NewStartTime)
	{
		InternalSetRotationSpeed(NewOriginRotation, NewRotationSpeed, NewStartTime);
	}

	private void InternalSetRotationSpeed(FRotator NewOriginRotation, FVector NewRotationSpeed, float NewStartTime)
	{
		StartCrumbTime = NewStartTime;
		OriginRotation = NewOriginRotation;
		RotationSpeed = FRotator::MakeFromEuler(NewRotationSpeed);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbResumeMovement()
	{
		InternalResumeMovement();
	}

	private void InternalResumeMovement()
	{
		bPaused = false;
		StartCrumbTime = GetRelevantCrumbTime() - PauseCrumbTime + StartCrumbTime;
		UpdatePosition();
		if (bIsActive)
			SetActorTickEnabled(true);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSnapToEnd()
	{
		InternalSnapToEnd();
	}

	private void InternalSnapToEnd()
	{
		switch(MovementMode)
		{
			case EKineticRotatingMode::Manual:
			{
				// Snap to when the forward movement would stop (but before the wait to go back)
				StartCrumbTime = GetRelevantCrumbTime() - ForwardMovementDuration;
				bStartForward = true;
				bIsActive = false;
				SetActorTickEnabled(false);

				if (bPaused)
					PauseCrumbTime = GetRelevantCrumbTime();

				UpdatePosition();
				break;
			}
			case EKineticRotatingMode::AlwaysMoveBackAndForth:
			{
				break;
			}
			case EKineticRotatingMode::AlwaysSpinAround:
			{
				break;
			}
		}
	}

	UFUNCTION(Meta = (DeprecatedFunction, DeprecationMessage = "Use PauseMovement with an instigator"))
	void PausePlatform()
	{
		PauseMovement(this);
	}

	UFUNCTION(Meta = (DeprecatedFunction, DeprecationMessage = "Use UnPauseMovement with an instigator"))
	void UnPausePlatform()
	{
		UnpauseMovement(this);
	}

	FRotator GetRotationSpeed() const
	{
		check(RotationMode == EKineticRotatingMode::AlwaysSpinAround);
		return RotationSpeed;
	}

	UFUNCTION(BlueprintEvent)
	void OnForwardActivated() {}
	UFUNCTION(BlueprintEvent)
	void OnBackwardsActivated() {}

#if EDITOR
	void Visualize(const UHazeScriptComponentVisualizer Visualizer, FTransform ParentTransform, bool bSimulate, FTransform&out OutTransform) const
	{
		if(Visualizer == nullptr)
			return;

		FTransform CurrentActorTransform = ActorRelativeTransform * ParentTransform;

		if(bSimulate)
		{
			float Time = Time::GameTimeSeconds;

			if(MovementMode == EKineticRotatingMode::Manual)
			{
				float Duration = 0;
				if(bRetractAutomatically)
					Duration = ForwardMovementDuration + AutoRetractDelay + BackwardMovementDuration;
				else
					Duration = bStartForward ? ForwardMovementDuration : BackwardMovementDuration;

				// Small delay when reaching end
				Duration += 1;
				Time %= Duration;
			}

			const float Alpha = GetAlphaAtTime(Time);

			FRotator RelativeRotation = GetRotationAtAlpha(ActorRelativeRotation, TargetRotation, Alpha);
			CurrentActorTransform = FTransform(RelativeRotation, ActorRelativeLocation, ActorRelativeScale3D) * ParentTransform;
		}

		DrawTransform(Visualizer, CurrentActorTransform, KineticActorVisualizer::GetMaterial(this));

		if(bVisualizeTargetRotation && KineticActorVisualizer::IsExclusivelySelected(this) && (MovementMode == EKineticRotatingMode::Manual || MovementMode == EKineticRotatingMode::AlwaysMoveBackAndForth))
		{
			const FTransform TargetActorTransform = FTransform(TargetRotation, ActorRelativeLocation, ActorRelativeScale3D) * ParentTransform;
			DrawTransform(Visualizer, TargetActorTransform, KineticActorVisualizer::GetUnselectedMaterial());
		}

		OutTransform = CurrentActorTransform;
	}

	private void DrawTransform(const UHazeScriptComponentVisualizer Visualizer, FTransform Transform, UMaterialInterface Material) const
	{
		if(KineticActorVisualizer::bVisualizeOnlyMainMesh)
		{
			if(IsValid(PlatformMesh) && PlatformMesh.bVisible)
			{
				const FTransform CurrentMeshTransform = PlatformMesh.RelativeTransform * Transform;

				Visualizer.DrawMeshWithMaterial(
					PlatformMesh.StaticMesh,
					Material,
					CurrentMeshTransform.Location,
					CurrentMeshTransform.Rotation,
					CurrentMeshTransform.Scale3D
				);
			}
		}
		else
		{
			KineticActorVisualizer::DrawAllStaticMeshesOnActor(Visualizer, this, Transform, Material);
		}
	}
#endif
}

#if EDITOR
UCLASS(NotBlueprintable, NotPlaceable)
class UKineticRotatingActorEditorComponent : UActorComponent
{
};

class UKineticRotatingActorEditorComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UKineticRotatingActorEditorComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		if(Editor::IsPlaying())
			return;

		auto KineticRotating = Cast<AKineticRotatingActor>(Component.Owner);
		if(KineticRotating == nullptr)
			return;

		if(!KineticRotating.bVisualize)
			return;

		if(KineticRotating.bVisualizeAttachedActors)
		{
			KineticActorVisualizer::VisualizeKineticChain(KineticRotating, this, KineticRotating.bSimulateOnlySelected);
		}
		else
		{
			FTransform ParentTransform = FTransform::Identity;
			if(KineticRotating.GetAttachParentActor() != nullptr)
				ParentTransform = KineticRotating.GetAttachParentActor().ActorTransform;

			FTransform OutTransform;
			KineticActorVisualizer::VisualizeSingle(KineticRotating, this, ParentTransform, KineticRotating.bSimulateOnlySelected, OutTransform);
		}
	}
};
#endif

enum EMoveSettingsPrototypeGenericRotatingActor
{
	AlwaysMoveBackAndForth,
	AlwaysSpinAround,
	Normal
}