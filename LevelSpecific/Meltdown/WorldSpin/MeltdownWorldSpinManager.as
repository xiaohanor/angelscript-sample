class AMeltdownWorldSpinManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(DefaultComponent)
	USceneCaptureComponent2D SceneCapture;
	default SceneCapture.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerCapabilities.Add(n"MeltdownWorldSpinnerPlayerCapability");

	bool bManagerActive = false;
	
	UPROPERTY(EditAnywhere)
	bool bSunRotationEnabled = false;
	UPROPERTY()
	TSubclassOf<UMeshDissolveComponent> DissolveComponentClass;

	AHazePlayerCharacter MovePlayer;
	AHazePlayerCharacter SpinPlayer;

	FQuat WorldSpinRotation;

	TPerPlayer<FHazeComputedView> PlayerViews;
	UTextureRenderTarget2D RenderTarget;

	AGameSky Sky;

	FQuat DirectionalLightStartRotation;
	FQuat SkydomeStartRotation;
	FQuat SkydomeLowerStartRotation;
	FQuat SkydomeSunStartRotation;

	bool bHasForcedAngle = false;
	float ForcedAngle = 0;
	float ForcedAngleBlendStart = 0;
	float ForcedAngleBlendDuration = 0;

	UMeshDissolveComponent PlayerDissolve;
	bool bDissolveActive = false;
	bool bHadAnyOutfit = false;
	float DissolveTimer = 0.0;
	TArray<AMeltdownWorldSpinOutfitVolume> OutfitVolumes;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UPlayerWorldSpinComponent::GetOrCreate(Game::Mio).Manager = this;
	}

	void UpdateWorldSpinRotation(FQuat Rotation, float SpinAngle)
	{
		WorldSpinRotation = Rotation;
		
		if (Sky == nullptr)
		{
			Sky = GetSky();
		}
		
		if (Sky != nullptr)
		{
			DirectionalLightStartRotation = Sky.DirectionalLight.ComponentQuat;
			SkydomeStartRotation = Sky.Skydome.ComponentQuat;
			SkydomeLowerStartRotation = Sky.SkydomeLowerHemisphere.ComponentQuat;
			SkydomeSunStartRotation = Sky.SkydomeSun.ComponentQuat;
		}

		if (Sky != nullptr && bSunRotationEnabled)
		{
			Sky.DirectionalLight.Mobility = EComponentMobility::Movable; // tested on the Xbox, looks fine ?

			FQuat SunRotation = FQuat(FVector::ForwardVector, Math::DegreesToRadians(SpinAngle * 1.0));
			Sky.DirectionalLight.SetWorldRotation(SunRotation * DirectionalLightStartRotation);
		}
	}

	UFUNCTION(DevFunction)
	void ForceWorldSpinRotation(float Angle, float BlendTime = 1.0)
	{
		bHasForcedAngle = true;
		ForcedAngle = Angle;
		ForcedAngleBlendStart = Time::GameTimeSeconds;
		ForcedAngleBlendDuration = BlendTime;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		DeactivateMeltdownWorldSpin();
	}

	UFUNCTION()
	void ActivateMeltdownWorldSpin()
	{
		if (bManagerActive)
			return;

		bManagerActive = true;
		MovePlayer = Game::Zoe;
		SpinPlayer = Game::Mio;

		SpinPlayer.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);
		MovePlayer.ApplyGameplayPerspectiveMode(EPlayerMovementPerspectiveMode::SideScroller, this);

		for (auto Player : Game::Players)
		{
			Player.ApplyOtherPlayerIndicatorMode(EOtherPlayerIndicatorMode::Hidden, this);
			Player.BlockCapabilities(CameraTags::CameraControl, this);

			auto ViewPoint = Player.GetViewPoint(false);
			ViewPoint.bCullAsIfAlwaysRendered = true;
		}

		auto MoveCameraUser = UCameraUserComponent::Get(MovePlayer);
		MoveCameraUser.ControlCameraWithoutScreenSizeAllower.Add(this);

		UCameraSettings MoveCameraSettings = UCameraSettings::GetSettings(MovePlayer);
		MoveCameraSettings.CameraOffset.Apply(FVector::ZeroVector, this, 0, EHazeCameraPriority::MAX);
		MoveCameraSettings.PivotOffset.Apply(FVector::ZeroVector, this, 0, EHazeCameraPriority::MAX);
		MoveCameraSettings.WorldPivotOffset.Apply(FVector::ZeroVector, this, 0, EHazeCameraPriority::MAX);
		MoveCameraSettings.CameraOffsetOwnerSpace.Apply(FVector::ZeroVector, this, 0, EHazeCameraPriority::MAX);
		MoveCameraSettings.IdealDistance.Apply(0, this, 0, EHazeCameraPriority::MAX);

		// auto SpinCameraViewPoint = SpinPlayer.GetViewPoint();
		// SpinCameraViewPoint.ApplyAntiAliasingOverride(this, EAntiAliasingMethod::AAM_FXAA);

		SpinPlayer.BlockCapabilities(CapabilityTags::Visibility, this);
		SpinPlayer.BlockCapabilities(CapabilityTags::Collision, this);
		SpinPlayer.BlockCapabilities(CapabilityTags::GameplayAction, this);
		SpinPlayer.BlockCapabilities(CapabilityTags::Movement, this);

		MovePlayer.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);

		PlayerDissolve = MovePlayer.CreateComponent(DissolveComponentClass);

		// if (RenderTarget == nullptr)
		// {
		// 	FVector2D Resolution = SceneView::GetFullViewportResolution();
		// 	Resolution.Y = Math::CeilToFloat(Resolution.X / 16.0 * 9.0);

		// 	RenderTarget = Rendering::CreateRenderTarget2D(
		// 		Math::Max(10, int(Resolution.X)),
		// 		Math::Max(10, int(Resolution.Y)),
		// 		ETextureRenderTargetFormat::RTF_RGB10A2
		// 	);
		// }

		// TArray<UMeshComponent> Meshes;
		// SceneDisplayActor.GetComponentsByClass(Meshes);

		// for (auto MeshComp : Meshes)
		// {
		// 	auto Material = MeshComp.CreateDynamicMaterialInstance(0);
		// 	Material.SetTextureParameterValue(n"TiltSceneTexture", RenderTarget);
		// }

		// SceneCapture.TextureTarget = RenderTarget;
		// SceneCapture.Activate();
	}

	UFUNCTION()
	void DeactivateMeltdownWorldSpin()
	{
		if (!bManagerActive)
			return;

		bManagerActive = false;
		MovePlayer.ClearViewSizeOverride(this);

		auto SpinCameraViewPoint = SpinPlayer.GetViewPoint();
		SpinCameraViewPoint.ClearAntiAliasingOverride(this);

		for (auto Player : Game::Players)
		{
			Player.ClearOtherPlayerIndicatorMode(this);
			Player.UnblockCapabilities(CameraTags::CameraControl, this);

			auto ViewPoint = Player.GetViewPoint(false);
			ViewPoint.bCullAsIfAlwaysRendered = false;
		}

		SpinPlayer.UnblockCapabilities(CapabilityTags::Visibility, this);
		SpinPlayer.UnblockCapabilities(CapabilityTags::Collision, this);
		SpinPlayer.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		SpinPlayer.UnblockCapabilities(CapabilityTags::Movement, this);

		MovePlayer.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);

		auto PostComp = UPostProcessingComponent::Get(MovePlayer);
		PostComp.ClearPostProcess(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bManagerActive)
			return;

		if (bDissolveActive)
		{
			DissolveTimer += DeltaSeconds;
			if (DissolveTimer >= 1.0)
			{
				PlayerDissolve.SetAlpha(1.0);
				PlayerDissolve.FinishDissolve();
				bDissolveActive = false;
			}
			else
			{
				float Alpha = Math::Saturate(DissolveTimer);
				PlayerDissolve.SetAlpha(Alpha);
			}
		}
		else
		{
			USkeletalMesh WantedMesh = nullptr;
			if (OutfitVolumes.Num() != 0)
				WantedMesh = OutfitVolumes[0].Outfit;

			if (WantedMesh != nullptr && WantedMesh != MovePlayer.Mesh.SkeletalMeshAsset)
			{
				if (!bHadAnyOutfit)
				{
					MovePlayer.Mesh.SetSkeletalMeshAsset(WantedMesh);
					bHadAnyOutfit = true;
				}
				else
				{
					bDissolveActive = true;
					DissolveTimer = 0.0;

					PlayerDissolve.SetupDissolve(
						WantedMesh, MovePlayer.Mesh, EHazeDissolveType::Sphere
					);
					PlayerDissolve.StartDissolve();
				}
			}
		}

		// if (RenderTarget != nullptr)
		// {
		// 	FVector2D Resolution = SceneView::GetFullViewportResolution();
		// 	Resolution.Y = Math::CeilToFloat(Resolution.X / 16.0 * 9.0);
		// 	Resolution = FVector2D(1920.0, 1080.0);
		// 	Rendering::ResizeRenderTarget(RenderTarget, int(Resolution.X), int(Resolution.Y));
		// }

		// // Calculate the actual view matrices for the players
		// for (auto Player : Game::Players)
		// {
		// 	auto ViewPoint = Player.GetViewPoint();

		// 	FHazeViewParameters ViewParams;
		// 	ViewParams.Location = ViewPoint.ViewLocation;
		// 	ViewParams.Rotation = ViewPoint.ViewRotation;
		// 	ViewParams.FOV = ViewPoint.ViewFOV;
		// 	PlayerViews[Player] = SceneView::ComputeView(ViewParams);
		// }

		// {
		// 	auto ViewPoint = MovePlayer.GetViewPoint();
		// 	SceneCapture.SetWorldLocationAndRotation(
		// 		ViewPoint.ViewLocation,
		// 		ViewPoint.ViewRotation
		// 	);
		// 	SceneCapture.FOVAngle = ViewPoint.ViewFOV;

		// 	SceneCapture.bUseCustomProjectionMatrix = true;
		// 	SceneCapture.CustomProjectionMatrix = PlayerViews[MovePlayer].ProjectionMatrix;
		// }
	}
};

class AMeltdownWorldSpinOutfitVolume : APlayerTrigger
{
	UPROPERTY(EditAnywhere)
	USkeletalMesh Outfit;

	void TriggerOnPlayerEnter(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerEnter(Player);

		auto Manager = ActorList::GetSingle(AMeltdownWorldSpinManager);
		if (Manager != nullptr)
			Manager.OutfitVolumes.Add(this);
	}

	void TriggerOnPlayerLeave(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerLeave(Player);

		auto Manager = ActorList::GetSingle(AMeltdownWorldSpinManager);
		if (Manager != nullptr)
			Manager.OutfitVolumes.Remove(this);
	}
}

class UPlayerWorldSpinComponent : UActorComponent
{
	AMeltdownWorldSpinManager Manager;
}

namespace AMeltdownWorldSpinManager
{
	AMeltdownWorldSpinManager GetWorldSpinManager()
	{
		return UPlayerWorldSpinComponent::GetOrCreate(Game::Mio).Manager;
	}
}