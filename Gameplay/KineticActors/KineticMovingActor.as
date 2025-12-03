event void FOnStartMovingForward();
event void FOnStartMovingBackward();

enum EKineticMovementMode
{
	// Manually trigger moving forward and backward
	Manual,

	// Automatically move back and forth while the actor exists
	AlwaysMoveBackAndForth,
};

enum EKineticMovementNetwork
{
	// Default behavior is to use local movement in Manual mode, and predicted movement in permanent movement modes
	Default,
	// No syncing happens, all movement happens locally and can be desynced.
	Local,
	// Position is synced from the host.
	SyncedFromHost,
	// Position is synced always from Mio's side.
	SyncedFromMioControl,
	// Position is synced always from Zoe's side.
	SyncedFromZoeControl,
	// Position is predicted to match up more closely to the other side
	PredictedSyncPosition,
	// Position is controlled by Mio, and predicted on the Zoe side
	PredictedToMioControl,
	// Position is controlled by Zoe, and predicted on the Mio side
	PredictedToZoeControl,
};

enum EKineticMovementCurve
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

event void FKineticMovingEvent();

class AKineticMovingActor : AHazeActor
{
	access EditOnly = protected, * (editdefaults, readonly);
	access VisualizerOnly = protected, UKineticMovingActorEditorComponentVisualizer, VisualizeSingle;

	default PrimaryActorTick.bStartWithTickEnabled = false;
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_HazeInput;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UBillboardComponent TargetLocationComp;
	default TargetLocationComp.RelativeLocation = FVector(500.0, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(DefaultComponent)
	USoundDefContextComponent SoundDefComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent StartLocationBillboard;
	default StartLocationBillboard.bSelectable = false;

	UPROPERTY(DefaultComponent)
	UKineticMovingActorEditorComponent EditorComp;
#endif

	/** When to move the actor. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Movement")
	access:EditOnly
	EKineticMovementMode MovementMode = EKineticMovementMode::Manual;

	/** How long it takes to extend the actor forward. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Movement", Meta = (ClampMin = "0.0"))
	access:EditOnly
	float ForwardMovementDuration = 2.25;

	/** How long it takes to retract the actor backward. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Movement", Meta = (ClampMin = "0.0"))
	access:EditOnly
	float BackwardMovementDuration = 2.75;

	/** How long after moving forward should we start moving backward. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Movement", Meta = (ClampMin = "0.0", EditCondition = "MovementMode == EKineticMovementMode::AlwaysMoveBackAndForth", EditConditionHides))
	access:EditOnly
	float DelayAfterMovingForward = 0.0;

	/** How long after moving backward should we start moving forward. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Movement", Meta = (ClampMin = "0.0", EditCondition = "MovementMode == EKineticMovementMode::AlwaysMoveBackAndForth", EditConditionHides))
	access:EditOnly
	float DelayAfterMovingBackward = 0.0;

	/** Whether to automatically retract back to the starting position after extending. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Movement", Meta = (EditCondition = "MovementMode == EKineticMovementMode::Manual", EditConditionHides))
	access:EditOnly
	bool bRetractAutomatically = false;

	/** How long after extending to retract. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Movement", Meta = (ClampMin = "0.0", EditCondition = "bRetractAutomatically && MovementMode == EKineticMovementMode::Manual", EditConditionHides))
	access:EditOnly
	float AutoRetractDelay = 0.0;

	/** Offset the start time of the movement by this duration, so different actors can move at different timings. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Movement", Meta = (EditCondition = "MovementMode == EKineticMovementMode::AlwaysMoveBackAndForth", EditConditionHides))
	access:EditOnly
	float StartOffsetTime = 0.0;

	/** Pause the actor instead of starting movement immediately. Pause instigator is the actor itself. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Movement", Meta = (EditCondition = "MovementMode != EKineticMovementMode::Manual", EditConditionHides))
	access:EditOnly
	bool bPausedFromStart = false;

	/** What kind of curve to use on the movement. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Movement")
	access:EditOnly
	EKineticMovementCurve MovementCurve = EKineticMovementCurve::EaseOut;

	/** Smoothing factor to use for the smoothed movement curve. 1 is fully linear, with larger values meaning more pronounced motion. <1 is invalid and will be clamped. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Movement", Meta = (ClampMin = "1.0", EditCondition = "MovementCurve != EKineticMovementCurve::Linear", EditConditionHides))
	access:EditOnly
	float MovementSmoothingFactor = 2.5;

	/**
	  * Disable the PlatformMesh component completely. Ideally we would remove that component, but it might be used somewhere.
	  * Will simply hide the mesh in Editor, and block Visuals, Ticking and Collision in BeginPlay.
	  */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Movement")
	bool bDisablePlatformMesh = false;

	/** Which player controls the moving actor in network. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Network")
	access:EditOnly
	EKineticMovementNetwork NetworkMode = EKineticMovementNetwork::Default;

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
	 * If true, a line will be drawn to show where we are moving from and to, and the actor wireframe will be drawn at the destination.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Visualize", Meta = (EditCondition = "bVisualize"))
	access:VisualizerOnly
	bool bVisualizeTargetLocation = true;

	UPROPERTY(EditAnywhere, Category = "Kinetic Movement", AdvancedDisplay)
	bool bTemporalLogTransforms = true;

	UPROPERTY(EditAnywhere, Category = "Kinetic Movement", AdvancedDisplay)
	bool bDebug = false;
#endif

	/** Called when the actor starts moving forward (towards the target location) */
	UPROPERTY()
	FOnStartMovingForward OnStartForward;

	/** Called when the actor starts moving backwards (from the target to the original location) */
	UPROPERTY()
	FOnStartMovingBackward OnStartBackward;

	/** Called whenever the actor reaches the forward (target) location. */
	UPROPERTY()
	FKineticMovingEvent OnReachedForward;

	/** Called whenever the actor reaches the backward (initial) location. */
	UPROPERTY()
	FKineticMovingEvent OnReachedBackward;

	private FVector OriginLocation;
	private FVector TargetLocation;
	private bool bIsActive = false;
	private bool bPaused = false;
	private float StartCrumbTime = 0.0;
	private float PauseCrumbTime = 0.0;
	private bool bStartForward = true;
	private bool bActivatedForward = false;
	private bool bActivatedBackward = false;
	private int TotalReachedForwardCount = 0;
	private int TotalReachedBackwardCount = 0;
	private TArray<FInstigator> ControlPauseInstigators;

	private float GetRelevantCrumbTime() const
	{
		switch(NetworkMode)
		{
			case EKineticMovementNetwork::Default:
				if (MovementMode == EKineticMovementMode::Manual)
					return Time::GameTimeSeconds;
				else
					return Time::GetPredictedGlobalCrumbTrailTime();

			case EKineticMovementNetwork::Local:
				return Time::GameTimeSeconds;
				
			case EKineticMovementNetwork::SyncedFromHost:
			case EKineticMovementNetwork::SyncedFromMioControl:
			case EKineticMovementNetwork::SyncedFromZoeControl:
				return Time::GetActorControlCrumbTrailTime(this);

			case EKineticMovementNetwork::PredictedSyncPosition:
				return Time::GetPredictedGlobalCrumbTrailTime();

			case EKineticMovementNetwork::PredictedToMioControl:
			{
				if(Game::Mio.HasControl())
					return Time::ThisSideCrumbTrailSendTime;
				else
					return Time::OtherSideCrumbTrailSendTimePrediction;
			}

			case EKineticMovementNetwork::PredictedToZoeControl:
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
			case EKineticMovementNetwork::Local:
				return true;
			case EKineticMovementNetwork::Default:
				return MovementMode == EKineticMovementMode::Manual;
			default:
				return false;
		}
	}

	/** Move forward to the target location. */
	UFUNCTION()
	void ActivateForward()
	{
		if (MovementMode == EKineticMovementMode::AlwaysMoveBackAndForth)
		{
			devError("Cannot manually activate a kinetic moving actor set to always move back and forth.");
			return;
		}

		int ReachedForwardCount = 0;
		int ReachedBackwardCount = 0;
		float NewStartTime = GetRelevantCrumbTime() - (InverseMovementCurve(GetCurrentAlpha(ReachedForwardCount, ReachedBackwardCount)) * ForwardMovementDuration);

		if (IsLocalMovement())
			InternalSetMovement(true, NewStartTime);
		else if (HasControl())
			CrumbSetMovement(true, NewStartTime);
	}

	/** Move backward to the original location. */
	UFUNCTION()
	void ReverseBackwards()
	{
		if (MovementMode == EKineticMovementMode::AlwaysMoveBackAndForth)
		{
			devError("Cannot manually reverse a kinetic moving actor set to always move back and forth.");
			return;
		}

		int ReachedForwardCount = 0;
		int ReachedBackwardCount = 0;
		float NewStartTime = GetRelevantCrumbTime() - (InverseMovementCurve(1.0 - GetCurrentAlpha(ReachedForwardCount, ReachedBackwardCount)) * BackwardMovementDuration);

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

	/**
	 * Snap this actor to be at the target location.
	 * Only works for Manual movement.
	 * @param bInitial Is this our initial value? Set to true if called from BeginPlay or a Progress Point. This will skip networking, saving on RPC calls.
	 */
	UFUNCTION()
	void SnapToEnd(bool bInitial)
	{
		switch(MovementMode)
		{
			case EKineticMovementMode::Manual:
				break;

			case EKineticMovementMode::AlwaysMoveBackAndForth:
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
	EMoveSettingPrototypeGenericMovingActor MoveSettingsPlatform = EMoveSettingPrototypeGenericMovingActor::Normal;
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

		if (MoveSettingsPlatform == EMoveSettingPrototypeGenericMovingActor::AlwaysMoveBackAndForth)
		{
			MovementMode = EKineticMovementMode::AlwaysMoveBackAndForth;
			MoveSettingsPlatform = EMoveSettingPrototypeGenericMovingActor::Normal;
		}

		if(MovementSmoothingFactor < 1.0)
			MovementSmoothingFactor = 1.0;
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
			case EKineticMovementNetwork::Default:
			case EKineticMovementNetwork::Local:
			case EKineticMovementNetwork::SyncedFromHost:
			case EKineticMovementNetwork::PredictedSyncPosition:
				// Host control is the default
				break;

			case EKineticMovementNetwork::SyncedFromMioControl:
			case EKineticMovementNetwork::PredictedToMioControl:
				SetActorControlSide(Game::Mio);
				break;

			case EKineticMovementNetwork::SyncedFromZoeControl:
			case EKineticMovementNetwork::PredictedToZoeControl:
				SetActorControlSide(Game::Zoe);
				break;
		}

		OriginLocation = GetActorRelativeLocation();
		TargetLocation = GetActorRelativeTransform().TransformPosition(TargetLocationComp.RelativeLocation);
		StartCrumbTime = 0;

		if (MovementMode == EKineticMovementMode::AlwaysMoveBackAndForth)
		{
			StartCrumbTime += StartOffsetTime;
			SetActorTickEnabled(true);
			bIsActive = true;
		}
		else
		{
			bIsActive = false;
			bStartForward = false;
			StartCrumbTime = -BackwardMovementDuration;
		}

		if (bPausedFromStart)
		{
			if (HasControl() || IsLocalMovement())
				ControlPauseInstigators.AddUnique(this);
			bPaused = true;
			PauseCrumbTime = StartCrumbTime;
			SetActorTickEnabled(false);
		}

		// Update reached forward/backward
		GetCurrentAlpha(TotalReachedForwardCount, TotalReachedBackwardCount);

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
		switch (MovementCurve)
		{
			case EKineticMovementCurve::EaseInOut:
				return Math::EaseInOut(0, 1, Alpha, MovementSmoothingFactor);
			case EKineticMovementCurve::EaseIn:
				return Math::EaseIn(0, 1, Alpha, MovementSmoothingFactor);
			case EKineticMovementCurve::EaseOut:
				return Math::EaseOut(0, 1, Alpha, MovementSmoothingFactor);
			case EKineticMovementCurve::Linear:
				return Alpha;

		}
	}

	private float InverseMovementCurve(float Alpha) const
	{
		switch (MovementCurve)
		{
			case EKineticMovementCurve::EaseInOut:
				return InverseEaseInOut(Alpha);
			case EKineticMovementCurve::EaseIn:
				return InverseEaseIn(Alpha);
			case EKineticMovementCurve::EaseOut:
				return InverseEaseOut(Alpha);
			case EKineticMovementCurve::Linear:
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
		return Math::Pow(Alpha, 1.0 / MovementSmoothingFactor);
	}

	private float InverseEaseOut(float Alpha) const
	{
		return 1.0 - Math::Pow(1.0 - Alpha, 1.0 / MovementSmoothingFactor);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsActive && !bPaused)
			UpdatePosition();
		else
			SetActorTickEnabled(false);
	}

	float GetCurrentAlpha(int& ReachedForwardCount, int& ReachedBackwardCount) const
	{
		return GetAlphaAtTime(GetCurrentTime(), ReachedForwardCount, ReachedBackwardCount);
	}

	private float GetCurrentTime() const
	{
		if (bPaused)
			return PauseCrumbTime - StartCrumbTime;
		else
			return GetRelevantCrumbTime() - StartCrumbTime;
	}

	private float GetAlphaAtTime(float InTime, int& ReachedForwardCount, int& ReachedBackwardCount) const
	{
		switch(MovementMode)
		{
			case EKineticMovementMode::Manual:
				return GetAlphaAtTime_Manual(InTime, ReachedForwardCount, ReachedBackwardCount);
			
			case EKineticMovementMode::AlwaysMoveBackAndForth:
				return GetAlphaAtTime_AlwaysMoveBackAndForth(InTime, ReachedForwardCount, ReachedBackwardCount);
		}
	}

	private float GetAlphaAtTime_Manual(float InTime, int& ReachedForwardCount, int& ReachedBackwardCount) const
	{
		float Alpha = 0;

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

			if(InTime > ForwardMovementDuration)
				ReachedForwardCount = 1;

			if(InTime > ForwardMovementDuration + AutoRetractDelay + BackwardMovementDuration)
				ReachedBackwardCount = 1;
		}
		else if (bStartForward)
		{
			if (InTime < ForwardMovementDuration)
			{
				Alpha = EvaluateMovementCurve(InTime / Math::Max(ForwardMovementDuration, 0.001));
			}
			else
			{
				Alpha = 1.0;
				ReachedForwardCount = 1;
			}
		}
		else
		{
			if (InTime < BackwardMovementDuration)
			{
				Alpha = 1.0 - EvaluateMovementCurve(InTime / Math::Max(BackwardMovementDuration, 0.001));
			}
			else
			{
				Alpha = 0.0;
				ReachedBackwardCount = 1;
			}
		}

		return Alpha;
	}

	private float GetAlphaAtTime_AlwaysMoveBackAndForth(float InTime, int& ReachedForwardCount, int& ReachedBackwardCount) const
	{
		float Alpha = 0;

		const float CycleDuration = ForwardMovementDuration + DelayAfterMovingForward + BackwardMovementDuration + DelayAfterMovingBackward;
		if(CycleDuration < KINDA_SMALL_NUMBER)
		{
			PrintError(f"{this} has a total cycle duration of {CycleDuration} seconds, which is invalid!");
			return 0;
		}

		float Time = Math::Wrap(InTime, 0.0, CycleDuration);

		{
			// Calculate the amount of Forward and Backward hits

			const int CycleCount = Math::FloorToInt(InTime / CycleDuration);

			// If we have not hit forward this cycle, the amount of
			// total times we have reached forward must be the same as the number of cycles
			// If we reached forward this cycle, add 1
			if(Time < ForwardMovementDuration)
				ReachedForwardCount = CycleCount;
			else
				ReachedForwardCount = CycleCount + 1;

			// Same as forward hits, but different duration
			if(Time < ForwardMovementDuration + DelayAfterMovingForward + BackwardMovementDuration)
				ReachedBackwardCount = CycleCount;
			else
				ReachedBackwardCount = CycleCount + 1;
		}

		if (Time < ForwardMovementDuration)
		{
			// Moving forwards
			Alpha = EvaluateMovementCurve(Time / Math::Max(ForwardMovementDuration, 0.001));
		}
		else
		{
			// Finished moving forward

			Time -= ForwardMovementDuration;
			if (Time < DelayAfterMovingForward)
			{
				// Wait a duration at the forward location
				Alpha = 1.0;
			}
			else
			{
				// Move backwards
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

		return Alpha;
	}

	/**
	 * Is this actor currently Active, meaning that it wants to move (or has moved)?
	 * Note that this does not override bPaused.
	 */
	bool IsActive() const
	{
		return bIsActive;
	}

	/**
	 * Are we currently moving?
	 * This is false while waiting at the start or end for any durations.
	 * Also false if we are not active or are paused.
	 * @param bOutForward Are we moving forwards or backwards? While waiting at either end, the previous value is returned, i.e we are going forward while waiting at the end.
	 */
	bool IsMoving(bool&out bOutForward) const
	{
		if(!IsActive())
			return false;

		if(bPaused)
			return false;

		const float Time = GetCurrentTime();

		switch(MovementMode)
		{
			case EKineticMovementMode::Manual:
			{
				if (bRetractAutomatically && bStartForward)
				{
					if (Time < ForwardMovementDuration)
					{
						// Moving forward
						bOutForward = true;
						return true;
					}
					else if (Time < ForwardMovementDuration + AutoRetractDelay)
					{
						// Stopped at end, waiting for auto retract
						bOutForward = true;
						return false;
					}
					else if (Time < ForwardMovementDuration + AutoRetractDelay + BackwardMovementDuration)
					{
						// Moving back after auto retract
						bOutForward = false;
						return true;
					}
					else
					{
						// Stopped at start
						bOutForward = false;
						return false;
					}
				}
				else if (bStartForward)
				{
					if (Time < ForwardMovementDuration)
					{
						// Moving forward
						bOutForward = true;
						return true;
					}
					else
					{
						// Stopped at end
						bOutForward = true;
						return false;
					}
				}
				else
				{
					if (Time < BackwardMovementDuration)
					{
						// Moving backward
						bOutForward = false;
						return true;
					}
					else
					{
						// Stopped at start
						bOutForward = false;
						return false;
					}
				}
			}

			case EKineticMovementMode::AlwaysMoveBackAndForth:
			{
				float CycleDuration = ForwardMovementDuration + DelayAfterMovingForward + BackwardMovementDuration + DelayAfterMovingBackward;
				float CycleTime = Math::Wrap(Time, 0.0, CycleDuration);

				if (CycleTime < ForwardMovementDuration)
				{
					// Moving forward
					bOutForward = true;
					return true;
				}
				else if(CycleTime < ForwardMovementDuration + DelayAfterMovingForward)
				{
					// Stopped at end
					bOutForward = true;
					return false;
				}
				else if(CycleTime < ForwardMovementDuration + DelayAfterMovingForward + BackwardMovementDuration)
				{
					// Moving back
					bOutForward = false;
					return true;
				}
				else
				{
					// Stopped at start
					bOutForward = false;
					return false;
				}
			}
		}
	}

	/**
	 * Are we currently moving forward?
	 */
	bool IsMovingForward() const
	{
		bool bForward = false;
		if(!IsMoving(bForward))
			return false;

		return bForward;
	}

	/**
	 * Are we currently moving backward?
	 */
	bool IsMovingBackward() const
	{
		bool bForward = false;
		if(!IsMoving(bForward))
			return false;

		return !bForward;
	}

	private void UpdatePosition()
	{
		int ReachedForwardCount = 0;
		int ReachedBackwardCount = 0;
		const float Alpha = GetCurrentAlpha(ReachedForwardCount, ReachedBackwardCount);

		SetActorRelativeLocation(GetLocationAtAlpha(OriginLocation, TargetLocation, Alpha));

		if (bIsActive)
		{
			// Update if we reached a destination
			while (TotalReachedForwardCount < ReachedForwardCount)
			{
				OnReachedForward.Broadcast();
				++TotalReachedForwardCount;

#if EDITOR
				if(bDebug)
					Print("OnReachedForward");
#endif
			}

			while (TotalReachedBackwardCount < ReachedBackwardCount)
			{
				OnReachedBackward.Broadcast();
				++TotalReachedBackwardCount;

#if EDITOR
				if(bDebug)
					Print("OnReachedBackward");
#endif
			}

			// Update what direction we're moving in
			if (IsMovingBackward())
			{
				bActivatedForward = false;
				if (!bActivatedBackward)
				{
					bActivatedBackward = true;
					OnBackwardsActivated();

					OnStartBackward.Broadcast();

#if EDITOR
					if(bDebug)
						Print("OnStartBackward");
#endif
				}
			}
			else if(IsMovingForward())
			{
				bActivatedBackward = false;
				if (!bActivatedForward)
				{
					bActivatedForward = true;
					OnForwardActivated();

					OnStartForward.Broadcast();

#if EDITOR
					if(bDebug)
						Print("OnStartForward");
#endif
				}
			}
		}

		// Stop moving after we're done
		if (MovementMode == EKineticMovementMode::Manual)
		{
			float Time = GetCurrentTime();
			if (bRetractAutomatically && bStartForward)
			{
				if (Time > ForwardMovementDuration + AutoRetractDelay + BackwardMovementDuration)
					bIsActive = false;
			}
			else if (bStartForward)
			{
				if (Time > ForwardMovementDuration)
					bIsActive = false;
			}
			else
			{
				if (Time > BackwardMovementDuration)
					bIsActive = false;
			}
		}
	}

	FVector GetLocationAtAlpha(FVector Origin, FVector Target, float Alpha) const
	{
		return Math::Lerp(
			Origin,
			Target,
			Alpha,
		);
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
		UpdatePosition();
		StartCrumbTime = NewStartTime;
		bStartForward = bForward;
		bIsActive = true;
		TotalReachedForwardCount = 0;
		TotalReachedBackwardCount = 0;

		if (bPaused)
			PauseCrumbTime = GetRelevantCrumbTime();
		else
			SetActorTickEnabled(true);
		UpdatePosition();
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
		TotalReachedForwardCount = 0;
		TotalReachedBackwardCount = 0;

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
			case EKineticMovementMode::Manual:
			{
				// Snap to when the forward movement would stop (but before the wait to go back)
				StartCrumbTime = GetRelevantCrumbTime() - ForwardMovementDuration;
				bStartForward = true;
				bIsActive = false;
				SetActorTickEnabled(false);
				TotalReachedForwardCount = 0;
				TotalReachedBackwardCount = 0;

				if (bPaused)
					PauseCrumbTime = GetRelevantCrumbTime();

				UpdatePosition();
				break;
			}

			case EKineticMovementMode::AlwaysMoveBackAndForth:
				break;
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
		const FVector VisualizeTargetLocation = ActorRelativeTransform.TransformPosition(TargetLocationComp.RelativeLocation);

		if(bSimulate)
		{
			float Time = Time::GameTimeSeconds;

			if(MovementMode == EKineticMovementMode::Manual)
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

			int ReachedForwardCount = 0;
			int ReachedBackwardCount = 0;
			float Alpha = GetAlphaAtTime(
				Time,
				ReachedForwardCount,
				ReachedBackwardCount);


			const FVector RelativeLocation = GetLocationAtAlpha(ActorRelativeLocation, VisualizeTargetLocation, Alpha);

			CurrentActorTransform = FTransform(ActorRelativeRotation, RelativeLocation, ActorRelativeScale3D) * ParentTransform;
		}

		DrawTransform(Visualizer, CurrentActorTransform, KineticActorVisualizer::GetMaterial(this));

		if(bVisualizeTargetLocation && KineticActorVisualizer::IsExclusivelySelected(this))
		{
			const FTransform TargetActorTransform = FTransform(ActorRelativeRotation, VisualizeTargetLocation, ActorRelativeScale3D) * ParentTransform;
			Visualizer.DrawArrow(ActorLocation, TargetActorTransform.Location, FLinearColor::DPink, 50, 3, true);
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
};

#if EDITOR
UCLASS(NotBlueprintable, NotPlaceable)
class UKineticMovingActorEditorComponent : UActorComponent
{
};

class UKineticMovingActorEditorComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UKineticMovingActorEditorComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		if(Editor::IsPlaying())
			return;

		auto KineticMovingActor = Cast<AKineticMovingActor>(Component.Owner);
		if(KineticMovingActor == nullptr)
			return;

		if(!KineticMovingActor.bVisualize)
			return;

		if(KineticMovingActor.bVisualizeAttachedActors)
		{
			KineticActorVisualizer::VisualizeKineticChain(KineticMovingActor, this, KineticMovingActor.bSimulateOnlySelected);
		}
		else
		{
			FTransform ParentTransform = FTransform::Identity;
			if(KineticMovingActor.GetAttachParentActor() != nullptr)
				ParentTransform = KineticMovingActor.GetAttachParentActor().ActorTransform;

			FTransform OutTransform;
			KineticActorVisualizer::VisualizeSingle(KineticMovingActor, this, ParentTransform, KineticMovingActor.bSimulateOnlySelected, OutTransform);
		}
	}
};
#endif

enum EMoveSettingPrototypeGenericMovingActor
{
	AlwaysMoveBackAndForth,
	Normal
};