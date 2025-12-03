UCLASS(HideCategories = "Debug Activation Collision Cooking Rendering Actor Tags")
class ASoftSplitManager : ACustomMergeSplitManager
{
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostUpdateWork;
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY()
	TPerPlayer<UPlayerHighlightSettings> HighlightSettings;

	UPROPERTY(EditInstanceOnly, Category = "Splits")
	TMap<TSoftObjectPtr<UWorld>, EHazePlayer> LevelToPlayerMap;

	UPROPERTY(EditAnywhere, Category = "Splits")
	FVector SoftSplitOffset(200000, 0.0, 0.0);

	UPROPERTY()
	TSubclassOf<USoftSplitFakeLetterbox> FakeLetterboxWidgetClass;

	bool bSoftSplitActive = false;
	bool bHasPlayerPositions = false;
	AStaticCameraActor MioCam;

	bool bIntroCutsceneActive = false;
	bool bFakeLetterboxActive = false;
	bool bBlendOutIntroCutscene = false;
	float IntroCutsceneBlendTime = 0.0;
	USoftSplitFakeLetterbox FakeLetterbox;

	float WobbleIntensity = 1.0;

	TPerPlayer<ASoftSplitPlayerCopy> PlayerCopies;
	TPerPlayer<FHazeAcceleratedVector> PlayerAcceleratedPosition;
	TPerPlayer<bool> PlayerHasTeleported;

	FVector2D CenterInScreenSpace;
	FVector2D DirectionInScreenSpace;
	FQuat ScreenDirectionRotation;

	UFUNCTION(BlueprintPure) const
	FVector2D GetSoftSplitLineDirection()
	{
		return FVector2D(ScreenDirectionRotation.ForwardVector.X, ScreenDirectionRotation.ForwardVector.Y); 
	}

	void GetWorldSplitPlane(EHazeWorldLinkLevel TargetSplit, FVector& OutPlaneOrigin, FVector& OutPlaneNormal)
	{
		FVector CenterOrigin;
		FVector CenterDirection;

		SceneView::DeprojectScreenToWorld_Relative(
			Game::Zoe, CenterInScreenSpace,
			CenterOrigin, CenterDirection,
		);

		FVector DirOrigin;
		FVector DirDirection;

		FVector2D OffsetPos;
		FVector ScreenForward = ScreenDirectionRotation.ForwardVector;

		SceneView::DeprojectScreenToWorld_Relative(
			Game::Zoe, CenterInScreenSpace + FVector2D(ScreenForward.Y * 0.1, -ScreenForward.X * 0.1),
			DirOrigin, DirDirection,
		);

		OutPlaneOrigin = CenterOrigin;
		OutPlaneNormal = FQuat::MakeFromYZ((DirOrigin - CenterOrigin), CenterDirection).ForwardVector;

		OutPlaneOrigin += CenterDirection * 1000.0;
		OutPlaneOrigin = Position_Convert(OutPlaneOrigin, EHazeWorldLinkLevel::Fantasy, TargetSplit);
	}

	FVector Position_FantasyToScifi(FVector Vector) const
	{
		return Vector + SoftSplitOffset;
	}

	FVector Position_ScifiToFantasy(FVector Vector) const
	{
		return Vector - SoftSplitOffset;
	}

	FVector Position_Convert(FVector Position, EHazeWorldLinkLevel SourceSplit, EHazeWorldLinkLevel TargetSplit)
	{
		FVector Result = Position;
		if (SourceSplit == EHazeWorldLinkLevel::SciFi)
			Result -= SoftSplitOffset;
		if (TargetSplit == EHazeWorldLinkLevel::SciFi)
			Result += SoftSplitOffset;
		return Result;
	}

	AHazePlayerCharacter GetPlayerForSplit(EHazeWorldLinkLevel Split)
	{
		if (Split == EHazeWorldLinkLevel::SciFi)
			return Game::Mio;
		else
			return Game::Zoe;
	}

	EHazeWorldLinkLevel GetSplitAssociatedWithAbsoluteLocation(FVector Location)
	{
		if (Location.Distance(SoftSplitOffset) < Location.Size())
			return EHazeWorldLinkLevel::SciFi;
		else
			return EHazeWorldLinkLevel::Fantasy;
	}

	AHazePlayerCharacter GetClosestPlayerTo(FVector Position, EHazeWorldLinkLevel PositionSplit, EHazeSelectPlayer AllowPlayers = EHazeSelectPlayer::Both)
	{
		float ClosestDist = MAX_flt;
		AHazePlayerCharacter Target = nullptr;
		for (int i = 0; i < 2; ++i)
		{
			EHazeWorldLinkLevel Split = EHazeWorldLinkLevel(i+1);

			AHazePlayerCharacter Player = GetPlayerForSplit(Split);
			if (Player.IsPlayerDead())
				continue;
			if (!Player.IsSelectedBy(AllowPlayers))
				continue;

			FVector PlayerLocation = Position_Convert(Player.ActorLocation, Split, PositionSplit);
			float Dist = PlayerLocation.Distance(Position);
			if (Dist < ClosestDist)
			{
				ClosestDist = Dist;
				Target = Player;
			}
		}

		return Target;
	}

	EHazeWorldLinkLevel GetSplitForLocation(FVector Location)
	{
		if (Location.Distance(SoftSplitOffset) < Location.Size())
			return EHazeWorldLinkLevel::SciFi;
		else
			return EHazeWorldLinkLevel::Fantasy;
	}

	EHazeWorldLinkLevel GetSplitForPlayer(AHazePlayerCharacter Player)
	{
		if (Player.IsMio())
			return EHazeWorldLinkLevel::SciFi;
		else
			return EHazeWorldLinkLevel::Fantasy;
	}

	EHazeWorldLinkLevel GetOtherSplit(EHazeWorldLinkLevel Split)
	{
		if (Split == EHazeWorldLinkLevel::Fantasy)
			return EHazeWorldLinkLevel::SciFi;
		else
			return EHazeWorldLinkLevel::Fantasy;
	}

	EHazeWorldLinkLevel GetVisibleSoftSplitAtLocation(FVector Position) const
	{
		FVector2D ScreenPos;
		if (Position.Distance(SoftSplitOffset) < Position.Size())
			SceneView::ProjectWorldToScreenPosition(Game::Mio, Position, ScreenPos);
		else
			SceneView::ProjectWorldToScreenPosition(Game::Zoe, Position, ScreenPos);

		FVector2D ScreenOffset = ScreenPos - CenterInScreenSpace;

		FVector SplitNormal = ScreenDirectionRotation.ForwardVector;
		if (ScreenOffset.DotProduct(FVector2D(SplitNormal.X, SplitNormal.Y)) < 0.0)
			return EHazeWorldLinkLevel::SciFi;
		else
			return EHazeWorldLinkLevel::Fantasy;
	}

	EHazeWorldLinkLevel GetVisibleSoftSplitAtLocationAndScreenPosition(FVector Position, FVector2D& ScreenPos) const
	{
		if (Position.Distance(SoftSplitOffset) < Position.Size())
			SceneView::ProjectWorldToScreenPosition(Game::Mio, Position, ScreenPos);
		else
			SceneView::ProjectWorldToScreenPosition(Game::Zoe, Position, ScreenPos);

		FVector2D ScreenOffset = ScreenPos - CenterInScreenSpace;
		
		FVector SplitNormal = ScreenDirectionRotation.ForwardVector;
		if (ScreenOffset.DotProduct(FVector2D(SplitNormal.X, SplitNormal.Y)) < 0.0)
			return EHazeWorldLinkLevel::SciFi;
		else
			return EHazeWorldLinkLevel::Fantasy;
	}

	UFUNCTION()
	void Editor_TriggerPlayFromHereHelper()
	{
		ActivateSoftSplit();
		for (auto Player : Game::Players)
		{
			auto Anchor = WorldLink::GetClosestAnchor(Player.ActorLocation);
			FVector TargetLocation = Position_Convert(Player.ActorLocation, Anchor.AnchorLevel, GetSplitForPlayer(Player));
			Player.SetActorLocation(TargetLocation);
			Player.SnapCameraBehindPlayer();
		}
	}

	UFUNCTION()
	void ActivateIntroCutscene()
	{
		bIntroCutsceneActive = true;
		FakeLetterbox = Widget::AddFullscreenWidget(FakeLetterboxWidgetClass, EHazeWidgetLayer::Overlay);
		bFakeLetterboxActive = true;
		ActivateCustomSplit();

		for (auto LevelElem : LevelToPlayerMap)
		{
			auto Player = Game::GetPlayer(LevelElem.Value);
			Player.OtherPlayer.SetLevelRenderedForPlayer(
				LevelElem.Key, false
			);
			Player.ApplyOtherPlayerIndicatorMode(EOtherPlayerIndicatorMode::Hidden, this);
		}
	}

	UFUNCTION()
	void BlendOutIntroCutscene()
	{
		bBlendOutIntroCutscene = true;
		IntroCutsceneBlendTime = 0.0;
	}

	UFUNCTION()
	void ActivateSoftSplit()
	{
		if (bSoftSplitActive)
			return;

		bSoftSplitActive = true;
		bFakeLetterboxActive = false;
		ActivateCustomSplit();

		SetActorTickEnabled(true);

		UpdateDiagonalSplit(0.0, !bIntroCutsceneActive);
		UPlayerSoftSplitComponent::GetOrCreate(Game::Mio).Manager = this;

		MioCam = AStaticCameraActor::Spawn();
		MioCam.SetActorLocationAndRotation(Position_FantasyToScifi(Game::Zoe.ViewLocation), Game::Zoe.ViewRotation);

		float CameraBlendTime = 0.0;
		if (bIntroCutsceneActive)
			CameraBlendTime = 4.0;
		Game::Mio.ActivateCamera(MioCam, CameraBlendTime, this, EHazeCameraPriority::High);

		bIntroCutsceneActive = false;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.ApplyOtherPlayerIndicatorMode(EOtherPlayerIndicatorMode::Hidden, this);
			Player.ApplySettings(HighlightSettings[Player], this);

			FCameraFrustumBoundarySettings BoundarySettings;
			BoundarySettings.MinimumDistanceFromFrustum = 100.0;
			Boundary::ApplyMovementConstrainToCameraFrustum(Player, BoundarySettings, this);

			PlayerAcceleratedPosition[Player].SnapTo(Player.ActorCenterLocation);

			auto ViewPoint = Cast<UHazeCameraViewPoint>(Player.GetViewPoint());
			ViewPoint.ClearOffCenterProjectionOffset(this, 2.0);
		}

		for (auto LevelElem : LevelToPlayerMap)
		{
			auto Player = Game::GetPlayer(LevelElem.Value);
			Player.OtherPlayer.SetLevelRenderedForPlayer(
				LevelElem.Key, false
			);
		}

		for (auto Player : Game::Players)
		{
			PlayerCopies[Player] = ASoftSplitPlayerCopy::Spawn();
			PlayerCopies[Player].Init(Player);
		}

		// SSS and SSR are extra expensive during soft split, because we are essentially rendering full screen twice
		// Since neither really do much of anything visually during this level, we turn them off
		auto RenderingSetings = Game::GetSingleton(URenderingSettingsSingleton);
		RenderingSetings.EnableScreenSpaceReflections.Apply(ERenderingSettingMode::NeedUltraShaderQuality, this);
		RenderingSetings.EnableSubsurfaceScattering.Apply(ERenderingSettingMode::Off, this);
	}

	UFUNCTION()
	void DeactivateSoftSplit()
	{
		if (!bSoftSplitActive)
			return;

		DeactivateCustomSplit();
		bSoftSplitActive = false;
		Game::Mio.DeactivateCamera(MioCam);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.ClearSettingsByInstigator(this);
			Player.ClearOtherPlayerIndicatorMode(this);
			Boundary::ClearMovementConstrainToCameraFrustum(Player, this);
		}

		auto MioCamSettings = UCameraSettings::GetSettings(Game::Mio);
		MioCamSettings.FOV.Clear(this);

		auto RenderingSetings = Game::GetSingleton(URenderingSettingsSingleton);
		RenderingSetings.EnableScreenSpaceReflections.Clear(this);
		RenderingSetings.EnableSubsurfaceScattering.Clear(this);
	}

	void UpdateIntroCutsceneSplit(float DeltaTime)
	{
		float BlendOutAlpha = 0.0;
		if (bBlendOutIntroCutscene)
		{
			IntroCutsceneBlendTime += DeltaTime;
			BlendOutAlpha = Math::Saturate(IntroCutsceneBlendTime * 0.35);
		}
		
		for (auto Player : Game::Players)
		{
			FVector2D Offset;
			if (Player.IsMio())
				Offset.X = 0.5;
			else
				Offset.X = -0.5;

			Offset *= 1.0 - BlendOutAlpha;

			auto ViewPoint = Cast<UHazeCameraViewPoint>(Player.GetViewPoint());
			ViewPoint.ApplyOffCenterProjectionOffset(Offset, this, EInstigatePriority::Normal, 0.0);

			PlayerAcceleratedPosition[Player].SnapTo(Player.ActorCenterLocation);
			bHasPlayerPositions = true;
		}

		float Angle = BlendOutAlpha * 90.0;
		FVector2D Direction = Math::AngleDegreesToDirection(Angle);
		SplitScreenInstance.SetVectorParameterValue(n"ScreenCenterPosition", FLinearColor(0.5, 0.5, 0, 0));
		SplitScreenInstance.SetVectorParameterValue(n"ScreenSplitDirection", FLinearColor(Direction.X, Direction.Y, 0, 0));

		WobbleIntensity = 0.0;
		SplitScreenInstance.SetScalarParameterValue(n"WobbleIntensity", 0.0);
		SplitScreenInstance.SetScalarParameterValue(n"BorderSize",
			Math::Lerp(2.0 / SceneView::FullViewportResolution.X, 0.0025, BlendOutAlpha));

		ScreenDirectionRotation = FQuat::MakeFromXZ(
			FVector(Direction.X, Direction.Y, 0.0),
			FVector::UpVector);
	}

	UFUNCTION()
	void BlendOutFakeLetterbox()
	{
		bFakeLetterboxActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);

		if (FakeLetterbox != nullptr && !bFakeLetterboxActive)
		{
			FakeLetterbox.Percentage = Math::FInterpConstantTo(FakeLetterbox.Percentage, 0.0, DeltaSeconds, 1.0);
			if (FakeLetterbox.Percentage <= 0.0)
			{
				Widget::RemoveFullscreenWidget(FakeLetterbox);
				FakeLetterbox = nullptr;
			}
		}

		if (bIntroCutsceneActive)
		{
			UpdateIntroCutsceneSplit(DeltaSeconds);
			return;
		}

		if (!bSoftSplitActive)
			return;

		UpdateDiagonalSplit(DeltaSeconds, false);

		auto ZoeCameraUser = UCameraUserComponent::Get(Game::Zoe);
		FHazeMinimalViewInfo ZoeView = ZoeCameraUser.GetCameraView(false, false, false);

		MioCam.SetActorLocationAndRotation(Position_FantasyToScifi(ZoeView.Location), ZoeView.Rotation);

		auto MioCamSettings = UCameraSettings::GetSettings(Game::Mio);
		MioCamSettings.FOV.Apply(Game::Zoe.ViewFOV, this, Priority = EHazeCameraPriority::High);

		// Fix the player positions (could be wrong after a debug teleport or something)
		for (auto Player : Game::Players)
		{
			EHazeWorldLinkLevel PlayerSplit = GetSplitForPlayer(Player);
			EHazeWorldLinkLevel PositionSplit = GetSplitAssociatedWithAbsoluteLocation(Player.ActorLocation);

			if (PlayerSplit != PositionSplit)
			{
				Player.SetActorLocation(
					Position_Convert(Player.ActorLocation, PositionSplit, PlayerSplit)
				);
				Player.SnapCameraAtEndOfFrame(FRotator(), EHazeCameraSnapType::BehindUser);
				Player.OtherPlayer.SnapCameraAtEndOfFrame(FRotator(), EHazeCameraSnapType::BehindUser);
			}
		}
	}

	void UpdateDiagonalSplit(float DeltaTime, bool bFirstUpdate)
	{
		for (auto Player : Game::Players)
		{
			UTeleportResponseComponent TeleportComp = UTeleportResponseComponent::GetOrCreate(Player);
			if ((TeleportComp.HasTeleportedSinceLastFrame() || PlayerHasTeleported[Player]) && bHasPlayerPositions)
			{
				PlayerHasTeleported[Player] = true;
				PlayerAcceleratedPosition[Player].AccelerateTo(Player.ActorCenterLocation, 1.0, DeltaTime);
				if (PlayerAcceleratedPosition[Player].Value.Distance(Player.ActorCenterLocation) < 1.0)
					PlayerHasTeleported[Player] = false;
			}
			else
			{
				PlayerAcceleratedPosition[Player].SnapTo(Player.ActorCenterLocation);
			}
		}

		FVector MioInZoeSpace = Position_ScifiToFantasy(PlayerAcceleratedPosition[Game::Mio].Value);

		FVector2D ZoeInScreenSpace;
		SceneView::ProjectWorldToViewpointRelativePosition(Game::Zoe, PlayerAcceleratedPosition[Game::Zoe].Value, ZoeInScreenSpace);

		FVector2D MioInScreenSpace;
		SceneView::ProjectWorldToViewpointRelativePosition(Game::Zoe, MioInZoeSpace, MioInScreenSpace);

		CenterInScreenSpace = (ZoeInScreenSpace + MioInScreenSpace) * 0.5;
		DirectionInScreenSpace = (ZoeInScreenSpace - CenterInScreenSpace).GetSafeNormal();

		FQuat WantedRotation = FQuat::MakeFromXZ(
			FVector(DirectionInScreenSpace.X, DirectionInScreenSpace.Y, 0.0),
			FVector::UpVector);

		if (bFirstUpdate || !bHasPlayerPositions)
			ScreenDirectionRotation = WantedRotation;
		else
			ScreenDirectionRotation = Math::QInterpConstantTo(ScreenDirectionRotation, WantedRotation, DeltaTime, PI);

		FVector2D LerpedDirection(
			ScreenDirectionRotation.ForwardVector.X,
			ScreenDirectionRotation.ForwardVector.Y,
		);

		SplitScreenInstance.SetVectorParameterValue(n"ScreenCenterPosition", FLinearColor(CenterInScreenSpace.X, CenterInScreenSpace.Y, 0.0, 0.0));
		SplitScreenInstance.SetVectorParameterValue(n"ScreenSplitDirection", FLinearColor(LerpedDirection.X, LerpedDirection.Y, 0.0, 0.0));

		if (WobbleIntensity < 1.0)
		{
			WobbleIntensity = Math::FInterpConstantTo(WobbleIntensity, 1.0, DeltaTime, 0.35);
			SplitScreenInstance.SetScalarParameterValue(n"WobbleIntensity", WobbleIntensity);
		}

		if (!bFirstUpdate)
			bHasPlayerPositions = true;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		DeactivateSoftSplit();
		Super::EndPlay(EndPlayReason);
	}
};

class UPlayerSoftSplitComponent : UActorComponent
{
	ASoftSplitManager Manager;
}

namespace ASoftSplitManager
{
	ASoftSplitManager GetSoftSplitManger()
	{
		return TListedActors<ASoftSplitManager>().GetSingle();
	}
}


class USoftSplitFakeLetterbox : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UWidget TopLetterbox;
	UPROPERTY(BindWidget)
	UWidget BottomLetterbox;

	float Percentage = 1.0;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		auto TopSlot = Cast<UCanvasPanelSlot>(TopLetterbox.Slot);	
		TopSlot.SetAnchors(FAnchors(0, 0, 1, 0.125 * Percentage));

		auto BottomSlot = Cast<UCanvasPanelSlot>(BottomLetterbox.Slot);	
		BottomSlot.SetAnchors(FAnchors(0, 1.0 - 0.125 * Percentage, 1, 1));
	}
}