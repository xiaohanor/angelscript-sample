UCLASS(Abstract)
class ASketchbook2DManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(DefaultComponent)
	USceneCaptureComponent2D SceneCaptureComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditInstanceOnly)
	ASketchbookPaper Paper;

	UPROPERTY(VisibleInstanceOnly)
	UTextureRenderTarget2D RenderTarget;

	FHazeComputedView PlayerView;
	uint PlayerViewFrame;
	FVector2D Resolution;

	private bool bActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(SceneView::GetFullScreenPlayer() != nullptr)
			Activate();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(SceneView::GetFullScreenPlayer() == nullptr)
			return;

		if(!bActivated)
			Activate();

		if (RenderTarget != nullptr)
		{
			FVector2D CurrentResolution = SceneView::GetFullViewportResolution();
			if(Resolution != CurrentResolution)
			{
				Resolution = CurrentResolution;
				Rendering::ResizeRenderTarget(RenderTarget, int(CurrentResolution.X), int(CurrentResolution.Y));
			}
		}

		auto ViewPoint = SceneView::GetFullScreenPlayer().GetViewPoint();

		SceneCaptureComp.SetWorldLocationAndRotation(
			ViewPoint.ViewLocation,
			ViewPoint.ViewRotation
		);
		SceneCaptureComp.FOVAngle = ViewPoint.ViewFOV;

		SceneCaptureComp.bUseCustomProjectionMatrix = true;
		SceneCaptureComp.CustomProjectionMatrix = GetPlayerCameraView().ProjectionMatrix;
	}

	void Activate()
	{
		if(!ensure(!bActivated))
			return;

		if (RenderTarget == nullptr)
		{
			Resolution = SceneView::GetFullViewportResolution();

			RenderTarget = Rendering::CreateRenderTarget2D(
				Math::Max(10, int(Resolution.X)),
				Math::Max(10, int(Resolution.Y)),
				ETextureRenderTargetFormat::RTF_RGB10A2
			);
		}

		SceneCaptureComp.TextureTarget = RenderTarget;
		SceneCaptureComp.Activate();

		UMaterialInstanceDynamic Material = Paper.MeshComp.CreateDynamicMaterialInstance(0);
		Material.SetTextureParameterValue(n"SceneTexture", RenderTarget);

		UHazeViewPoint ViewPoint = SceneView::FullScreenPlayer.GetViewPoint();
		ViewPoint.ApplyAntiAliasingOverride(this, EAntiAliasingMethod::AAM_FXAA);
	}

	void Deactivate()
	{
		Rendering::ReleaseRenderTarget2D(RenderTarget);
		RenderTarget = nullptr;

		SceneCaptureComp.Deactivate();

		UHazeViewPoint ViewPoint = SceneView::FullScreenPlayer.GetViewPoint();
		ViewPoint.ClearAntiAliasingOverride(this);
	}

	FHazeComputedView GetPlayerCameraView()
	{
		if(PlayerViewFrame < Time::FrameNumber)
		{
			auto ViewPoint = SceneView::GetFullScreenPlayer().GetViewPoint();
			FHazeViewParameters ViewParams;
			ViewParams.Location = ViewPoint.ViewLocation;
			ViewParams.Rotation = ViewPoint.ViewRotation;
			ViewParams.FOV = ViewPoint.ViewFOV;
			PlayerView = SceneView::ComputeView(ViewParams);
			PlayerViewFrame = Time::FrameNumber;
		}

		return PlayerView;
	}
};

namespace Sketchbook
{
	FHazeComputedView GetPlayerCameraView()
	{
		return TListedActors<ASketchbook2DManager>().Single.GetPlayerCameraView();
	}
}