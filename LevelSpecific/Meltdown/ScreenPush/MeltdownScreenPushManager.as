class AMeltdownScreenPushManager : AHazeActor
{
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_HazeGameplay;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(EditAnywhere)
	AHazeCameraActor MiddleCameraActor;
	UPROPERTY(EditAnywhere)
	AHazeSkeletalMeshActor MiddleRader;

	UPROPERTY(EditAnywhere)
	AHazeLevelSequenceActor PushSequence;

	UPROPERTY(Interp, EditAnywhere)
	float ProjectionOffsetPct = 0.0;
	UPROPERTY(Interp, EditAnywhere)
	UAnimSequence ZoeMashIdleMH;
	UPROPERTY(Interp, EditAnywhere)
	UAnimSequence MioMashIdleMH;
	UPROPERTY(Interp, EditAnywhere)
	UAnimSequence ZoeMashPushingMH;
	UPROPERTY(Interp, EditAnywhere)
	UAnimSequence MioMashPushingMH;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float CurrentSequenceTime = 0.0;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsSequencePlaying = false;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsMioPushing = false;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsZoePushing = false;

	UPROPERTY(Interp, EditAnywhere)
	bool bEnablePlayerHandIK = false;

	UPROPERTY(Interp, EditAnywhere)
	bool bPlayRaderIdle = false;

	UPROPERTY(Interp, EditAnywhere)
	bool bRaderEnableIKHandLeft = false;

	UPROPERTY(Interp, EditAnywhere)
	bool bRaderEnableIKHandRight = false;

	// Whether to currently allow the sequence to be paused because the players aren't mashing
	UPROPERTY(Interp, EditAnywhere)
	bool bAllowPausingFromMash = true;

	bool bHasEverAllowedPausing = false;

	UPROPERTY()
	TSubclassOf<UAnimInstance> ScreenPushAnimInstanceClass;
	UPROPERTY()
	TSubclassOf<UMeltdownScreenPushMashWidget> MashWidgetClass;

	bool bStartCenterPush = false;
	float GameTimeStartMiddleBlend = 0.0;
	AMultiScreenCameraUser MiddleCamUser;

	FVector RaderLeftHandPosition;
	FRotator RaderLeftHandRotation;
	FVector RaderRightHandPosition;
	FRotator RaderRightHandRotation;

	AStaticCameraActor MioCam;
	bool bMioCamActive = false;
	bool bCamerasSeparated = false;

	bool bActive = false;
	bool bMashActive = false;
	bool bHiddenLevel = false;

	bool bIsPausedFromMash = false;
	bool bIsAutoAdvance = false;
	float PreventPauseFromMashUntilGameTime = 0.0;

	UMeltdownScreenPushMashWidget MashWidget;

	TPerPlayer<UClass> PreviousAnimInstanceClass;
	TPerPlayer<USceneComponent> MashAttachLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MioCam = AStaticCameraActor::Spawn();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		auto RenderingSingleton = Game::GetSingleton(URenderingSettingsSingleton);
		RenderingSingleton.ViewDistanceScale.Clear(this);
		RenderingSingleton.TextureBoost.Clear(this);

		auto MioSubComp = USubtitleManagerComponent::Get(Game::Mio);
		if (MioSubComp != nullptr)
			MioSubComp.RemoveForceFullscreenInstigator(this);

		auto ZoeSubComp = USubtitleManagerComponent::Get(Game::Zoe);
		if (ZoeSubComp != nullptr)
			ZoeSubComp.RemoveForceHiddenInstigator(this);
	}

	UFUNCTION(DevFunction)
	void StartScreenPushIntro(bool bAutoAdvance = false)
	{
		bActive = true;
		bIsAutoAdvance = bAutoAdvance;
		SceneView::SetLevelRenderedForAnyView(Cast<UWorld>(Level.Outer), true);

		for (auto Player : Game::Players)
		{
			Player.ApplyOtherPlayerIndicatorMode(EOtherPlayerIndicatorMode::Hidden, this);
			PreviousAnimInstanceClass[Player] = Player.Mesh.GetAnimClass();
			Player.Mesh.SetAnimClass(ScreenPushAnimInstanceClass);

			Player.BlockCapabilities(n"PlayerHighlight", this);
		}

		auto RenderingSingleton = Game::GetSingleton(URenderingSettingsSingleton);
		RenderingSingleton.ViewDistanceScale.Apply(10.0, this);
		RenderingSingleton.TextureBoost.Apply(10.0, this);

		auto MioSubComp = USubtitleManagerComponent::Get(Game::Mio);
		if (MioSubComp != nullptr)
			MioSubComp.AddForceFullscreenInstigator(this);

		auto ZoeSubComp = USubtitleManagerComponent::Get(Game::Zoe);
		if (ZoeSubComp != nullptr)
			ZoeSubComp.AddForceHiddenInstigator(this);
	}

	UFUNCTION(DevFunction)
	void StartButtonMash()
	{
		MashWidget = Widget::AddFullscreenWidget(MashWidgetClass);
		MashWidget.Manager = this;

		bMashActive = true;
		for (auto Player : Game::Players)
		{
			FName AttachName;
			if (Player.IsMio())
				AttachName = n"MashAttach_Mio";
			else
				AttachName = n"MashAttach_Zoe";

			auto MashAttach = USceneComponent::Create(this, AttachName);
			MashAttachLocation[Player] = MashAttach;

			FButtonMashSettings Mash;
			Mash.ProgressionMode = EButtonMashProgressionMode::MashRateOnly; 
			Mash.WidgetAttachComponent = MashAttach;
			Mash.WidgetPositionOffset = FVector(0, 0, 0);
			Mash.Duration = 1.0;
			Mash.bShowButtonMashWidget = false;

			Player.StartButtonMash(Mash, this);
			Player.SetButtonMashAllowCompletion(this, false);

			UButtonMashComponent MashComp = UButtonMashComponent::Get(Player);
			if (Player.IsMio())
				MashComp.OnVisualPulse.AddUFunction(MashWidget, n"OnMioMash");
			else
				MashComp.OnVisualPulse.AddUFunction(MashWidget, n"OnZoeMash");

			UMeltdownScreenPushEffectHandler::Trigger_StartRaderBeam(Player);
		}
	}

	UFUNCTION(DevFunction)
	void StopButtonMash()
	{
		bMashActive = false;
		for (auto Player : Game::Players)
		{
			Player.StopButtonMash(this);
			UMeltdownScreenPushEffectHandler::Trigger_StopRaderBeam(Player);
		}

		NetPushSequenceFinished();

		if (MashWidget != nullptr)
		{
			Widget::RemoveFullscreenWidget(MashWidget);
			MashWidget = nullptr;
		}
	}

	UFUNCTION(DevFunction)
	void StartMiddleBlend()
	{
		bStartCenterPush = true;
		GameTimeStartMiddleBlend = Time::GameTimeSeconds;
		SetTickGroup(ETickingGroup::TG_PostUpdateWork);

		MiddleCamUser = SpawnActor(AMultiScreenCameraUser);
		MiddleCamUser.CameraUser.ChangeSplitScreenPosition(EHazeSplitScreenPosition::ThirdScreen);
		MiddleCamUser.ActivateCamera(MiddleCameraActor, 0.0, this, EHazeCameraPriority::Medium);

		for (auto Player : Game::Players)
		{
			UMeltdownScreenPushEffectHandler::Trigger_StopRaderBeam(Player);
		}
	}

	UFUNCTION(DevFunction)
	void SeparateCameras()
	{
		bCamerasSeparated = true;

		if (bMioCamActive)
		{
			Game::Mio.DeactivateCamera(MioCam, 0.0);

			auto MioCamSettings = UCameraSettings::GetSettings(Game::Mio);
			MioCamSettings.FOV.Clear(this);

			bMioCamActive = false;
		}
	}

	void UpdateProjectionOffsetPct()
	{
		auto MioViewPoint = Cast<UHazeCameraViewPoint>(Game::Mio.GetViewPoint());
		MioViewPoint.ApplyOffCenterProjectionOffset(FVector2D(-1.0 * ProjectionOffsetPct, 0.0), this);

		auto ZoeViewPoint = Cast<UHazeCameraViewPoint>(Game::Zoe.GetViewPoint());
		ZoeViewPoint.ApplyOffCenterProjectionOffset(FVector2D(1.0 *  ProjectionOffsetPct, 0.0), this);
	}

	void UpdateMioCamera()
	{
		if (!bCamerasSeparated)
		{
			if (!bMioCamActive)
			{
				Game::Mio.ActivateCamera(MioCam, 0.0, this, EHazeCameraPriority::MAX);
				bMioCamActive = true;
			}

			MioCam.SetActorLocationAndRotation(
				Game::Zoe.ViewLocation - FVector(50000, -400000, 0), Game::Zoe.ViewRotation);

			auto MioCamSettings = UCameraSettings::GetSettings(Game::Mio);
			MioCamSettings.FOV.Apply(Game::Zoe.ViewFOV, this, Priority = EHazeCameraPriority::MAX);
		}
	}

	UFUNCTION()
	void OnSequenceFinished()
	{
	}

	void UpdateMashing(float DeltaSeconds)
	{
		if (!bMashActive)
			return;

		if (HasControl())
		{
			bool bBothPlayersMashing = true;
			for (auto Player : Game::Players)
			{
				float MashRate;
				bool bMashRateSufficient;
				Player.GetButtonMashCurrentRate(this, MashRate, bMashRateSufficient);

				if (!bMashRateSufficient)
				{
					bBothPlayersMashing = false;
				}
			}

			if (bIsAutoAdvance)
				bBothPlayersMashing = true;
			if (bEitherSidePushFinished)
				bBothPlayersMashing = true;

			if (bIsPausedFromMash)
			{
				if (bBothPlayersMashing)
				{
					PushSequence.GetSequencePlayer().Play();
					bIsPausedFromMash = false;
					PreventPauseFromMashUntilGameTime = Time::GameTimeSeconds + 1.0;
					NetPushSequenceResume(PushSequence.GetSequencePlayer().CurrentTime.Time.FrameNumber.Value);
				}
			}
			else
			{
				if (!bBothPlayersMashing && PreventPauseFromMashUntilGameTime <= Time::GameTimeSeconds && bAllowPausingFromMash)
				{
					NetPushSequencePause(PushSequence.GetSequencePlayer().CurrentTime.Time.FrameNumber.Value);
					PushSequence.GetSequencePlayer().Pause();
					bIsPausedFromMash = true;
				}
			}
		}
		else
		{
			if (bIsPausedFromMash)
			{
				if (!bControlSidePaused || bEitherSidePushFinished)
				{
					RemoteUnpauseDelay -= DeltaSeconds;
					if (RemoteUnpauseDelay <= 0.0)
					{
						PushSequence.GetSequencePlayer().Play();
						bIsPausedFromMash = false;
					}
				}
			}
			else
			{
				if (bControlSidePaused && !bEitherSidePushFinished)
				{
					if (PushSequence.GetSequencePlayer().CurrentTime.Time.FrameNumber.Value >= ControlSidePauseFrame)
					{
						PushSequence.GetSequencePlayer().Pause();
						bIsPausedFromMash = true;
					}
				}
			}
		}

		if (!bStartCenterPush)
		{
			for (auto Player : Game::Players)
			{
				FMeltdownScreenPushRaderBeamParams BeamParams;
				BeamParams.PlayerLocation = (Player.Mesh.GetSocketLocation(n"LeftHand") + Player.Mesh.GetSocketLocation(n"RightHand")) * 0.5;
				BeamParams.RaderLocation = Player.ActorLocation;
				BeamParams.RaderLocation.Z = BeamParams.PlayerLocation.Z;
				UMeltdownScreenPushEffectHandler::Trigger_UpdateRaderBeam(Player, BeamParams);
			}
		}

		for (auto Player : Game::Players)
		{
			// FVector PushLocation = (Player.Mesh.GetSocketLocation(n"LeftHand") + Player.Mesh.GetSocketLocation(n"RightHand")) * 0.5;
			MashAttachLocation[Player].WorldLocation = Player.Mesh.GetSocketLocation(n"FaceManager");
		}
	}

	int ControlSidePauseFrame = 0;
	bool bControlSidePaused = false;
	bool bEitherSidePushFinished = false;
	float RemoteUnpauseDelay = 0.0;

	UFUNCTION(NetFunction)
	void NetPushSequenceResume(int ResumeFrame)
	{
		if (HasControl())
			return;

		bControlSidePaused = false;
	}

	UFUNCTION(NetFunction)
	void NetPushSequencePause(int PauseFrame)
	{
		if (HasControl())
			return;

		ControlSidePauseFrame = PauseFrame;
		bControlSidePaused = true;

		int OvershotFrames = PushSequence.GetSequencePlayer().CurrentTime.Time.FrameNumber.Value - ControlSidePauseFrame;
		float FrameTime = float(PushSequence.GetSequencePlayer().FrameRate.Denominator) / float(PushSequence.GetSequencePlayer().FrameRate.Numerator);
		RemoteUnpauseDelay = Math::Max(0.0, float(OvershotFrames) * FrameTime);
	}
	
	UFUNCTION(NetFunction)
	void NetPushSequenceFinished()
	{
		bEitherSidePushFinished = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bActive && !bHiddenLevel)
		{
			SceneView::SetLevelRenderedForAnyView(Cast<UWorld>(Level.Outer), false);
			bHiddenLevel = true;
		}

		FVector2D ConstrainedResolution = SceneView::GetConstrainedViewportResolution();
		if (ConstrainedResolution.X == 0 || ConstrainedResolution.Y == 0)
			return;

		FVector2D ViewportResolution = SceneView::GetFullViewportResolution();
		if (ViewportResolution.X == 0 || ViewportResolution.Y == 0)
			return;

		if (!bActive)
			return;

		if (PushSequence != nullptr)
			CurrentSequenceTime = PushSequence.GetSequencePlayer().CurrentTime.AsSeconds();
		bIsSequencePlaying = !bIsPausedFromMash;

		for (auto Player : Game::Players)
		{
			float MashRate;
			bool bMashRateSufficient;
			Player.GetButtonMashCurrentRate(this, MashRate, bMashRateSufficient);

			if (Player.IsMio())
				bIsMioPushing = bMashRateSufficient;
			else
				bIsZoePushing = bMashRateSufficient;
		}

		// PrintToScreenScaled(f"{CurrentSequenceTime=}");
		// PrintToScreenScaled(f"{bIsSequencePlaying=}");
		// PrintToScreenScaled(f"{bIsMioPushing=}");
		// PrintToScreenScaled(f"{bIsZoePushing=}");

		UpdateMashing(DeltaSeconds);
		UpdateMioCamera();

		if (!bStartCenterPush)
		{
			UpdateProjectionOffsetPct();
			return;
		}

		if (!bAllowPausingFromMash)
		{
			if (bHasEverAllowedPausing)
			{
				for (auto Player : Game::Players)
				{
					Player.SetFrameForceFeedback(0.1, 0.15, 0.0, 0.0);
				}
			}
		}
		else
		{
			bHasEverAllowedPausing = true;
		}

		float PixelCenter = Math::GridSnap(0.5, 2.0 / ConstrainedResolution.X);

		// Calculate the views as if we had the full screen available
		auto MioViewPoint = Cast<UHazeCameraViewPoint>(Game::Mio.GetViewPoint());
		FHazeViewParameters MioViewParams;
		MioViewParams.Location = MioViewPoint.ViewLocation;
		MioViewParams.Rotation = MioViewPoint.ViewRotation;
		MioViewParams.FOV = MioViewPoint.ViewFOV;
		MioViewParams.bConstrainAspectRatio = true;
		MioViewParams.ViewRectMin = FVector2D(0, 0);
		MioViewParams.ViewRectMax = FVector2D(PixelCenter, 1);
		MioViewParams.OffCenterProjectionOffset = FVector2D(-1.0, 0.0);
		MioViewParams.ScreenResolution = ViewportResolution;

		auto ZoeViewPoint = Cast<UHazeCameraViewPoint>(Game::Zoe.GetViewPoint());
		FHazeViewParameters ZoeViewParams;
		ZoeViewParams.Location = ZoeViewPoint.ViewLocation;
		ZoeViewParams.Rotation = ZoeViewPoint.ViewRotation;
		ZoeViewParams.FOV = ZoeViewPoint.ViewFOV;
		ZoeViewParams.bConstrainAspectRatio = true;
		ZoeViewParams.ViewRectMin = FVector2D(PixelCenter, 0);
		ZoeViewParams.ViewRectMax = FVector2D(1.0, 1.0);
		ZoeViewParams.OffCenterProjectionOffset = FVector2D(1.0, 0.0);
		ZoeViewParams.ScreenResolution = ViewportResolution;

		FHazeComputedView MioView = SceneView::ComputeView(MioViewParams);
		FHazeComputedView ZoeView = SceneView::ComputeView(ZoeViewParams);

		FVector HandOffset(0, 0, 15);

		// Figure out where the player is pushing on this fake full view
		FVector MioAlign = Game::Mio.Mesh.GetSocketTransform(n"Align").TransformPosition(HandOffset);
		// Debug::DrawDebugSphere(MioAlign);

		FVector2D MioAlignUV;
		MioView.ProjectWorldToViewUV(MioAlign, MioAlignUV);

		FVector ZoeAlign = Game::Zoe.Mesh.GetSocketTransform(n"Align").TransformPosition(HandOffset);

		FVector2D ZoeAlignUV;
		ZoeView.ProjectWorldToViewUV(ZoeAlign, ZoeAlignUV);

		// Debug::DrawDebugSphere(ZoeLeftHand, 10);

		// Adjust the view rectangles to match
		SceneView::SetSplitScreenMode(EHazeSplitScreenMode::ManualViews);

		TArray<FHazeManualView> ManualViews;

		float PushBlendAlpha = 1.0;
		float Time = Time::GetGameTimeSince(GameTimeStartMiddleBlend);
		if (Time < 0.5)
			PushBlendAlpha = Math::EaseIn(0.0, 1.0, Time / 0.5, 2.0);

		float MioOffset = Math::Clamp(0.5 * (1.0 - MioAlignUV.X) * PushBlendAlpha, 0.0, 0.49);
		MioOffset = Math::GridSnap(MioOffset, 1.0 / ConstrainedResolution.X);
		MioOffset += (0.5/ConstrainedResolution.X);

		float ZoeOffset = Math::Clamp((0.5 * ZoeAlignUV.X) * PushBlendAlpha, 0.0, 0.49);
		ZoeOffset = Math::GridSnap(ZoeOffset, 1.0 / ConstrainedResolution.X);
		ZoeOffset += (0.5/ConstrainedResolution.X);

		float MioSize = PixelCenter - MioOffset;
		float MioModifiedCenter = PixelCenter * MioSize;
		float MioPreviousCenter = PixelCenter;

		float MioCenterDelta = MioPreviousCenter - MioModifiedCenter;
		float MioCenterOffset = MioCenterDelta / MioSize * -2.0;

		FHazeManualView MioFinalView;
		MioFinalView.TopLeft = FVector2D(0, 0);
		MioFinalView.BottomRight = FVector2D(0.5 - MioOffset, 1.0);
		ManualViews.Add(MioFinalView);
		MioViewPoint.ApplyOffCenterProjectionOffset(FVector2D(MioCenterOffset, 0.0), this);

		float ZoeSize = PixelCenter - ZoeOffset;
		float ZoeModifiedCenter = 1.0 - PixelCenter * ZoeSize;
		float ZoePreviousCenter = PixelCenter;

		float ZoeCenterDelta = ZoePreviousCenter - ZoeModifiedCenter;
		float ZoeCenterOffset = ZoeCenterDelta / ZoeSize * -2.0;

		FHazeManualView ZoeFinalView;
		ZoeFinalView.TopLeft = FVector2D(1.0 - ZoeSize, 0);
		ZoeFinalView.BottomRight = FVector2D(1.0, 1.0);
		ManualViews.Add(ZoeFinalView);
		ZoeViewPoint.ApplyOffCenterProjectionOffset(FVector2D(ZoeCenterOffset, 0.0), this);

		TEMPORAL_LOG("/SceneView/View 0").Section("ScreenPush")
			.Point("MioAlign", MioAlign)
			.Value("MioAlignUV", MioAlignUV.X)
			.Value("MioOffset", MioOffset)
			.Value("ConstrainedResolution.X", ConstrainedResolution.X)
			.Value("MioPixelOffset", MioOffset*ConstrainedResolution.X)
			.Value("MioFinalView.Left", int(MioFinalView.TopLeft.X*ConstrainedResolution.X))
			.Value("MioFinalView.Right", int(MioFinalView.BottomRight.X*ConstrainedResolution.X))
			.Value("MioCenterOffset", MioCenterOffset)
		;

		TEMPORAL_LOG("/SceneView/View 1").Section("ScreenPush")
			.Point("ZoeAlign", ZoeAlign)
			.Value("ZoeAlignUV", ZoeAlignUV.X)
			.Value("ZoeOffset", ZoeOffset)
			.Value("ConstrainedResolution.X", ConstrainedResolution.X)
			.Value("ZoePixelOffset", ZoeOffset*ConstrainedResolution.X)
			.Value("ZoeFinalView.Left", int(ZoeFinalView.TopLeft.X*ConstrainedResolution.X))
			.Value("ZoeFinalView.Right", int(ZoeFinalView.BottomRight.X*ConstrainedResolution.X))
			.Value("ZoeCenterOffset", ZoeCenterOffset)
		;

		if (ZoeOffset + MioOffset > 0.0001)
		{
			FHazeManualView MiddleView;
			MiddleView.TopLeft = FVector2D(0.5 - MioOffset + 4 / ConstrainedResolution.X, 0.0);
			MiddleView.BottomRight = FVector2D(0.5 + ZoeOffset - 4 / ConstrainedResolution.X, 1.0);
			ManualViews.Add(MiddleView);

			auto RaderViewPoint = Cast<UHazeCameraViewPoint>(MiddleCamUser.CameraUser.GetView());
			RaderViewPoint.SetShowLetterbox(true);
			RaderViewPoint.SetLetterboxBlendSpeed(EHazeViewPointBlendSpeed::Instant);
			RaderViewPoint.ApplyConstrainAspectRatio(this);

			float FadeAlpha = Math::GetMappedRangeValueClamped(
				FVector2D(0.025, 0.05),
				FVector2D(1, 0),
				ZoeOffset + MioOffset
			);
			MiddleCamUser.SetFadeOverlayColor(FLinearColor(0, 0, 0, FadeAlpha));

			FHazeViewParameters RaderViewParams;
			RaderViewParams.Location = RaderViewPoint.ViewLocation;
			RaderViewParams.Rotation = RaderViewPoint.ViewRotation;
			RaderViewParams.FOV = RaderViewPoint.ViewFOV;
			RaderViewParams.bConstrainAspectRatio = true;
			RaderViewParams.ViewRectMin = FVector2D(0.5 - MioOffset, 0.0);
			RaderViewParams.ViewRectMax = FVector2D(0.5 + ZoeOffset, 1);
			RaderViewParams.ScreenResolution = ConstrainedResolution;

			FHazeComputedView RaderView = SceneView::ComputeView(RaderViewParams);

			FVector RaderShoulderLocation = MiddleRader.Mesh.WorldLocation + FVector(200, 0, 100);
			FVector2D RaderShoulderUV;
			RaderView.ProjectWorldToViewUV(RaderShoulderLocation, RaderShoulderUV);

			const float RaderCenterDepth = RaderShoulderLocation.Distance(RaderViewParams.Location);
			const float RaderHandDepth = RaderCenterDepth - 15.0;
			const float RaderHandOffset = 0.0;

			FVector LeftOrigin;
			FVector LeftDirection;
			RaderView.DeprojectViewUVToWorld(FVector2D(1.0, RaderShoulderUV.Y), LeftOrigin, LeftDirection);

			RaderLeftHandPosition = LeftOrigin + LeftDirection * RaderHandDepth - RaderViewPoint.ViewRotation.RightVector * RaderHandOffset;
			RaderLeftHandRotation = FRotator::MakeFromX(RaderViewPoint.ViewRotation.RightVector);
			// Debug::DrawDebugSphere(RaderLeftHandPosition, 50);

			FVector RightOrigin;
			FVector RightDirection;
			RaderView.DeprojectViewUVToWorld(FVector2D(0.0, RaderShoulderUV.Y), RightOrigin, RightDirection);

			RaderRightHandPosition = RightOrigin + RightDirection * RaderHandDepth + RaderViewPoint.ViewRotation.RightVector * RaderHandOffset;
			RaderRightHandRotation = FRotator::MakeFromX(-RaderViewPoint.ViewRotation.RightVector);
			// Debug::DrawDebugSphere(RaderRightHandPosition, 50);
		}

		SceneView::SetManualViews(ManualViews);

		// Update Rader's view to match Zoe's
		if (bStartCenterPush)
		{
			MiddleCameraActor.SetActorLocationAndRotation(
				Game::Zoe.ViewLocation + FVector(-50000, 50000, 0),
				Game::Zoe.ViewRotation);

			auto MiddleCamSettings = MiddleCamUser.CameraUser.GetCameraSettings();
			MiddleCamSettings.FOV.Apply(Game::Zoe.ViewFOV, this, Priority = EHazeCameraPriority::MAX);
		}
	}
};

struct FMeltdownScreenPushRaderBeamParams
{
	UPROPERTY()
	FVector PlayerLocation;
	UPROPERTY()
	FVector RaderLocation;
}

UCLASS(Abstract)
class UMeltdownScreenPushEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartRaderBeam() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void UpdateRaderBeam(FMeltdownScreenPushRaderBeamParams BeamParams) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopRaderBeam() {}
}

class UMeltdownScreenPushMashWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UButtonMashWidget MioMashWidget;
	UPROPERTY(BindWidget)
	UButtonMashWidget ZoeMashWidget;

	AMeltdownScreenPushManager Manager;

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		MioMashWidget.MashSettings.ProgressionMode = EButtonMashProgressionMode::MashRateOnly;
		MioMashWidget.OverrideWidgetPlayer(Game::Mio);

		ZoeMashWidget.MashSettings.ProgressionMode = EButtonMashProgressionMode::MashRateOnly;
		ZoeMashWidget.OverrideWidgetPlayer(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		UpdateWidget(Game::Mio, MioMashWidget);
		UpdateWidget(Game::Zoe, ZoeMashWidget);
	}

	void UpdateWidget(AHazePlayerCharacter MashPlayer, UButtonMashWidget MashWidget)
	{
		FVector2D UIPos;
		SceneView::ProjectWorldToScreenPosition(MashPlayer, MashPlayer.Mesh.GetSocketLocation(n"Align"), UIPos);

		auto MashSlot = Cast<UCanvasPanelSlot>(MashWidget.Slot);
		MashSlot.SetAnchors(FAnchors(UIPos.X, UIPos.Y));
	}

	UFUNCTION()
	void OnMioMash()
	{
		MioMashWidget.Pulse();
	}

	UFUNCTION()
	void OnZoeMash()
	{
		ZoeMashWidget.Pulse();
	}
}

class UMeltdownScreenPushStepNotify : UAnimNotify
{
	UPROPERTY(EditAnywhere)
	bool bIsFinal = false;

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		auto Player = Cast<AHazePlayerCharacter>(MeshComp.Owner);
		if (Player != nullptr)
		{
			if (bIsFinal)
				Player.PlayForceFeedback(ForceFeedback::Default_Heavy, this);
			else
				Player.PlayForceFeedback(ForceFeedback::Default_Medium_Short, this);
		}

		return true;
	}
}