event void FVillagePumpCartEvent();

UCLASS(Abstract)
class AVillagePumpCart : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent CartRoot;
	// This root is a static mesh in order to allow shadowing as a group
	default CartRoot.bLightAttachmentsAsGroup = true;

	UPROPERTY(DefaultComponent, Attach = CartRoot)
	USceneComponent LeftTopWheel;

	UPROPERTY(DefaultComponent, Attach = CartRoot)
	USceneComponent LeftBottomWheel;

	UPROPERTY(DefaultComponent, Attach = CartRoot)
	USceneComponent RightTopWheel;

	UPROPERTY(DefaultComponent, Attach = CartRoot)
	USceneComponent RightBottomWheel;

	UPROPERTY(DefaultComponent, Attach = CartRoot)
	UInteractionComponent LeftInteraction;

	UPROPERTY(DefaultComponent, Attach = CartRoot)
	UInteractionComponent RightInteraction;

	UPROPERTY(DefaultComponent, Attach = CartRoot)
	USceneComponent PumpBase;

	UPROPERTY(DefaultComponent, Attach = PumpBase)
	USceneComponent PumpRoot;

	UPROPERTY(DefaultComponent, Attach = PumpRoot)
	USceneComponent LeftPumpHandle;

	UPROPERTY(DefaultComponent, Attach = PumpRoot)
	USceneComponent RightPumpHandle;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedPosition;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;
	default CapabilityRequestComp.PlayerCapabilities.Add(n"VillagePumpCartPlayerCapability");

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect PumpFF;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect FailFF;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> MovePassiveCamShakeClass;
	UCameraShakeBase MovePassiveCamShakeInstance;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> FailCamShake;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> HitBottomCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect HitBottomFF;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> HitTopCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect HitTopFF;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike CrashDownTimeLike;
	bool bCrashingDown = false;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeaturePumpCart MioFeature;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeaturePumpCart ZoeFeature;

	UPROPERTY(EditAnywhere)
	bool bAtTop = true;

	UPROPERTY(EditDefaultsOnly)
	FText PumpTutorialText;

	UPROPERTY()
	FVillagePumpCartEvent OnBothPlayersEntered;

	UPROPERTY()
	FVillagePumpCartEvent OnReachedTop;

	UPROPERTY()
	FVillagePumpCartEvent OnCrashedDown;

	bool bMoving = false;
	float CurrentMoveSpeed = 0.0;
	float CurrentMoveSpeedInterpSpeed = 3.0;
	float TargetMoveSpeed = 0.0;
	float MaxUpMoveSpeed = 600.0;
	float MaxDownMoveSpeed = 600.0;
	float SpeedIncreasePerPump = 150.0;

	float SpeedDecreaseRate = 120.0;
	float MinSpeedDecreaseRate = 120.0;
	float MaxSpeedDecreaseRate = 300.0;
	float SpeedDecreaseRateInterpSpeed = 1.0;

	float SplineDist = 0.0;

	bool bReachedTop = false;

	bool bMioInteracting = false;
	bool bZoeInteracting = false;
	bool bBothPlayersInteracting = false;

	bool bPumpOnLeftSide = true;
	bool bPumping = false;
	float CurrentPumpTime = 0.0;
	float PumpDuration = 0.5;
	float LastPumpGameTime = 0.0;

	bool bFailActive = false;
	float CurrentFailTime = 0.0;
	float FailDuration = 1.2;

	UPROPERTY(EditInstanceOnly)
	bool bPreviewPosition = false;
	UPROPERTY(EditInstanceOnly, meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float PreviewFraction = 0.0;

	float BufferThreshold = 0.4;

	AVillagePumpCartHandle Handle;

	bool bFullscreenTransitionFinished = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewPosition && SplineActor != nullptr)
		{
			FTransform PreviewTransform = SplineActor.Spline.GetWorldTransformAtSplineDistance(SplineActor.Spline.SplineLength * PreviewFraction);
			FRotator Rot = FRotator(PreviewTransform.Rotation);
			Rot.Roll = 0.0;
			Rot.Pitch = 0.0;
			SetActorLocationAndRotation(PreviewTransform.Location, Rot);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Handle = TListedActors<AVillagePumpCartHandle>().Single;

		LeftInteraction.OnInteractionStarted.AddUFunction(this, n"LeftStarted");
		RightInteraction.OnInteractionStarted.AddUFunction(this, n"RightStarted");

		CrashDownTimeLike.BindUpdate(this, n"UpdateCrashDown");
		CrashDownTimeLike.BindFinished(this, n"FinishCrashDown");

		if (bAtTop)
		{
			SetActorLocation(SplineActor.Spline.GetWorldLocationAtSplineFraction(1.0));
		}
	}

	UFUNCTION()
	private void LeftStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		UVillagePumpCartPlayerComponent PlayerComp = UVillagePumpCartPlayerComponent::GetOrCreate(Player);
		PlayerComp.PumpCart = this;

		bMioInteracting = true;
	}

	UFUNCTION()
	private void RightStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		UVillagePumpCartPlayerComponent PlayerComp = UVillagePumpCartPlayerComponent::GetOrCreate(Player);
		PlayerComp.PumpCart = this;

		bZoeInteracting = true;
	}

	void BothPlayersEntered()
	{
		if (bBothPlayersInteracting)
			return;

		bBothPlayersInteracting = true;
		OnBothPlayersEntered.Broadcast();
	}

	UFUNCTION()
	void SetFullScreenTransitionFinished()
	{
		bFullscreenTransitionFinished = true;
	}

	void InteractionCancelled(AHazePlayerCharacter Player)
	{
		if (Player.IsMio())
			bMioInteracting = false;
		else
			bZoeInteracting = false;
	}

	void Pump()
	{
		if (bPumping)
			return;
		if (bReachedTop)
			return;

		LastPumpGameTime = Time::GameTimeSeconds;
		TargetMoveSpeed = Math::Clamp(TargetMoveSpeed + SpeedIncreasePerPump, SpeedIncreasePerPump, MaxUpMoveSpeed);
		SpeedDecreaseRate = MinSpeedDecreaseRate;

		CurrentPumpTime = 0.0;
		bPumping = true;

		AHazePlayerCharacter Player = bPumpOnLeftSide ? Game::Mio : Game::Zoe;
		Player.PlayForceFeedback(PumpFF, false, true, this, 0.5);

	}

	void FinishPump()
	{
		if (bReachedTop)
			return;
		bPumping = false;

		FVIllagePumpCartPlayerParams Params;
		Params.Player = bPumpOnLeftSide ? Game::Zoe : Game::Mio;
		UVillagePumpCartEffectEventHandler::Trigger_SuccessfulPump(this, Params);

		bPumpOnLeftSide = !bPumpOnLeftSide;
	}

	void FailPump(AHazePlayerCharacter FailingPlayer)
	{
		if (bReachedTop)
			return;
		CurrentFailTime = 0.0;
		bFailActive = true;

		TargetMoveSpeed = -MaxDownMoveSpeed;
		CurrentMoveSpeed = 0.0;
		SpeedDecreaseRate = MaxSpeedDecreaseRate;

		if (bPumping)
		{
			bPumping = false;
		}
		else
		{
			bPumpOnLeftSide = !bPumpOnLeftSide;
		}

		FVIllagePumpCartPlayerParams Params;
		Params.Player = FailingPlayer;
		UVillagePumpCartEffectEventHandler::Trigger_FailedPump(this, Params);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.PlayCameraShake(FailCamShake, this);
			Player.PlayForceFeedback(FailFF, false, true, this);
		}
	}

	UFUNCTION()
	private void FinishFail()
	{
		bFailActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bAtTop)
			return;

		if (bReachedTop)
			return;

		if (bFailActive)
		{
			CurrentFailTime += DeltaTime;
			if (CurrentFailTime >= FailDuration)
				bFailActive = false;
		}
		else if (bPumping)
		{
			CurrentPumpTime += DeltaTime;
			if (CurrentPumpTime >= PumpDuration)
				FinishPump();
		}

		if (HasControl())
		{
			float SpeedDecreaseDeltaTime = DeltaTime;

			// In network, the speed decrease is slower to make up for ping
			if (Network::IsGameNetworked())
			{
				if (Time::GetGameTimeSince(LastPumpGameTime) < PumpDuration + Network::PingRoundtripSeconds)
					SpeedDecreaseDeltaTime *= (PumpDuration / (PumpDuration + Network::PingRoundtripSeconds));
			}

			SpeedDecreaseRate = Math::FInterpTo(SpeedDecreaseRate, MaxSpeedDecreaseRate, SpeedDecreaseDeltaTime, SpeedDecreaseRateInterpSpeed);
			TargetMoveSpeed -= SpeedDecreaseRate * SpeedDecreaseDeltaTime;

			TargetMoveSpeed = Math::Clamp(TargetMoveSpeed, -MaxDownMoveSpeed, MaxUpMoveSpeed);
			CurrentMoveSpeed = Math::FInterpTo(CurrentMoveSpeed, TargetMoveSpeed, DeltaTime, CurrentMoveSpeedInterpSpeed);

			SplineDist += CurrentMoveSpeed * DeltaTime;
			SplineDist = Math::Clamp(SplineDist, 0.0, SplineActor.Spline.SplineLength);

			SyncedPosition.Value = SplineDist;
		}
		else
		{
			SplineDist = SyncedPosition.Value;
		}

		SetActorLocation(SplineActor.Spline.GetWorldLocationAtSplineDistance(SplineDist));
		if (SplineDist <= 0.0)
			StopMoving(true);
		else
			StartMoving();

		if (MovePassiveCamShakeInstance != nullptr)
		{
			float CamShakeScale = Math::GetMappedRangeValueClamped(FVector2D(0.0, MaxDownMoveSpeed), FVector2D(0.1, 1.0), Math::Abs(CurrentMoveSpeed));
			MovePassiveCamShakeInstance.ShakeScale = CamShakeScale;
		}

		if (SplineDist >= SplineActor.Spline.SplineLength && HasControl())
			CrumbReachedTop();
	}

	void StartMoving()
	{
		if (bMoving)
			return;

		bMoving = true;

		if (SceneView::FullScreenPlayer != nullptr) // May not be fullscreen yet if still blending
			MovePassiveCamShakeInstance = SceneView::FullScreenPlayer.PlayCameraShake(MovePassiveCamShakeClass, this);
	}

	void StopMoving(bool bBottom)
	{
		if (!bMoving)
			return;

		bMoving = false;
		if (SceneView::FullScreenPlayer != nullptr) // May not be fullscreen yet if still blending
			SceneView::FullScreenPlayer.StopCameraShakeInstance(MovePassiveCamShakeInstance, false);
		MovePassiveCamShakeInstance = nullptr;

		if (bBottom)
		{
			if (Math::Abs(CurrentMoveSpeed) >= MaxDownMoveSpeed/2)
			{
				if (SceneView::FullScreenPlayer != nullptr) // May not be fullscreen yet if still blending
					SceneView::FullScreenPlayer.PlayCameraShake(HitBottomCamShake, this, 0.2);

				for (AHazePlayerCharacter Player : Game::GetPlayers())
				{
					Player.PlayCameraShake(HitBottomCamShake, this);
					Player.PlayForceFeedback(HitBottomFF, false, true, this);
				}

				UVillagePumpCartEffectEventHandler::Trigger_ReachedBottom(this);
			}
		}
	}

	UFUNCTION(DevFunction)
	void PretendWeReachedTheTop()
	{
		if (HasControl())
			CrumbReachedTop();
	}

	UFUNCTION(CrumbFunction)
	void CrumbReachedTop()
	{
		SceneView::FullScreenPlayer.PlayCameraShake(HitTopCamShake, this, 0.2);
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.PlayCameraShake(HitTopCamShake, this);
			Player.PlayForceFeedback(HitTopFF, false, true, this);
		}

		bReachedTop = true;
		bFailActive = false;
		bPumping = false;
		OnReachedTop.Broadcast();

		LeftInteraction.Disable(this);
		RightInteraction.Disable(this);

		StopMoving(false);

		UVillagePumpCartEffectEventHandler::Trigger_ReachedTop(this);
	}

	UFUNCTION(DevFunction)
	void CrashDown()
	{
		bCrashingDown = true;
		CrashDownTimeLike.PlayFromStart();

		UVillagePumpCartEffectEventHandler::Trigger_StartCrashing(this);
		BP_CrashDown();
	}

	UFUNCTION(BlueprintEvent)
	void BP_CrashDown() {}

	UFUNCTION()
	private void UpdateCrashDown(float CurValue)
	{
		float SplineFraction = Math::Lerp(1.0, 0.0, CurValue);
		SetActorLocation(SplineActor.Spline.GetWorldLocationAtSplineFraction(SplineFraction));

		float TopWheelRot = Math::Lerp(0.0, 1080.0, CurValue);
		RightTopWheel.SetRelativeRotation(FRotator(TopWheelRot, 0.0, 0.0));
		LeftTopWheel.SetRelativeRotation(FRotator(TopWheelRot, 0.0, 0.0));

		float BottomWheelRot = Math::Lerp(0.0, 1440.0, CurValue);
		RightBottomWheel.SetRelativeRotation(FRotator(BottomWheelRot, 0.0, 0.0));
		LeftBottomWheel.SetRelativeRotation(FRotator(BottomWheelRot, 0.0, 0.0));
	}

	UFUNCTION()
	private void FinishCrashDown()
	{
		bCrashingDown = false;
		bAtTop = false;
		OnCrashedDown.Broadcast();
		UVillagePumpCartEffectEventHandler::Trigger_CrashFinished(this);

		BP_FinishCrashingDown();

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (GetDistanceTo(Player) <= 1500.0)
			{
				FKnockdown Knockdown;
				Knockdown.Duration = 1.5;
				FVector KnockdownDir = (Player.ActorLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
				Knockdown.Move = KnockdownDir * 200.0;
				Player.ApplyKnockdown(Knockdown);
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_FinishCrashingDown() {}

	UFUNCTION(BlueprintPure)
	float GetNormalizedSplineDistance() property
	{
		return Math::Min(1, SplineDist / SplineActor.Spline.SplineLength);
	}

	UFUNCTION(BlueprintPure)
	float GetNormalizedPumpRotation() property
	{
		float CurPitch = Handle.Mesh.GetSocketRotation(n"Base").Pitch;
		float NormalizedPitch = Math::GetMappedRangeValueClamped(FVector2D(-30.0, 30.0), FVector2D(1.0, -1.0), CurPitch);
		return NormalizedPitch;
	}
}

class UVillagePumpCartEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void FailedPump(FVIllagePumpCartPlayerParams Params) {}
	UFUNCTION(BlueprintEvent)
	void SuccessfulPump(FVIllagePumpCartPlayerParams Params) {}
	UFUNCTION(BlueprintEvent)
	void ReachedBottom() {}
	UFUNCTION(BlueprintEvent)
	void ReachedTop() {}
	UFUNCTION(BlueprintEvent)
	void StartCrashing() {}
	UFUNCTION(BlueprintEvent)
	void CrashFinished() {}
}

struct FVIllagePumpCartPlayerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}