UCLASS(hideCategories="Rendering Cooking Input Actor LOD AssetUserData Debug Collision, InternalHiddenObjects")
class ASanctuaryBossSlideCamera : AHazeCameraActor
{   
    UPROPERTY(OverrideComponent = Camera, ShowOnActor)
    USplineFollowCamera Camera;
	default Camera.bSnapOnTeleport = false;
	default Camera.bHasKeepInViewSettings = true;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UCameraWeightedTargetComponent FocusTargetComponent;

	UPROPERTY(DefaultComponent)
	USceneComponent FocusTarget;

	UPROPERTY(EditAnywhere, Category = "CameraOptions", Meta = (ShowOnlyInnerProperties))
	FCameraSplineFollowUserSettings SplineFollowSettings;

	UPROPERTY(EditAnywhere, Category = "CameraOptions")
	FVector FocusTargetOffset = FVector(0.0, 0.0, -300.0);

	UPROPERTY(EditAnywhere, Category = "CameraOptions")
	AActor ActorWithSpline;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		#if EDITOR
		if(ActorWithSpline != nullptr)
		{
			// We want to debug draw the focus locations on the spline
			FocusTargetComponent.EditorDebugSpline = UHazeSplineComponent::Get(ActorWithSpline);
			SplineFollowSettings.SetEditorEditConditions(ECameraSplineLocationTargetType::PlaceAtTargetSplineLocation, ECameraSplineRotationTargetType::LookAtFocusTarget);
		}
		#endif
	}

	UFUNCTION(BlueprintOverride)
	void PrepareUpdaterForUser(const UHazeCameraUserComponent HazeUser, UHazeCameraUpdater CameraData, FHazeCameraTransform CameraTransform) const
	{
		auto SplineData = Cast<UCameraSplineUpdater>(CameraData);
	
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

		if(ActorWithSpline != nullptr)
		{
			SplineData.InitSettings(UHazeSplineComponent::Get(ActorWithSpline), SplineFollowSettings);
		}

		SplineData.PlaceAtTargetSplineLocation(FocusTargets);
		SplineData.LookAtFocusTarget(FocusTargets);
		SplineData.ApplyKeepInViewToLocation(HazeUser);
	}


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// if (ActorWithSpline != nullptr)
		// {
		// 	Spline = UHazeSplineComponent::Get(ActorWithSpline);		
		// }

		FHazeCameraWeightedFocusTargetInfo FocusTargetinfo;
		FocusTargetinfo.SetFocusToComponent(FocusTarget);
		//FocusTargetinfo.AdvancedSettings.LocalOffset = FocusTargetOffset;
		FocusTargetComponent.AddFocusTarget(FocusTargetinfo, this);
		UpdateTargetTransform();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateTargetTransform();
	}

	void UpdateTargetTransform()
	{
		if (ActorWithSpline != nullptr)
		{
			auto Spline = UHazeSplineComponent::Get(ActorWithSpline);

			FSplinePosition TargetPosition;
			for (auto Player : Game::Players)
			{
				auto PlayerSplinePosition = Spline.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);
				if (!TargetPosition.IsValid() || TargetPosition.CanReach(PlayerSplinePosition, ESplineMovementPolarity::Positive))
					TargetPosition = PlayerSplinePosition;
			}

			FTransform Transform = TargetPosition.WorldTransform;
			Transform.Location = Transform.Location + Transform.TransformVectorNoScale(FocusTargetOffset);

			FocusTarget.WorldTransform = Transform;

			//	Debug::DrawDebugPoint(TargetPosition.WorldLocation, 100.0, FLinearColor::Yellow, 0.0);
			//	Debug::DrawDebugPoint(FocusTarget.WorldLocation, 100.0, FLinearColor::Green, 0.0);		
		}
	}
}