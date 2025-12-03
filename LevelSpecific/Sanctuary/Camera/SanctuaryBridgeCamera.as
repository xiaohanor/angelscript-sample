UCLASS(hideCategories="Rendering Cooking Input Actor LOD AssetUserData Debug Collision InternalHiddenObjects")
class ASanctuaryBridgeCameraActor : AHazeCameraActor
{
    UPROPERTY(OverrideComponent = Camera, ShowOnActor)
	UFocusTargetCamera Camera;
	default Camera.CameraUpdaterType = USanctuaryBridgeCameraUpdater;
	default Camera.bSnapOnTeleport = false;
	default Camera.bHasKeepInViewSettings = true;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USanctuaryBridgeCameraPitchTweakerComponent PitchTweakerComponent;

    UPROPERTY(DefaultComponent, ShowOnActor)
	USanctuaryBridgeCameraHeightTweakerComponent HeightTweakerComponent;	

	UPROPERTY(DefaultComponent, ShowOnActor)
	UCameraWeightedTargetComponent FocusTargetComponent;
	default FocusTargetComponent.EmptyTargetDefaultType = ECameraWeightedTargetEmptyInitType::DefaultToBothPlayers;

	// How much the camera is currently allowed to move towards the target value. Normally (1,1,1), if (0,0,0) it's locked in all axes, if (1,1,0) it's locked upwards/downwards.
    UPROPERTY(EditAnywhere, Category = "CameraOptions", AdvancedDisplay)
    FVector AxisFreedomFactor = FVector(1.0, 0.0, 1.0);

	// If set, the camera will use this focus target as it's center to lock axes relative to. If not set, camera will always be locked relative to current location.
	UPROPERTY(EditAnywhere, Category = "CameraOptions", AdvancedDisplay, meta = (EditCondition="bInternalUseFreedomFactor"))
	FHazeCameraWeightedFocusTargetInfo AxisFreedomCenter;
	default AxisFreedomCenter.SetFocusToPlayerMio();

	UFUNCTION(BlueprintOverride)
	void PrepareUpdaterForUser(const UHazeCameraUserComponent HazeUser, UHazeCameraUpdater CameraData, FHazeCameraTransform CameraTransform) const
	{
		auto Updater = Cast<USanctuaryBridgeCameraUpdater>(CameraData);
		auto& Settings = Updater.UpdaterSettings;

		#if EDITOR
		if(CameraData.Type == EHazeCameraUpdaterType::EditorPreview)
		{
			Updater.FocusTargets = FocusTargetComponent.GetEditorPreviewTargets();

			if (AxisFreedomFactor != FVector::OneVector)
			{
				auto EditorAxisFreedomCenter = FocusTargetComponent.GetEditorPreviewFocus(AxisFreedomCenter);
				Settings.SetAxisFreedomFactor(AxisFreedomFactor, EditorAxisFreedomCenter.Location, Camera);
			}
		}
		else
		#endif
		{
			auto PlayerOwner = HazeUser.GetPlayerOwner();
			if(PlayerOwner != nullptr)
			{
				Updater.FocusTargets = FocusTargetComponent.GetFocusTargets(PlayerOwner);
				
				if (AxisFreedomFactor != FVector::OneVector)
				{
					FHazeCameraWeightedFocusTargetInfo RuntimeAxisFreedomCenter = AxisFreedomCenter;
					RuntimeAxisFreedomCenter.WorldOffset = (Game::Zoe.ActorLocation - Game::Mio.ActorLocation) * 0.5;
					Settings.SetAxisFreedomFactor(AxisFreedomFactor, RuntimeAxisFreedomCenter.GetFocusLocation(PlayerOwner), Camera);
				}
			}
		}	

		
		Settings.Init(HazeUser);
		Updater.UseFocusLocation();	

		// Fill in the special values
		PitchTweakerComponent.GetSettings(Updater.PitchData);
		HeightTweakerComponent.GetSettings(Updater.HeightData);
	}
}

/**
 * A regular spline follow camera
 */
 
UCLASS(NotBlueprintable)
class USanctuaryBridgeCameraUpdater : UCameraFocusTargetUpdater
{
	FSanctuaryBridgeCameraPitchTweakerUserData PitchData;
	FSanctuaryBridgeCameraHeightTweakerUserData HeightData;

	FHazeAcceleratedFloat AccPitchOffset;
	FHazeAcceleratedFloat AccHeightOffset;

	UFUNCTION(BlueprintOverride)
	void Copy(const UHazeCameraUpdater SourceBase)
	{
		Super::Copy(SourceBase);

		auto Source = Cast<USanctuaryBridgeCameraUpdater>(SourceBase);
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

struct FSanctuaryBridgeCameraHeightTweakerUserData
{
	float MinHeight = 0.0;
	float MaxHeight = 200.0;
	float MinPlayerDepth = 100.0;
	float MaxPlayerDepth = 600.0;
	float AccelerationDuration = 1.0;
	

    float GetTargetHeightOffset(FHazeCameraTransform CameraWorldTransform)
    {
        //FVector Forward = Owner.ActorForwardVector;
		FVector Forward = CameraWorldTransform.PivotRotation.ForwardVector;
        float Depth = Math::Abs(Forward.DotProduct(Game::Mio.ActorLocation - Game::Zoe.ActorLocation));
        return Math::GetMappedRangeValueClamped(FVector2D(MinPlayerDepth, MaxPlayerDepth), FVector2D(MinHeight, MaxHeight), Depth);
    }
}

class USanctuaryBridgeCameraHeightTweakerComponent : UActorComponent
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

	
	void GetSettings(FSanctuaryBridgeCameraHeightTweakerUserData& Out) const
	{
		Out.MinHeight = MinHeight;
		Out.MaxHeight = MaxHeight;
		Out.MinPlayerDepth = MinPlayerDepth;
		Out.MaxPlayerDepth = MaxPlayerDepth;
		Out.AccelerationDuration = AccelerationDuration;
	}
}


struct FSanctuaryBridgeCameraPitchTweakerUserData
{
	float MinPitch = 0.0;
	float MaxPitch = 200.0;
	float MinPlayerDepth = 100.0;
	float MaxPlayerDepth = 600.0;
	float AccelerationDuration = 1.0;

    float GetTargetPitchOffset(FHazeCameraTransform CameraWorldTransform)
    {
       // FVector Forward = Owner.ActorForwardVector;
	    FVector Forward = CameraWorldTransform.PivotRotation.ForwardVector;
        float Depth = Math::Abs(Forward.DotProduct(Game::Mio.ActorLocation - Game::Zoe.ActorLocation));
        return Math::GetMappedRangeValueClamped(FVector2D(MinPlayerDepth, MaxPlayerDepth), FVector2D(MinPitch, MaxPitch), Depth);
    }
}

class USanctuaryBridgeCameraPitchTweakerComponent : UActorComponent
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

	void GetSettings(FSanctuaryBridgeCameraPitchTweakerUserData& Out) const
	{
		Out.MinPitch = MinPitch;
		Out.MaxPitch = MaxPitch;
		Out.MinPlayerDepth = MinPlayerDepth;
		Out.MaxPlayerDepth = MaxPlayerDepth;
		Out.AccelerationDuration = AccelerationDuration;
	}
}