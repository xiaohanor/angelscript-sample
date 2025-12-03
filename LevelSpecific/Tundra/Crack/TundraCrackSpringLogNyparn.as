class UTundraCrackSpringLogNyparnVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundraCrackSpringLogNyparnVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto SpringLogNyparn = Cast<ATundraCrackSpringLogNyparn>(Component.Owner);

		const float SphereRadius = SpringLogNyparn.DetectLogSphere.SphereRadius;
		const FVector Origin = SpringLogNyparn.DetectLogSphere.WorldLocation;
		const FVector WorldAxisToTranslate = SpringLogNyparn.ActorTransform.TransformVectorNoScale(SpringLogNyparn.LocalAxisToTranslate);
		const FVector MaxPoint = Origin + WorldAxisToTranslate * SpringLogNyparn.MaxTranslation;
		const FVector MaxPointClosed = Origin + WorldAxisToTranslate * SpringLogNyparn.MaxTranslationClosedNyparn;

		DrawWireSphere(Origin, SphereRadius, FLinearColor::Red);
		DrawWireSphere(MaxPoint, SphereRadius, FLinearColor::Green);
		DrawWorldString("Max Point", MaxPoint, FLinearColor::Green, 1.0);
		DrawWireSphere(MaxPointClosed, SphereRadius, FLinearColor::LucBlue);
		DrawWorldString("Max Point when closed", MaxPointClosed + FVector::UpVector * (SphereRadius * 0.5), FLinearColor::LucBlue, 1.0);
	}
}

struct FTundraCrackSpringLogAnimData
{
	// This is between 0 and 1, 0 means open, 1 means closed
	float CloseAlpha;

	// This is between 0 and 1, 0 is lowest speed, 1 is full speed
	float SpeedAlpha;
	bool bAttachedToLog;
}

UCLASS(NotPlaceable, NotBlueprintable)
class UTundraCrackSpringLogNyparnVisualizerComponent : UActorComponent
{
	
}

UCLASS(Abstract)
class ATundraCrackSpringLogNyparn : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach=Root)
	USceneComponent NyparParent;

	UPROPERTY(DefaultComponent, Attach=NyparParent)
	UHazeSkeletalMeshComponentBase Nyparn;

	UPROPERTY(DefaultComponent, Attach=NyparParent)
	USphereComponent DetectLogSphere;
	default DetectLogSphere.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UTundraCrackSpringLogNyparnVisualizerComponent VisualizerComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedNyparParentLocation;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedTranslationSpeed;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY(EditInstanceOnly)
	ATundraRangedLifeGivingActor LifeGivingActor;

	/* Nyparn parent will be offset towards this direction */
	UPROPERTY(EditAnywhere)
	FVector LocalAxisToTranslate = FVector::RightVector;

	/* Rotate with movement */
	UPROPERTY(EditAnywhere)
	bool bRotateWithMove = true;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bRotateWithMove", EditConditionHides))
	float AmountOfRotationsForFullTranslation = 0.5;

	/* Nyparn parent cannot be offset any more than this from its original location */
	UPROPERTY(EditAnywhere)
	float MaxTranslation = 1700.0;

	/* Nyparn parent cannot be offset any more than this from its original location when nyparn is closed */
	UPROPERTY(EditAnywhere)
	float MaxTranslationClosedNyparn = 1500.0;

	/* How many units/s nypar parent will be moved towards axis to translate (clamped with max translation) */
	UPROPERTY(EditAnywhere)
	float TranslationMaxSpeed = 800.0;

	/* The acceleration of the speed (capped at max speed) */
	UPROPERTY(EditAnywhere)
	float TranslationAcceleration = 800.0;

	/* The deceleration of the speed */
	UPROPERTY(EditAnywhere)
	float TranslationDeceleration = 1600.0;

	/* When this far off the clamp, the translation speed will become slower and slower. */
	UPROPERTY(EditAnywhere)
	float TranslationSlowDownRange = 100.0;

	/* How fast to actually interp nypar parent to the current translation target */
	UPROPERTY(EditAnywhere)
	float TranslationInterpSpeed = -1;

	UPROPERTY(EditAnywhere)
	float NyparnCloseTime = 0.25;

	UPROPERTY(EditAnywhere)
	float NyparnOpenTime = 0.34;

	UPROPERTY(EditAnywhere)
	bool bLerpNyparnLocationToAttachPoint = true;

	UPROPERTY(EditAnywhere)
	bool bLerpNyparnRotationToAttachPoint = true;

	UPROPERTY(EditAnywhere)
	float NyparnLerpToLogDuration = 0.5;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent NyparnMoveVFX;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect GrabFF;

	bool bNyparnAttached = false;

	bool bVFXActive = false;
	
	// Property for audio
	UPROPERTY(EditInstanceOnly)
	ATundraCrackSpringLog SpringLog;
	
	ATundraCrackSpringLog CurrentSpringLog;
	float CurrentTranslation = 0.0;
	FVector ExtraTranslationToLerpAway;
	FVector OriginalNyparParentLocation;
	bool bCurrentlyClosing = false;
	float CurrentAlpha = 0.0;
	float PreviousAlpha = 0.0;
	bool bInteracting = false;
	float CurrentMax;
	FTundraCrackSpringLogAnimData AnimData;
	FQuat OriginalNyparnParentWorldQuat;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalNyparnParentWorldQuat = NyparParent.ComponentQuat;
		LifeGivingActor.LifeReceivingComponent.OnInteractStartDuringLifeGive.AddUFunction(this, n"StartClosingNyparn");
		LifeGivingActor.LifeReceivingComponent.OnInteractStopDuringLifeGive.AddUFunction(this, n"StartOpeningNyparn");
		LifeGivingActor.LifeReceivingComponent.OnInteractStart.AddUFunction(this, n"OnInteractStart");
		LifeGivingActor.LifeReceivingComponent.OnInteractStop.AddUFunction(this, n"OnInteractStop");
		OriginalNyparParentLocation = NyparParent.WorldLocation;

		if(!Math::IsNearlyEqual(LocalAxisToTranslate.Size(), 1.0))
			devError("Axis to translate not set (also make sure that the vector has a size of 1)");

		SetActorControlSide(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdateHorizontalInput(bInteracting ? LifeGivingActor.LifeReceivingComponent.RawHorizontalInput : -1.0);

		if(bCurrentlyClosing)
			CurrentAlpha += DeltaTime * (1.0 / NyparnCloseTime);
		else
			CurrentAlpha -= DeltaTime * (1.0 / NyparnOpenTime);

		if(bNyparnAttached)
			CurrentAlpha = Math::Clamp(CurrentAlpha, 0.0, 0.5);
		else
			CurrentAlpha = Math::Clamp(CurrentAlpha, 0.0, 1.0);
		
		AnimData.CloseAlpha = CurrentAlpha;

		if(bNyparnAttached)
		{
			if(bLerpNyparnLocationToAttachPoint)
			{
				FVector LocalPoint = Nyparn.WorldTransform.InverseTransformPositionNoScale(NyparParent.WorldLocation);
				FVector TargetLocation = CurrentSpringLog.NyparnAttachPoint.WorldTransform.TransformPositionNoScale(LocalPoint);
				NyparParent.WorldLocation = Math::VInterpTo(NyparParent.WorldLocation, TargetLocation, DeltaTime, 5.0);
			}

			if(bLerpNyparnRotationToAttachPoint)
			{
				FRotator LocalRotation = Nyparn.WorldTransform.InverseTransformRotation(NyparParent.WorldRotation);
				FRotator TargetRotation = CurrentSpringLog.NyparnAttachPoint.WorldTransform.TransformRotation(LocalRotation);
				NyparParent.WorldRotation = Math::RInterpShortestPathTo(NyparParent.WorldRotation, TargetRotation, DeltaTime, 5.0);
			}
		}
		else if(HasControl() && PreviousAlpha < 0.5 && CurrentAlpha >= 0.5)
		{
			FHazeTraceSettings Trace = Trace::InitProfile(n"BlockAllDynamic");
			Trace.UseSphereShape(DetectLogSphere);
			Trace.IgnoreActor(this);
			Trace.IgnorePlayers();
			FOverlapResultArray Overlaps = Trace.QueryOverlaps(DetectLogSphere.WorldLocation);
			for(auto Overlap : Overlaps.BlockHits)
			{
				auto OverlapSpringLog = Cast<ATundraCrackSpringLog>(Overlap.Actor);
				if(OverlapSpringLog == nullptr)
					continue;

				if(!OverlapSpringLog.IsLoweredToBottom())
					break;

				CrumbAttach(OverlapSpringLog);
				break;
			}
		}

		PreviousAlpha = CurrentAlpha;
		
		//VFX
		if(LifeGivingActor.LifeReceivingComponent.LifeForce >= 0.3 && !bVFXActive)
		{
			NyparnMoveVFX.Activate();
			bVFXActive = true;
		}
		else if(LifeGivingActor.LifeReceivingComponent.LifeForce < 0.3 && bVFXActive)
		{
			NyparnMoveVFX.Deactivate();
			bVFXActive = false;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnInteractStart(bool bForced)
	{
		bInteracting = true;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnInteractStop(bool bForced)
	{
		StartOpeningNyparn();
		bInteracting = false;
	}

	UFUNCTION(NotBlueprintCallable)
	private void StartClosingNyparn()
	{
		bCurrentlyClosing = true;

		FTundraCrackSpringLogNyparnGrabEffectParams Params;
		Params.GrabDuration = NyparnCloseTime * (1.0 - CurrentAlpha);
		UTundraCrackSpringLogNyparnEffectHandler::Trigger_StartGrab(this, Params);

		Game::GetZoe().PlayForceFeedback(GrabFF, this);

	}

	UFUNCTION(NotBlueprintCallable)
	private void StartOpeningNyparn()
	{
		if(bCurrentlyClosing)
		{
			FTundraCrackSpringLogNyparnGrabEffectParams Params;
			Params.GrabDuration = NyparnOpenTime * CurrentAlpha;
			UTundraCrackSpringLogNyparnEffectHandler::Trigger_StopGrab(this, Params);
		}

		bCurrentlyClosing = false;
		
		if(bNyparnAttached && HasControl())
			CrumbDetach();
	}

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	private void CrumbAttach(ATundraCrackSpringLog InSpringLog)
	{
		NyparParent.AttachToComponent(SpringLog.FauxTranslateComp, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		bNyparnAttached = true;
		AnimData.bAttachedToLog = true;
		CurrentSpringLog = InSpringLog;

		FTundraCrackSpringLogNyparnLogEffectParams Params;
		Params.Log = CurrentSpringLog;
		UTundraCrackSpringLogNyparnEffectHandler::Trigger_GrabLog(this, Params);

		CurrentSpringLog.OnNyparnInteract(this);
	}

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	private void CrumbDetach()
	{
		NyparParent.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		CurrentTranslation = NyparParent.WorldLocation.Distance(OriginalNyparParentLocation);
		CurrentTranslation = Math::Clamp(CurrentTranslation, 0.0, MaxTranslation);
		FVector Target = GetTargetLocationBasedOnTranslation(CurrentTranslation);
		ExtraTranslationToLerpAway = NyparParent.WorldLocation - Target;

		SyncedNyparParentLocation.TransitionSync(this);

		bNyparnAttached = false;
		AnimData.bAttachedToLog = false;

		FTundraCrackSpringLogNyparnLogEffectParams Params;
		Params.Log = CurrentSpringLog;
		UTundraCrackSpringLogNyparnEffectHandler::Trigger_ReleaseLog(this, Params);

		CurrentSpringLog.OnNyparnStopInteract(this);
		CurrentSpringLog = nullptr;
	}

	UFUNCTION(BlueprintEvent)
	void BP_UpdateNyparnCloseAlpha(float CloseAlpha) {}

	UFUNCTION(NotBlueprintCallable)
	private void UpdateHorizontalInput(float NewHorizontalInput)
	{
		const float DeltaTime = Time::GetActorDeltaSeconds(this);

		if(!bNyparnAttached)
		{
			if(HasControl())
			{
				if(NewHorizontalInput == 0.0)
				{
					TranslationSpeed = Math::FInterpConstantTo(TranslationSpeed, 0.0, DeltaTime, TranslationDeceleration);
				}
				else
				{
					TranslationSpeed = Math::FInterpConstantTo(TranslationSpeed, NewHorizontalInput * TranslationMaxSpeed, DeltaTime, TranslationAcceleration);
				}

				float TargetMax = CurrentAlpha > 0.5 ? MaxTranslationClosedNyparn : MaxTranslation;

				CurrentMax = Math::FInterpTo(CurrentMax, TargetMax, DeltaTime, 5.0);

				LifeGivingActor.LifeReceivingComponent.HorizontalAlphaSettings.bEnableForceFeedback = true;
				if((CurrentTranslation < TranslationSlowDownRange && NewHorizontalInput < -0.1) || (CurrentTranslation > CurrentMax - TranslationSlowDownRange && NewHorizontalInput > 0.1))
				{
					float Multiplier1 = CurrentTranslation / TranslationSlowDownRange;
					float Multiplier2 = Math::GetMappedRangeValueClamped(FVector2D(CurrentMax, CurrentMax - TranslationSlowDownRange), FVector2D(0.0, 1.0), CurrentTranslation);

					float Multiplier = Math::Min(Multiplier1, Multiplier2);
					TranslationSpeed *= Multiplier;
					LifeGivingActor.LifeReceivingComponent.HorizontalAlphaSettings.bEnableForceFeedback = false;
				}

				float CurrentDelta = TranslationSpeed * DeltaTime;
				CurrentTranslation += CurrentDelta;
				CurrentTranslation = Math::Clamp(CurrentTranslation, 0.0, CurrentMax);

				//PrintToScreen(f"{LifeGivingActor.LifeReceivingComponent.HorizontalAlphaSettings.bEnableForceFeedback=}");

				ExtraTranslationToLerpAway = Math::VInterpTo(ExtraTranslationToLerpAway, FVector::ZeroVector, DeltaTime, 5.0);
				// VInterpTo will internally snap to target value if interp speed is 0 or below
				NyparParent.WorldLocation = Math::VInterpTo(NyparParent.WorldLocation, GetTargetLocationBasedOnTranslation(CurrentTranslation) + ExtraTranslationToLerpAway, DeltaTime, TranslationInterpSpeed);
				SyncedNyparParentLocation.Value = NyparParent.WorldLocation;
			}
			else
			{
				NyparParent.WorldLocation = SyncedNyparParentLocation.Value;
			}
		}
		else if(HasControl())
		{
			TranslationSpeed = 0.0;
			CurrentSpringLog.UpdateRawHorizontalInput(NewHorizontalInput);
			CurrentMax = MaxTranslation;
		}

		if(bRotateWithMove && !bNyparnAttached)
		{
			float Dist = OriginalNyparParentLocation.DistXY(NyparParent.WorldLocation);
			FVector AxisToRotateAround = ActorTransform.TransformVectorNoScale(LocalAxisToTranslate);

			float Alpha = (Dist / MaxTranslation) * AmountOfRotationsForFullTranslation * 2.0;

			FRotator TargetRotation = FQuat::Slerp(OriginalNyparnParentWorldQuat, Math::RotatorFromAxisAndAngle(AxisToRotateAround, 180.0).Quaternion() * OriginalNyparnParentWorldQuat, Alpha).Rotator();
			NyparParent.WorldRotation = Math::RInterpShortestPathTo(NyparParent.WorldRotation, TargetRotation, DeltaTime, 4.0);
		}
		
		AnimData.SpeedAlpha = TranslationSpeed / TranslationMaxSpeed;
	}

	FVector GetTargetLocationBasedOnTranslation(float Translation)
	{
		return OriginalNyparParentLocation + ActorTransform.TransformVectorNoScale(LocalAxisToTranslate) * Translation;
	}

	UFUNCTION(BlueprintPure)
	float GetTranslationAlpha()
	{
		return Math::Min(1, SyncedNyparParentLocation.Value.Distance(OriginalNyparParentLocation) / 1700);
	}

	UFUNCTION(BlueprintPure)
	float GetNyparnLengthAlpha()
	{
		return Math::GetMappedRangeValueClamped(FVector2D(150, 1700), FVector2D(0.0, 1.0), OriginalNyparParentLocation.DistXY(NyparParent.WorldLocation));
	}

	float GetTranslationSpeed() const property
	{
		return SyncedTranslationSpeed.Value;
	}

	void SetTranslationSpeed(float Value) property
	{
		SyncedTranslationSpeed.Value = Value;
	}
}