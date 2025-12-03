struct FCameraBlendToSplitScreenData
{
	bool bActive = false;
	float TimeSinceStart = 0.0;
	float BlendDuration = 0.0;

	bool bSplitFadedIn = false;
	UObject PendingViewSizeInstigator;
	AHazePlayerCharacter FullscreenPlayer;

	bool bAppliedCamera = false;
	FVector ViewVelocity;
	AStaticCameraActor ViewCamera;
}

struct FCameraBlendToFullScreenData
{
	bool bActive = false;
	float TimeSinceStart = 0.0;
	float TotalBlendDuration = 0.0;
	float CameraBlendDuration = 0.0;
	float ProjectionBlendTime = 0.0;

	UObject PendingViewSizeInstigator;
	AHazePlayerCharacter FullscreenPlayer;
	UHazeCameraComponent TargetCamera;

	UHazeCameraViewPointBlendType BlendType;
	UCameraDefaultBlend DefaultBlendType;
	bool bUseCameraBlendForOffset = false;

	bool bAppliedViewSize = false;
	bool bAppliedCamera = false;
}

class UCameraSingleton : UHazeCameraSingleton
{
	const float SPLIT_FADE_IN_TIME = 0.15;
	const float SPLIT_FADE_OUT_TIME = 0.15;

	FCameraBlendToSplitScreenData SplitBlend;
	FCameraBlendToFullScreenData FSBlend;
	AStaticCameraActor DummyCamera;

	UFUNCTION(BlueprintOverride)
	void BlendToFullScreenUsingProjectionOffset(AHazePlayerCharacter NewFullScreenPlayer,
	                                            UObject ViewSizeInstigatorToApply,
												float CameraBlendTime,
	                                            float ProjectionBlendTime)
	{
		if (SplitBlend.bActive)
			StopBlendingToSplitScreen();
		if (FSBlend.bActive)
			StopBlendingToFullScreen();

		FSBlend = FCameraBlendToFullScreenData();
		FSBlend.bActive = true;
		FSBlend.FullscreenPlayer = NewFullScreenPlayer;
		FSBlend.TimeSinceStart = 0.0;
		FSBlend.PendingViewSizeInstigator = ViewSizeInstigatorToApply;

		float AccelerationFinishedFactor = 1.0;
		float BaseBlendTime = Math::Max(ProjectionBlendTime, CameraBlendTime);

		FSBlend.TotalBlendDuration = BaseBlendTime * AccelerationFinishedFactor;
		FSBlend.CameraBlendDuration = BaseBlendTime;
		FSBlend.ProjectionBlendTime = ProjectionBlendTime;

		FSBlend.TargetCamera = FSBlend.FullscreenPlayer.CurrentlyUsedCamera;

		FSBlend.BlendType = UCameraUserComponent::Get(FSBlend.FullscreenPlayer).ActiveCameraBlendType;
		FSBlend.DefaultBlendType = Cast<UCameraDefaultBlend>(FSBlend.BlendType);
		if (FSBlend.BlendType != nullptr)
		{
			FSBlend.FullscreenPlayer.OtherPlayer.ActivateCameraCustomBlend(
				FSBlend.TargetCamera, FSBlend.BlendType,
				CameraBlendTime, this, EHazeCameraPriority::MAX);
		}
		else
		{
			FSBlend.FullscreenPlayer.OtherPlayer.ActivateCamera(
				FSBlend.TargetCamera,
				CameraBlendTime, this, EHazeCameraPriority::MAX);
		}

		FSBlend.bAppliedCamera = true;

		if (FSBlend.DefaultBlendType != nullptr && !HasAnyOffset())
		{
			FSBlend.bUseCameraBlendForOffset = true;
		}
		else
		{
			ApplyOffsetAlpha(1.0, ProjectionBlendTime);
			FSBlend.bUseCameraBlendForOffset = false;
		}

		SceneView::SetSplitShareEyeAdaptation(true);
	}

	UFUNCTION(BlueprintOverride)
	void BlendToSplitScreenUsingProjectionOffset(UObject ViewSizeInstigatorToClear, float BlendTime)
	{
		if (SplitBlend.bActive)
			StopBlendingToSplitScreen();
		if (FSBlend.bActive)
			StopBlendingToFullScreen();

		SplitBlend = FCameraBlendToSplitScreenData();
		SplitBlend.bActive = true;
		SplitBlend.bSplitFadedIn = false;
		SplitBlend.TimeSinceStart = 0.0;
		SplitBlend.BlendDuration = Math::Max(BlendTime, SPLIT_FADE_IN_TIME);
		SplitBlend.PendingViewSizeInstigator = ViewSizeInstigatorToClear;

		SplitBlend.FullscreenPlayer = SceneView::FullScreenPlayer;
		ApplySplitBlendCamera();
	}

	bool IsBlendingToFullScreen() const
	{
		return FSBlend.bActive;
	}

	bool IsBlendingToSplitScreen() const
	{
		return SplitBlend.bActive;
	}

	bool HasProjectionBlend() const
	{
		return SplitBlend.bActive || FSBlend.bActive;
	}

	UFUNCTION(BlueprintOverride)
	void ResetStateBetweenLevels()
	{
		if (FSBlend.bActive)
			StopBlendingToFullScreen();
		if (SplitBlend.bActive)
			StopBlendingToSplitScreen();
	}

	bool HasAnyOffset()
	{
		for (auto Player : Game::Players)
		{
			auto CameraViewPoint = Cast<UHazeCameraViewPoint>(Player.GetViewPoint());
			if (!CameraViewPoint.BlendedOffCenterProjectionOffset.Value.IsNearlyZero(0.05))
				return true;
		}

		return false;
	}

	void ApplyOffsetAlpha(float Alpha, float BlendTime)
	{
		for (auto Player : Game::Players)
		{
			FVector2D BaseOffset;
			if (Player.IsMio())
				BaseOffset = FVector2D(-1, 0);
			else
				BaseOffset = FVector2D(1, 0);

			auto CameraViewPoint = Cast<UHazeCameraViewPoint>(Player.GetViewPoint());
			if (CameraViewPoint != nullptr)
			{
				if (Alpha == 0)
					CameraViewPoint.ClearOffCenterProjectionOffset(this, BlendTime);
				else
					CameraViewPoint.ApplyOffCenterProjectionOffset(BaseOffset * Alpha, this, EInstigatePriority::Cutscene, BlendTime);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float UndilatedDeltaTime = Time::GetCameraDeltaSeconds();
		UpdateSplitBlend(UndilatedDeltaTime);
		UpdateFullScreenBlend(UndilatedDeltaTime);
	}

	void ApplySplitBlendCamera()
	{
		if (!SplitBlend.bAppliedCamera)
		{
			if (SplitBlend.FullscreenPlayer != nullptr)
			{
				if (!IsValid(DummyCamera))
				{
					DummyCamera = AStaticCameraActor::Spawn();
					DummyCamera.Camera.AddTag(n"AllowSyncStaticCameraRotation");
				}

				DummyCamera.SetActorLocationAndRotation(SplitBlend.FullscreenPlayer.ViewLocation, SplitBlend.FullscreenPlayer.ViewRotation);
				float FieldOfView = SplitBlend.FullscreenPlayer.ViewFOV;

				SplitBlend.bAppliedCamera = true;
				SplitBlend.ViewVelocity = SplitBlend.FullscreenPlayer.ViewVelocity;

				UHazeCameraComponent CurrentCamera = SplitBlend.FullscreenPlayer.CurrentlyUsedCamera;
				if (CurrentCamera.Owner.IsA(AStaticCameraActor))
					SplitBlend.ViewCamera = Cast<AStaticCameraActor>(CurrentCamera.Owner);

				for (auto Player : Game::Players)
				{
					Player.ActivateCamera(DummyCamera, 0.0, this, EHazeCameraPriority::MAX);

					auto CamSettings = UCameraSettings::GetSettings(Player);
					CamSettings.FOV.Apply(FieldOfView, this, 0.0, EHazeCameraPriority::MAX);
				}

			}
		}
	}

	void UpdateSplitBlend(float DeltaTime)
	{
		if (SplitBlend.bActive)
		{
			float Time = SplitBlend.TimeSinceStart;
			SplitBlend.TimeSinceStart += DeltaTime;

			if (IsValid(DummyCamera))
			{
				if (IsValid(SplitBlend.ViewCamera))
					DummyCamera.SetActorLocationAndRotation(SplitBlend.ViewCamera.Camera.WorldLocation, SplitBlend.ViewCamera.Camera.WorldRotation);
				else
					DummyCamera.ActorLocation += SplitBlend.ViewVelocity * DeltaTime;
			}

			if (Time < SPLIT_FADE_IN_TIME)
			{
				SceneView::SetSplitDividerOpacity(Time / SPLIT_FADE_IN_TIME);
				ApplySplitBlendCamera();
			}
			else
			{
				SceneView::SetSplitDividerOpacity(-1.0);

				if (SplitBlend.bAppliedCamera)
				{
					if (IsValid(SplitBlend.FullscreenPlayer))
					{
						for (auto Player : Game::Players)
						{
							float RemainingBlendTime = SplitBlend.BlendDuration - SPLIT_FADE_IN_TIME;
							Player.DeactivateCameraByInstigator(this, RemainingBlendTime);

							auto CamSettings = UCameraSettings::GetSettings(Player);
							CamSettings.FOV.Clear(this, RemainingBlendTime);
						}
					}
					SplitBlend.bAppliedCamera = false;
				}

				if (Time >= SplitBlend.BlendDuration)
				{
					SplitBlend.bActive = false;
					SceneView::SetVignetteFullScreenBlend(0.0);
				}
				else
				{
					SceneView::SetVignetteFullScreenBlend(1.0 - Time / SplitBlend.BlendDuration);
				}

				if (!SplitBlend.bSplitFadedIn)
				{
					SplitBlend.bSplitFadedIn = true;
					for (auto Player : Game::Players)
						Player.ClearViewSizeOverride(SplitBlend.PendingViewSizeInstigator, EHazeViewPointBlendSpeed::Instant);

					ApplyOffsetAlpha(1.0, 0.0);
					ApplyOffsetAlpha(0.0, SplitBlend.BlendDuration - SPLIT_FADE_IN_TIME);
				}
			}
		}
	}

	void StopBlendingToSplitScreen()
	{
		SplitBlend.bActive = false;
		ApplyOffsetAlpha(0.0, 0.0);
		SceneView::SetSplitDividerOpacity(-1.0);
		SceneView::SetVignetteFullScreenBlend(0.0);

		if (SplitBlend.bAppliedCamera)
		{
			for (auto Player : Game::Players)
			{
				Player.DeactivateCameraByInstigator(this, 0.0);

				auto CamSettings = UCameraSettings::GetSettings(Player);
				CamSettings.FOV.Clear(this, 0.0);
			}
			SplitBlend.bAppliedCamera = false;
		}
	}

	void UpdateFullScreenBlend(float DeltaTime)
	{
		if (FSBlend.bActive)
		{
			float Time = FSBlend.TimeSinceStart;
			FSBlend.TimeSinceStart += DeltaTime;

			if (Time >= FSBlend.TotalBlendDuration)
			{
				if (!FSBlend.bAppliedViewSize)
				{
					if (IsValid(FSBlend.FullscreenPlayer))
						FSBlend.FullscreenPlayer.ApplyViewSizeOverride(FSBlend.PendingViewSizeInstigator, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant, EHazeViewPointPriority::High);

					for (auto Player : Game::Players)
						UCameraUserComponent::Get(Player).TriggerCameraCutThisFrame();

					ApplyOffsetAlpha(0.0, 0.0);
					SceneView::SetVignetteFullScreenBlend(0.0);
					FSBlend.bAppliedViewSize = true;
				}

				if (FSBlend.bAppliedCamera)
				{
					if (IsValid(FSBlend.FullscreenPlayer))
						FSBlend.FullscreenPlayer.OtherPlayer.DeactivateCameraByInstigator(this, 0.0);
					FSBlend.bAppliedCamera = false;
				}

				if (Time >= FSBlend.TotalBlendDuration + SPLIT_FADE_OUT_TIME)
				{
					FSBlend.bActive = false;
					SceneView::SetSplitDividerOpacity(-1.0);
					SceneView::SetSplitShareEyeAdaptation(false);
				}
				else
				{
					SceneView::SetSplitDividerOpacity(1.0 - (Time - FSBlend.TotalBlendDuration) / SPLIT_FADE_OUT_TIME);
				}
			}
			else
			{
				SceneView::SetVignetteFullScreenBlend(Time / FSBlend.TotalBlendDuration);

				if (FSBlend.FullscreenPlayer.CurrentlyUsedCamera != FSBlend.TargetCamera)
				{
					FSBlend.TargetCamera = FSBlend.FullscreenPlayer.CurrentlyUsedCamera;
					FSBlend.FullscreenPlayer.OtherPlayer.DeactivateCameraByInstigator(this, 0.0);

					float CameraBlendTime = FSBlend.CameraBlendDuration - Time;
					FSBlend.BlendType = UCameraUserComponent::Get(FSBlend.FullscreenPlayer).ActiveCameraBlendType;
					FSBlend.DefaultBlendType = Cast<UCameraDefaultBlend>(FSBlend.BlendType);
					if (FSBlend.BlendType != nullptr)
					{
						FSBlend.FullscreenPlayer.OtherPlayer.ActivateCameraCustomBlend(
							FSBlend.TargetCamera, FSBlend.BlendType,
							CameraBlendTime, this, EHazeCameraPriority::MAX);
					}
					else
					{
						FSBlend.FullscreenPlayer.OtherPlayer.ActivateCamera(
							FSBlend.TargetCamera,
							CameraBlendTime, this, EHazeCameraPriority::MAX);
					}

					if (FSBlend.DefaultBlendType != nullptr && !HasAnyOffset())
					{
						FSBlend.bUseCameraBlendForOffset = true;
					}
					else
					{
						ApplyOffsetAlpha(1.0, FSBlend.ProjectionBlendTime - Time);
						FSBlend.bUseCameraBlendForOffset = false;
					}
				}

				if (FSBlend.bUseCameraBlendForOffset)
				{
					FHazeCameraViewPointBlendInfo BlendInfo;
					BlendInfo.BlendAlpha = UCameraUserComponent::Get(FSBlend.FullscreenPlayer).ActiveCameraBlendAlpha;
					BlendInfo.AcceleratedBlendAlpha = UCameraUserComponent::Get(FSBlend.FullscreenPlayer).ActiveCameraAcceleratedBlendAlpha;
					ApplyOffsetAlpha(
						CameraBlend::GetBlendAlpha(
							FSBlend.DefaultBlendType.AlphaType,
							BlendInfo,
							FSBlend.DefaultBlendType.BlendCurve,
							FSBlend.DefaultBlendType.Exponential,
						), 0.0
					);
				}
			}
		}
	}

	void StopBlendingToFullScreen()
	{
		FSBlend.bActive = false;
		ApplyOffsetAlpha(0.0, 0.0);
		SceneView::SetSplitDividerOpacity(-1.0);
		SceneView::SetSplitShareEyeAdaptation(false);
		SceneView::SetVignetteFullScreenBlend(0.0);

		if (!FSBlend.bAppliedViewSize)
		{
			if (IsValid(FSBlend.FullscreenPlayer))
				FSBlend.FullscreenPlayer.ApplyViewSizeOverride(FSBlend.PendingViewSizeInstigator, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant, EHazeViewPointPriority::High);
			FSBlend.bAppliedViewSize = true;
		}

		if (FSBlend.bAppliedCamera)
		{
			if (IsValid(FSBlend.FullscreenPlayer))
			{
				FSBlend.FullscreenPlayer.OtherPlayer.DeactivateCameraByInstigator(this, 0.0);
			}
			FSBlend.bAppliedCamera = false;
		}
	}
}