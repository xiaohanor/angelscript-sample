class APinballDofManager : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditInstanceOnly)
	TSoftObjectPtr<AHazePostProcessVolume> PostProcessVolumeSoft;

	private AHazePostProcessVolume PostProcessVolume;

	TInstigated<AActor> DofTarget;
	float SensorWidthMultiplier = 1;

	float FocusDepth = 0;

	AHazePlayerCharacter DofPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PostProcessVolume = PostProcessVolumeSoft.Get();

		DofTarget.SetDefaultValue(Game::Zoe);

		FocusDepth = DofTarget.Get().ActorLocation.X;
		const float TargetFocusDistance =  Math::Abs(FocusDepth - Game::Mio.ViewLocation.X);

		FPostProcessSettings& Settings = PostProcessVolume.Settings;
		Settings.DepthOfFieldFocalDistance = TargetFocusDistance;
		Settings.DepthOfFieldSensorWidth = TargetFocusDistance * SensorWidthMultiplier;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AHazePlayerCharacter ViewPlayer = SceneView::FullScreenPlayer;

		FocusDepth = Math::FInterpTo(
			FocusDepth,
			DofTarget.Get().ActorLocation.X,
			DeltaSeconds,
			1
		);

		FPostProcessSettings& Settings = PostProcessVolume.Settings;

		Settings.bOverride_DepthOfFieldFocalDistance = true;
		Settings.DepthOfFieldFocalDistance = FocusDepth - ViewPlayer.ViewLocation.X;

		Settings.bOverride_DepthOfFieldSensorWidth = true;
		Settings.DepthOfFieldSensorWidth = Settings.DepthOfFieldFocalDistance * SensorWidthMultiplier;

#if EDITOR
		TEMPORAL_LOG(this).Transform("View Transform", ViewPlayer.ViewTransform, 500);
		TEMPORAL_LOG(this).Arrow("Focal Distance", ViewPlayer.ViewLocation, ViewPlayer.ViewLocation + (ViewPlayer.ViewRotation.ForwardVector * Settings.DepthOfFieldFocalDistance));
		TEMPORAL_LOG(this).Value("Sensor Width", Settings.DepthOfFieldSensorWidth);
#endif
	}
};

namespace APinballDofManager
{
	APinballDofManager Get()
	{
		return TListedActors<APinballDofManager>().Single;
	}
}

UFUNCTION(BlueprintCallable, Category = "Pinball")
void PinballApplyDofTargetActor(AActor Actor, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
{
	APinballDofManager::Get().DofTarget.Apply(Actor, Instigator, Priority);
}

UFUNCTION(BlueprintCallable, Category = "Pinball")
void PinballClearDofTargetActor(FInstigator Instigator)
{
	APinballDofManager::Get().DofTarget.Clear(Instigator);
}

UFUNCTION(BlueprintCallable, Category = "Pinball")
void PinballSetDofSensorWidthMultiplier(float SensorWidthMultiplier)
{
	APinballDofManager::Get().SensorWidthMultiplier = SensorWidthMultiplier;
}