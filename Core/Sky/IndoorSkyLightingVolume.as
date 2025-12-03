UCLASS(Meta = (HideCategories = "EditorRendering Navigation Collision Actor Debug Rendering Cooking"))
class AIndoorSkyLightingVolume : AVolume
{
    default Shape::SetVolumeBrushColor(this, FLinearColor(0.94, 1.00, 0.43));
	default BrushComponent.SetCollisionProfileName(n"OverlapAll");

	// We can safely disable overlap updates when this moves, because players always update overlaps every frame
	default BrushComponent.bDisableUpdateOverlapsOnComponentMove = true;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	// Disable cascades while the player is indoors
	UPROPERTY(EditAnywhere, Category = "Lighting Settings")
	bool bAffectCascades = true;

	// Disable the directional light entirely while the player is indoors
	UPROPERTY(EditAnywhere, Category = "Lighting Settings")
	bool bAffectDirectionalLight = true;

	/**
	 * Set this as an inverted volume.
	 * 
	 * If ANY inverted volumes are present in the level, the player is considered
	 * indoors EXCEPT when inside one of the inverted volumes.
	 */
	UPROPERTY(EditAnywhere, Category = "Lighting Settings")
	bool bIsInvertedVolume = false;

	/**
	 * Check whether the player is inside the volume instead of whether the camera is inside the volume.
	 */
	UPROPERTY(EditAnywhere, Category = "Trigger")
	EVisibilityVolumeApplyType ApplyWhen = EVisibilityVolumeApplyType::PlayerCameraInside;
}

namespace AIndoorSkyLightingVolume
{
	void GetIndoorSkyLightingSettings(
		FVector CameraLocation,
		FVector PlayerLocation,
		bool& OutDisableCascades,
		bool& OutDisableDirectionalLight,
	)
	{
		OutDisableCascades = false;
		OutDisableDirectionalLight = false;

		bool bAnyInvertedVolumeAffectsCascades = false;
		bool bAnyInvertedVolumeAffectsDirectionalLight = false;

		bool bIsInsideInvertedVolumeAffectingCascades = false;
		bool bIsInsideInvertedVolumeAffectingDirectionalLight = false;

		for (AIndoorSkyLightingVolume Volume : TListedActors<AIndoorSkyLightingVolume>())
		{
			bool bIsInsideVolume = false;
			switch (Volume.ApplyWhen)
			{
				case EVisibilityVolumeApplyType::PlayerCameraInside:
					bIsInsideVolume = Volume.EncompassesPoint(CameraLocation);
				break;
				case EVisibilityVolumeApplyType::PlayerActorInside:
					bIsInsideVolume = Volume.EncompassesPoint(PlayerLocation);
				break;
			}

			if (Volume.bIsInvertedVolume)
			{
				if (Volume.bAffectCascades)
					bAnyInvertedVolumeAffectsCascades = true;
				if (Volume.bAffectDirectionalLight)
					bAnyInvertedVolumeAffectsDirectionalLight = true;

				if (bIsInsideVolume)
				{
					if (Volume.bAffectCascades)
						bIsInsideInvertedVolumeAffectingCascades = true;
					if (Volume.bAffectDirectionalLight)
						bIsInsideInvertedVolumeAffectingDirectionalLight = true;
				}
			}
			else
			{
				if (bIsInsideVolume)
				{
					if (Volume.bAffectCascades)
						OutDisableCascades = true;
					if (Volume.bAffectDirectionalLight)
						OutDisableDirectionalLight = true;
				}
			}
		}

		if (bAnyInvertedVolumeAffectsCascades && !bIsInsideInvertedVolumeAffectingCascades)
			OutDisableCascades = true;
		if (bAnyInvertedVolumeAffectsDirectionalLight && !bIsInsideInvertedVolumeAffectingDirectionalLight)
			OutDisableDirectionalLight = true;
	}
}