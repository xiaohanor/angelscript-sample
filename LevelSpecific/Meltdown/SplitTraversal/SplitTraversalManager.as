struct FSplitTraversalPlayerData
{
	FHazeAcceleratedVector2D OffCenterProjectionOffset;
	FVector2D OffCenterProjectionTarget;
	float OffCenterBlendTime = 0.0;

	bool bIsDissolving = false;
	float DissolveDuration = 0.0;
	float DissolveTimer = 0.0;

	TPerPlayer<UNiagaraComponent> CrossingParticleEffects;
	TPerPlayer<UNiagaraComponent> PlayerCrossingEffects;
	bool bCrossingParticlesActive = false;
	float CrossingParticlesTriggerTime = 0;
}

UCLASS(HideCategories = "Debug Activation Collision Cooking Rendering Actor Tags")
class ASplitTraversalManager : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_LastDemotable;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerCapabilities.Add(n"SplitTraversalContextualMovesUICapability");

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComponent;

	UPROPERTY()
	UHazePlayerVariantAsset PlayerVariant_Scifi;
	UPROPERTY()
	UHazePlayerVariantAsset PlayerVariant_Fantasy;

	UPROPERTY()
	UHazePlayerVariantAsset PlayerVariant_Whitespace;

	UPROPERTY(EditInstanceOnly, Category = "Splits")
	TMap<TSoftObjectPtr<UWorld>, EHazePlayer> LevelToPlayerMap;

	UPROPERTY()
	TSubclassOf<ASplitTraversalPlayerCopy> PlayerCopyClass;

	UPROPERTY(Category = "Effect Line")
	TSubclassOf<UMeltdownEffectLineWidget> EffectLineWidget;
	UPROPERTY(Category = "Effect Line")
	UNiagaraSystem EffectLineParticles;
	UPROPERTY(Category = "Effect Line")
	float EffectLineParticleDepth = 100.0;

	UPROPERTY(Category = "Crossing Effect")
	FSoundDefReference MioSoundDef;
	UPROPERTY(Category = "Crossing Effect")
	FSoundDefReference ZoeSoundDef;
	UPROPERTY(Category = "Crossing Effect", Meta=(Units="ms"))
	float InFantasyOrScifiRtpcInterpolationInMs = 200;

	UPROPERTY()
	TSubclassOf<UMeshDissolveComponent> DissolveComponentClass;

	UPROPERTY()
	TSubclassOf<USplitTraversalCopySwimmingEffectsHandler> SlideSwimmingEffectHandler;

	UPROPERTY(Interp, EditAnywhere)
	float SplitPosition = 0.5;

	FVector SplitOffset(500000.0, 0.0, 0.0);

	bool bSplitSlideActive = false;
	bool bBothPlayersInScifiWorld = false;
	bool bSeparateWorldTraversalActive = false;
	bool bInitialSetupDone = false;

	TPerPlayer<ASplitTraversalPlayerCopy> PlayerCopies;
	TPerPlayer<FSplitTraversalPlayerData> PerPlayerData;

	FVector SplitPlaneOrigin;
	FVector SplitPlaneNormal;

	bool bSplitCameraActive = false;
	bool bSharedCameraActive = false;
	EHazeWorldLinkLevel SharedCameraBaseSplit;
	AStaticCameraActor DuplicatedCamera;
	UMeltdownEffectLineWidget LineWidget;
	TArray<UNiagaraComponent> LineParticles;

	FHazeAudioID Rtpc_Meltdown_SplitTraversal_InFantasy("Rtpc_Meltdown_SplitTraversal_InFantasy");
	FHazeAudioID Rtpc_Meltdown_SplitTraversal_InScifi("Rtpc_Meltdown_SplitTraversal_InScifi");

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		DeactivateManager();
	}

	FVector Position_FantasyToScifi(FVector Vector) const
	{
		return Vector + SplitOffset;
	}

	FVector Position_ScifiToFantasy(FVector Vector) const
	{
		return Vector - SplitOffset;
	}

	EHazeWorldLinkLevel GetOtherSplit(EHazeWorldLinkLevel Split) const
	{
		if (Split == EHazeWorldLinkLevel::SciFi)
			return EHazeWorldLinkLevel::Fantasy;
		else
			return EHazeWorldLinkLevel::SciFi;
	}

	FVector Position_Convert(FVector Position, EHazeWorldLinkLevel SourceSplit, EHazeWorldLinkLevel TargetSplit)
	{
		FVector Result = Position;
		if (SourceSplit == EHazeWorldLinkLevel::SciFi)
			Result -= SplitOffset;
		if (TargetSplit == EHazeWorldLinkLevel::SciFi)
			Result += SplitOffset;
		return Result;
	}

	FVector ConvertPositionBasedOnScreenSpaceForceDepth(FVector Position, EHazeWorldLinkLevel SourceSplit, EHazeWorldLinkLevel TargetSplit, float TargetDepth)
	{
		AHazePlayerCharacter SourcePlayer = GetPlayerForSplit(SourceSplit);
		AHazePlayerCharacter TargetPlayer = GetPlayerForSplit(TargetSplit);

		if (SourcePlayer == TargetPlayer)
			return Position;

		FVector2D ScreenLocation;
		SceneView::ProjectWorldToScreenPosition(
			SourcePlayer,
			Position,
			ScreenLocation,
		);

		FVector Origin;
		FVector Direction;
		SceneView::DeprojectScreenToWorldInView_Absolute(
			TargetPlayer,
			ScreenLocation, Origin, Direction
		);
		
		return Origin + Direction * TargetDepth;
	}

	FVector ConvertPositionBasedOnScreenSpaceMaintainDepth(FVector Position, EHazeWorldLinkLevel SourceSplit, EHazeWorldLinkLevel TargetSplit)
	{
		AHazePlayerCharacter SourcePlayer = GetPlayerForSplit(SourceSplit);
		AHazePlayerCharacter TargetPlayer = GetPlayerForSplit(TargetSplit);

		if (SourcePlayer == TargetPlayer)
			return Position;

		FVector2D ScreenLocation;
		SceneView::ProjectWorldToScreenPosition(
			SourcePlayer,
			Position,
			ScreenLocation,
		);

		float SourceDepth = SourcePlayer.ViewLocation.Distance(Position);

		FVector Origin;
		FVector Direction;
		SceneView::DeprojectScreenToWorldInView_Absolute(
			TargetPlayer,
			ScreenLocation, Origin, Direction
		);
		
		return Origin + Direction * SourceDepth;
	}

	AHazePlayerCharacter GetPlayerForSplit(EHazeWorldLinkLevel Split)
	{
		if (Split == EHazeWorldLinkLevel::SciFi)
			return Game::Mio;
		else
			return Game::Zoe;
	}

	AHazePlayerCharacter GetClosestPlayerTo(FVector Position, EHazeWorldLinkLevel PositionSplit)
	{
		float ClosestDist = MAX_flt;
		AHazePlayerCharacter Target = nullptr;
		for (int i = 0; i < 2; ++i)
		{
			EHazeWorldLinkLevel Split = EHazeWorldLinkLevel(i+1);

			AHazePlayerCharacter Player = GetPlayerForSplit(Split);
			if (Player.IsPlayerDead())
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

	EHazeWorldLinkLevel GetSplitForPlayer(AHazePlayerCharacter Player)
	{
		if (Player == nullptr || Player.IsMio())
			return EHazeWorldLinkLevel::SciFi;
		else
			return EHazeWorldLinkLevel::Fantasy;
	}

	EHazeWorldLinkLevel GetSplitForLocation(FVector Location)
	{
		if (Location.Distance(SplitOffset) < Location.Size())
			return EHazeWorldLinkLevel::SciFi;
		else
			return EHazeWorldLinkLevel::Fantasy;
	}

	EHazeWorldLinkLevel GetVisibleSplitForLocationOnScreen(FVector Location)
	{
		EHazeWorldLinkLevel SourceSplit = GetSplitForLocation(Location);
		AHazePlayerCharacter SourcePlayer = GetPlayerForSplit(SourceSplit);

		FVector2D ScreenLocation;
		SceneView::ProjectWorldToScreenPosition(
			SourcePlayer,
			Location,
			ScreenLocation,
		);

		AHazePlayerCharacter VisiblePlayer = SceneView::GetPlayerScreenAtScreenPosition(ScreenLocation);
		return GetSplitForPlayer(VisiblePlayer);
	}

	FName GetVisibleWorldAtLocation(FVector Location) const
	{
		FVector LocationInFantasy = Location;

		auto Anchor = WorldLink::GetClosestAnchor(Location);
		if (Anchor.AnchorLevel == EHazeWorldLinkLevel::SciFi)
			LocationInFantasy = Position_ScifiToFantasy(Location);

		float Direction = (LocationInFantasy - SplitPlaneOrigin).DotProduct(SplitPlaneNormal);
		if (Direction >= 0.0)
			return n"Fantasy";
		else
			return n"Scifi";
	}

	void InitialSetup()
	{
		if (bInitialSetupDone)
			return;
		bInitialSetupDone = true;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			auto IndicatorComp = UOtherPlayerIndicatorComponent::Get(Player);
			if (Player.IsMio())
				IndicatorComp.IndicatorWorldOffset.Apply(-SplitOffset, this);
			else
				IndicatorComp.IndicatorWorldOffset.Apply(SplitOffset, this);
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
			Player.ApplyPlayerVariantOverride(Player.IsMio() ? PlayerVariant_Scifi : PlayerVariant_Fantasy, this, EInstigatePriority::High);

			PlayerCopies[Player] = SpawnActor(PlayerCopyClass);
			PlayerCopies[Player].Init(Player);
			PlayerCopies[Player].SetPlayerVariant(Player.IsMio() ? PlayerVariant_Fantasy : PlayerVariant_Scifi);
		}
	}

	UFUNCTION()
	void Editor_TriggerPlayFromHereHelper()
	{
		ActivateSeparateWorldTraversal();
		for (auto Player : Game::Players)
		{
			auto Anchor = WorldLink::GetClosestAnchor(Player.ActorLocation);
			FVector TargetLocation = Position_Convert(Player.ActorLocation, Anchor.AnchorLevel, GetSplitForPlayer(Player));
			Player.SetActorLocation(TargetLocation);
			Player.SnapCameraBehindPlayer();
		}
	}

	UFUNCTION()
	void TeleportPlayerToOtherSide(AHazePlayerCharacter Player)
	{
		Player.SetActorLocation(
			Position_Convert(Player.ActorLocation, GetSplitForPlayer(Player), GetOtherSplit(GetSplitForPlayer(Player))));
		bBothPlayersInScifiWorld = true;

		for (auto CutPlayer : Game::Players)
			UCameraUserComponent::Get(CutPlayer).TriggerCameraCutThisFrame();
	}

	UFUNCTION()
	void ActivateSplitSlide()
	{
		if (bSplitSlideActive)
			return;

		if (!bInitialSetupDone)
			InitialSetup();

		if (DuplicatedCamera == nullptr)
			DuplicatedCamera = AStaticCameraActor::Spawn();

		bSplitSlideActive = true;
		bBothPlayersInScifiWorld = true;
		bSeparateWorldTraversalActive = false;
		SceneView::SetSplitScreenMode(EHazeSplitScreenMode::ManualViews);

		for (auto Player : Game::Players)
		{
			Player.RegisterEffectEventHandler(NewObject(Player, SlideSwimmingEffectHandler));
			Player.BlockCapabilities(PlayerSlideTags::SlideCamera, this);
			Player.BlockCapabilities(n"RespawnWaitingOverlay", this);
			Player.BlockCapabilities(n"HoverboardTrickScore", this);
			// Player.ApplyGameplayPerspectiveMode(EPlayerMovementPerspectiveMode::DisableAllCameraBehavior, this);

			Player.ApplyPlayerVariantOverride(PlayerVariant_Scifi, this, EInstigatePriority::High);
			PlayerCopies[Player].SetPlayerVariant(PlayerVariant_Fantasy);

			UPlayerHealthSettings::SetRespawnFadeInDuration(Player, 0.0, this);
			UPlayerHealthSettings::SetRespawnBlackScreenDuration(Player, 0.0, this);
			UPlayerHealthSettings::SetRespawnFadeOutDuration(Player, 0.0, this);

			auto IndicatorComp = UOtherPlayerIndicatorComponent::Get(Player);
			IndicatorComp.IndicatorWorldOffset.Clear(this);
			IndicatorComp.IndicatorMode.Apply(EOtherPlayerIndicatorMode::Hidden, this);

			//Hannes added this line of code
			UPlayerHealthComponent::Get(Player).OnStartDying.AddUFunction(this, n"HandlePlayerDeath");

			if (Player.IsZoe())
			{
				auto CamSettings = UCameraSettings::GetSettings(Player);
				CamSettings.WorldPivotOffset.Apply(Position_ScifiToFantasy(FVector()), this, 0, EHazeCameraPriority::High);

				Player.ActivateCamera(DuplicatedCamera, 0.0, this, EHazeCameraPriority::MAX);

				auto TargetablesComp = UPlayerTargetablesComponent::Get(Player);
				TargetablesComp.TargetingViewLocationOffset.Apply(Position_FantasyToScifi(FVector()), this);
				TargetablesComp.IgnoreVisualWidgetDistance.Apply(true, this);
			}

			if (Player.IsMio())
			{
				if (MioSoundDef.IsValid())
					MioSoundDef.SpawnSoundDefAttached(Player, this);
			}
			else if (ZoeSoundDef.IsValid()) 
			{
				ZoeSoundDef.SpawnSoundDefAttached(Player, this);
			}
		}

		SetActorTickEnabled(true);
	}

	UFUNCTION(DevFunction)
	void ActivateEffectLine()
	{
		LineWidget = Widget::AddFullscreenWidget(EffectLineWidget, EHazeWidgetLayer::Overlay);

		if (EffectLineParticles != nullptr)
		{
			for (int i = 0; i < 4; ++i)
			{
				UNiagaraComponent Comp = UNiagaraComponent::Create(this);
				Comp.SetAsset(EffectLineParticles);
				LineParticles.Add(Comp);
			}
		}
	}

	UFUNCTION(DevFunction)
	void BlendBackToPlayerCameras(float BlendTime = 2.0)
	{
		bSplitCameraActive = true;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			auto CamSettings = UCameraSettings::GetSettings(Player);
			auto ViewPoint = Cast<UHazeCameraViewPoint>(Player.GetViewPoint());
			ViewPoint.ClearOffCenterProjectionOffset(this, BlendTime);

			if (Player.IsZoe())
				Player.DeactivateCamera(DuplicatedCamera, BlendTime);
		}
	}

	UFUNCTION(DevFunction)
	void DissolveOutfitsToWhiteSpace(float Duration = 1.0)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			USkeletalMesh TargetMesh;
			if (Player.IsMio())
				TargetMesh = PlayerVariant_Whitespace.MioSkeletalMesh;
			else
				TargetMesh = PlayerVariant_Whitespace.ZoeSkeletalMesh;

			{
				auto DissolveComp = Player.CreateComponent(DissolveComponentClass);
				DissolveComp.SetupDissolve(TargetMesh, Player.Mesh, EHazeDissolveType::Sphere);
				DissolveComp.StartDissolve();
			}

			{
				auto DissolveComp = PlayerCopies[Player].CreateComponent(DissolveComponentClass);
				DissolveComp.SetupDissolve(TargetMesh, PlayerCopies[Player].Mesh, EHazeDissolveType::Sphere);
				DissolveComp.StartDissolve();
			}

			PerPlayerData[Player].bIsDissolving = true;
			PerPlayerData[Player].DissolveTimer = 0.0;
			PerPlayerData[Player].DissolveDuration = Duration;
		}
	}

	void UpdateDissolve(float DeltaTime)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			FSplitTraversalPlayerData& Data = PerPlayerData[Player];
			if (!Data.bIsDissolving)
				continue;

			Data.DissolveTimer += DeltaTime;
			if (Data.DissolveTimer >= Data.DissolveDuration)
			{
				{
					auto DissolveComp = UMeshDissolveComponent::Get(Player);
					DissolveComp.SetAlpha(1.0);
					DissolveComp.FinishDissolve();
				}

				{
					auto DissolveComp = UMeshDissolveComponent::Get(PlayerCopies[Player]);
					DissolveComp.SetAlpha(1.0);
					DissolveComp.FinishDissolve();
				}

				Data.bIsDissolving = false;
			}
			else
			{
				{
					auto DissolveComp = UMeshDissolveComponent::Get(Player);
					DissolveComp.SetAlpha(Math::Saturate(Data.DissolveTimer / Data.DissolveDuration));
				}

				{
					auto DissolveComp = UMeshDissolveComponent::Get(PlayerCopies[Player]);
					DissolveComp.SetAlpha(Math::Saturate(Data.DissolveTimer / Data.DissolveDuration));
				}
			}
		}
	}

	//And this function
	UFUNCTION()
	private void HandlePlayerDeath()
	{
		if (Game::Mio.IsPlayerDead() && Game::Zoe.IsPlayerDead())
		{
			PlayerHealth::TriggerGameOver();
		}
	}

	UFUNCTION()
	void ActivateSeparateWorldTraversal()
	{
		if (bSeparateWorldTraversalActive)
			return;

		if (!bInitialSetupDone)
			InitialSetup();

		bSeparateWorldTraversalActive = true;
		bSplitSlideActive = false;
		SceneView::SetSplitScreenMode(EHazeSplitScreenMode::Vertical);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			auto ViewPoint = Cast<UHazeCameraViewPoint>(Player.GetViewPoint());
			ViewPoint.ClearOffCenterProjectionOffset(this);
		}

		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void ActivateSharedTraversalCamera(AHazeCameraActor Camera, float CameraBlendTime, float PerspectiveBlendTime)
	{
		bSharedCameraActive = true;

		SharedCameraBaseSplit = GetSplitForLocation(Camera.ActorLocation);
		GetPlayerForSplit(SharedCameraBaseSplit).ActivateCamera(Camera, CameraBlendTime, this);

		if (DuplicatedCamera == nullptr)
			DuplicatedCamera = AStaticCameraActor::Spawn();
		GetPlayerForSplit(GetOtherSplit(SharedCameraBaseSplit)).ActivateCamera(DuplicatedCamera, CameraBlendTime, this);

		for (auto Player : Game::Players)
			ActivateOffCenterProjection(Player, PerspectiveBlendTime);
	}

	UFUNCTION()
	void ActivateOffCenterProjection(AHazePlayerCharacter Player, float BlendTime)
	{
		float HalfScreenSize = (1.0 - SplitPosition) * 0.5;
		float ScreenCenterPos = SplitPosition + HalfScreenSize;

		if (Player.IsMio())
		{
			HalfScreenSize = SplitPosition * 0.5;
			ScreenCenterPos = SplitPosition - HalfScreenSize;
		}

		FVector2D ProjectionOffset;
		ProjectionOffset.X = (ScreenCenterPos - 0.5) / Math::Max(HalfScreenSize, 0.01);

		PerPlayerData[Player].OffCenterBlendTime = BlendTime;
		PerPlayerData[Player].OffCenterProjectionTarget = ProjectionOffset;
	}

	UFUNCTION()
	void DeactivateSharedTraversalCamera(AHazeCameraActor Camera, float CameraBlendTime, float PerspectiveBlendTime)
	{
		bSharedCameraActive = false;

		for (auto Player : Game::Players)
		{
			Player.DeactivateCameraByInstigator(this, CameraBlendTime);
			DeactivateOffCenterProjection(Player, PerspectiveBlendTime);
		}
	}

	UFUNCTION()
	void DeactivateOffCenterProjection(AHazePlayerCharacter Player, float BlendTime)
	{
		PerPlayerData[Player].OffCenterBlendTime = BlendTime;
		PerPlayerData[Player].OffCenterProjectionTarget = FVector2D::ZeroVector;
	}

	UFUNCTION()
	void DeactivateManager()
	{
		if (!bInitialSetupDone)
			return;

		bInitialSetupDone = false;
		bSeparateWorldTraversalActive = false;
		bSplitSlideActive = false;
		SceneView::SetSplitScreenMode(EHazeSplitScreenMode::Vertical);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			auto ViewPoint = Cast<UHazeCameraViewPoint>(Player.GetViewPoint());
			ViewPoint.ClearOffCenterProjectionOffset(this);

			if (bSeparateWorldTraversalActive)
				Player.UnblockCapabilities(PlayerSlideTags::SlideCamera, this);

			auto IndicatorComp = UOtherPlayerIndicatorComponent::Get(Player);
			IndicatorComp.IndicatorWorldOffset.Clear(this);
			IndicatorComp.IndicatorMode.Clear(this);
		}

		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateDissolve(DeltaSeconds);

		if (bSplitSlideActive)
		{
			auto ActiveView = UCameraUserComponent::Get(Game::Mio).GetCameraView(true);

			if (DuplicatedCamera != nullptr)
			{
				DuplicatedCamera.ActorLocation = Position_ScifiToFantasy(Game::Mio.ViewLocation);
				DuplicatedCamera.ActorRotation = Game::Mio.ViewRotation;
				DuplicatedCamera.Camera.FieldOfView = Game::Mio.ViewFOV;
			}

			for (AHazePlayerCharacter Player : Game::Players)
			{
				auto ViewPoint = Cast<UHazeCameraViewPoint>(Player.GetViewPoint());
				auto CamSettings = UCameraSettings::GetSettings(Player);

				if (bSplitCameraActive)
				{
					// if (Player.IsZoe())
					// {
					// 	FMinimalViewInfo ViewInfo;
					// 	ViewInfo.Location = Position_ScifiToFantasy(ViewPoint.ViewLocation);
					// 	ViewInfo.Rotation = ViewPoint.ViewRotation;
					// 	ViewInfo.FOV = ViewPoint.ViewFOV;
					// 	ViewInfo.OffCenterProjectionOffset = ViewPoint.BlendedOffCenterProjectionOffset.Value;

					// 	ViewPoint.SnapView(ViewInfo);
					// }
				}
				else
				{
					if (Player.IsZoe())
					{
						float HalfScreenSize = (1.0 - SplitPosition) * 0.5;
						float ScreenCenterPos = SplitPosition + HalfScreenSize;

						FVector2D ProjectionOffset;
						ProjectionOffset.X = (ScreenCenterPos - 0.5) / Math::Max(HalfScreenSize, 0.01);

						ViewPoint.ApplyOffCenterProjectionOffset(ProjectionOffset, this);

						FMinimalViewInfo ViewInfo;
						ViewInfo.Location = Position_ScifiToFantasy(ActiveView.Location);
						ViewInfo.Rotation = ActiveView.Rotation;
						ViewInfo.FOV = ActiveView.FOV;
						ViewInfo.OffCenterProjectionOffset = ProjectionOffset;

						ViewPoint.SnapView(ViewInfo);
					}
					else
					{
						float HalfScreenSize = SplitPosition * 0.5;
						float ScreenCenterPos = SplitPosition - HalfScreenSize;

						ViewPoint.ApplyOffCenterProjectionOffset(FVector2D(
							(ScreenCenterPos - 0.5) / Math::Max(HalfScreenSize, 0.01), 0.0
						), this);
					}
				}
			}

			TArray<FHazeManualView> ActiveViews;

			// Mio's view
			{
				FHazeManualView View;
				View.TopLeft.X = 0.0;
				View.TopLeft.Y = 0.0;
				View.BottomRight.X = SplitPosition;
				View.BottomRight.Y = 1.0;
				ActiveViews.Add(View);
			}

			// Zoe's view
			{
				FHazeManualView View;
				View.TopLeft.X = SplitPosition;
				View.TopLeft.Y = 0.0;
				View.BottomRight.X = 1.0;
				View.BottomRight.Y = 1.0;
				ActiveViews.Add(View);
			}

			SceneView::SetManualViews(ActiveViews);

			FVector RayOrigin;
			FVector RayDirection;
			SceneView::DeprojectScreenToWorld_Relative(Game::Mio, FVector2D(SplitPosition, 0.5), RayOrigin, RayDirection);

			SplitPlaneOrigin = RayOrigin;
			SplitPlaneNormal = Game::Mio.ViewRotation.RightVector;
		}
		else if (bSeparateWorldTraversalActive)
		{
#if EDITOR
			// Fix the player positions in editor (could be wrong after a debug teleport or something)
			for (auto Player : Game::Players)
			{
				EHazeWorldLinkLevel PlayerSplit = GetSplitForPlayer(Player);
				EHazeWorldLinkLevel PositionSplit = GetSplitForLocation(Player.ActorLocation);

				if (PlayerSplit != PositionSplit)
				{
					Player.SetActorLocation(
						Position_Convert(Player.ActorLocation, PositionSplit, PlayerSplit)
					);
					Player.SnapCameraAtEndOfFrame(FRotator(), EHazeCameraSnapType::BehindUser);
				}
			}
#endif

			if (bSharedCameraActive)
			{
				AHazePlayerCharacter BasePlayer = GetPlayerForSplit(SharedCameraBaseSplit);
				DuplicatedCamera.ActorLocation = Position_Convert(BasePlayer.ViewLocation, SharedCameraBaseSplit, GetOtherSplit(SharedCameraBaseSplit));
				DuplicatedCamera.ActorRotation = BasePlayer.ViewRotation;
				DuplicatedCamera.Camera.FieldOfView = BasePlayer.ViewFOV;
			}

			for (auto Player : Game::Players)
			{
				auto ViewPoint = Cast<UHazeCameraViewPoint>(Player.GetViewPoint());

				FSplitTraversalPlayerData& PlayerData = PerPlayerData[Player];
				PlayerData.OffCenterProjectionOffset.AccelerateTo(
					PlayerData.OffCenterProjectionTarget, PlayerData.OffCenterBlendTime, DeltaSeconds
				);


				ViewPoint.ApplyOffCenterProjectionOffset(PlayerData.OffCenterProjectionOffset.Value, this);
			}
		}

		if (LineWidget != nullptr)
		{
			// Update distortion effects
			LineWidget.DistortionSpheres.Reset();
			for (auto Player : Game::Players)
			{
				FMeltdownEffectLineDistortionSphere Sphere;
				Sphere.Center = Player.ActorCenterLocation;
				Sphere.PlayerScreen = Game::Mio;
				LineWidget.DistortionSpheres.Add(Sphere);
			}

			// Update niagara effects
			for (int i = 0, Count = LineParticles.Num(); i < Count; ++i)
			{
				UNiagaraComponent Comp = LineParticles[i];

				AHazePlayerCharacter Player;
				FVector2D UV;

				switch (i)
				{
					case 0:
						Player = Game::Mio;
						UV = FVector2D(1, 0);
					break;
					case 1:
						Player = Game::Mio;
						UV = FVector2D(1, 1);
					break;
					case 2:
						Player = Game::Zoe;
						UV = FVector2D(0, 0);
					break;
					case 3:
						Player = Game::Zoe;
						UV = FVector2D(0, 1);
					break;
				}

				FVector Origin;
				FVector Direction;
				SceneView::DeprojectScreenToWorld_Relative(Player, UV, Origin, Direction);

				FHitResult Hit;
				Comp.SetWorldLocationAndRotation(Origin + Direction * EffectLineParticleDepth, FRotator::MakeFromX(Direction), false, Hit, true);
			}
		}
		
		// Update the crossing effect particles
		if (bSplitSlideActive)
		{
			// Track if the players are in fantasy/scifi
			float PlayersInFantasy = 0;

			for (auto Player : Game::Players)
			{
				FVector CameraRight = Game::Mio.ViewRotation.RightVector;
				FVector LeftWorldLocation = Player.ActorCenterLocation - CameraRight * Player.CapsuleComponent.ScaledCapsuleRadius;
				FVector RightWorldLocation = Player.ActorCenterLocation + CameraRight * Player.CapsuleComponent.ScaledCapsuleRadius;

				FVector2D LeftScreenLocation;
				SceneView::ProjectWorldToScreenPosition(Game::Mio, LeftWorldLocation, LeftScreenLocation);

				FVector2D RightScreenLocation;
				SceneView::ProjectWorldToScreenPosition(Game::Mio, RightWorldLocation, RightScreenLocation);

				bool bShouldBeActive = false;
				if ((LeftScreenLocation.X < 0.5) != (RightScreenLocation.X < 0.5))
					bShouldBeActive = true;

				if (LeftScreenLocation.X > 0.5)
				{
					++PlayersInFantasy;
				}
			}

			// Update the rtpcs based on where the players are currently
			AudioComponent::SetGlobalRTPC(Rtpc_Meltdown_SplitTraversal_InFantasy, PlayersInFantasy, 250);
			AudioComponent::SetGlobalRTPC(Rtpc_Meltdown_SplitTraversal_InScifi, 2 - PlayersInFantasy, 250);
		}
	}
};


namespace ASplitTraversalManager
{
	ASplitTraversalManager GetSplitTraversalManager()
	{
		return TListedActors<ASplitTraversalManager>().GetSingle();
	}
}
