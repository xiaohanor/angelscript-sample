class ASolarFlareSolarPanel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ControlPanelRoot1;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ControlPanelRoot2;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent PoleMesh;

	UPROPERTY(DefaultComponent)
	USceneComponent PanelRoot;

	UPROPERTY(DefaultComponent, Attach = ControlPanelRoot1)
	UInteractionComponent PanelMovingInteractionComp;
	default PanelMovingInteractionComp.UsableByPlayers = EHazeSelectPlayer::Both;
	default PanelMovingInteractionComp.InteractionCapability = n"SolarFlareSolarPanelMovingCapability";

	UPROPERTY(DefaultComponent, Attach = ControlPanelRoot2)
	UInteractionComponent PanelRotatingInteractionComp;
	default PanelRotatingInteractionComp.UsableByPlayers = EHazeSelectPlayer::Both;	
	default PanelRotatingInteractionComp.InteractionCapability = n"SolarFlareSolarPanelRotationCapability";

#if EDITOR
	UPROPERTY(DefaultComponent)
	USolarFlareSolarPanelDummyComp DummyComp;
#endif

	UPROPERTY(EditAnywhere, Category = "Animation")
	FHazePlaySlotAnimationParams InteractionAnimation;
	default InteractionAnimation.PlayRate = 1.0;
	default InteractionAnimation.bLoop = true;

	UPROPERTY(EditAnywhere)
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY(EditAnywhere, Category = "Moving Settings")
	bool bEnableMovingInteraction = true; 

	UPROPERTY(EditAnywhere, Category = "Moving Settings", Meta = (EditCondition = "bEnableMovingInteraction", EditConditionHides))
	float PanelMoveSpeed = 200;

	UPROPERTY(EditAnywhere, Category = "Moving Settings", Meta = (EditCondition = "bEnableMovingInteraction", EditConditionHides))
	float PanelMoveMax = 500;

	UPROPERTY(EditAnywhere, Category = "Moving Settings", Meta = (EditCondition = "bEnableMovingInteraction", EditConditionHides))
	float PanelMoveMin = 0.0;

	UPROPERTY(EditAnywhere, Category = "Moving Settings", Meta = (EditCondition = "bEnableMovingInteraction", EditConditionHides))
	bool bMoveBackWhenNotInteracting = true;

	UPROPERTY(EditAnywhere, Category = "Moving Settings", Meta = (EditCondition = "bEnableMovingInteraction && bMoveBackWhenNotInteracting", EditConditionHides))
	float MoveBackSpeed = 160;

	UPROPERTY(EditAnywhere, Category = "Rotation Settings")
	bool bEnableRotationInteraction = true;

	UPROPERTY(EditAnywhere, Category = "Rotation Settings", Meta = (EditCondition = "bEnableRotationInteraction", EditConditionHides))
	float PanelRotationSpeed = 100;

	UPROPERTY(EditAnywhere, Category = "Rotation Settings", Meta = (EditCondition = "bEnableRotationInteraction", EditConditionHides))
	bool bConstrictRotation = true;

	UPROPERTY(EditAnywhere, Category = "Rotation Settings", Meta = (EditCondition = "bConstrictRotation && bEnableRotationInteraction", EditConditionHides))
	float PanelRotationMax = 200;

	UPROPERTY(EditAnywhere, Category = "Rotation Settings", Meta = (EditCondition = "bConstrictRotation && bEnableRotationInteraction", EditConditionHides))
	float PanelRotationMin = 40.0;

	UPROPERTY(EditAnywhere, Category = "Rotation Settings", Meta = (EditCondition = "bEnableRotationInteraction", EditConditionHides))
	bool bRotateBackWhenNotInteracting = true;

	UPROPERTY(EditAnywhere, Category = "Rotation Settings", Meta = (EditCondition = "bEnableRotationInteraction && bRotateBackWhenNotInteracting", EditConditionHides))
	float RotateBackSpeed = 40;

	FVector StartPanelRelativeLocation;
	FRotator StartPanelRelativeRotation;

	bool bMoveInteractionIsActive = false;
	bool bRotationInteractionIsActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(!bEnableMovingInteraction)
		{
			TArray<USceneComponent> Children;
			ControlPanelRoot1.GetChildrenComponents(true, Children);
			for(auto Child : Children)
			{
				Child.AddComponentVisualsBlocker(this);
				Child.AddComponentTickBlocker(this);

				auto Primitive = Cast<UPrimitiveComponent>(Child);
				if(Primitive != nullptr)
					Primitive.AddComponentCollisionBlocker(this);
			}
			PanelMovingInteractionComp.Disable(this);
		}

		if(!bEnableRotationInteraction)
		{
			TArray<USceneComponent> Children;
			ControlPanelRoot2.GetChildrenComponents(true, Children);
			for(auto Child : Children)
			{
				Child.AddComponentVisualsBlocker(this);
				Child.AddComponentTickBlocker(this);

				auto Primitive = Cast<UPrimitiveComponent>(Child);
				if(Primitive != nullptr)
					Primitive.AddComponentCollisionBlocker(this);
			}
			PanelRotatingInteractionComp.Disable(this);
		}


		PanelRoot.RelativeLocation = GetConstrictedLocation(PanelRoot.RelativeLocation);

		if(bConstrictRotation)
			PanelRoot.RelativeRotation = GetConstrictedRotation(PanelRoot.RelativeRotation);

		StartPanelRelativeLocation = PanelRoot.RelativeLocation;
		StartPanelRelativeRotation = PanelRoot.RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bMoveBackWhenNotInteracting
		&& !bMoveInteractionIsActive)
			PanelRoot.RelativeLocation = Math::VInterpConstantTo(PanelRoot.RelativeLocation, StartPanelRelativeLocation, DeltaSeconds, MoveBackSpeed);

		if(bRotateBackWhenNotInteracting
		&& !bRotationInteractionIsActive)
			PanelRoot.RelativeRotation = Math::RInterpConstantTo(PanelRoot.RelativeRotation, StartPanelRelativeRotation, DeltaSeconds, RotateBackSpeed);
	}

	void ApplySolarPanelCameraSettings(AHazePlayerCharacter Player, bool bCanApply)
	{
		if (CameraSettings == nullptr)
			return;

		if (bCanApply)
			Player.ApplyCameraSettings(CameraSettings, 2.5, this);
		else
			Player.ClearCameraSettingsByInstigator(this, 2.5);
	}

	FVector GetConstrictedLocation(FVector DesiredLocation) const
	{
		FVector ConstrictedLocation = DesiredLocation;
		ConstrictedLocation.Z = Math::Clamp(DesiredLocation.Z, PanelMoveMin, PanelMoveMax);

		return ConstrictedLocation;
	}

	FRotator GetConstrictedRotation(FRotator DesiredRotation) const
	{
		FRotator ConstrictedRotation = DesiredRotation;
		ConstrictedRotation.Yaw = Math::ClampAngle(ConstrictedRotation.Yaw, 360 - PanelRotationMax, PanelRotationMin);

		return ConstrictedRotation;
	}

	UFUNCTION(CallInEditor)
	void ConstrictPanelRoot()
	{
		PanelRoot.RelativeLocation = GetConstrictedLocation(PanelRoot.RelativeLocation);
		PanelRoot.RelativeRotation = GetConstrictedRotation(PanelRoot.RelativeRotation);
	}
};

#if EDITOR
class USolarFlareSolarPanelDummyComp : UActorComponent {}
class USolarFlareSolarPanelVisualizerComp : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USolarFlareSolarPanelDummyComp;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto VisualizeComponent = Cast<USolarFlareSolarPanelDummyComp>(Component);
        if (VisualizeComponent == nullptr)
            return;
		
		ASolarFlareSolarPanel Panel = Cast<ASolarFlareSolarPanel>(Component.Owner);

		if(Panel.bEnableMovingInteraction)
		{
			DrawWireSphere(Panel.PanelRoot.WorldLocation, 10, FLinearColor(0.54, 0.54, 0.54), 5, 12, false);

			FVector MinLocation = Panel.Root.WorldLocation + (Panel.Root.UpVector * Panel.PanelMoveMin);
			float DistToMinLocationSqrd = MinLocation.DistSquared(Panel.PanelRoot.WorldLocation);
			if(!Math::IsNearlyZero(DistToMinLocationSqrd))
				DrawArrow(Panel.PanelRoot.WorldLocation, MinLocation, FLinearColor::Black, 7, 10, false);

			FVector MaxLocation = Panel.Root.WorldLocation + (Panel.Root.UpVector * Panel.PanelMoveMax);
			float DistToMaxLocationSqrd = MaxLocation.DistSquared(Panel.PanelRoot.WorldLocation);
			if(!Math::IsNearlyZero(DistToMaxLocationSqrd))
				DrawArrow(Panel.PanelRoot.WorldLocation, MaxLocation, FLinearColor::White, 7, 10, false);
		}


		if(Panel.bEnableRotationInteraction
		&& Panel.bConstrictRotation)
		{
			DrawArrow(Panel.PanelRoot.WorldLocation, Panel.PanelRoot.WorldLocation + Panel.PanelRoot.RelativeRotation.RightVector * 100, FLinearColor::Red, 10, 3, false);

			FVector PanelForwardRotatedHalfTowardsRotationMax = Panel.ActorRightVector.RotateAngleAxis(-Panel.PanelRotationMax * 0.5, Panel.ActorUpVector);
			DrawArc(Panel.PanelRoot.WorldLocation, Panel.PanelRotationMax, 100, PanelForwardRotatedHalfTowardsRotationMax, FLinearColor::White, 4, FVector::UpVector, 32, 20, true);

			FVector PanelForwardRotatedHalfTowardsRotationMin = Panel.ActorRightVector.RotateAngleAxis(Panel.PanelRotationMin * 0.5, Panel.ActorUpVector);
			DrawArc(Panel.PanelRoot.WorldLocation, Panel.PanelRotationMin, 100, PanelForwardRotatedHalfTowardsRotationMin, FLinearColor::Black, 4, FVector::UpVector, 32, 20, true);
		}
	}
}
#endif
