UCLASS(HideCategories = "Debug Activation Collision Cooking Rendering Actor Tags")
class ASplitBonanzaManager : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerCapabilities.Add(n"SplitBonanzaPlayerCollisionCapability");

	UPROPERTY(EditAnywhere, Category = "Camera")
	AHazeCameraActor Camera;
	UPROPERTY(EditAnywhere, Category = "Camera")
	UHazeCameraSettingsDataAsset CameraSettings;

	UPROPERTY(EditAnywhere, Category = "Splits")
	TArray<ASplitBonanzaLine> SplitLines;

	UPROPERTY(EditAnywhere, Category = "Splits", Meta = (MakeEditWidget))
	FTransform SpotlightLocation;

	UPROPERTY(EditAnywhere, Category = "Splits")
	bool bEnablePerPlayerLighting = true;

	UPROPERTY(Interp)
	bool bApplyBonanzaLightingToPlayers = true;

	UPROPERTY(EditAnywhere, Category = "Splits")
	FSplitBonanzaLightingSettings DefaultLighting;

	UPROPERTY(EditAnywhere, Category = "Splits")
	UMaterialInterface LevelStencilMaterial;

	UPROPERTY(VisibleAnywhere, Transient)
	UTextureRenderTarget2D LevelStencil;

	UPROPERTY(EditInstanceOnly)
	TArray<TSoftObjectPtr<AHazeSphere>> HazeSpheresToHideDuringCutscene;

	UFakeSplitRenderManagerComponent SplitRenderComp;
	bool bBonanzaActive = false;
	bool bWorldsAddedToSplit = false;

	// We completely hijack these trace channels to make this work!
	TArray<ECollisionChannel> ChannelsToHijack;
	default ChannelsToHijack.Add(ECollisionChannel::ECC_EngineTraceChannel1);
	default ChannelsToHijack.Add(ECollisionChannel::ECC_EngineTraceChannel2);
	default ChannelsToHijack.Add(ECollisionChannel::ECC_EngineTraceChannel3);
	default ChannelsToHijack.Add(ECollisionChannel::ECC_EngineTraceChannel4);
	default ChannelsToHijack.Add(ECollisionChannel::ECC_EngineTraceChannel5);
	default ChannelsToHijack.Add(ECollisionChannel::ECC_EngineTraceChannel6);
	
	TPerPlayer<FSplitBonanzaLightingSettings> LightingSettings;
	TPerPlayer<USpotLightComponent> SpotLights;
	TPerPlayer<USpotLightComponent> HighlightSpotlights;
	UMaterialInstanceDynamic StencilDynamicMaterial;
	bool bHiddenHazeSpheres = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TListedActors<ASplitBonanzaOffsetManager> OffsetManagers;
		for (ASplitBonanzaOffsetManager OffsetActor : OffsetManagers)
			OffsetActor.ActivateSplitBonanza();
		CheckLinesForActivate();
	}

	void ActivateBonanzaOnOffsetActor(ASplitBonanzaOffsetManager OffsetActor)
	{
		OffsetActor.ActivateSplitBonanza();
		CheckLinesForActivate();
	}

	void CheckLinesForActivate()
	{
		SplitRenderComp = UFakeSplitRenderManagerComponent::Get(this);

		for (int LineIndex = 0, LineCount = SplitLines.Num(); LineIndex < LineCount; ++LineIndex)
		{
			ASplitBonanzaLine LineActor = SplitLines[LineIndex];
			if (LineActor.bLineActivated)
				continue;

			bool bLoadedManager = false;

			TListedActors<ASplitBonanzaOffsetManager> OffsetManagers;
			for (auto Manager : OffsetManagers)
			{
				if (!Manager.bActivatedInManager)
					continue;

				if (LineActor.AffectedLevels.Contains(Cast<UWorld>(Manager.Level.Outer)))
				{
					bLoadedManager = true;
					break;
				}
			}

			if (!bLoadedManager)
				break;

			if (LineActor.bNeverCollideWithPlayer)
				SplitRenderComp.SetSplitRemoveCollision(LineActor.Name, true);
			else
				SplitRenderComp.SetSplitCollisionOverrideType(LineActor.Name, ChannelsToHijack[LineIndex]);

			FLightingChannels StaticChannels;
			StaticChannels.bChannel0 = false;
			StaticChannels.bChannel1 = false;
			StaticChannels.bChannel2 = false;

			FLightingChannels MovableChannels;
			MovableChannels.bChannel0 = true;
			MovableChannels.bChannel1 = false;
			MovableChannels.bChannel2 = false;

			SplitRenderComp.SetSplitLightingChannels(LineActor.Name, StaticChannels, MovableChannels);

			SplitRenderComp.AddActorToSplit(
				LineActor, LineActor.Name
			);

			for (auto AffectLevel : LineActor.AffectedLevels)
			{
				SplitRenderComp.AddLevelToSplit(
					AffectLevel, LineActor.Name
				);
			}

			LineActor.bLineActivated = true;
		}
	}

	UFUNCTION()
	void ActivateIntroCutscene()
	{
		AddWorldsToSplit();

		for (int LineIndex = 0, LineCount = SplitLines.Num(); LineIndex < LineCount; ++LineIndex)
		{
			ASplitBonanzaLine LineActor = SplitLines[LineIndex];
			if (!LineActor.bVisibleDuringIntroCutscene)
				LineActor.BlockRendering(n"IntroCutscene");
		}

		for (TSoftObjectPtr<AHazeSphere> HazeSpherePtr : HazeSpheresToHideDuringCutscene)
		{
			AHazeSphere HazeSphere = HazeSpherePtr.Get();
			if (IsValid(HazeSphere))
				HazeSphere.AddActorVisualsBlock(this);
		}
		bHiddenHazeSpheres = true;
	}

	void AddWorldsToSplit()
	{
		if (bWorldsAddedToSplit)
			return;

		bWorldsAddedToSplit = true;
		SetActorTickEnabled(true);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (bEnablePerPlayerLighting)
			{
				auto Spot = USpotLightComponent::Create(this);
				Spot.SetCastShadows(false);
				Spot.SetMobility(EComponentMobility::Movable);
				Spot.SetIntensityUnits(ELightUnits::Unitless);
				Spot.SetUseInverseSquaredFalloff(false);

				// Spot.AttachToComponent(Player.Mesh);
				Spot.RelativeTransform = SpotlightLocation;
				// Spot.SetVisibility(false);

				Spot.SetLightingChannels(false, Player.IsMio(), Player.IsZoe());

				// Spot.AttachToComponent(Player.Mesh);
				Spot.RelativeTransform = SpotlightLocation;

				SpotLights[Player] = Spot;
				LightingSettings[Player] = GetTargetLightingSettings(Player);
				LightingSettings[Player].Apply(Spot);

				auto HighlightSpot = USpotLightComponent::Create(this);
				HighlightSpot.SetCastShadows(false);
				HighlightSpot.SetMobility(EComponentMobility::Movable);
				HighlightSpot.SetIntensityUnits(ELightUnits::Unitless);
				HighlightSpot.SetUseInverseSquaredFalloff(false);
				HighlightSpot.SetLightingChannels(false, Player.IsMio(), Player.IsZoe());

				HighlightSpotlights[Player] = HighlightSpot;

				Player.Mesh.SetLightingChannels(false, Player.IsMio(), Player.IsZoe());
			}
		}

		// Create the spotlight that will be used for non-player stuff
		{
			auto Spot = USpotLightComponent::Create(this);
			Spot.SetMobility(EComponentMobility::Movable);
			Spot.SetIntensityUnits(ELightUnits::Unitless);
			Spot.SetUseInverseSquaredFalloff(false);

			Spot.RelativeTransform = SpotlightLocation;
			Spot.SetLightingChannels(true, false, false);

			DefaultLighting.Apply(Spot);
		}
	}

	UFUNCTION()
	void ActivateSplitBonanza()
	{
		if (bBonanzaActive)
			return;

		SplitRenderComp = UFakeSplitRenderManagerComponent::Get(this);
		SplitRenderComp.ActivateMeltdownRendering();

		bBonanzaActive = true;

		Game::Mio.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);
		Game::Mio.ActivateCamera(Camera, 0.0, this);
		Game::Mio.ApplyCameraSettings(CameraSettings, 0.0, this, EHazeCameraPriority::Medium);

		// Game::Mio.GetViewPoint().ApplyLODDistanceFactor(this, 2.0);

		AddWorldsToSplit();
		UpdateSplits();

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.CapsuleComponent.ApplyCollisionProfile(n"PlayerCharacterAlternate", this);
		}


		for (int LineIndex = 0, LineCount = SplitLines.Num(); LineIndex < LineCount; ++LineIndex)
		{
			ASplitBonanzaLine LineActor = SplitLines[LineIndex];
			LineActor.UnblockRendering(n"IntroCutscene");
		}

		if (bHiddenHazeSpheres)
		{
			bHiddenHazeSpheres = false;
			for (TSoftObjectPtr<AHazeSphere> HazeSpherePtr : HazeSpheresToHideDuringCutscene)
			{
				AHazeSphere HazeSphere = HazeSpherePtr.Get();
				if (IsValid(HazeSphere))
				{
					HazeSphere.RemoveActorVisualsBlock(this);

					float Opacity = HazeSphere.HazeSphereComponent.Opacity;
					HazeSphere.HazeSphereComponent.SetOpacityValue(0.0);
					HazeSphere.HazeSphereComponent.SetOpacityOverTime(1.0, Opacity);
				}
			}
		}
	}

	FSplitBonanzaLightingSettings GetTargetLightingSettings(AHazePlayerCharacter Player)
	{
		int SplitIndex = SplitRenderComp.GetLevelIndexForPoint(Player.ActorLocation);
		if (!SplitLines.IsValidIndex(SplitIndex))
			return DefaultLighting;
		return SplitLines[SplitIndex].LightingSettings;
	}

	UFUNCTION()
	void DeactivateSplitBonanza()
	{
		if (!bBonanzaActive)
			return;

		bBonanzaActive = false;
		Game::Mio.ClearViewSizeOverride(this);
		Game::Mio.DeactivateCamera(Camera);
		Game::Mio.ClearCameraSettingsByInstigator(this);
		SetActorTickEnabled(false);

		for (AHazePlayerCharacter Player : Game::Players)
			Player.CapsuleComponent.ClearCollisionProfile(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bBonanzaActive)
			UpdateSplits();
		UpdateLighting(DeltaSeconds);
		if (bBonanzaActive)
			UpdateLevelStencil();
	}

	void UpdateLighting(float DeltaSeconds)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			FRotator SpotlightAngle;
			const float SpotlightDistance = 400.0;

			HighlightSpotlights[Player].SetLightColor(Player.GetPlayerUIColor());
			HighlightSpotlights[Player].SetIntensity(20);
			HighlightSpotlights[Player].SetAttenuationRadius(1000);
			HighlightSpotlights[Player].SetVisibility(true);

			FQuat SpotlightRotation = Player.ViewRotation.Quaternion() * SpotlightAngle.Quaternion();
			HighlightSpotlights[Player].SetWorldLocationAndRotation(
				Player.Mesh.GetSocketLocation(n"Hips")
					- SpotlightRotation.ForwardVector * SpotlightDistance
					+ Player.ActorTransform.TransformVector(FVector()),
				SpotlightRotation);

			if (bEnablePerPlayerLighting && bWorldsAddedToSplit)
			{
				if (bApplyBonanzaLightingToPlayers)
				{
					HighlightSpotlights[Player].SetVisibility(true);
					SpotLights[Player].SetVisibility(true);
				}
				else
				{
					HighlightSpotlights[Player].SetVisibility(false);
					SpotLights[Player].SetVisibility(false);
				}
			}
		}

		if (!bEnablePerPlayerLighting)
			return;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			LightingSettings[Player].BlendTowards(GetTargetLightingSettings(Player), DeltaSeconds, 10.0);
			LightingSettings[Player].Apply(SpotLights[Player]);
		}
	}

	void AddToBoundingBox(FBox& Box, FHazeComputedView PlayerView, FVector2D UV)
	{
		FVector TopLeftRayStart;
		FVector TopLeftRayDirection;
		PlayerView.DeprojectViewUVToWorld(UV, TopLeftRayStart, TopLeftRayDirection);

		Box += TopLeftRayStart;
		Box += TopLeftRayStart + TopLeftRayDirection * 3000.0;
	}

	void GetScreenSpaceBoundingBox(FBox Box, FTransform Transform,
		FVector2D& OutWideMin, FVector2D& OutWideMax,
		FVector2D& OutTightMin, FVector2D& OutTightMax)
	{
		TArray<FVector> WorldPoints;
		WorldPoints.Add(Transform.TransformPosition(FVector(Box.Min.X, Box.Min.Y, Box.Center.Z)));
		WorldPoints.Add(Transform.TransformPosition(FVector(Box.Max.X, Box.Min.Y, Box.Center.Z)));
		WorldPoints.Add(Transform.TransformPosition(FVector(Box.Min.X, Box.Max.Y, Box.Center.Z)));
		WorldPoints.Add(Transform.TransformPosition(FVector(Box.Min.X, Box.Min.Y, Box.Center.Z)));

		TArray<FVector2D> ScreenPoints;

		for (FVector Point : WorldPoints)
		{
			FVector2D ScreenPos;
			SceneView::ProjectWorldToScreenPosition(Game::Mio, Point, ScreenPos);
			ScreenPoints.Add(ScreenPos);
		}

		// Find the wide bounds
		OutWideMin = FVector2D(BIG_NUMBER, BIG_NUMBER);
		OutWideMax = FVector2D(-BIG_NUMBER, -BIG_NUMBER);
		for (FVector2D ScreenPos : ScreenPoints)
		{
			OutWideMin.X = Math::Min(OutWideMin.X, ScreenPos.X);
			OutWideMin.Y = Math::Min(OutWideMin.Y, ScreenPos.Y);

			OutWideMax.X = Math::Max(OutWideMax.X, ScreenPos.X);
			OutWideMax.Y = Math::Max(OutWideMax.Y, ScreenPos.Y);
		}

		// Find the center
		FVector2D CenterPos = (OutWideMin + OutWideMax) * 0.5;

		// Find the tight bounds
		OutTightMin = OutWideMin;
		OutTightMax = OutWideMax;
		for (FVector2D ScreenPos : ScreenPoints)
		{
			if (ScreenPos.X < CenterPos.X)
				OutTightMin.X = Math::Max(ScreenPos.X, OutTightMin.X);
			else
				OutTightMax.X = Math::Min(ScreenPos.X, OutTightMax.X);

			if (ScreenPos.Y < CenterPos.Y)
				OutTightMin.Y = Math::Max(ScreenPos.Y, OutTightMin.Y);
			else
				OutTightMax.Y = Math::Min(ScreenPos.Y, OutTightMax.Y);
		}
	}

	bool OverlapsScreenSpace(FVector2D AMin, FVector2D AMax, FVector2D BMin, FVector2D BMax)
	{
		if (AMin.X > BMax.X)
			return false;
		if (AMin.Y > BMax.Y)
			return false;
		if (AMax.X < BMin.X)
			return false;
		if (AMax.Y < BMin.Y)
			return false;
		return true;
	}

	bool IsFullyInsideOnScreen(FVector2D OuterMin, FVector2D OuterMax, FVector2D InnerMin, FVector2D InnerMax)
	{
		FVector2D OuterScreenMin = FVector2D(Math::Max(OuterMin.X, 0), Math::Min(OuterMin.Y, 1));
		FVector2D OuterScreenMax = FVector2D(Math::Max(OuterMax.X, 0), Math::Min(OuterMax.Y, 1));
		FVector2D InnerScreenMin = FVector2D(Math::Max(InnerMin.X, 0), Math::Min(InnerMin.Y, 1));
		FVector2D InnerScreenMax = FVector2D(Math::Max(InnerMax.X, 0), Math::Min(InnerMax.Y, 1));

		if (InnerScreenMin.X >= OuterScreenMin.X && InnerScreenMax.X <= OuterScreenMax.X)
		{
			if (InnerScreenMin.Y >= OuterScreenMin.Y && InnerScreenMax.Y <= OuterScreenMax.Y)
			{
				return true;
			}
		}

		return false;
	}

	void UpdateSplits()
	{
		// Update bounding boxes for where the line actors are rendered
		for (auto LineActor : SplitLines)
		{
			LineActor.UpdateSplitBoundingBox();

			GetScreenSpaceBoundingBox(LineActor.SplitLocalBoundingBox, LineActor.ActorTransform,
				LineActor.SplitScreenSpaceWideBoundsMin, LineActor.SplitScreenSpaceWideBoundsMax,
				LineActor.SplitScreenSpaceTightBoundsMin, LineActor.SplitScreenSpaceTightBoundsMax
				);
		}

		// Update area data for each split
		for (int LineIndex = 0, LineCount = SplitLines.Num(); LineIndex < LineCount; ++LineIndex)
		{
			ASplitBonanzaLine LineActor = SplitLines[LineIndex];
			bool bShouldRender = true;

			FVector2D AreaSize;
			switch (LineActor.AreaType)
			{
				case EFakeSplitAreaType::Split:
					if (LineActor.SplitAngularSize < SMALL_NUMBER)
						bShouldRender = false;
					AreaSize.X = Math::DegreesToRadians(LineActor.SplitAngularSize);
				break;
				case EFakeSplitAreaType::Rectangle:
					if (LineActor.RectangleExtents.X <= 1.0)
						bShouldRender = false;
					if (LineActor.RectangleExtents.Y <= 1.0)
						bShouldRender = false;
					AreaSize.X = LineActor.RectangleExtents.X;
					AreaSize.Y = LineActor.RectangleExtents.Y;
				break;
				case EFakeSplitAreaType::CircleArc:
					if (LineActor.SplitAngularSize < SMALL_NUMBER)
						bShouldRender = false;
					if (LineActor.CircleRadius <= 1.0)
						bShouldRender = false;
					AreaSize.X = Math::DegreesToRadians(LineActor.SplitAngularSize);
					AreaSize.Y = LineActor.CircleRadius;
				break;
			}

			SplitRenderComp.SetSplitConstraint(
				LineActor.Name,
				LineActor.ActorLocation,
				LineActor.ActorQuat,
				LineActor.AreaType,
				AreaSize,
				LineActor.SplitZOrder,
			);

			FBox SplitBoundingBox = LineActor.SplitLocalBoundingBox.TransformBy(LineActor.ActorTransform);

			// Don't render the split if it's completely out of the view
			if (bShouldRender)
			{
				if (!OverlapsScreenSpace(LineActor.SplitScreenSpaceWideBoundsMin, LineActor.SplitScreenSpaceWideBoundsMax, FVector2D(0, 0), FVector2D(1, 1)))
				{
					bShouldRender = false;
				}
			}

			// Check if the level is being fully covered by a higher priority line
			if (bShouldRender)
			{
				for (int OtherSplitIndex = 0; OtherSplitIndex < LineCount; ++OtherSplitIndex)
				{
					auto OtherSplit = SplitLines[OtherSplitIndex];
					if (OtherSplit == LineActor)
						continue;
					if (OtherSplit.SplitZOrder < LineActor.SplitZOrder)
						continue;
					if (OtherSplit.SplitZOrder == LineActor.SplitZOrder)
					{
						if (OtherSplitIndex < LineIndex)
							continue;
					}
					if (OtherSplit.AreaType == EFakeSplitAreaType::Split)
					{
						if (OtherSplit.SplitAngularSize < 89.9)
							continue;
					}
					if (OtherSplit.AreaType == EFakeSplitAreaType::CircleArc)
					{
						if (OtherSplit.SplitAngularSize < 359.9)
							continue;
					}

					const bool bFullyCovered = IsFullyInsideOnScreen(
						OtherSplit.SplitScreenSpaceTightBoundsMin, OtherSplit.SplitScreenSpaceTightBoundsMax,
						LineActor.SplitScreenSpaceWideBoundsMin, LineActor.SplitScreenSpaceWideBoundsMax,
					);
					if (bFullyCovered)
					{
						bShouldRender = false;
						break;
					}
				}
			}

			if (bShouldRender)
				LineActor.UnblockRendering(this);
			else
				LineActor.BlockRendering(this);
		}
	}

	void UpdateLevelStencil()
	{
		FVector2D FloatResolution = SceneView::GetFullViewportResolution();
		FIntVector2 Resolution(int(FloatResolution.X), int(FloatResolution.Y));

		if (LevelStencil == nullptr)
		{
			LevelStencil = Rendering::CreateRenderTarget2D(
				Resolution.X, Resolution.Y,
				ETextureRenderTargetFormat::RTF_R8);

			SceneView::SetHazeGlobalTextureForViewPosition(EHazeSplitScreenPosition::FirstPlayer, 7, LevelStencil);

#if EDITOR
			auto LevelEditorSubsystem = UHazeLevelEditorViewportSubsystem::Get();
			LevelEditorSubsystem.SetHazeGlobalTextureForEditor(7, LevelStencil);
#endif
		}
		else
		{
			if (LevelStencil.SizeX != Resolution.X || LevelStencil.SizeY != Resolution.Y)
				Rendering::ResizeRenderTarget2D(LevelStencil, Resolution.X, Resolution.Y);
		}

		if (StencilDynamicMaterial == nullptr)
		{
			StencilDynamicMaterial = Material::CreateDynamicMaterialInstance(this, LevelStencilMaterial);
		}

		// Compute the view
		UHazeViewPoint ViewPoint = Game::Mio.GetViewPoint();
		FHazeViewParameters ViewParams;
		ViewParams.Location = ViewPoint.ViewLocation;
		ViewParams.Rotation = ViewPoint.ViewRotation;
		ViewParams.FOV = ViewPoint.ViewFOV;
		ViewParams.bConstrainAspectRatio = false;
		ViewParams.ViewRectMin = FVector2D(0, 0);
		ViewParams.ViewRectMax = FVector2D(1, 1);
		ViewParams.ScreenResolution = FloatResolution;

		FHazeComputedView PlayerView = SceneView::ComputeView(ViewParams);
		StencilDynamicMaterial.SetVectorParameterValue(
			n"InvProj_PlaneX",
			FLinearColor(
				PlayerView.InvViewProjMatrix.XPlane.X,
				PlayerView.InvViewProjMatrix.XPlane.Y,
				PlayerView.InvViewProjMatrix.XPlane.Z,
				PlayerView.InvViewProjMatrix.XPlane.W,
			),
		);
		StencilDynamicMaterial.SetVectorParameterValue(
			n"InvProj_PlaneY",
			FLinearColor(
				PlayerView.InvViewProjMatrix.YPlane.X,
				PlayerView.InvViewProjMatrix.YPlane.Y,
				PlayerView.InvViewProjMatrix.YPlane.Z,
				PlayerView.InvViewProjMatrix.YPlane.W,
			),
		);
		StencilDynamicMaterial.SetVectorParameterValue(
			n"InvProj_PlaneZ",
			FLinearColor(
				PlayerView.InvViewProjMatrix.ZPlane.X,
				PlayerView.InvViewProjMatrix.ZPlane.Y,
				PlayerView.InvViewProjMatrix.ZPlane.Z,
				PlayerView.InvViewProjMatrix.ZPlane.W,
			),
		);
		StencilDynamicMaterial.SetVectorParameterValue(
			n"InvProj_PlaneW",
			FLinearColor(
				PlayerView.InvViewProjMatrix.WPlane.X,
				PlayerView.InvViewProjMatrix.WPlane.Y,
				PlayerView.InvViewProjMatrix.WPlane.Z,
				PlayerView.InvViewProjMatrix.WPlane.W,
			),
		);

		Rendering::DrawMaterialToRenderTarget(LevelStencil, StencilDynamicMaterial);
	}

	bool IsLevelVisibleAtPosition(ULevel CheckLevel, FVector Position) const
	{
		int CheckLevelIndex = SplitRenderComp.GetLevelIndexForLevel(CheckLevel);
		if (CheckLevelIndex == -1)
			return true;

		int VisibleLevelIndex = SplitRenderComp.GetLevelIndexForPoint(Position);
		return VisibleLevelIndex == CheckLevelIndex;
	}
};

class USplitBonanzaHackFixChaosComponent : UActorComponent
{
	bool bMoved;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bMoved)
		{
			bMoved = true;

			// Chaos sometimes forgets that collision exists until it's moved
			// Who knows why
			Owner.ActorLocation += FVector(0, 0, 0.01);
		}
	}
}

namespace ASplitBonanzaManager
{
	ASplitBonanzaManager Get()
	{
		return TListedActors<ASplitBonanzaManager>().GetSingle();
	}
}