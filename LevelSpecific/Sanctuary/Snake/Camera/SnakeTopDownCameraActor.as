UCLASS(hideCategories="Rendering Cooking Input Actor LOD AssetUserData Debug Collision InternalHiddenObjects")
class ASnakeTerrainCameraActor : AHazeCameraActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(OverrideComponent = Camera, ShowOnActor)
	UHazeCameraComponent Camera;
	default Camera.CameraUpdaterType = USnakeTerrainCameraUpdater;
	default Camera.bHasKeepInViewSettings = true;

	UPROPERTY(DefaultComponent)
	UCameraSnakeTerrainRotatorComponent TopDownRotator;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UCameraWeightedTargetComponent FocusTargetContainer;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FocusTargetComponent;
	default FocusTargetComponent.SetRelativeLocation(FVector(200.0, 0.0, 0.0));

	UFUNCTION(BlueprintOverride)
	void PrepareUpdaterForUser(const UHazeCameraUserComponent HazeUser, UHazeCameraUpdater CameraData, FHazeCameraTransform CameraTransform) const
	{
		auto Updater = Cast<USnakeTerrainCameraUpdater>(CameraData);
		auto& Settings = Updater.UpdaterSettings;
	
		#if EDITOR
		if(CameraData.Type == EHazeCameraUpdaterType::EditorPreview)
		{
			Updater.FocusTargets = FocusTargetContainer.GetEditorPreviewTargets();
		}
		else
		#endif
		{
			auto PlayerOwner = HazeUser.GetPlayerOwner();
			if(PlayerOwner != nullptr)
			{
				Updater.FocusTargets = FocusTargetContainer.GetFocusTargets(PlayerOwner);
			}
		}	

		Settings.Init(HazeUser);
		Updater.UseFocusLocation();	

		// Fill in the special values
		TopDownRotator.GetSettings(Updater.TerrainRotationSettings);

		USanctuarySnakeRiderComponent RiderComp = USanctuarySnakeRiderComponent::Get(HazeUser.Owner);	
	 	auto SnakeComp = USanctuarySnakeComponent::Get(RiderComp.Snake);
		Updater.SnakeCompWorldUp = SnakeComp.WorldUp;
		Updater.bHasNoScreen = HazeUser.HasNoScreen();
		Updater.OtherPlayerViewRotation = HazeUser.GetOtherPlayer().ViewRotation;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FHazeCameraWeightedFocusTargetInfo Focus;
		Focus.SetFocusToComponent(FocusTargetComponent);
		FocusTargetContainer.AddFocusTarget(Focus, this);
		FocusTargetComponent.DetachFromParent();
	}
}


UCLASS(NotBlueprintable)
class USnakeTerrainCameraUpdater : UCameraFocusTargetUpdater
{
	FVector SnakeCompWorldUp;
	FRotator OtherPlayerViewRotation;
	bool bHasNoScreen = false;

	FSnakeTerrainRotatorUserData TerrainRotationSettings;
	FHazeAcceleratedRotator Rotation;
	FHazeAcceleratedFloat AccelerationDuration;

	UFUNCTION(BlueprintOverride)
	void Copy(const UHazeCameraUpdater SourceBase)
	{
		Super::Copy(SourceBase);

		auto Source = Cast<USnakeTerrainCameraUpdater>(SourceBase);
		SnakeCompWorldUp = Source.SnakeCompWorldUp;
		OtherPlayerViewRotation = Source.OtherPlayerViewRotation;
		bHasNoScreen = Source.bHasNoScreen;
		TerrainRotationSettings = Source.TerrainRotationSettings;
		Rotation = Source.Rotation;
		AccelerationDuration = Source.AccelerationDuration;
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraSnap(FHazeCameraTransform& OutResult)
	{
		Super::OnCameraSnap(OutResult);

		float TargetDuration = TerrainRotationSettings.FlatRotationDuration;
		Rotation.SnapTo(TerrainRotationSettings.GetTargetRotation(SnakeCompWorldUp, OutResult.ViewRotation, OutResult.PivotLocation, TargetDuration));
		AccelerationDuration.SnapTo(TargetDuration);

		OutResult.ViewRotation = Rotation.Value;
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraUpdate(float DeltaSeconds, FHazeCameraTransform& OutResult)
	{
		Super::OnCameraUpdate(DeltaSeconds, OutResult);

		//FSnakeTerrainRotatorUserData& Data = UserData[User];
		if (bHasNoScreen)
		{
			Rotation.SnapTo(OtherPlayerViewRotation);
		}
		else
		{
			float TargetDuration = TerrainRotationSettings.FlatRotationDuration;
			FRotator TargetRot = TerrainRotationSettings.GetTargetRotation(SnakeCompWorldUp, OutResult.ViewRotation, OutResult.PivotLocation, TargetDuration);
			float Duration = AccelerationDuration.AccelerateTo(TargetDuration, 2.0, DeltaSeconds);
			Rotation.AccelerateTo(TargetRot, Duration, DeltaSeconds);
		}

		OutResult.ViewRotation = Rotation.Value;
	}
}



struct FSnakeTerrainRotatorUserData
{
	float FlatRotationDuration = 10.0;
	float CurvedRotationDuration = 1.0;
	FRotator RotationOffset = FRotator(0.0, 0.0, 0.0);
	float ProbeOffset = 600.0; 
	float ProbeHeight = 300.0;
	float ProbeDepth = 2000.0;

	

	FRotator GetTargetRotation(FVector SnakeWorldUp, FRotator ViewRot, FVector ActorLocation, float& OutTargetDuration)
	{
// #if TEST
// 		if (Cast<AHazeActor>(User.Owner).IsAnyCapabilityActive(CameraTags::CameraDebugCamera))
// 			return (-SnakeComp.WorldUp).Rotation().Compose(RotationOffset);
// #endif

		// Probe to the left, right, above and below of user in camera space
		// Snake moves in a convex world, so any missed probe means we are near a corner 
		// and should rotate around the outside of that corner
		//FRotator ViewRot = User.ViewRotation;
		FRotator ProbeRot = (-SnakeWorldUp).Rotation();
		FVector ProbeForward = ProbeRot.ForwardVector;
		FVector ProbeRight = ProbeRot.RightVector;
		FVector ProbeUp = ViewRot.UpVector;
		FVector BaseLoc = ActorLocation - ProbeForward * ProbeHeight;
		FVector ProbeReach = ProbeForward * (ProbeDepth * ProbeHeight);

		// FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::WorldGeometry);
		// Trace.UseLine();
		// Trace.SetTraceComplex(false);
		// FHitResult RightProbe = Trace.QueryTraceSingle(BaseLoc + ProbeRight * ProbeOffset, BaseLoc + ProbeRight * ProbeOffset + ProbeReach);		
		// FHitResult LeftProbe = Trace.QueryTraceSingle(BaseLoc - ProbeRight * ProbeOffset, BaseLoc - ProbeRight * ProbeOffset + ProbeReach);		
		// FHitResult UpProbe = Trace.QueryTraceSingle(BaseLoc + ProbeUp * ProbeOffset, BaseLoc + ProbeUp * ProbeOffset + ProbeReach);		
		// FHitResult DownProbe = Trace.QueryTraceSingle(BaseLoc - ProbeUp * ProbeOffset, BaseLoc - ProbeUp * ProbeOffset + ProbeReach);		

		FRotator TargetRot = ViewRot;

		// if (!RightProbe.bBlockingHit && !LeftProbe.bBlockingHit)
		// {
		// 	// Both left/right probes miss, we're on a thin pole. Fall back to movement world up. 
		// 	TargetRot = (-SnakeComp.WorldUp).Rotation(); 
		// }
		// else if (!RightProbe.bBlockingHit)
		// {
		// 	// Corner to the right, yaw left
		// 	float InwardYaw = (-SnakeComp.WorldUp.ConstrainToPlane(ProbeUp)).Rotation().Yaw;
		// 	TargetRot.Yaw = InwardYaw - 45.0;
		// }
		// else if (!LeftProbe.bBlockingHit)
		// {
		// 	// Corner to the left, yaw right
		// 	float InwardYaw = (-SnakeComp.WorldUp.ConstrainToPlane(ProbeUp)).Rotation().Yaw;
		// 	TargetRot.Yaw = InwardYaw + 45.0;
		// }
		// else
		{
			TargetRot = (-SnakeWorldUp).Rotation();
		}

		float ViewDot = ViewRot.ForwardVector.DotProduct(ProbeForward);
		OutTargetDuration = Math::Lerp(CurvedRotationDuration, FlatRotationDuration, Math::Clamp(Math::Square(ViewDot), 0.0, 1.0));
// PrintToScreenScaled("Dot " + ViewDot);		
// PrintToScreenScaled("Target " + OutTargetDuration);
// PrintToScreenScaled("Duration " + UserData[User].AccelerationDuration.Value);		

		TargetRot = TargetRot.Compose(RotationOffset);

// #if EDITOR
// 		bHazeEditorOnlyDebugBool = true;
// 		if (bHazeEditorOnlyDebugBool)
// 		{
// 			// Debug::DrawDebugLine(BaseLoc + ProbeRight * ProbeOffset, BaseLoc + ProbeRight * ProbeOffset + ProbeReach, (RightProbe.bBlockingHit ? FLinearColor::Yellow : FLinearColor::Green), 10.0);			
// 			// Debug::DrawDebugLine(BaseLoc - ProbeRight * ProbeOffset, BaseLoc - ProbeRight * ProbeOffset + ProbeReach, (LeftProbe.bBlockingHit ? FLinearColor::Yellow : FLinearColor::Green), 10.0);			
// 			// Debug::DrawDebugLine(BaseLoc + ProbeUp * ProbeOffset, BaseLoc + ProbeUp * ProbeOffset + ProbeReach, (UpProbe.bBlockingHit ? FLinearColor::Yellow : FLinearColor::Green), 10.0);			
// 			// Debug::DrawDebugLine(BaseLoc - ProbeUp * ProbeOffset, BaseLoc - ProbeUp * ProbeOffset + ProbeReach, (DownProbe.bBlockingHit ? FLinearColor::Yellow : FLinearColor::Green), 10.0);			
// 		}
// #endif
		return TargetRot;
	}
}

class UCameraSnakeTerrainRotatorComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	float FlatRotationDuration = 10.0;

	UPROPERTY(EditAnywhere)
	float CurvedRotationDuration = 1.0;

	UPROPERTY(EditAnywhere)
	FRotator RotationOffset = FRotator(0.0, 0.0, 0.0);
	
	// How far away in view horizontal plane we probe
	UPROPERTY(EditAnywhere)
	float ProbeOffset = 600.0; 

	// How far above user location we start probe
	UPROPERTY(EditAnywhere)
	float ProbeHeight = 300.0;

	// How far below user height we probe (i.e. total trace length is ProbeHeight + ProbeDepth)
	UPROPERTY(EditAnywhere)
	float ProbeDepth = 2000.0;

	void GetSettings(FSnakeTerrainRotatorUserData& Out) const
	{
		Out.FlatRotationDuration = FlatRotationDuration;
		Out.CurvedRotationDuration = CurvedRotationDuration;
		Out.RotationOffset = RotationOffset;
		Out.ProbeOffset = ProbeOffset;
		Out.ProbeHeight = ProbeHeight;
		Out.ProbeDepth = ProbeDepth;
	}
};
