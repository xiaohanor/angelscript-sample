enum EKineticSplineFollowMode
{
	// Move from the start to the end of the spline and then stop
	MoveToEnd,

	// Move back and forth along the spline
	MoveBackAndForth,

	// Automatically loop from end to start on the spline
	LoopAround,
};

enum EKineticSplineFollowNetwork
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

event void FKineticSplineFollowEvent();

UCLASS(HideCategories = "Activation Rendering AssetUserData Debug Cooking Actor DataLayers")
class AKineticSplineFollowActor : AHazeActor
{
	access EditOnly = protected, * (editdefaults);
	access VisualizerOnly = protected, UKineticSplineFollowActorEditorComponentVisualizer, VisualizeSingle;

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

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.bSelectable = false;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UKineticSplineFollowActorEditorComponent EditorComp;
#endif

	/** When to move the actor. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Spline Follow")
	access:EditOnly
	EKineticSplineFollowMode MovementMode = EKineticSplineFollowMode::MoveToEnd;

	/** Which spline to move along. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Spline Follow")
	access:EditOnly
	ASplineActor SplineToFollow;

	/** Whether to start moving automatically or only when activated. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Spline Follow")
	access:EditOnly
	bool bAutoActivate = true;

	/** Whether to set the rotation of the actor to the spline's rotation. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Spline Follow", DisplayName = "Follow Spline Rotation")
	access:EditOnly
	bool bSetRotation = true;

	/** Offset to start moving at on the spline */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Spline Movement", DisplayName = "Starting Distance Along Spline")
	access:EditOnly
	float DistanceAlongSplineOffset = 0.0;
	/** Follow speed to start moving at. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Spline Movement", DisplayName = "Starting Follow Speed")
	access:EditOnly
	float CurrentFollowSpeed = 400;
	/** Follow speed to reach after accelerating. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Spline Movement")
	access:EditOnly
	float DesiredFollowSpeed = 600;
	/** Duration over which to accelerate to the desired follow speed. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Spline Movement")
	access:EditOnly
	float AccelerationDuration = 1.0;
	/** Duration over which to decelerate before stopping at the end. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Spline Movement", Meta = (EditCondition = "MovementMove != EKineticSplineFollowMode::LoopAround"))
	access:EditOnly
	float DecelerationDuration = 0.0;

	/**
	  * Disable the PlatformMesh component completely. Ideally we would remove that component, but it might be used somewhere.
	  * Will simply hide the mesh in Editor, and block Visuals, Ticking and Collision in BeginPlay.
	  */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Kinetic Spline Movement")
	bool bDisablePlatformMesh = false;

	/** Which player controls the moving actor in network. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Network")
	access:EditOnly
	EKineticSplineFollowNetwork NetworkMode = EKineticSplineFollowNetwork::Default;

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

	UPROPERTY(EditAnywhere, Category = "Kinetic Spline Movement", AdvancedDisplay)
	bool bTemporalLogTransforms = true;
#endif

	/** Called whenever the spline reaches the end or start of the spline, or loops around. */
	UPROPERTY()
	FKineticSplineFollowEvent OnReachedEnd;

	private bool bIsActive = false;
	private bool bEverMoved = false;
	private bool bPaused = false;
	private bool bReversed = false;
	private float StartCrumbTime = 0.0;
	private float PauseCrumbTime = 0.0;
	private int TotalReachedEndCount = 0;
	private TArray<FInstigator> ControlPauseInstigators;

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
			case EKineticSplineFollowNetwork::Default:
			case EKineticSplineFollowNetwork::Local:
			case EKineticSplineFollowNetwork::SyncedFromHost:
			case EKineticSplineFollowNetwork::PredictedSyncPosition:
				// Host control is the default
				break;

			case EKineticSplineFollowNetwork::SyncedFromMioControl:
			case EKineticSplineFollowNetwork::PredictedToMioControl:
				SetActorControlSide(Game::Mio);
				break;

			case EKineticSplineFollowNetwork::SyncedFromZoeControl:
			case EKineticSplineFollowNetwork::PredictedToZoeControl:
				SetActorControlSide(Game::Zoe);
				break;
		}

		StartCrumbTime = 0.0;
		bIsActive = false;

		if (bAutoActivate)
			InternalActivateMovement(StartCrumbTime);

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

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsActive && !bPaused)
			UpdatePosition();
		else
			SetActorTickEnabled(false);
	}

	private float GetRelevantCrumbTime() const
	{
		switch(NetworkMode)
		{
			case EKineticSplineFollowNetwork::Default:
				if (bAutoActivate)
					return Time::GetPredictedGlobalCrumbTrailTime();
				else
					return Time::GameTimeSeconds;

			case EKineticSplineFollowNetwork::Local:
				return Time::GameTimeSeconds;

			case EKineticSplineFollowNetwork::SyncedFromHost:
			case EKineticSplineFollowNetwork::SyncedFromMioControl:
			case EKineticSplineFollowNetwork::SyncedFromZoeControl:
				return Time::GetActorControlCrumbTrailTime(this);

			case EKineticSplineFollowNetwork::PredictedSyncPosition:
				return Time::GetPredictedGlobalCrumbTrailTime();

			case EKineticSplineFollowNetwork::PredictedToMioControl:
			{
				if(Game::Mio.HasControl())
					return Time::ThisSideCrumbTrailSendTime;
				else
					return Time::OtherSideCrumbTrailSendTimePrediction;
			}

			case EKineticSplineFollowNetwork::PredictedToZoeControl:
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
			case EKineticSplineFollowNetwork::Default:
				if (bAutoActivate)
					return false;
				else
					return true;

			case EKineticSplineFollowNetwork::Local:
				return true;

			default:
				return false;
		}
	}

	bool IsActive() const
	{
		return bIsActive;
	}

	bool IsReversed() const
	{
		return bReversed;
	}

	ASplineActor GetFollowSpline() const
	{
		return SplineToFollow;
	}

	/** Activate the spline follow */
	UFUNCTION()
	void ActivateFollowSpline()
	{
		float NewStartTime = GetRelevantCrumbTime();
		if (IsLocalMovement())
			InternalActivateMovement(NewStartTime);
		else if (HasControl())
			CrumbActivateMovement(NewStartTime);
	}

	/** Reverse direction on the spline */
	UFUNCTION()
	void ReverseDirection()
	{
		if (SplineToFollow == nullptr)
			return;

		float Time = GetCurrentTime();

		float SplineDistance = 0.0;
		int ReachedEndCount = 0;
		GetSplineDistanceAtTime(Time, SplineDistance, ReachedEndCount);

		float SplineLength = SplineToFollow.Spline.SplineLength;

		bool bNewReversed = false;
		if (MovementMode == EKineticSplineFollowMode::MoveBackAndForth)
			bNewReversed = (TotalReachedEndCount % 2 == 0) != bReversed;
		else
			bNewReversed = !bReversed;

		if (bNewReversed)
			SplineDistance = SplineLength - SplineDistance;

		float CrumbTime = GetRelevantCrumbTime();
		float NewStartTime = CrumbTime - (SplineDistance / DesiredFollowSpeed);

		if (IsLocalMovement())
			InternalReverseDirection(NewStartTime, bNewReversed, TotalReachedEndCount);
		else if (HasControl())
			CrumbReverseDirection(NewStartTime, bNewReversed, TotalReachedEndCount);
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
					InternalUnpauseMovement();
				else
					CrumbUnpauseMovement();
			}
		}
	}

	/** Set the distance along spline, can only be used when not active */
	UFUNCTION()
	void SetInitialDistanceAlongSpline(float NewDistanceAlongSpline)
	{
		if (bEverMoved)
		{
			devError("Cannot change initial distance along spline after actor has started moving.");
			return;
		}

		DistanceAlongSplineOffset = NewDistanceAlongSpline;
	}

	UFUNCTION()
	void SnapSplinePositionToStart()
	{
		SnapSplinePositionToDistanceAlongSpline(0);
	}

	UFUNCTION()
	void SnapSplinePositionToEnd()
	{
		SnapSplinePositionToDistanceAlongSpline(SplineToFollow.Spline.SplineLength);
	}

	UFUNCTION()
	void SnapSplinePositionToClosestDistanceAlongSpline()
	{
		const float ClosestSplineDistance = SplineToFollow.Spline.GetClosestSplineDistanceToWorldLocation(ActorLocation);
		SnapSplinePositionToDistanceAlongSpline(ClosestSplineDistance);
	}

	UFUNCTION()
	void SnapSplinePositionToDistanceAlongSpline(float DistanceAlongSpline)
	{
		bool bForward = true;
		if (MovementMode == EKineticSplineFollowMode::MoveBackAndForth)
			bForward = (TotalReachedEndCount % 2 == 0);

		if (IsLocalMovement())
			InternalSnapToDistanceAlongSpline(DistanceAlongSpline, bForward);
		else if (HasControl())
			CrumbSnapToDistanceAlongSpline(DistanceAlongSpline, bForward);
	}

	UFUNCTION()
	void SetNewSplineToFollow(ASplineActor SplineActor, bool bStartAtClosestSplinePosition = false)
	{
		if (SplineActor != nullptr)
			SplineToFollow = SplineActor;

		if (bStartAtClosestSplinePosition)
			SnapSplinePositionToClosestDistanceAlongSpline();
		else
			SnapSplinePositionToStart();
	}

#if EDITOR
	UFUNCTION(CallInEditor, Category = "Kinetic Spline Movement")
	void AutoSetInitialDistanceAlongSpline()
	{
		if(SplineToFollow == nullptr)
			return;

		SetInitialDistanceAlongSpline(SplineToFollow.Spline.GetClosestSplineDistanceToWorldLocation(ActorLocation));
	}

	UFUNCTION(CallInEditor, Category = "Kinetic Spline Movement")
	void AutoSetActorLocationFromClosestSplineLocation()
	{
		if(SplineToFollow == nullptr)
			return;

		SetActorLocation(SplineToFollow.Spline.GetClosestSplineWorldLocationToWorldLocation(ActorLocation));
	}

	UFUNCTION(CallInEditor, Category = "Kinetic Spline Movement")
	void AutoSetActorRotationFromClosestSplineRotation()
	{
		if(SplineToFollow == nullptr)
			return;

		SetActorRotation(SplineToFollow.Spline.GetClosestSplineWorldRotationToWorldLocation(ActorLocation));
	}
#endif

	float GetCurrentTime() const
	{
		if (bPaused)
			return PauseCrumbTime - StartCrumbTime;
		else if (!bEverMoved)
			return 0.0;
		else
			return GetRelevantCrumbTime() - StartCrumbTime;
	}

	float GetDurationOfSingleCycle(
		float StartDistance, float SplineLength, float StartSpeed,
		float DesiredSpeed, float AccelDuration, float DecelDuration
	) const
	{
		// Check if acceleration and deceleration times overlap
		float RemainingDistance = SplineLength - StartDistance;
		if (Math::IsNearlyZero(RemainingDistance))
			return 0;
		if (Math::IsNearlyZero(DesiredSpeed))
			return 0;

		float DistanceDuringAcceleration = StartSpeed * AccelDuration + 0.5 * (DesiredSpeed - StartSpeed) * AccelDuration;
		float DistanceDuringDeceleration = DesiredSpeed * DecelDuration * 0.5;

		if (DistanceDuringAcceleration > RemainingDistance)
		{
			// We aren't able to accelerate up to full speed in time
			float Acceleration = (DesiredSpeed - StartSpeed) / AccelDuration;
			return Trajectory::GetTimeToReachTarget(RemainingDistance, StartSpeed, DesiredSpeed, Acceleration);
		}
		else if (DistanceDuringAcceleration + DistanceDuringDeceleration > RemainingDistance)
		{
			// We aren't able to decelerate in time
			float Deceleration = -DesiredSpeed / AccelerationDuration;
			return AccelDuration + Trajectory::GetTimeToReachTarget(RemainingDistance - DistanceDuringAcceleration, DesiredSpeed, 0, Deceleration);
		}
		else
		{
			// We reach full speed before we decelerate
			return AccelDuration + DecelDuration + (RemainingDistance - DistanceDuringAcceleration - DistanceDuringDeceleration) / DesiredSpeed;
		}
	}

	float GetSplineDistanceWithinSingleCycle(
		float StartDistance, float SplineLength, float StartSpeed,
		float DesiredSpeed, float AccelDuration, float DecelDuration,
		float CycleTime
	) const
	{
		float RemainingDistance = SplineLength - StartDistance;
		if (Math::IsNearlyZero(RemainingDistance))
			return 0;
		if (Math::IsNearlyZero(DesiredSpeed))
			return 0;

		// Calculate when we actually start decelerating time wise
		float DistanceDuringAcceleration = StartSpeed * AccelDuration + 0.5 * (DesiredSpeed - StartSpeed) * AccelDuration;
		float DistanceDuringDeceleration = DesiredSpeed * DecelDuration * 0.5;

		float TimeStartDecelerating = 0.0;
		if (DistanceDuringAcceleration > RemainingDistance)
			TimeStartDecelerating = MAX_flt;
		else if (DistanceDuringAcceleration + DistanceDuringDeceleration > RemainingDistance)
			TimeStartDecelerating = AccelDuration;
		else
			TimeStartDecelerating = AccelDuration + (RemainingDistance - DistanceDuringAcceleration - DistanceDuringDeceleration) / DesiredSpeed;

		// Acceleration
		float Distance = StartDistance;
		float AccelTime = Math::Min(AccelDuration, CycleTime);
		if (AccelTime > 0)
		{
			float Acceleration = (DesiredSpeed - StartSpeed) / AccelDuration;
			Distance += (StartSpeed * AccelTime) + Acceleration * Math::Square(AccelTime) * 0.5;
		}

		// Deceleration
		float DecelTime = Math::Clamp(CycleTime - TimeStartDecelerating, 0.0, DecelDuration);
		if (DecelTime > 0)
		{
			float Deceleration = DesiredSpeed / DecelDuration;
			Distance += (DesiredSpeed * DecelTime) - Deceleration * Math::Square(DecelTime) * 0.5;
		}

		// Maintained velocity
		float TimeMaintained = Math::Max(CycleTime - AccelTime - DecelTime, 0);
		Distance += TimeMaintained * DesiredSpeed;

		return Distance;
	}

	void GetSplineDistanceAtTime(float InTime, float&out SplineDistance, int&out ReachedEndCount) const
	{
		if (SplineToFollow == nullptr)
			return;
		float SplineLength = SplineToFollow.Spline.SplineLength;

		if (SplineLength < 0.01)
			return;

		if (DesiredFollowSpeed < 0.01)
			return;

		SplineDistance = 0.0;
		if (MovementMode == EKineticSplineFollowMode::LoopAround)
		{
			SplineDistance += DistanceAlongSplineOffset;

			// Cover distance during the initial acceleration
			float AccelTime = 0.0;
			if (AccelerationDuration > 0.0 && DesiredFollowSpeed != CurrentFollowSpeed)
			{
				AccelTime = Math::Min(AccelerationDuration, InTime);
				float Acceleration = (DesiredFollowSpeed - CurrentFollowSpeed) / AccelerationDuration;

				SplineDistance += CurrentFollowSpeed * AccelTime;
				SplineDistance += Acceleration * AccelTime * AccelTime * 0.5;
			}

			// Cover distance afterward cruising
			float CruiseTime = Math::Max(InTime - AccelTime, 0.0);
			SplineDistance += CruiseTime * DesiredFollowSpeed;

			// Loop around to the beginning of the spline
			ReachedEndCount = Math::FloorToInt(SplineDistance / SplineLength);
			SplineDistance = SplineDistance % SplineLength;
		}
		else if (MovementMode == EKineticSplineFollowMode::MoveToEnd)
		{
			SplineDistance = GetSplineDistanceWithinSingleCycle(
				DistanceAlongSplineOffset,
				SplineLength, CurrentFollowSpeed, DesiredFollowSpeed,
				AccelerationDuration, DecelerationDuration,
				InTime,
			);

			// Stop at the end of the spline
			if (SplineDistance >= SplineLength)
			{
				ReachedEndCount = 1;
				SplineDistance = SplineLength;
			}
		}
		else if (MovementMode == EKineticSplineFollowMode::MoveBackAndForth)
		{
			// We need to treat the first bounce differently, because it has configurable starting speed.
			// The subsequent bounces have 0 starting speed.
			float FirstBounceTime = GetDurationOfSingleCycle(
				DistanceAlongSplineOffset, SplineLength, CurrentFollowSpeed, DesiredFollowSpeed,
				AccelerationDuration, DecelerationDuration
			);

			// Subsequent bounces accelerate from zero
			float SubsequentBounceTime = GetDurationOfSingleCycle(
				0, SplineLength, 0, DesiredFollowSpeed,
				AccelerationDuration, DecelerationDuration
			);

			if (InTime < FirstBounceTime)
			{
				// Treat the first bounce specially
				ReachedEndCount = 0;
				SplineDistance = GetSplineDistanceWithinSingleCycle(
					DistanceAlongSplineOffset,
					SplineLength, CurrentFollowSpeed, DesiredFollowSpeed,
					AccelerationDuration, DecelerationDuration,
					InTime,
				);
			}
			else
			{
				// Figure out which bounce we are in
				ReachedEndCount = 1 + Math::FloorToInt((InTime - FirstBounceTime) / SubsequentBounceTime);

				// Get position in the current bounce
				float TimeInBounce = (InTime - FirstBounceTime) % SubsequentBounceTime;
				SplineDistance = GetSplineDistanceWithinSingleCycle(
					0,
					SplineLength, 0, DesiredFollowSpeed,
					AccelerationDuration, DecelerationDuration,
					TimeInBounce,
				);

				// Is this bounce going forward or backward?
				bool bForward = (ReachedEndCount % 2) == 0;
				if (!bForward)
					SplineDistance = SplineLength - SplineDistance;
			}
		}

		// If we are moving in reverse, we should be on the opposite end of the spline
		if (bReversed)
			SplineDistance = SplineLength - SplineDistance;
	}

	/**
	 * NOTE: This function for MoveBackAndForth always works as if it is the second loop, so StartingFollowSpeed is ignored.
	 */
	float GetTimeForSplineDistance(float SplineDistance, bool bForward) const
	{
		if (SplineToFollow == nullptr)
			return 0;

		float SplineLength = SplineToFollow.Spline.SplineLength;
		if (SplineLength < 0.01)
			return 0;

		if (DesiredFollowSpeed < 0.01)
			return 0;

		bool bMovingForward = (bForward != bReversed);
		float TargetSplineDistance = SplineDistance;
		if (!bMovingForward)
			TargetSplineDistance = SplineLength - SplineDistance;

		if (MovementMode == EKineticSplineFollowMode::LoopAround)
		{
			float DistanceDuringAcceleration = CurrentFollowSpeed * AccelerationDuration + 0.5 * (DesiredFollowSpeed - CurrentFollowSpeed) * AccelerationDuration;
			float BeginNormalTime = AccelerationDuration + (SplineLength - DistanceDuringAcceleration) / DesiredFollowSpeed;
			return BeginNormalTime + TargetSplineDistance / DesiredFollowSpeed;
		}
		else if (MovementMode == EKineticSplineFollowMode::MoveToEnd)
		{
			float DistanceDuringAcceleration = CurrentFollowSpeed * AccelerationDuration + 0.5 * (DesiredFollowSpeed - CurrentFollowSpeed) * AccelerationDuration;
			float DistanceDuringDeceleration = DesiredFollowSpeed * DecelerationDuration * 0.5;

			if (TargetSplineDistance < DistanceDuringAcceleration)
			{
				return Trajectory::GetTimeToReachTarget(TargetSplineDistance, CurrentFollowSpeed, DesiredFollowSpeed / AccelerationDuration);
			}
			else if (TargetSplineDistance > SplineLength - DistanceDuringDeceleration)
			{
				return AccelerationDuration
					+ (SplineLength - DistanceDuringAcceleration + DistanceDuringDeceleration) / DesiredFollowSpeed
					+ Trajectory::GetTimeToReachTarget(TargetSplineDistance - (SplineLength - DistanceDuringDeceleration), DesiredFollowSpeed, -DesiredFollowSpeed / DecelerationDuration);
			}
			else
			{
				return AccelerationDuration
					+ (TargetSplineDistance - DistanceDuringAcceleration) / DesiredFollowSpeed;
			}
		}
		else if (MovementMode == EKineticSplineFollowMode::MoveBackAndForth)
		{
			// We need to treat the first bounce differently, because it has configurable starting speed.
			// The subsequent bounces have 0 starting speed.
			float FirstBounceTime = GetDurationOfSingleCycle(
				DistanceAlongSplineOffset, SplineLength, CurrentFollowSpeed, DesiredFollowSpeed,
				AccelerationDuration, DecelerationDuration
			);

			// Subsequent bounces accelerate from zero
			float SubsequentBounceTime = GetDurationOfSingleCycle(
				0, SplineLength, 0, DesiredFollowSpeed,
				AccelerationDuration, DecelerationDuration
			);

			float BeginNormalTime = FirstBounceTime;
			if (bMovingForward)
				BeginNormalTime += SubsequentBounceTime;

			float StartSpeed = 0;
			float DistanceDuringAcceleration = StartSpeed * AccelerationDuration + 0.5 * (DesiredFollowSpeed - StartSpeed) * AccelerationDuration;
			float DistanceDuringDeceleration = DesiredFollowSpeed * DecelerationDuration * 0.5;

			if (TargetSplineDistance < DistanceDuringAcceleration)
			{
				return BeginNormalTime
					+ Trajectory::GetTimeToReachTarget(TargetSplineDistance, StartSpeed, DesiredFollowSpeed / AccelerationDuration);
			}
			else if (TargetSplineDistance > SplineLength - DistanceDuringDeceleration)
			{
				return BeginNormalTime
					+ SubsequentBounceTime
					- DecelerationDuration
					+ Trajectory::GetTimeToReachTarget(TargetSplineDistance - (SplineLength - DistanceDuringDeceleration), DesiredFollowSpeed, -DesiredFollowSpeed / DecelerationDuration);
			}
			else
			{
				return BeginNormalTime
					+ AccelerationDuration
					+ (TargetSplineDistance - DistanceDuringAcceleration) / DesiredFollowSpeed;
			}
		}

		return 0;
	}

	private void UpdatePosition()
	{
		if (SplineToFollow == nullptr)
			return;

		float Time = GetCurrentTime();
		float SplineDistance = 0.0;
		int ReachedEndCount = 0;
		GetSplineDistanceAtTime(Time, SplineDistance, ReachedEndCount);

		FTransform SplineTransform = SplineToFollow.Spline.GetWorldTransformAtSplineDistance(SplineDistance);

		if (bSetRotation)
			SetActorLocationAndRotation(SplineTransform.Location, SplineTransform.Rotation);
		else
			SetActorLocation(SplineTransform.Location);

		// Stop moving after we're done
		if (MovementMode == EKineticSplineFollowMode::MoveToEnd)
		{
			if (ReachedEndCount > 0)
				bIsActive = false;
		}

		// Call the event whenever we reach the end of the spline
		while (TotalReachedEndCount < ReachedEndCount)
		{
			OnReachedEnd.Broadcast();
			++TotalReachedEndCount;
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbActivateMovement(float NewStartTime)
	{
		InternalActivateMovement(NewStartTime);
	}

	private void InternalActivateMovement(float NewStartTime)
	{
		// Update the position so we can actually receive all 'reached end' events we want
		if (bEverMoved)
			UpdatePosition();

		TotalReachedEndCount = 0;
		StartCrumbTime = NewStartTime;
		bIsActive = true;
		bEverMoved = true;
		if (bPaused)
			PauseCrumbTime = GetRelevantCrumbTime();
		else
			SetActorTickEnabled(true);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbReverseDirection(float NewStartTime, bool bNewReversed, int ControlTotalReachedEndCount)
	{
		InternalReverseDirection(NewStartTime, bNewReversed, ControlTotalReachedEndCount);
	}

	private void InternalReverseDirection(float NewStartTime, bool bNewReversed, int ControlTotalReachedEndCount)
	{
		// Call the event whenever we reach the end of the spline
		while (TotalReachedEndCount < ControlTotalReachedEndCount)
		{
			OnReachedEnd.Broadcast();
			++TotalReachedEndCount;
		}

		bIsActive = true;
		bEverMoved = true;
		bReversed = bNewReversed;
		TotalReachedEndCount = 0;
		AccelerationDuration = 0.0;
		DistanceAlongSplineOffset = 0.0;
		StartCrumbTime = NewStartTime;

		UpdatePosition();
		if (bPaused)
			PauseCrumbTime = GetRelevantCrumbTime();
		else
			SetActorTickEnabled(true);
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
	private void CrumbUnpauseMovement()
	{
		InternalUnpauseMovement();
	}

	private void InternalUnpauseMovement()
	{
		bPaused = false;
		StartCrumbTime = GetRelevantCrumbTime() - PauseCrumbTime + StartCrumbTime;
		UpdatePosition();
		if (bIsActive)
			SetActorTickEnabled(true);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSnapToDistanceAlongSpline(float DistanceAlongSpline, bool bForward)
	{
		InternalSnapToDistanceAlongSpline(DistanceAlongSpline, bForward);
	}

	private void InternalSnapToDistanceAlongSpline(float DistanceAlongSpline, bool bForward)
	{
		// Clamp our distance along spline, and get the time when we would be at that distance.
		const float TimeToDistance = GetTimeForSplineDistance(
			Math::Clamp(DistanceAlongSpline, 0, SplineToFollow.Spline.SplineLength),
			bForward
		);

		// Set the start time in the past, so that we are currently at the distance we want to be.
		StartCrumbTime = GetRelevantCrumbTime() - TimeToDistance;

		float Time = GetCurrentTime();
		float SplineDistance = 0.0;
		int ReachedEndCount = 0;
		GetSplineDistanceAtTime(Time, SplineDistance, ReachedEndCount);

		// Update TotalReachedEndCount to prevent sending events from this snap
		TotalReachedEndCount = ReachedEndCount;

		if(MovementMode == EKineticSplineFollowMode::MoveBackAndForth)
		{
			// When moving back and forth, we add one, since when we snap to the start or end we technically snap to just before it.
			TotalReachedEndCount++;
		}

		// We need to set that we have moved for UpdatePosition to run correctly
		bEverMoved = true;

		// If paused, also update the paused time
		if (bPaused)
			PauseCrumbTime = GetRelevantCrumbTime();

		UpdatePosition();
	}

#if EDITOR
	void EditorOnly_SetInitialSplinePosition(float NewPosition)
	{
		DistanceAlongSplineOffset = NewPosition;
	}

	void Visualize(const UHazeScriptComponentVisualizer Visualizer, FTransform ParentTransform, bool bSimulate, FTransform&out OutTransform) const
	{
		if(Visualizer == nullptr)
			return;

		if(SplineToFollow == nullptr)
			return;

		FTransform CurrentActorTransform = ActorRelativeTransform * ParentTransform;

		if(bSimulate)
		{
			float Time = Time::GameTimeSeconds;

			if(MovementMode == EKineticSplineFollowMode::MoveToEnd)
			{
				// If we want to move to the end, calculate how long that will take and make the visualizing time loop
				float TimeToReachEnd = 0;
				if (AccelerationDuration > 0.0 && DesiredFollowSpeed != CurrentFollowSpeed)
				{
					const float Acceleration = (DesiredFollowSpeed - CurrentFollowSpeed) / AccelerationDuration;

					const float DistanceToEnd = SplineToFollow.Spline.SplineLength - DistanceAlongSplineOffset;

					float SplineDistanceToFullAcceleration = CurrentFollowSpeed * AccelerationDuration;
					SplineDistanceToFullAcceleration += Acceleration * Math::Square(AccelerationDuration) * 0.5;

					if(SplineDistanceToFullAcceleration > DistanceToEnd)
					{
						// We didn't finish accelerating until we hit the end, calculate where in the acceleration we reached it
						const float A = Acceleration;
						const float B = CurrentFollowSpeed * 2;
						const float C = -DistanceToEnd * 2;

						// B² - 4AC
						const float Radicand = Math::Square(B) - (4 * (A * C));

						if(Radicand >= 0)
							TimeToReachEnd = (-B + Math::Sqrt(Radicand)) / (2 * A);
					}
					else
					{
						// We finished accelerating before reaching the end, add the "cruise" time to the duration
						const float SplineDistanceLeftAfterAcceleration = DistanceToEnd - SplineDistanceToFullAcceleration;
						const float TimeToCruise = SplineDistanceLeftAfterAcceleration / DesiredFollowSpeed;
						TimeToReachEnd = AccelerationDuration + TimeToCruise;
					}
				}
				else
				{
					TimeToReachEnd = (SplineToFollow.Spline.SplineLength - DistanceAlongSplineOffset) / DesiredFollowSpeed;
				}

				// Small delay when reaching end
				TimeToReachEnd += 1;
				Time %= TimeToReachEnd;
			}

			float SplineDistance = 0;
			int ReachedEndCount = 0;
			GetSplineDistanceAtTime(
				Time,
				SplineDistance,
				ReachedEndCount
			);

			const FTransform RelativeSplineTransform = SplineToFollow.Spline.GetWorldTransformAtSplineDistance(SplineDistance).GetRelativeTransform(SplineToFollow.ActorTransform);
			const FTransform SplineActorTransform = SplineToFollow.ActorRelativeTransform * ParentTransform;
			const FTransform SplineTransform = RelativeSplineTransform * SplineActorTransform;

			if (bSetRotation)
			{
				CurrentActorTransform.SetLocation(SplineTransform.Location);
				CurrentActorTransform.SetRotation(SplineTransform.Rotation);
			}
			else
			{
				CurrentActorTransform.SetLocation(SplineTransform.Location);
			}
		}

		auto Material = KineticActorVisualizer::GetMaterial(this);

		if(KineticActorVisualizer::bVisualizeOnlyMainMesh)
		{
			if(IsValid(PlatformMesh) && PlatformMesh.bVisible)
			{
				const FTransform CurrentMeshTransform = PlatformMesh.RelativeTransform * CurrentActorTransform;

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
			KineticActorVisualizer::DrawAllStaticMeshesOnActor(Visualizer, this, CurrentActorTransform, Material);
		}

		OutTransform = CurrentActorTransform;
	}
#endif
}

#if EDITOR
UCLASS(NotBlueprintable, NotPlaceable, HideCategories = "ComponentTick Debug Activation Cooking Disable Tags AssetUserData Navigation")
class UKineticSplineFollowActorEditorComponent : UActorComponent
{
};

class UKineticSplineFollowActorEditorComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UKineticSplineFollowActorEditorComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		if(Editor::IsPlaying())
			return;

		auto KineticSplineFollowActor = Cast<AKineticSplineFollowActor>(Component.Owner);
		if(KineticSplineFollowActor == nullptr)
			return;

		if(!KineticSplineFollowActor.bVisualize)
			return;

		if(KineticSplineFollowActor.bVisualizeAttachedActors)
		{
			KineticActorVisualizer::VisualizeKineticChain(KineticSplineFollowActor, this, KineticSplineFollowActor.bSimulateOnlySelected);
		}
		else
		{
			FTransform ParentTransform = FTransform::Identity;
			if(KineticSplineFollowActor.GetAttachParentActor() != nullptr)
				ParentTransform = KineticSplineFollowActor.GetAttachParentActor().ActorTransform;

			FTransform OutTransform;
			KineticActorVisualizer::VisualizeSingle(KineticSplineFollowActor, this, ParentTransform, KineticSplineFollowActor.bSimulateOnlySelected, OutTransform);
		}
	}
};
#endif