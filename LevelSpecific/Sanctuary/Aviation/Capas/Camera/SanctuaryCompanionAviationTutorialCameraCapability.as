class USanctuaryCompanionAviationTutorialCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default TickGroup = EHazeTickGroup::Gameplay;
	USanctuaryCompanionAviationPlayerComponent AviationComp;

	bool bNoRef = false;

	ASplineFollowCameraActor SplineCam;
	float OGHorizontalOffset;
	float OGVerticalOffset;

	FHazeAcceleratedFloat AccHorizontal;
	FHazeAcceleratedFloat AccVertical;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		AviationDevToggles::Camera::NoCameraOffset.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (bNoRef)
			return false;
		if (AviationComp.GetIsAviationActive())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bNoRef)
			return true;
		if (!AviationComp.GetIsAviationActive())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TListedActors<ASanctuaryAviationTutorialReferencesActor> TutorialRefs;
		if (TutorialRefs.Num() == 0)
		{
			bNoRef = true;
			return;
		}
		if (Player.IsMio())
			EnableCamera(true, TutorialRefs.Single.TutorialSplineCameraMio, TutorialRefs.Single.TutorialSplineCameraBlendInTime);
		else
			EnableCamera(true, TutorialRefs.Single.TutorialSplineCameraZoe, TutorialRefs.Single.TutorialSplineCameraBlendInTime);
		if (TutorialRefs.Single.TutorialSplineCameraSettings != nullptr)
			Player.ApplyCameraSettings(TutorialRefs.Single.TutorialSplineCameraSettings, TutorialRefs.Single.TutorialSplineCameraBlendInTime, this, EHazeCameraPriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (bNoRef)
			return;
		TListedActors<ASanctuaryAviationTutorialReferencesActor> TutorialRefs;
		if (Player.IsMio())
			EnableCamera(false, TutorialRefs.Single.TutorialSplineCameraMio, TutorialRefs.Single.TutorialSplineCameraBlendOutTime);
		else
			EnableCamera(false, TutorialRefs.Single.TutorialSplineCameraZoe, TutorialRefs.Single.TutorialSplineCameraBlendOutTime);
		if (TutorialRefs.Single.TutorialSplineCameraSettings != nullptr)
			Player.ClearCameraSettingsByInstigator(this);


		if (SplineCam != nullptr && !AviationDevToggles::Camera::NoCameraOffset.IsEnabled())
		{
			SplineCam.SplineFollowSettings.LocationOffset.Z = OGVerticalOffset;
			SplineCam.SplineFollowSettings.LocationOffset.Y = OGHorizontalOffset;
		}
	}

	private void EnableCamera(bool bEnabled, AHazeCameraActor Cam, float BlendTime)
	{
		if (Cam == nullptr || Cam.IsActorBeingDestroyed())
			return;

		SplineCam = Cast<ASplineFollowCameraActor>(Cam);
		if (SplineCam != nullptr && bEnabled)
		{
			OGHorizontalOffset = SplineCam.SplineFollowSettings.LocationOffset.Y;
			OGVerticalOffset = SplineCam.SplineFollowSettings.LocationOffset.Z;
		}

		if (bEnabled)
			Player.ActivateCamera(Cam, BlendTime, this, EHazeCameraPriority::High);
		else
			Player.DeactivateCamera(Cam, BlendTime);
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (SplineCam != nullptr && !AviationDevToggles::Camera::NoCameraOffset.IsEnabled())
		{
			float VerticalOffset = OGVerticalOffset;
			float HorizontalOffset = OGHorizontalOffset;
			float OffsetAlpha = AviationComp.SyncedFlyingMinMaxAlphaValue.Value;
			FVector2D FlyingOffset = AviationComp.SyncedFlyingOffsetValue.Value;

			VerticalOffset += FlyingOffset.Y * Math::Lerp(AviationComp.Settings.TutorialCameraVerticalDistanceMin, AviationComp.Settings.TutorialCameraVerticalDistanceMax, OffsetAlpha);
			HorizontalOffset += FlyingOffset.X * Math::Lerp(AviationComp.Settings.TutorialCameraHorizontalDistanceMin, AviationComp.Settings.TutorialCameraHorizontalDistanceMax, OffsetAlpha);

			AccHorizontal.AccelerateTo(HorizontalOffset, 0.01, DeltaTime);
			AccVertical.AccelerateTo(VerticalOffset, 0.01, DeltaTime);

			SplineCam.SplineFollowSettings.LocationOffset.Z = AccVertical.Value;
			SplineCam.SplineFollowSettings.LocationOffset.Y = AccHorizontal.Value;
		}
	}
};