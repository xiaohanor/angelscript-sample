event void FThumperEventsForVO(AHazePlayerCharacter Player);

struct FSandSharkThumperDistractionParams
{
	FSandSharkThumperDistractionParams(ASandSharkSpline InSpline, float Duration)
	{
		Spline = InSpline;
		TimeWhenStarted = Time::GameTimeSeconds;
		DistractDuration = Duration;
		bIsValid = true;
	}
	ASandSharkSpline Spline;
	float TimeWhenStarted;
	float DistractDuration;
	bool bIsValid;
}

class ASandSharkThumper : AHazeActor
{
	default TickGroup = ETickingGroup::TG_PrePhysics;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent PoleMeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BaseMeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent WidgetAttachComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent LeftHandleMeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent RightHandleMeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UDesertCrankInteractionComponent LeftInteractionComp;
	default LeftInteractionComp.UsableByPlayers = EHazeSelectPlayer::Both;
	default LeftInteractionComp.bPlayerCanCancelInteraction = false;
	default LeftInteractionComp.bShowCancelPrompt = false;
	default LeftInteractionComp.bShowForOtherPlayer = true;
	default LeftInteractionComp.RelativeLocation = FVector(-58, -118, 0);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UDesertCrankInteractionComponent RightInteractionComp;
	default RightInteractionComp.UsableByPlayers = EHazeSelectPlayer::Both;
	default RightInteractionComp.bPlayerCanCancelInteraction = false;
	default RightInteractionComp.bShowCancelPrompt = false;
	default RightInteractionComp.bShowForOtherPlayer = true;
	default RightInteractionComp.RelativeLocation = FVector(-58, 118, 0);
	default RightInteractionComp.bIsRightSideCrank = true;

	UPROPERTY(DefaultComponent)
	USandSharkPendulumComponent PendulumComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerCapabilities.Add(n"SandSharkPlayerPendulumCapability");

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CamShakeFFComp;

	UPROPERTY(EditInstanceOnly)
	ASandShark SharkToAttract;

	UPROPERTY(EditInstanceOnly)
	ASandSharkSpline SharkPatrolOverrideSpline;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY()
	UNiagaraSystem ThumpDust;

	UPROPERTY()
	UNiagaraSystem ThumpDistortion;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ThumpShake;

	UPROPERTY()
	UForceFeedbackEffect ThumpFF;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence ThumperPlayerAnimSequence;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ThumpFailFF;

	UPROPERTY()
	FThumperEventsForVO OnInstanceThumpSuccess;

	UPROPERTY()
	FThumperEventsForVO OnInstanceThumpFail;

	UPROPERTY()
	FThumperEventsForVO OnInstanceThumpFullyDown;

	UPROPERTY()
	FThumperEventsForVO OnInstanceThumperPlayerAttached;

	float TargetOffsetHeight = -500;

	FVector StartLocation;
	FVector RaisedLocation;

	float ThumpDistractDuration = 1.456;

	uint NrStepsBeforeReset = 4;
	// Time it takes to return to original position
	float MaxResetDuration = 1.8 * 2.3;

	float MoveTimePerStep = 0.2;
	float MoveAmountPerStep = TargetOffsetHeight / NrStepsBeforeReset;
	FVector CurrentLocation;

	FVector NextLocation;

	float DisableDurationOnFail = 1;

	AHazePlayerCharacter InteractingPlayer;

	UButtonMashComponent MashComp;

	TArray<bool> StepsCompleted;

	TArray<FInstigator> InteractionDisableInstigators;

	uint NrSuccessfulHits = 0;

	bool bHasStopped;
	bool bHasStarted;

	float CrankRotationDegrees = 0;
	float PrevRotationStep = 0;
	float NextRotationStep = 0;

	uint FrameStartedInteraction;

	UDesertPlayerPendulumComponent PlayerPendulumComp;
	USandSharkPlayerComponent PlayerSharkComp;

	float FullRotationPeriod = 1.6 * 1.3;


	UPROPERTY(EditAnywhere)
	bool bHasHandleOnLeftSide = true;

	UInteractionComponent RelevantInteractionComp;

	FRotator LeftHandleStartRotation;
	FRotator RightHandleStartRotation;
	FRotator PreviousHandleRotation;

	UPROPERTY(EditDefaultsOnly)
	UHazeLocomotionFeatureBase ThumperFeature;

	void AddInteractionDisableInstigator(FInstigator Instigator)
	{
		if (!InteractionDisableInstigators.Contains(Instigator))
		{
			InteractionDisableInstigators.Add(Instigator);
			LeftInteractionComp.Disable(Instigator);
		}
	}

	void RemoveInteractionDisableInstigator(FInstigator Instigator)
	{
		if (InteractionDisableInstigators.Contains(Instigator))
		{
			InteractionDisableInstigators.Remove(Instigator);
			LeftInteractionComp.Enable(Instigator);
		}
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bHasHandleOnLeftSide)
		{
			RightHandleMeshComp.bVisible = false;
			LeftHandleMeshComp.bVisible = true;
		}
		else
		{
			LeftHandleMeshComp.bVisible = false;
			RightHandleMeshComp.bVisible = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);

		if (bHasHandleOnLeftSide)
		{
			RightInteractionComp.Disable(this);
			RightHandleMeshComp.AddComponentVisualsAndCollisionAndTickBlockers(this);

			LeftInteractionComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
			LeftInteractionComp.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
		}
		else
		{
			LeftInteractionComp.Disable(this);
			LeftHandleMeshComp.AddComponentVisualsAndCollisionAndTickBlockers(this);

			RightInteractionComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
			RightInteractionComp.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
		}

		LeftHandleStartRotation = LeftHandleMeshComp.RelativeRotation;
		RightHandleStartRotation = RightHandleMeshComp.RelativeRotation;

		StartLocation = PoleMeshComp.WorldLocation;
		RaisedLocation = PoleMeshComp.WorldLocation + ActorUpVector * TargetOffsetHeight;

		CurrentLocation = StartLocation;
		NextLocation = StartLocation + FVector::UpVector * MoveAmountPerStep;

		PendulumComp.OnSuccess.AddUFunction(this, n"OnPendulumSuccess");
		PendulumComp.OnFail.AddUFunction(this, n"OnPendulumFail");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
#if EDITOR
		FTemporalLog Log = TEMPORAL_LOG(this);
		Log = Log.Page(f"InteractionDisableInstigators");
		for (int i = 0; i < InteractionDisableInstigators.Num(); i++)
		{
			Log.Value(f"DisableInstigator{i}", InteractionDisableInstigators[i].ToString());
		}
#endif
		if (FrameStartedInteraction > 0 && Time::FrameNumber > FrameStartedInteraction && InteractingPlayer != nullptr)
			InteractingPlayer.Mesh.RequestLocomotion(n"Thumper", this);

		if (bHasStarted && !bHasStopped)
		{
			//CrankRotationDegrees += (360.0 / 1.3) * DeltaSeconds;
			float PitchDelta = Math::Abs(LeftHandleMeshComp.WorldRotation.Pitch - PreviousHandleRotation.Pitch);
			PreviousHandleRotation = LeftHandleMeshComp.WorldRotation;
			CrankRotationDegrees += PitchDelta;
			//HandleMeshRoot.RelativeRotation = FRotator(-CrankRotationDegrees, 0, 0);
		}
	}

	UFUNCTION()
	private void OnPendulumFail(AHazePlayerCharacter Player)
	{
		if (HasControl())
		{
			Player.PlayForceFeedback(ThumpFailFF, false, true, this);
			CrumbStopPlayerInteraction(Player);
			CrumbDisableInteraction();
		}
		USandSharkThumperEventHandler::Trigger_OnThumpFail(this);
		USandSharkThumperPlayerEventHandler::Trigger_OnThumpFail(Player);

		OnInstanceThumpFail.Broadcast(Player);

		bHasStopped = true;

		QueueSlam();
	}

	UFUNCTION(CrumbFunction)
	void CrumbDisableInteraction()
	{
		AddInteractionDisableInstigator(n"PendulumFail");
		Timer::SetTimer(this, n"PendulumFailTimeout", DisableDurationOnFail);
	}

	UFUNCTION()
	private void PendulumFailTimeout()
	{
		RemoveInteractionDisableInstigator(n"PendulumFail");
	}

	UFUNCTION()
	private void OnPendulumSuccess(AHazePlayerCharacter Player)
	{
		USandSharkThumperEventHandler::Trigger_OnThumpSuccess(this);
		USandSharkThumperPlayerEventHandler::Trigger_OnThumpSuccess(Player);
		
		PlayerPendulumComp.AnimData.AnimState = ESandSharkPendulumAnimationState::Thump;
		bHasStarted = true;
		NrSuccessfulHits++;
		Timer::SetTimer(this, n"ResetThumpAnim", 0.3);

		CurrentLocation = PoleMeshComp.WorldLocation;
		NextLocation = CurrentLocation + FVector::UpVector * MoveAmountPerStep;
		PrevRotationStep = CrankRotationDegrees;
		NextRotationStep = CrankRotationDegrees + Math::RadiansToDegrees(TWO_PI / FullRotationPeriod);
		ActionQueue.Duration(MoveTimePerStep, this, n"Move");
		ActionQueue.Event(this, n"StepReached");
		float Scale = float(NrSuccessfulHits + 1) / NrStepsBeforeReset;
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ThumpDust, ActorLocation - FVector(0, 0, 0), FRotator::ZeroRotator, FVector(Scale, Scale, Scale));
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ThumpDistortion, ActorLocation - FVector(0, 0, 20), FRotator::ZeroRotator, FVector(Scale, Scale, Scale));
		if (SceneView::FullScreenPlayer == nullptr)
			Player.PlayCameraShake(ThumpShake, this);
		else
			SceneView::FullScreenPlayer.PlayCameraShake(ThumpShake, this);

		OnInstanceThumpSuccess.Broadcast(Player);

		if (InteractingPlayer != nullptr)
			InteractingPlayer.PlayForceFeedback(ThumpFF, false, false, this);
	}

	UFUNCTION()
	private void ResetThumpAnim()
	{
		PlayerPendulumComp.AnimData.AnimState = ESandSharkPendulumAnimationState::Mh;
	}

	UFUNCTION()
	void Move(float Alpha)
	{
		PoleMeshComp.WorldLocation = Math::Lerp(CurrentLocation, NextLocation, Math::ExpoIn(0, 1, Alpha));
	}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent InteractionComponent,
							  AHazePlayerCharacter Player)
	{
		InteractingPlayer = nullptr;
		Player.Mesh.RemoveLocomotionFeature(ThumperFeature, this);
		SetActorTickEnabled(false);
	}

	UFUNCTION(CrumbFunction)
	void CrumbStopPlayerInteraction(AHazePlayerCharacter Player)
	{
		//InteractionComp.KickAnyPlayerOutOfInteraction();
		//Player.StopAllSlotAnimations(0.2);
		PlayerPendulumComp.AnimData.AnimState = ESandSharkPendulumAnimationState::Exit;
		Timer::SetTimer(this, n"OnStoppedCranking", 0.5);
	}

	UFUNCTION()
	private void OnStoppedCranking()
	{
		LeftHandleMeshComp.AttachToComponent(MeshRoot, NAME_None, EAttachmentRule::KeepWorld);
		RightHandleMeshComp.AttachToComponent(MeshRoot, NAME_None, EAttachmentRule::KeepWorld);
		LeftInteractionComp.KickAnyPlayerOutOfInteraction();
		PlayerSharkComp.bIsThumping = false;
		InteractingPlayer = nullptr;
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
							  AHazePlayerCharacter Player)
	{
		SetActorControlSide(Player);
		Player.Mesh.AddLocomotionFeature(ThumperFeature, this);
		PlayerPendulumComp = UDesertPlayerPendulumComponent::GetOrCreate(Player);
		PlayerPendulumComp.AnimData.bIsLeftSideThumper = bHasHandleOnLeftSide;
		PlayerPendulumComp.AnimData.AnimState = ESandSharkPendulumAnimationState::Enter;
		InteractingPlayer = Player;
		
		FrameStartedInteraction = Time::FrameNumber;
		
		// FHazePlaySlotAnimationParams Params;
		// Params.Animation = ThumperPlayerAnimSequence;
		// Params.bLoop = true;
		// Player.PlaySlotAnimation(Params);
		SetActorTickEnabled(true);

		Timer::SetTimer(this, n"OnStartBlendFinished", 0.5);
		bHasStarted = false;
		bHasStopped = false;
	}

	UFUNCTION()
	private void OnStartBlendFinished()
	{
		if (InteractingPlayer == nullptr)
			return;
		
		PlayerSharkComp = USandSharkPlayerComponent::Get(InteractingPlayer);
		PlayerSharkComp.bIsThumping = true;

		PendulumComp.Period = FullRotationPeriod;
		PendulumComp.WidgetAttachComponent = WidgetAttachComp;
		PendulumComp.StartPendulum(InteractingPlayer);

		LeftHandleMeshComp.AttachToComponent(InteractingPlayer.Mesh, n"Align", EAttachmentRule::KeepWorld);
		RightHandleMeshComp.AttachToComponent(InteractingPlayer.Mesh, n"Align", EAttachmentRule::KeepWorld);
		USandSharkThumperEventHandler::Trigger_OnPlayerAttached(this);
		OnInstanceThumperPlayerAttached.Broadcast(InteractingPlayer);
	}

	void QueueSlam()
	{
		float ResetDuration = NrSuccessfulHits * (MaxResetDuration / NrStepsBeforeReset);
		if (Math::IsNearlyZero(ResetDuration))
			ResetDuration = 0.25;

		ActionQueue.Event(this, n"StartSlam");
		ActionQueue.Duration(ResetDuration, this, n"Slam");
		ActionQueue.Event(this, n"EndSlam");
	}

	void QueueSlam(float ResetDuration)
	{
		ActionQueue.Event(this, n"StartSlam");
		ActionQueue.Duration(ResetDuration, this, n"Slam");
		ActionQueue.Event(this, n"EndSlam");
	}

	UFUNCTION()
	private void StepReached()
	{
		CurrentLocation = PoleMeshComp.WorldLocation;
		float RemainingSuccessZone = PendulumComp.LastSuccessAlpha;
		float ExtraDuration = RemainingSuccessZone * 0.12; //just a lil extra duration if you press really early
		float Duration = ThumpDistractDuration + ExtraDuration;
		SharkToAttract.QueueDistractionParams(FSandSharkThumperDistractionParams(SharkPatrolOverrideSpline, Duration));
		if (NrSuccessfulHits == NrStepsBeforeReset)
		{
			// PendulumComp.StopPendulum(InteractingPlayer);
			QueueSlam(MaxResetDuration);
			if (HasControl())
				CrumbStopPlayerInteraction(InteractingPlayer);
			AddInteractionDisableInstigator(n"Completed");
			USandSharkThumperEventHandler::Trigger_OnFullyDown(this);
			OnInstanceThumpFullyDown.Broadcast(InteractingPlayer);
		}
	}

	UFUNCTION()
	void Slam(float Alpha)
	{
		//float NewRoll = Math::Lerp(-CrankRotationDegrees, 0, Math::ExpoIn(0, 1, Alpha));
		//LeftHandleMeshComp.RelativeRotation = FRotator(NewRoll, LeftHandleStartRotation.Yaw, LeftHandleStartRotation.Roll);
		//RightHandleMeshComp.RelativeRotation = FRotator(NewRoll, RightHandleStartRotation.Yaw, RightHandleStartRotation.Roll);
		PoleMeshComp.WorldLocation = Math::Lerp(CurrentLocation, StartLocation, Math::ExpoIn(0, 1, Alpha));
	}

	UFUNCTION()
	private void EndSlam()
	{
		RemoveInteractionDisableInstigator(n"Slam");

		CurrentLocation = StartLocation;
		NextLocation = StartLocation + FVector::UpVector * MoveAmountPerStep;
		NrSuccessfulHits = 0;
		CrankRotationDegrees = 0;
		PrevRotationStep = 0;
		NextRotationStep = 0;
		bHasStarted = false;
		bHasStopped = false;
		CamShakeFFComp.ActivateCameraShakeAndForceFeedback();
		USandSharkThumperEventHandler::Trigger_OnFullyReset(this);
	}

	UFUNCTION()
	private void StartSlam()
	{
		bHasStopped = true;
		RemoveInteractionDisableInstigator(n"Completed");
		AddInteractionDisableInstigator(n"Slam");

		// InteractionComp.Disable(this);
	}
};