enum EMaxSecurityLaserNetwork
{
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
};

enum EMaxSecurityLaserSplineMovement
{
	Constant,
	Curve,
};

enum EMaxSecurityLaserSplineWrapMode
{
	LoopBackToStart,
	MoveBackAndForth,
};

UCLASS(Abstract, HideCategories = "Collision Actor Cooking")
class AMaxSecurityLaser : AHazeActor
{	
	access Visualized = private, UMaxSecurityLaserEditorComponentVisualizer;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp, ShowOnActor)
	UMaxSecurityLaserComponent LaserComp;

	UPROPERTY(DefaultComponent, Attach = LaserComp)
	UStaticMeshComponent LaserMeshComp;
	default LaserMeshComp.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = LaserComp)
	UStaticMeshComponent MeshComp;
	default MeshComp.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000;
	default DisableComp.bActorIsVisualOnly = true;

#if EDITOR
	UPROPERTY(DefaultComponent, ShowOnActor)
	UMaxSecurityLaserEditorComponent EditorComp;
#endif

	/**
	 * Spline Movement
	 */

	UPROPERTY(EditInstanceOnly, Category = "Spline")
	private AHazeActor SplineActor;
	private UHazeSplineComponent SplineComp;

	UPROPERTY(EditInstanceOnly, Category = "Spline", Meta = (EditCondition = "SplineActor != nullptr", EditConditionHides))
	EMaxSecurityLaserSplineMovement SplineMovement = EMaxSecurityLaserSplineMovement::Constant;

	UPROPERTY(EditInstanceOnly, Category = "Spline", Meta = (EditCondition = "SplineActor != nullptr", EditConditionHides))
	EMaxSecurityLaserSplineWrapMode SplineWrapMode = EMaxSecurityLaserSplineWrapMode::LoopBackToStart;

	UPROPERTY(EditAnywhere, Category = "Spline", Meta = (EditCondition = "SplineActor != nullptr", EditConditionHides))
	float SplineHeightOffset = 0.0;

	UPROPERTY(EditAnywhere, Category = "Spline", Meta = (EditCondition = "SplineActor != nullptr", EditConditionHides))
	bool bFollowSplineRotation = false;

	UPROPERTY(EditAnywhere, Category = "Spline", Meta = (EditCondition = "bFollowSplineRotation", EditConditionHides))
	bool bOnlyFollowYaw = false;

	UPROPERTY(EditInstanceOnly, Category = "Spline", Meta = (EditCondition = "SplineActor != nullptr", EditConditionHides))
	bool bSetInitialSplineAlpha = false;

	UPROPERTY(EditInstanceOnly, meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"), Category = "Spline", Meta = (EditCondition = "SplineActor != nullptr && bSetInitialSplineAlpha", EditConditionHides))
	float InitialSplineAlpha = 0.0;

	/**
	 * Spline | Constant
	 */

	UPROPERTY(EditAnywhere, Category = "Spline|Constant", Meta = (EditCondition = "SplineActor != nullptr && SplineMovement == EMaxSecurityLaserSplineMovement::Constant", EditConditionHides))
	bool bMoveForward = true;

	UPROPERTY(EditAnywhere, Category = "Spline|Constant", Meta = (EditCondition = "SplineActor != nullptr && SplineMovement == EMaxSecurityLaserSplineMovement::Constant", EditConditionHides))
	float MoveSpeed = 1000.0;

	/**
	 * Spline | Curve
	 */

	UPROPERTY(EditAnywhere, Category = "Spline|Curve", Meta = (EditCondition = "SplineActor != nullptr && SplineMovement == EMaxSecurityLaserSplineMovement::Curve", EditConditionHides))
	FRuntimeFloatCurve SplineTimeCurve;

	UPROPERTY(EditAnywhere, Category = "Spline|Curve")
	float SplineDelay = 0.0;

	UPROPERTY(EditAnywhere, Category = "Spline|Curve", Meta = (EditCondition = "SplineActor != nullptr && SplineMovement == EMaxSecurityLaserSplineMovement::Curve", EditConditionHides))
	float SplinePlayRate = 1.0;

	/**
	 * Rotation
	 */

	UPROPERTY(EditInstanceOnly, Category = "Rotation")
	bool bSetInitialRotationAlpha = true;

	UPROPERTY(EditInstanceOnly, Meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"), Category = "Rotation", Meta = (EditCondition = "bSetInitialRotationAlpha", EditConditionHides))
	float InitialRotationAlpha = 0.0;

	UPROPERTY(EditAnywhere, Category = "Rotation")
	float RotationDelay = 0.0;

	/**
	 * Rotation | Constant
	 */

	UPROPERTY(EditAnywhere, Category = "Rotation|Constant")
	bool bUseConstantRotation = false;

	UPROPERTY(EditAnywhere, Category = "Rotation|Constant", Meta = (EditCondition = "bUseConstantRotation"))
	FRotator ConstantRotationRate = FRotator::ZeroRotator;

	/**
	 * Rotation | Curve
	 */

	UPROPERTY(EditAnywhere, Category = "Rotation|Curve")
	bool bUseRotationCurve = false;

	UPROPERTY(EditAnywhere, Category = "Rotation|Curve", Meta = (EditCondition = "bUseRotationCurve", EditConditionHides))
	FRuntimeFloatCurve RotationTimeCurve;

	UPROPERTY(EditAnywhere, Category = "Rotation|Curve", Meta = (EditCondition = "bUseRotationCurve", EditConditionHides))
	float RotationPlayRate = 1.0;

	UPROPERTY(EditAnywhere, Category = "Rotation|Curve", Meta = (EditCondition = "bUseRotationCurve", EditConditionHides))
	FRotator TargetRotation = FRotator::ZeroRotator;

	/**
	 * Network
	 */

	/** Which player controls the moving actor in network. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Network")
	protected EMaxSecurityLaserNetwork NetworkMode = EMaxSecurityLaserNetwork::SyncedFromHost;

	// AUDIO

	UPROPERTY(EditInstanceOnly, Category = Audio)
	FSoundDefReference SoundDef;
	
	UPROPERTY(EditInstanceOnly, Category = Audio)
	ASpotSound SpotSound = nullptr;

	UPROPERTY(EditInstanceOnly, Category = Audio)
	int32 LaserCount = 1;

	bool bHasAudio = false;
	private FVector LastBeamEnd;
	private AHazeActor EventHandlerTargetActor;
	
	UPROPERTY(VisibleInstanceOnly, Category = Audio)
	AMaxSecurityLaserAudioVolume AudioVolume = nullptr;

	// INTERNAL

	private bool bMoving = false;
	bool bWillEverMove = false;
	private bool bEverMoved = false;
	private bool bPaused = false;
	private bool bReversed = false;
	private float StartCrumbTime = 0.0;
	private float PauseCrumbTime = 0.0;
	private int TotalReachedEndCount = 0;
	int SingletonRegistrationIndex = -1;
	private TArray<FInstigator> ControlPauseInstigators;
	FRotator InitialRelativeRotation;

	private float GetRelevantCrumbTime() const
	{
		if (NetworkMode == EMaxSecurityLaserNetwork::PredictedSyncPosition)
			return Time::GetPredictedGlobalCrumbTrailTime();
		else
			return Time::GetActorControlCrumbTrailTime(this);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		if(SplineActor != nullptr && bSetInitialSplineAlpha)
		{
			UHazeSplineComponent Spline = UHazeSplineComponent::Get(SplineActor);
			FTransform PreviewTransform;

			switch(SplineMovement)
			{
				case EMaxSecurityLaserSplineMovement::Constant:
				{
					PreviewTransform = Spline.GetWorldTransformAtSplineDistance(Spline.SplineLength * InitialSplineAlpha);
					if (SplineHeightOffset != 0.0)
						PreviewTransform.SetLocation(PreviewTransform.Location + (PreviewTransform.Rotation.UpVector * SplineHeightOffset));

					break;
				}

				case EMaxSecurityLaserSplineMovement::Curve:
				{
					float Alpha = SplineTimeCurve.GetFloatValue(InitialSplineAlpha * GetSplineCurveDuration());
					PreviewTransform = Spline.GetWorldTransformAtSplineDistance(Spline.SplineLength * Alpha);
					if (SplineHeightOffset != 0.0)
						PreviewTransform.SetLocation(PreviewTransform.Location + PreviewTransform.Location + (PreviewTransform.Rotation.UpVector * SplineHeightOffset));

					break;
				}
			}

			SetActorLocation(PreviewTransform.Location);
			
			if (bFollowSplineRotation)
			{
				FRotator PreviewRot = PreviewTransform.Rotator();
				if (bOnlyFollowYaw)
				{
					PreviewRot.Roll = 0.0;
					PreviewRot.Pitch = 0.0;
				}
				SetActorRotation(PreviewRot);
			}
		}

		if (LaserComp.bShowEmitter)
		{
			MeshComp.SetVisibility(true);
		}
		else
		{
			MeshComp.SetVisibility(false);
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitializeInitialState();

		switch (NetworkMode)
		{
			case EMaxSecurityLaserNetwork::Local:
				break;

			case EMaxSecurityLaserNetwork::SyncedFromHost:	// Host control is the default
				break;

			case EMaxSecurityLaserNetwork::SyncedFromMioControl:
				SetActorControlSide(Game::Mio);
				break;

			case EMaxSecurityLaserNetwork::SyncedFromZoeControl:
				SetActorControlSide(Game::Zoe);
				break;

			case EMaxSecurityLaserNetwork::PredictedSyncPosition:	// Control on host
				break;
		}

		StartCrumbTime = GetRelevantCrumbTime();
		bMoving = false;

		if (SplineActor != nullptr)
			bWillEverMove = true;
		else if (bUseConstantRotation)
			bWillEverMove = true;
		else if (bUseRotationCurve)
			bWillEverMove = true;

		// Always auto activate
		InternalActivateMovement(StartCrumbTime);

		bHasAudio = SoundDef.SoundDef != nullptr || SpotSound != nullptr;

		if(bHasAudio)
			Timer::SetTimer(this, n"LateBeginPlay", 0.1);

		RegisterToSingleton();
	}

	UFUNCTION()
	void LateBeginPlay()
	{
		UMaxSecurityLaserEventHandler::Trigger_SetupLaser(this, FMaxSecurityLaserSetupParams(this));
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		UnregisterFromSingleton();
	}

	private void RegisterToSingleton()
	{
		if (SingletonRegistrationIndex == -1)
		{
			auto Singleton = Game::GetSingleton(UMaxSecurityLaserSingleton);
			SingletonRegistrationIndex = Singleton.Lasers.Num();
			Singleton.Lasers.Add(this);
		}
	}

	private void UnregisterFromSingleton()
	{
		if (SingletonRegistrationIndex != -1)
		{
			auto Singleton = Game::GetSingleton(UMaxSecurityLaserSingleton);

			int LastIndex = Singleton.Lasers.Num() - 1;
			if (SingletonRegistrationIndex != LastIndex)
			{
				AMaxSecurityLaser LastLaser = Singleton.Lasers[LastIndex];
				Singleton.Lasers[SingletonRegistrationIndex] = LastLaser;
				LastLaser.SingletonRegistrationIndex = SingletonRegistrationIndex;
			}

			Singleton.Lasers.RemoveAt(LastIndex);
			SingletonRegistrationIndex = -1;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		UnregisterFromSingleton();
	}

	UFUNCTION(BlueprintOverride)
    void OnActorEnabled()
    {
        if(AudioVolume != nullptr && AudioVolume.RootLaser == this)
        {
            // Hacky way of making sure that RootLaser has time to initialize itself
            Timer::SetTimer(this, n"LateBeginPlay", 0.1);
        }

		if (HasActorBegunPlay())
			RegisterToSingleton();
    }

	void InitializeInitialState()
	{
		InitialRelativeRotation = LaserComp.RelativeRotation;

		if(SplineActor != nullptr)
			SplineComp = UHazeSplineComponent::Get(SplineActor);
		else
			SplineComp = nullptr;
	}

	/** Activate the spline follow */
	UFUNCTION()
	void ActivateFollowSpline()
	{
		float NewStartTime = GetRelevantCrumbTime();
		if (NetworkMode == EMaxSecurityLaserNetwork::Local)
			InternalActivateMovement(NewStartTime);
		else if (HasControl())
			CrumbActivateMovement(NewStartTime);
	}

	/** Reverse direction on the spline */
	UFUNCTION()
	void ReverseDirection()
	{
		if (SplineComp == nullptr)
			return;

		float Time = GetCurrentTime();

		float SplineDistance = 0.0;
		int ReachedEndCount = 0;
		GetSplineDistanceAtTime(Time, SplineDistance, ReachedEndCount);

		float SplineLength = SplineComp.SplineLength;

		bool bNewReversed = false;
		if (SplineWrapMode == EMaxSecurityLaserSplineWrapMode::MoveBackAndForth)
			bNewReversed = (TotalReachedEndCount % 2 == 0) != bReversed;
		else
			bNewReversed = !bReversed;

		if (bNewReversed)
			SplineDistance = SplineLength - SplineDistance;

		float CrumbTime = GetRelevantCrumbTime();

		// FB TODO: Custom for TimeLike mode
		float NewStartTime = CrumbTime - (SplineDistance / MoveSpeed);

		if (NetworkMode == EMaxSecurityLaserNetwork::Local)
			InternalReverseDirection(NewStartTime, bNewReversed, TotalReachedEndCount);
		else if (HasControl())
			CrumbReverseDirection(NewStartTime, bNewReversed, TotalReachedEndCount);
	}

	/** Reset the position back to the start. */
	UFUNCTION()
	void ResetSplinePosition()
	{
		float NewStartTime = GetRelevantCrumbTime();

		if (NetworkMode == EMaxSecurityLaserNetwork::Local)
			InternalActivateMovement(NewStartTime);
		else if (HasControl())
			CrumbActivateMovement(NewStartTime);
	}

	UFUNCTION()
	void SetNewSplineToFollow(AHazeActor Actor)
	{
		if (Actor != nullptr)
			SplineActor = Actor;

		ResetSplinePosition();
	}

	/** Pause any movement we might be doing. */
	UFUNCTION()
	void PauseMovement(FInstigator Instigator)
	{
		if (HasControl() || NetworkMode == EMaxSecurityLaserNetwork::Local)
		{
			ControlPauseInstigators.AddUnique(Instigator);
			if (!bPaused)
			{
				if (NetworkMode == EMaxSecurityLaserNetwork::Local)
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
		if (HasControl() || NetworkMode == EMaxSecurityLaserNetwork::Local)
		{
			ControlPauseInstigators.Remove(Instigator);
			if (bPaused && ControlPauseInstigators.Num() == 0)
			{
				if (NetworkMode == EMaxSecurityLaserNetwork::Local)
					InternalResumeMovement();
				else
					CrumbResumeMovement();
			}
		}
	}

#if EDITOR
	UFUNCTION(CallInEditor, Category = "Kinetic Spline Movement")
	void AutoSetInitialDistanceAlongSpline()
	{
		if(SplineActor == nullptr)
			return;

		auto Spline = Spline::GetGameplaySpline(SplineActor);
		if(Spline == nullptr)
			return;

		bSetInitialSplineAlpha = true;
		float DistanceAlongSpline = Spline.GetClosestSplineDistanceToWorldLocation(ActorLocation);
		InitialSplineAlpha = DistanceAlongSpline / Spline.SplineLength;
	}
#endif

#if EDITOR
	// An ugly little thing that evenly distributes the selected lasers along the spline
	UFUNCTION(CallInEditor, Category = "Kinetic Spline Movement")
	void DivideInitialDistanceOnMultiple()
	{
		TArray<AMaxSecurityLaser> Lasers;
		float Increment = 0;
		int Index = 0;
		
		// Just run this on one laser actor.
		TArray<AActor> SelectedActors = Editor::GetSelectedActors();
		if(SelectedActors[0] != this)
			return;

		for(auto Actor : SelectedActors)
		{
			auto Laser = Cast<AMaxSecurityLaser>(Actor);

			if (Laser == nullptr)
				continue;

			if(Laser.SplineActor == nullptr)
				continue;

			Lasers.Add(Laser);
		}

		Increment = 1 / (Lasers.Num() - 1.0);
		for(auto Laser : Lasers)
		{
			Laser.InitialSplineAlpha = Increment * Index;
			Index++;
		}
	}
#endif

#if EDITOR
	// An ugly little thing that evenly distributes the InitialRotationAlpha
	UFUNCTION(CallInEditor, Category = "Kinetic Spline Movement")
	void DivideInitialRotationOnMultiple()
	{
		TArray<AMaxSecurityLaser> Lasers;
		float Increment = 0;
		int Index = 0;
		
		// Just run this on one laser actor.
		TArray<AActor> SelectedActors = Editor::GetSelectedActors();
		if(SelectedActors[0] != this)
			return;

		for(auto Actor : SelectedActors)
		{
			auto Laser = Cast<AMaxSecurityLaser>(Actor);

			if (Laser == nullptr)
				continue;

			Lasers.Add(Laser);
		}

		Increment = 1 / (Lasers.Num() - 1.0);
		for(auto Laser : Lasers)
		{
			Laser.InitialRotationAlpha = Increment * Index;
			Index++;
		}
	}
#endif

	void ExternalTick(float DeltaSeconds)
	{
		// Debug::DrawDebugString(ActorLocation, f"Crumb {bMoving}", FLinearColor::Green, 0, 0.5);

		if (bMoving && !bPaused)
			Update();
	}

	access:Visualized
	float GetCurrentTime() const
	{
		if (bPaused)
			return PauseCrumbTime - StartCrumbTime;
		else if (!bEverMoved)
			return 0.0;
		else
			return GetRelevantCrumbTime() - StartCrumbTime;
	}

	float GetCurrentSplineDistance() const
	{
		float SplineDistance = 0;
		int ReachedEndCount = 0;
		GetSplineDistanceAtTime(GetCurrentTime(), SplineDistance, ReachedEndCount);
		return SplineDistance;
	}

	bool HasSpline() const
	{
		return SplineComp != nullptr;
	}

	UHazeSplineComponent GetSpline() const
	{
		check(HasSpline());
		return SplineComp;
	}

	private void GetSplineDistanceAtTime(float InTime, float& SplineDistance, int& ReachedEndCount) const
	{
		if (!ensure(SplineComp != nullptr))
			return;

		const float SplineLength = SplineComp.SplineLength;

		if (SplineLength < 0.01)
			return;

		SplineDistance = 0.0;
		if (SplineWrapMode == EMaxSecurityLaserSplineWrapMode::LoopBackToStart)
		{
			if(SplineMovement == EMaxSecurityLaserSplineMovement::Constant)
			{
				if(bSetInitialSplineAlpha)
					SplineDistance += InitialSplineAlpha * SplineLength;

				SplineDistance += InTime * MoveSpeed;

				// Loop around to the beginning of the spline
				ReachedEndCount = Math::FloorToInt(SplineDistance / SplineLength);
				SplineDistance = SplineDistance % SplineLength;
			}
			else if(SplineMovement == EMaxSecurityLaserSplineMovement::Curve)
			{
				const float TimeLikeDuration = GetSplineCurveDuration();
				float TimeLikeTime = InTime * SplinePlayRate;

				TimeLikeTime += SplineDelay;

				if(bSetInitialSplineAlpha)
					TimeLikeTime += InitialSplineAlpha * TimeLikeDuration;

				const float TimeLikeLoopCount = Math::FloorToInt(TimeLikeTime / TimeLikeDuration);
				const float TimeLikeLoopTime = TimeLikeTime % TimeLikeDuration;
				const float Alpha = SplineTimeCurve.GetFloatValue(TimeLikeLoopTime);

				const float DistanceFromLoops = SplineLength * TimeLikeLoopCount;
				const float DistanceFromTimeLikeAlpha = SplineLength * Alpha;
				SplineDistance += (DistanceFromLoops + DistanceFromTimeLikeAlpha);

				ReachedEndCount = Math::FloorToInt(SplineDistance / SplineLength);
				SplineDistance = SplineDistance % SplineLength;
			}
		}
		else if(SplineWrapMode == EMaxSecurityLaserSplineWrapMode::MoveBackAndForth)
		{
			if(SplineMovement == EMaxSecurityLaserSplineMovement::Constant)
			{
				if(bSetInitialSplineAlpha)
					SplineDistance += InitialSplineAlpha * SplineLength;

				SplineDistance += InTime * MoveSpeed;

				ReachedEndCount = Math::FloorToInt(SplineDistance / SplineLength);

				SplineDistance = SplineDistance % SplineLength;

				if(ReachedEndCount % 2 != 0)
				{
					// Traveling back, flip SplineDistance
					SplineDistance = SplineLength - SplineDistance;
				}
			}
			else if(SplineMovement == EMaxSecurityLaserSplineMovement::Curve)
			{
				const float TimeLikeDuration = GetSplineCurveDuration();
				float TimeLikeTime = InTime * SplinePlayRate;

				TimeLikeTime += SplineDelay;

				if(bSetInitialSplineAlpha)
					TimeLikeTime += InitialSplineAlpha * TimeLikeDuration;

				const float TimeLikeLoopCount = Math::FloorToInt(TimeLikeTime / TimeLikeDuration);
				const float TimeLikeLoopTime = TimeLikeTime % TimeLikeDuration;
				const float Alpha = SplineTimeCurve.GetFloatValue(TimeLikeLoopTime);

				const float DistanceFromLoops = SplineLength * TimeLikeLoopCount;
				const float DistanceFromTimeLikeAlpha = SplineLength * Alpha;
				SplineDistance += (DistanceFromLoops + DistanceFromTimeLikeAlpha);

				ReachedEndCount = Math::FloorToInt(SplineDistance / SplineLength);
				SplineDistance = SplineDistance % SplineLength;

				if(ReachedEndCount % 2 != 0)
				{
					// Traveling back, flip SplineDistance
					SplineDistance = SplineLength - SplineDistance;
				}
			}
		}

		// If we are moving in reverse, we should be on the opposite end of the spline
		if (bReversed)
			SplineDistance = SplineLength - SplineDistance;
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentSplineCurveValue() const
	{
		switch(SplineMovement)
		{
			case EMaxSecurityLaserSplineMovement::Constant:
			{
				const float SplineLength = SplineComp.SplineLength;

				float SplineDistance = 0;
				int ReachedEndCount = 0;
				GetSplineDistanceAtTime(GetCurrentTime(), SplineDistance, ReachedEndCount);

				PrintToScreen(f"{this} - Constant - {Math::Saturate(SplineDistance / SplineLength)}", 0, FLinearColor::Yellow);
				return Math::Saturate(SplineDistance / SplineLength);
			}

			case EMaxSecurityLaserSplineMovement::Curve:
			{
				const float TimeLikeDuration = GetSplineCurveDuration();
				float TimeLikeTime = GetCurrentTime() * SplinePlayRate;

				TimeLikeTime += SplineDelay;

				if(bSetInitialSplineAlpha)
					TimeLikeTime += InitialSplineAlpha * TimeLikeDuration;

				const float TimeLikeLoopTime = TimeLikeTime % TimeLikeDuration;
				PrintToScreen(f"{this} - Curve - {SplineTimeCurve.GetFloatValue(TimeLikeLoopTime)}", 0, FLinearColor::Green);
				return SplineTimeCurve.GetFloatValue(TimeLikeLoopTime);
			}
		}
	}

	private void Update()
	{
		const float Time = GetCurrentTime();

		FVector SplineLocation = ActorLocation;
		FQuat SplineRotation = ActorQuat;
		if (SplineComp != nullptr)
			UpdateSpline(Time, SplineLocation, SplineRotation, TotalReachedEndCount);

		FRotator OutAdditiveWorldRotation = FRotator::ZeroRotator;
		FRotator OutAdditiveRelativeRotation = FRotator::ZeroRotator;
		UpdateRotation(Time, OutAdditiveWorldRotation, OutAdditiveRelativeRotation);

		const FQuat FinalRotation = SplineRotation * OutAdditiveWorldRotation.Quaternion();

		SetActorLocationAndRotation(SplineLocation, FinalRotation);
		LaserComp.SetRelativeRotation(InitialRelativeRotation + OutAdditiveRelativeRotation);
	}

	void UpdateSpline(float InTime, FVector&out OutLocation, FQuat&out OutRotation, int& RefTotalReachedEndCount) const
	{
		if (!ensure(HasSpline()))
			return;

		float SplineDistance = 0.0;
		int ReachedEndCount = 0;
		GetSplineDistanceAtTime(InTime, SplineDistance, ReachedEndCount);

		FTransform SplineTransform = SplineComp.GetWorldTransformAtSplineDistance(SplineDistance);

		OutLocation = SplineTransform.Location;

		if (bFollowSplineRotation)
		{
			FRotator OutRotator = SplineTransform.Rotator();
			if (bOnlyFollowYaw)
			{
				OutRotator.Roll = 0.0;
				OutRotator.Pitch = 0.0;
			}

			OutRotation = OutRotator.Quaternion();
		}

		// Call the event whenever we reach the end of the spline
		while (RefTotalReachedEndCount < ReachedEndCount)
		{
			++RefTotalReachedEndCount;
		}
	}

	void UpdateRotation(float InTime, FRotator&out OutAdditiveWorldRotation, FRotator&out OutAdditiveRelativeRotation) const
	{
		if(bUseConstantRotation)
		{
			//FVector ConstantRotationAxle = FVector::UpVector;
			//float ConstantRotationAngularSpeed = 0;
			//ConstantRotationRate.Quaternion().ToAxisAndAngle(ConstantRotationAxle, ConstantRotationAngularSpeed);
			//FQuat ConstantRotation = FQuat(ConstantRotationAxle, ConstantRotationAngularSpeed * InTime);
			OutAdditiveWorldRotation = ConstantRotationRate * InTime;
		}

		if(bUseRotationCurve)
		{
			const float TimeLikeDuration = GetRotationCurveDuration();
			float TimeLikeTime = InTime * RotationPlayRate;

			TimeLikeTime += RotationDelay;

			if(bSetInitialRotationAlpha)
				TimeLikeTime += InitialRotationAlpha * TimeLikeDuration;

			const float TimeLikeLoopTime = TimeLikeTime % TimeLikeDuration;

			const float Alpha = RotationTimeCurve.GetFloatValue(TimeLikeLoopTime);
			OutAdditiveRelativeRotation += Math::LerpShortestPath(FRotator::ZeroRotator, TargetRotation, Alpha);
		}
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentRotationCurveValue() const
	{
		const float TimeLikeDuration = GetRotationCurveDuration();
		float TimeLikeTime = GetCurrentTime() * RotationPlayRate;

		TimeLikeTime += RotationDelay;

		if(bSetInitialRotationAlpha)
			TimeLikeTime += InitialRotationAlpha * TimeLikeDuration;

		const float TimeLikeLoopTime = TimeLikeTime % TimeLikeDuration;

		return RotationTimeCurve.GetFloatValue(TimeLikeLoopTime);
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
		Update();
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
			Update();

		TotalReachedEndCount = 0;
		StartCrumbTime = NewStartTime;
		bMoving = true;
		bEverMoved = true;
		if (bPaused)
			PauseCrumbTime = GetRelevantCrumbTime();
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
		Update();
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
			//OnReachedEnd.Broadcast();
			++TotalReachedEndCount;
		}

		bMoving = true;
		bEverMoved = true;
		bReversed = bNewReversed;
		TotalReachedEndCount = 0;
		StartCrumbTime = NewStartTime;

		Update();
		if (bPaused)
			PauseCrumbTime = GetRelevantCrumbTime();
	}

	UFUNCTION(Meta = (DeprecatedFunction, DeprecationMessage = "Use PauseMovement with an instigator"))
	void PauseSplineFollowActor()
	{
	}
	UFUNCTION(Meta = (DeprecatedFunction, DeprecationMessage = "Use UnpauseMovement with an instigator"))
	void UnPauseSplineFollowActor()
	{
	}

	float GetSplineCurveDuration() const
	{
		float32 Min = 0;
		float32 Max = 0;
		SplineTimeCurve.GetTimeRange(Min, Max);
		return float(Max - Min);
	}

	float GetRotationCurveDuration() const
	{
		float32 Min = 0;
		float32 Max = 0;
		RotationTimeCurve.GetTimeRange(Min, Max);
		return float(Max - Min);
	}
};

#if EDITOR
UCLASS(NotBlueprintable, NotPlaceable)
class UMaxSecurityLaserEditorComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, Category = "Visualize")
	bool bVisualize = true;

	UPROPERTY(EditAnywhere, Category = "Visualize", Meta = (EditCondition = "bVisualize"))
	bool bLoopVisualization = false;

	UPROPERTY(EditAnywhere, Category = "Visualize", Meta = (EditCondition = "bVisualize && bLoopVisualization"))
	float VisualizeDuration = 20;
};

class UMaxSecurityLaserVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UMaxSecurityLaserEditorComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Laser = Cast<AMaxSecurityLaser>(Component.Owner);
		if(Laser == nullptr)
			return;

		if(!Laser.EditorComp.bVisualize)
			return;
		
		// Please, don't rotate actors during play.
		if (Editor::IsPlaying())
			return;

		Laser.InitializeInitialState();

		float Time = Time::GameTimeSeconds;

		if(Laser.EditorComp.bLoopVisualization)
			Time %= Laser.EditorComp.VisualizeDuration;

		FVector SplineLocation = Laser.ActorLocation;
		FQuat SplineRotation = Laser.ActorQuat;
		int TotalReachedEndCount = 0;
		if (Laser.HasSpline())
			Laser.UpdateSpline(Time, SplineLocation, SplineRotation, TotalReachedEndCount);

		FRotator OutAdditiveRotation = FRotator::ZeroRotator;
		FRotator OutAdditiveRelativeRotation = FRotator::ZeroRotator;
		Laser.UpdateRotation(Time, OutAdditiveRotation, OutAdditiveRelativeRotation);

		const FQuat FinalRotation = SplineRotation * OutAdditiveRotation.Quaternion();

		FTransform ActorTransform = FTransform(FinalRotation, SplineLocation);
		FTransform LaserTransform = FTransform(Laser.LaserComp.RelativeRotation + OutAdditiveRelativeRotation, Laser.LaserComp.RelativeLocation) * ActorTransform;

		DrawLine(LaserTransform.Location, LaserTransform.Location + LaserTransform.Rotation.ForwardVector * Laser.LaserComp.BeamLength, FLinearColor::Red, 3, true);

		FString WorldString;

		if(Laser.EditorComp.bLoopVisualization)
			WorldString = f"Time: {Time:0.2}s/{Laser.EditorComp.VisualizeDuration:0.2}s";
		else
			WorldString = f"Time: {Time:0.2}s";

		if(Laser.LaserComp.bDamagePlayers)
			WorldString += "\nDamages Players";

		if(Laser.LaserComp.bShowImpactEffect)
		{
			WorldString += "\nShows Impact Effect";

			if(Laser.LaserComp.bTraceForImpact)
				WorldString += "\nTraces for Impact Effect";
		}

		// DrawWorldString(WorldString, LaserTransform.Location);
	}
};
#endif

class UMaxSecurityLaserSingleton : UHazeSingleton
{
	TArray<AMaxSecurityLaser> Lasers;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Lasers.Num() == 0)
			return;
		if (Game::Mio == nullptr)
			return;
		if (Game::Zoe == nullptr)
			return;

		FVector MioLocation = Game::Mio.ActorLocation;
		FVector ZoeLocation = Game::Zoe.ActorLocation;
		float SquareNearbyDist = Math::Square(5000);

		for (AMaxSecurityLaser Laser : Lasers)
		{
			if (Laser == nullptr)
				continue;

			FVector LaserLocation = Laser.ActorLocation;
			float MinDist = Math::Min(
				LaserLocation.DistSquared(MioLocation),
				LaserLocation.DistSquared(ZoeLocation),
			);
			bool bPlayerNearby = MinDist < SquareNearbyDist;

			if (Laser.bWillEverMove)
				Laser.ExternalTick(DeltaTime);
			if (bPlayerNearby)
				Laser.LaserComp.ExternalTick(DeltaTime);
		}
	}
}