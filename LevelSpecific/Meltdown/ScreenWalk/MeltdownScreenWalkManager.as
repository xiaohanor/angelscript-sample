class AMeltdownScreenWalkManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	default PrimaryActorTick.TickGroup = ETickingGroup::TG_LastDemotable;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	USceneCaptureComponent2D SceneCapture;
	default SceneCapture.bAutoActivate = false;

	UPROPERTY(EditInstanceOnly)
	AActor SceneDisplayActor;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> JumpLandCameraShake;

	TPerPlayer<FHazeComputedView> PlayerViews;
	UTextureRenderTarget2D RenderTarget;
	bool bManagerActive = false;

	FVector SceneDisplayActorTarget;

	TArray<UMeltdownScreenWalkResponseComponent> ResponseComponents;
	UPROPERTY(EditAnywhere)
	AMeltdownScreenWalkDisplayPlane DisplayPlane;

	bool bScreenWalkRayActive = false;
	bool bPlayerIsStomping = false;
	FVector ScreenWalkRayOrigin;
	FVector ScreenWalkRayDirection;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SceneDisplayActor.AddActorDisable(this);
		SceneDisplayActorTarget = SceneDisplayActor.ActorLocation;

		ActivateMeltdownSeethrough();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		DeactivateMeltdownSeethrough();
	}

	UFUNCTION()
	void ActivateMeltdownSeethrough()
	{
		Game::Mio.ClearGameplayPerspectiveMode(this);
		if (bManagerActive)
			return;

		bManagerActive = true;
		for (auto Player : Game::Players)
		{
			Player.ApplyOtherPlayerIndicatorMode(EOtherPlayerIndicatorMode::Hidden, this);
		}
		Game::Zoe.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);
		Game::Zoe.ApplyGameplayPerspectiveMode(EPlayerMovementPerspectiveMode::TopDown, this);
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

		UHazeViewPoint ZoeViewPoint = Game::Zoe.GetViewPoint();
		ZoeViewPoint.ApplyAntiAliasingOverride(this, EAntiAliasingMethod::AAM_FXAA);

		SceneCapture.TextureTarget = RenderTarget;
		SceneCapture.Activate();
	}

	UFUNCTION()
	void DeactivateMeltdownSeethrough()
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
		}

		AHazePlayerCharacter OutsidePlayer = Game::Zoe;
		UPlayerMovementComponent MoveComp = UPlayerMovementComponent::Get(OutsidePlayer);
		if (MoveComp.IsOnWalkableGround())
		{
			bScreenWalkRayActive = ProjectSeethrough_OutsideToInside(OutsidePlayer.ActorLocation, ScreenWalkRayOrigin, ScreenWalkRayDirection);
		}
		else
		{
			bScreenWalkRayActive = false;
		}

		Cast<AMeltdownScreenWalkDisplayPlane>(SceneDisplayActor).Suck(OutsidePlayer.GetActorLocation(), bPlayerIsStomping);
	}

	void StompEffects()
	{
		AHazePlayerCharacter OutsidePlayer = Game::Zoe;
		OutsidePlayer.OtherPlayer.PlayCameraShake(JumpLandCameraShake, this);
		
		if(SceneDisplayActor != nullptr)
			Cast<AMeltdownScreenWalkDisplayPlane>(SceneDisplayActor).Ripple(OutsidePlayer.GetActorLocation());
		
		FHazeCameraImpulse CamImpulse;
		CamImpulse.CameraSpaceImpulse = FVector(0.0, 0.0, 200.0);
		CamImpulse.ExpirationForce = 15.5;
		CamImpulse.Dampening = 0.8;
		OutsidePlayer.OtherPlayer.ApplyCameraImpulse(CamImpulse, this);

		DisplayPlane.Stomp();
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

	bool ProjectSeethrough_InsideToScreenPosition(FVector InsidePosition, bool bLockToPlayerPlane, FVector2D& OutOutsidePosition)
	{
		auto Player = Game::Mio;

		FVector2D ViewUV;
		bool bInFrontOfScreen = PlayerViews[Player].ProjectWorldToViewUV(
			InsidePosition, ViewUV
		);

		// We want the screenposition even if outside of view
		if (!bInFrontOfScreen) //|| ViewUV.X < 0.0 || ViewUV.X > 1.0 || ViewUV.Y < 0.0 || ViewUV.Y > 1.0)
			return false;

		OutOutsidePosition = ViewUV;

		return true;
	}
};

namespace AMeltdownScreenWalkManager
{
	AMeltdownScreenWalkManager Get()
	{
		return TListedActors<AMeltdownScreenWalkManager>().GetSingle();
	}
}