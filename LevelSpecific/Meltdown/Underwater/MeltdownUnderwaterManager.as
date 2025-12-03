class AMeltdownUnderwaterManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	default PrimaryActorTick.TickGroup = ETickingGroup::TG_LastDemotable;

	UPROPERTY(DefaultComponent)
	USceneCaptureComponent2D SceneCapture;
	default SceneCapture.bAutoActivate = false;

	UPROPERTY(EditInstanceOnly)
	AActor SceneDisplayActor;

	TPerPlayer<FHazeComputedView> PlayerViews;
	UTextureRenderTarget2D RenderTarget;
	bool bManagerActive = false;

	FVector SceneDisplayActorTarget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SceneDisplayActor.AddActorDisable(this);
		SceneDisplayActorTarget = SceneDisplayActor.ActorLocation;
		SceneDisplayActor.SetActorLocation(SceneDisplayActorTarget - FVector(0.0, 0.0, 500.0));
	}

	 UFUNCTION(BlueprintOverride)
	 void EndPlay(EEndPlayReason EndPlayReason)
	 {
		 DeactivateMeltdownUnderwater();
	 }

	UFUNCTION()
	void ActivateMeltdownUnderwater()
	{
		if (bManagerActive)
			return;

		bManagerActive = true;
		Game::Zoe.ApplyGameplayPerspectiveMode(EPlayerMovementPerspectiveMode::SideScroller, this);

		for (auto Player : Game::Players)
		{
			Player.ApplyOtherPlayerIndicatorMode(EOtherPlayerIndicatorMode::Hidden, this);
		}
	}

	UFUNCTION()
	void StartTopdownSection()
	{
		Game::Mio.ApplyGameplayPerspectiveMode(EPlayerMovementPerspectiveMode::TopDown, this);
		Game::Zoe.ApplyViewSizeOverride(this, EHazeViewPointSize::Small, EHazeViewPointBlendSpeed::Instant);
		SceneView::SetSplitScreenMode(EHazeSplitScreenMode::Vertical);
	}

	UFUNCTION()
	void StartSeethroughSection()
	{
		Game::Mio.ClearGameplayPerspectiveMode(this);
		Game::Zoe.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Normal);
		SceneView::SetSplitScreenMode(EHazeSplitScreenMode::Vertical);

		if (RenderTarget == nullptr)
		{
			FVector2D Resolution = SceneView::GetFullViewportResolution();
			Resolution.Y = Math::CeilToFloat(Resolution.X / 16.0 * 9.0);

			RenderTarget = Rendering::CreateRenderTarget2D(
				Math::Max(10, int(Resolution.X)),
				Math::Max(10, int(Resolution.Y)),
				ETextureRenderTargetFormat::RTF_RGB10A2
			);
		}

		SceneDisplayActor.RemoveActorDisable(this);

		TArray<UMeshComponent> Meshes;
		SceneDisplayActor.GetComponentsByClass(Meshes);

		for (auto MeshComp : Meshes)
		{
			auto Material = MeshComp.CreateDynamicMaterialInstance(0);
			Material.SetTextureParameterValue(n"TiltSceneTexture", RenderTarget);
		}

		auto MioCameraUser = UCameraUserComponent::Get(Game::Mio);
		MioCameraUser.ControlCameraWithoutScreenSizeAllower.Add(this);

		SceneCapture.TextureTarget = RenderTarget;
		SceneCapture.Activate();
	}

	UFUNCTION()
	void StartVerticalSection()
	{
		Game::Mio.ClearGameplayPerspectiveMode(this);
		SceneView::SetSplitScreenMode(EHazeSplitScreenMode::ManualViews);

		TArray<FHazeManualView> ActiveViews;

		// Mio's view
		{
			FHazeManualView View;
			View.TopLeft.X = 0.0;
			View.TopLeft.Y = 0.2;
			View.BottomRight.X = 1.0;
			View.BottomRight.Y = 1.0;
			ActiveViews.Add(View);
		}

		// Zoe's view
		{
			FHazeManualView View;
			View.TopLeft.X = 0.0;
			View.TopLeft.Y = 0.0;
			View.BottomRight.X = 1.0;
			View.BottomRight.Y = 0.2;
			ActiveViews.Add(View);
		}

		SceneView::SetManualViews(ActiveViews);
	}

	UFUNCTION()
	void DeactivateMeltdownUnderwater()
	{
		if (!bManagerActive)
			return;

		bManagerActive = false;
		Game::Zoe.ClearViewSizeOverride(this);
		Game::Zoe.ClearGameplayPerspectiveMode(this);
		Game::Mio.ClearGameplayPerspectiveMode(this);
		SceneView::SetSplitScreenMode(EHazeSplitScreenMode::Vertical);

		for (auto Player : Game::Players)
		{
			Player.ClearOtherPlayerIndicatorMode(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bManagerActive)
			return;

		if (RenderTarget != nullptr)
		{
			FVector2D Resolution = SceneView::GetFullViewportResolution();
			Resolution.Y = Math::CeilToFloat(Resolution.X / 16.0 * 9.0);
			Resolution = FVector2D(1920.0, 1080.0);
			
			if (Game::IsPlatformSage())
			{
				const float ScreenPercentage = Console::GetConsoleVariableFloat("r.screenpercentage");
				Resolution.X = Math::CeilToFloat(Resolution.X * ScreenPercentage / 100.0);
				Resolution.Y = Math::CeilToFloat(Resolution.Y * ScreenPercentage / 100.0);
			}

			Rendering::ResizeRenderTarget(RenderTarget, int(Resolution.X), int(Resolution.Y));
		}

		// Calculate the actual view matrices for the players
		for (auto Player : Game::Players)
		{
			auto ViewPoint = Player.GetViewPoint();

			FHazeViewParameters ViewParams;
			ViewParams.Location = ViewPoint.ViewLocation;
			ViewParams.Rotation = ViewPoint.ViewRotation;
			ViewParams.FOV = ViewPoint.ViewFOV;
			PlayerViews[Player] = SceneView::ComputeView(ViewParams);
		}

		{
			auto ViewPoint = Game::Mio.GetViewPoint();
			SceneCapture.SetWorldLocationAndRotation(
				ViewPoint.ViewLocation,
				ViewPoint.ViewRotation
			);
			SceneCapture.FOVAngle = ViewPoint.ViewFOV;

			SceneCapture.bUseCustomProjectionMatrix = true;
			SceneCapture.CustomProjectionMatrix = PlayerViews[EHazePlayer::Mio].ProjectionMatrix;
		}

		if (!SceneDisplayActor.IsActorDisabled())
		{
			FVector Bobbing;
			Bobbing.Z = Math::Sin(Time::GameTimeSeconds * 0.991) * 10.0;
			Bobbing.Y = Math::Sin(Time::GameTimeSeconds * 0.417) * 20.0;

			SceneDisplayActor.ActorLocation = Math::VInterpConstantTo(
				SceneDisplayActor.ActorLocation,
				SceneDisplayActorTarget + Bobbing,
				DeltaSeconds,
				500.0
			);
		}
	}

	bool ProjectSeethrough_InsideToOutside(FVector InsidePosition, bool bLockToPlayerPlane, FVector& OutOutsidePosition)
	{
		auto Player = Game::Zoe;

		FVector2D ViewUV;
		bool bInFrontOfScreen = PlayerViews[Player.OtherPlayer].ProjectWorldToViewUV(
			InsidePosition, ViewUV
		);

		if (!bInFrontOfScreen || ViewUV.X < 0.0 || ViewUV.X > 1.0 || ViewUV.Y < 0.0 || ViewUV.Y > 1.0)
			return false;

		FTransform DisplayTransform = SceneDisplayActor.ActorTransform;

		auto DisplayBox = SceneDisplayActor.GetActorLocalBoundingBox(false);
		OutOutsidePosition = DisplayTransform.TransformPosition(
			FVector(
				0.0,
				((ViewUV.X - 0.5) * 2.0) * DisplayBox.Extent.Y,
				((ViewUV.Y - 0.5) * 2.0) * -DisplayBox.Extent.Z,
			)
		);

		if (bLockToPlayerPlane)
		{
			FVector2D OutsideViewUV;
			PlayerViews[Player].ProjectWorldToViewUV(
				OutOutsidePosition, OutsideViewUV
			);

			FVector OutsideOrigin;
			FVector OutsideDirection;
			PlayerViews[Player].DeprojectViewUVToWorld(
				OutsideViewUV, OutsideOrigin, OutsideDirection
			);

			OutOutsidePosition = Math::LinePlaneIntersection(
				OutsideOrigin, OutsideOrigin + OutsideDirection,
				Player.ActorLocation, Player.ViewRotation.ForwardVector
			);

			FVector2D FinalViewUV;
			PlayerViews[Player].ProjectWorldToViewUV(
				OutOutsidePosition, FinalViewUV
			);
		}

		return true;
	}

	bool ProjectSeethrough_OutsideToInside(FVector OutsidePosition, FVector& OutOrigin, FVector& OutDirection)
	{
		auto Player = Game::Zoe;

		FTransform DisplayTransform = SceneDisplayActor.ActorTransform;
		FVector RelativePos = DisplayTransform.InverseTransformPosition(OutsidePosition);

		auto DisplayBox = SceneDisplayActor.GetActorLocalBoundingBox(false);
		
		FVector2D ViewUV;
		ViewUV.X = (RelativePos.Y / DisplayBox.Extent.Y) * 0.5 + 0.5;
		ViewUV.Y = (-RelativePos.Z / DisplayBox.Extent.Z) * 0.5 + 0.5;

		return PlayerViews[Player.OtherPlayer].DeprojectViewUVToWorld(
			ViewUV, OutOrigin, OutDirection
		);
	}

	bool ProjectSeethrough_InsideToOutside_LockToPlane(FVector InsidePosition, FVector LockLocation, FVector& OutOutsidePosition)
	{
		auto Player = Game::Zoe;

		FVector2D ViewUV;
		bool bInFrontOfScreen = PlayerViews[Player.OtherPlayer].ProjectWorldToViewUV(
			InsidePosition, ViewUV
		);

		if (!bInFrontOfScreen || ViewUV.X < 0.0 || ViewUV.X > 1.0 || ViewUV.Y < 0.0 || ViewUV.Y > 1.0)
			return false;

		FTransform DisplayTransform = SceneDisplayActor.ActorTransform;

		auto DisplayBox = SceneDisplayActor.GetActorLocalBoundingBox(false);
		OutOutsidePosition = DisplayTransform.TransformPosition(
			FVector(
				0.0,
				((ViewUV.X - 0.5) * 2.0) * DisplayBox.Extent.Y,
				((ViewUV.Y - 0.5) * 2.0) * -DisplayBox.Extent.Z,
			)
		);

		{
			FVector2D OutsideViewUV;
			PlayerViews[Player].ProjectWorldToViewUV(
				OutOutsidePosition, OutsideViewUV
			);

			FVector OutsideOrigin;
			FVector OutsideDirection;
			PlayerViews[Player].DeprojectViewUVToWorld(
				OutsideViewUV, OutsideOrigin, OutsideDirection
			);

			OutOutsidePosition = Math::LinePlaneIntersection(
				OutsideOrigin, OutsideOrigin + OutsideDirection,
				LockLocation, Player.ViewRotation.ForwardVector
			);

			FVector2D FinalViewUV;
			PlayerViews[Player].ProjectWorldToViewUV(
				OutOutsidePosition, FinalViewUV
			);
		}

		return true;
	}
};