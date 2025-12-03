UCLASS(Abstract)
class ALoadingScreenPostProcessActor : AHazeActor
{
	default PrimaryActorTick.bTickEvenWhenPaused = true;
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PrePhysics;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditAnywhere)
	UMaterialInterface LoadingScreenPostProcess;

	bool bActive = false;

	private UMaterialInstanceDynamic DynamicMaterial;
	private bool bIsPersistent = false;
	private int StreamingActivationCounter = 0;
	private int LoadingScreenRemainingFrames = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (!bIsPersistent)
		{
			// Spawn a persistent copy of ourselves so we don't get deleted when the sequence ends
			auto PersistentCopy = Cast<ALoadingScreenPostProcessActor>(
				SpawnPersistentActor(Class, ActorLocation, ActorRotation, bDeferredSpawn = true));
			PersistentCopy.bIsPersistent = true;
			PersistentCopy.LoadingScreenPostProcess = LoadingScreenPostProcess;
			FinishSpawningActor(PersistentCopy);

			SetActorTickEnabled(false);
			AddActorDisable(this);
		}
		else
		{
			for (ALoadingScreenPostProcessActor OtherActor : TListedActors<ALoadingScreenPostProcessActor>())
			{
				if (OtherActor != nullptr)
					OtherActor.bActive = false;
			}

			StreamingActivationCounter = Progress::LocalLevelStreamingActivationCounter;
			SetActorTickEnabled(true);

			DynamicMaterial = Material::CreateDynamicMaterialInstance(this, LoadingScreenPostProcess);
			DynamicMaterial.SetScalarParameterValue(
				n"LoadingScreenData_WhitespaceRealTime", Time::RealTimeSeconds,
			);

			SceneView::SetLoadingScreenPostProcessMaterial(DynamicMaterial);
			SceneView::SetForceRenderNoViews(false);
			Console::ExecuteConsoleCommand("Haze.FadeOutOnLoadingScreen 0");
			bActive = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (bActive)
		{
			bActive = false;
			SceneView::SetForceRenderNoViews(false);
			SceneView::SetLoadingScreenPostProcessMaterial(nullptr);
			Console::ExecuteConsoleCommand("Haze.FadeOutOnLoadingScreen 1");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bIsPersistent)
			return;

		DynamicMaterial.SetScalarParameterValue(
			n"LoadingScreenData_WhitespaceRealTime", Time::RealTimeSeconds,
		);

		if (Game::IsInLoadingScreen())
		{
			LoadingScreenRemainingFrames = 3;

			if (bActive)
				SceneView::SetForceRenderNoViews(true);
		}
		else if (StreamingActivationCounter != Progress::LocalLevelStreamingActivationCounter)
		{
			if (LoadingScreenRemainingFrames <= 0)
			{
				// Destroy the actor once we've transitioned to the new level
				if (bActive)
				{
					SceneView::SetLoadingScreenPostProcessMaterial(nullptr);
					Console::ExecuteConsoleCommand("Haze.FadeOutOnLoadingScreen 1");
					SceneView::SetForceRenderNoViews(false);

					for (auto Player : Game::Players)
					{
						auto FadeManager = UFadeManagerComponent::Get(Player);
						if (FadeManager != nullptr)
							FadeManager.SnapOutLoadingScreenFade();

						auto CameraUser = UCameraUserComponent::Get(Player);
						CameraUser.TriggerCameraCutThisFrame();
					}
				}
					
				DestroyActor();
			}
			else
			{
				--LoadingScreenRemainingFrames;
			}
		}
	}
};