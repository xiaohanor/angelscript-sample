asset SkylineChaseCameraPlayerFocusSettings of UPlayerFocusTargetSettings
{
	FocusActivationType = EPlayerFocusTargetSettingsType::IgnoreIfDead;
}

UCLASS(hideCategories="Rendering Cooking Input Actor LOD AssetUserData Debug Collision InternalHiddenObjects")
class ASkylineChaseCameraActor : AHazeCameraActor
{
    UPROPERTY(OverrideComponent = Camera, ShowOnActor)
	USplineFollowCamera Camera;
	default Camera.CameraUpdaterType = USkylineChaseCameraUpdater;
	default Camera.bSnapOnTeleport = false;
	default Camera.bHasKeepInViewSettings = true;

	UPROPERTY(DefaultComponent)
	USkylineChaseCameraPitchTweakerComponent PitchTweakerComponent;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USkylineChaseCameraHeightTweakerComponent HeightTweakerComponent;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UCameraWeightedTargetComponent FocusTargetComponent;
	default FocusTargetComponent.EmptyTargetDefaultType = ECameraWeightedTargetEmptyInitType::DefaultToBothPlayers;
	default FocusTargetComponent.PlayerFocusSettingsOverride = SkylineChaseCameraPlayerFocusSettings;
	
	// The spline the camera will follow rotation of
	UPROPERTY(DefaultComponent)
	UHazeSplineComponent CameraSpline;

	UPROPERTY(EditAnywhere, Category = "CameraOptions", Meta = (ShowOnlyInnerProperties))
	FCameraSplineFollowUserSettings SplineFollowSettings;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		#if EDITOR
		// We want to debug draw the focus locations on the spline
		FocusTargetComponent.EditorDebugSpline = CameraSpline;
		SplineFollowSettings.SetEditorEditConditions(ECameraSplineLocationTargetType::PlaceAtTargetSplineLocation, ECameraSplineRotationTargetType::LookAtFocusTarget);
		#endif
	}

	UFUNCTION(BlueprintOverride)
	void PrepareUpdaterForUser(const UHazeCameraUserComponent HazeUser, UHazeCameraUpdater CameraData, FHazeCameraTransform CameraTransform) const
	{
		auto Updater = Cast<USkylineChaseCameraUpdater>(CameraData);
		
		FFocusTargets FocusTargets;

		#if EDITOR
		if(CameraData.Type == EHazeCameraUpdaterType::EditorPreview)
		{
			FocusTargets = FocusTargetComponent.GetEditorPreviewTargets();
		}
		else
		#endif
		{
			auto PlayerOwner = HazeUser.GetPlayerOwner();
			if(PlayerOwner != nullptr)
			{
				FocusTargets = FocusTargetComponent.GetFocusTargets(PlayerOwner);
			}
		}	

		Updater.InitSettings(CameraSpline, SplineFollowSettings);
		Updater.PlaceAtTargetLocation(FocusTargets);
		Updater.LookInSplineRotationAtFocusTargetSplineLocation(FocusTargets);
		Updater.ApplyKeepInViewToLocation(HazeUser, FocusTargets);

		// Fill in the special values
		PitchTweakerComponent.GetSettings(Updater.PitchData);
		HeightTweakerComponent.GetSettings(Updater.HeightData);
	}
}

UCLASS(NotBlueprintable)
class USkylineChaseCameraUpdater : UCameraSplineUpdater
{
	FSkylineChaseCameraPitchTweakerUserData PitchData;
	FSkylineChaseCameraHeightTweakerUserData HeightData;

	FHazeAcceleratedFloat AccPitchOffset;
	FHazeAcceleratedFloat AccHeightOffset;

	UFUNCTION(BlueprintOverride)
	void Copy(const UHazeCameraUpdater SourceBase)
	{
		Super::Copy(SourceBase);

		auto Source = Cast<USkylineChaseCameraUpdater>(SourceBase);
		PitchData = Source.PitchData;
		HeightData = Source.HeightData;
		AccPitchOffset = Source.AccPitchOffset;
		AccHeightOffset = Source.AccHeightOffset;
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraSnap(FHazeCameraTransform& OutResult)
	{
		Super::OnCameraSnap(OutResult);

		AccPitchOffset.SnapTo(PitchData.GetTargetPitchOffset(OutResult));
		AccHeightOffset.SnapTo(HeightData.GetTargetHeightOffset(OutResult));
		
		OutResult.ViewRotation = FRotator(AccPitchOffset.Value, 0.0, 0.0).Compose(OutResult.ViewRotation);

		FVector NewLoc = OutResult.ViewLocation;
		NewLoc.Z += AccHeightOffset.Value;
		OutResult.ViewLocation = NewLoc;
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraUpdate(float DeltaSeconds, FHazeCameraTransform& OutResult)
	{
		Super::OnCameraUpdate(DeltaSeconds, OutResult);

		AccHeightOffset.AccelerateTo(HeightData.GetTargetHeightOffset(OutResult), HeightData.AccelerationDuration, DeltaSeconds);
		AccPitchOffset.AccelerateTo(PitchData.GetTargetPitchOffset(OutResult), PitchData.AccelerationDuration, DeltaSeconds);

		OutResult.ViewRotation = FRotator(AccPitchOffset.Value, 0.0, 0.0).Compose(OutResult.ViewRotation);

		FVector NewLoc = OutResult.ViewLocation;
		NewLoc.Z += AccHeightOffset.Value;
		OutResult.ViewLocation = NewLoc;	
	}
}

struct FSkylineChaseCameraHeightTweakerUserData
{
	float MinHeight = 0.0;
	float MaxHeight = 200.0;
	float MinPlayerDepth = 100.0;
	float MaxPlayerDepth = 600.0;
	float AccelerationDuration = 1.0;

	float GetTargetHeightOffset(FHazeCameraTransform CameraWorldTransform) const
	{
		if ((Game::Mio == nullptr) || (Game::Zoe == nullptr))
			return MinHeight;

		FVector Forward = CameraWorldTransform.ViewRotation.ForwardVector;
		float Depth = Math::Abs(Forward.DotProduct(Game::Mio.ActorLocation - Game::Zoe.ActorLocation));
		if (Game::Mio.IsPlayerDead() || Game::Zoe.IsPlayerDead())
			Depth = 0.0;

		return Math::GetMappedRangeValueClamped(FVector2D(MinPlayerDepth, MaxPlayerDepth), FVector2D(MinHeight, MaxHeight), Depth);
	}
}

class USkylineChaseCameraHeightTweakerComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	float MinHeight = 0.0;

	UPROPERTY(EditAnywhere)
	float MaxHeight = 200.0;

	UPROPERTY(EditAnywhere)
	float MinPlayerDepth = 100.0;

	UPROPERTY(EditAnywhere)
	float MaxPlayerDepth = 600.0;

	UPROPERTY(EditAnywhere)
	float AccelerationDuration = 1.0;

	void GetSettings(FSkylineChaseCameraHeightTweakerUserData& Out) const
	{
		Out.MinHeight = MinHeight;
		Out.MaxHeight = MaxHeight;
		Out.MinPlayerDepth = MinPlayerDepth;
		Out.MaxPlayerDepth = MaxPlayerDepth;
		Out.AccelerationDuration = AccelerationDuration;
	}
}

struct FSkylineChaseCameraPitchTweakerUserData
{
	float MinPitch = 0.0;
	float MaxPitch = 200.0;
	float MinPlayerDepth = 100.0;
	float MaxPlayerDepth = 600.0;
	float AccelerationDuration = 1.0;

	float GetTargetPitchOffset(FHazeCameraTransform CameraWorldTransform) const
	{
		if ((Game::Mio == nullptr) || (Game::Zoe == nullptr))
			return MinPitch;

		FVector Forward = CameraWorldTransform.ViewRotation.ForwardVector;
		float Depth = Math::Abs(Forward.DotProduct(Game::Mio.ActorLocation - Game::Zoe.ActorLocation));
		if (Game::Mio.IsPlayerDead() || Game::Zoe.IsPlayerDead())
			Depth = 0.0;
				
		return Math::GetMappedRangeValueClamped(FVector2D(MinPlayerDepth, MaxPlayerDepth), FVector2D(MinPitch, MaxPitch), Depth);
	}
}


class USkylineChaseCameraPitchTweakerComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	float MinPitch = 0.0;

	UPROPERTY(EditAnywhere)
	float MaxPitch = -30.0;

	UPROPERTY(EditAnywhere)
	float MinPlayerDepth = 400.0;

	UPROPERTY(EditAnywhere)
	float MaxPlayerDepth = 2000.0;

	UPROPERTY(EditAnywhere)
	float AccelerationDuration = 1.0;

	void GetSettings(FSkylineChaseCameraPitchTweakerUserData& Out) const
	{
		Out.MinPitch = MinPitch;
		Out.MaxPitch = MaxPitch;
		Out.MinPlayerDepth = MinPlayerDepth;
		Out.MaxPlayerDepth = MaxPlayerDepth;
		Out.AccelerationDuration = AccelerationDuration;
	}
}

