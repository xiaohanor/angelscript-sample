event void StartPoleClimb(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor);
event void StopPoleClimb(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor);
event void PoleDirectionExitEvent(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor, FVector JumpOutDirection);

UCLASS(Abstract)
class APoleClimbActor : AHazeActor
{
	access EditAndReadOnly = private, * (editdefaults, readonly);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Pole;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = RootComp)
	UPoleClimbEnterZone EnterZone;
	default EnterZone.bAlwaysShowShapeInEditor = false;

	UPROPERTY(DefaultComponent, Attach = RootComp, ShowOnActor)
	UPerchPointComponent PerchPointComp;

	UPROPERTY(DefaultComponent, Attach = PerchPointComp)
	UPerchEnterByZoneComponent PerchEnterZone;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = RootComp)
	UHazeMovablePlayerTriggerComponent TransferAssistTrigger;
	default TransferAssistTrigger.bVisible = false;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = PerchPointComp)
	UPerchPointDrawComponent PerchDrawComp;
#endif	

	UPROPERTY(EditAnywhere, Category = "Settings | PoleClimbDefaults")
	UHazeCameraSettingsDataAsset CameraSetting;

	UPROPERTY(EditAnywhere, Category = "Settings | PoleClimbDefaults")
	float JumpCameraImpulseStrength = 600.0;

	UPROPERTY(EditAnywhere, Category = "Settings | PoleClimbDefaults")
	float Height = 500.0;

	UPROPERTY(EditInstanceOnly, Category = "Settings | PoleClimbDefaults")
	EPoleType PoleType;

	//Acceleration downwards per second if not giving input
	UPROPERTY(EditInstanceOnly, Category = "Settings | PoleClimbDefaults", meta = (EditCondition="PoleType == EPoleType::Slippery", EditConditionHides))
	float IdleSlideAcceleration = 30.0;

	//Should you be allowed to climb up a slippery pole
	UPROPERTY(EditInstanceOnly, Category = "Settings | PoleClimbDefaults", meta = (EditCondition="PoleType == EPoleType::Slippery", EditConditionHides))
	bool bAllowClimbingUp = false;

	//Is player allowed to exit poleclimb when sliding down to the bottom
	UPROPERTY(EditAnywhere, Category = "Settings | PoleClimbDefaults")
	bool bAllowSlidingOff = true;

	UPROPERTY(EditAnywhere, Category = "Settings | PoleClimbDefaults")
	bool bAllowPerchOnTop = false;

	// Automatically turn around when the pole is first entered
	UPROPERTY(EditAnywhere, Category = "Settings | PoleClimbDefaults")
	bool bTurnAroundOnEnter = false;
	
	// Whether to allow any rotation around the pole at all
	UPROPERTY(EditAnywhere, AdvancedDisplay, Category = "Settings | PoleClimbDefaults")
	bool bAllowAnyRotation = true;

	// Whether to allow full 360 rotation, or only in static directions
	UPROPERTY(EditAnywhere, AdvancedDisplay, Category = "Settings | PoleClimbDefaults")
	bool bAllowFull360Rotation = true;

	// If true, the rotation will be towards the movement input, so you can rotate to the left/right in the camera direction
	UPROPERTY(EditAnywhere, AdvancedDisplay, Category = "Settings | PoleClimbDefaults", Meta = (EditCondition = "bAllowFull360Rotation", EditConditionHides))
	bool bFaceBackTowardsInputDirection = false;

	//If disabled you wont be able to rotate around pole in 2D poleclimbing (Entry angle defines where you climb)
	UPROPERTY(EditAnywhere, AdvancedDisplay, Category = "Settings | PoleClimbDefaults", Meta = (EditCondition = "false"))
	bool bAllow2DTurnaround = true;

	// If true the player will only be able to turn around on the pole climb in the four cardinal directions forward/back/right/left.
	UPROPERTY(EditAnywhere, AdvancedDisplay, Category = "Settings | PoleClimbDefaults", Meta = (EditCondition = "!bAllowFull360Rotation", EditConditionHides))
	bool bClimbInFourCardinalAngles = false;

	// This angle offset will offset all cardinal angles.
	UPROPERTY(EditAnywhere, AdvancedDisplay, Category = "Settings | PoleClimbDefaults", Meta = (EditCondition = "!bAllowFull360Rotation && bClimbInFourCardinalAngles", EditConditionHides))
	float CardinalAngleOffset = 0.0;

	// Add an extra rotation to the angle that the player climbs at
	UPROPERTY(EditAnywhere, AdvancedDisplay, Category = "Settings | PoleClimbDefaults", Meta = (EditCondition = "!bAllowFull360Rotation && !bClimbInFourCardinalAngles", EditConditionHides, Delta = "5", Units = "Degrees"))
	float ForwardClimbAngleRotation = 0.0;

	// Add an extra rotation to the angle that the player climbs at
	UPROPERTY(EditAnywhere, AdvancedDisplay, Category = "Settings | PoleClimbDefaults", Meta = (EditCondition = "!bAllowFull360Rotation && !bClimbInFourCardinalAngles", EditConditionHides, Delta = "5", Units = "Degrees"))
	float BackwardClimbAngleRotation = 0.0;

	//Should the player be detached from the pole if we impact something as a result of the pole actor moving
	UPROPERTY(EditAnywhere, AdvancedDisplay, Category = "Settings | PoleClimbDefaults")
	bool bDetachOnFollowImpact = true;

	//Should players be able to climb on the pole
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Settings | PoleClimbDefaults")
	access: EditAndReadOnly
	bool bEnabled = true;

	//Should this pole be Invalid if players world up doesnt align?
	UPROPERTY(EditAnywhere, Category = "Settings | PoleClimbDefaults")
	bool bShouldValidatePlayerPoleWorldUp = true;

	UPROPERTY(EditAnywhere, Category = "Settings", AdvancedDisplay)
	bool bCamSettingsShouldLinger = true;

	UPROPERTY(EditAnywhere, Category = "Settings | PoleClimbDefaults", meta = (EditCondition = "bShouldValidatePlayerPoleWorldUp", EditConditionHides))
	float UpVectorCutOffAngle = 5.0;
	
	UPROPERTY(EditAnywhere, Category = "Targetable | PoleClimbDefaults")	
	EHazeSelectPlayer UsableByPlayers = EHazeSelectPlayer::Both;

	// Whether to assist aim for transfering to this pole from other poles
	UPROPERTY(EditAnywhere, Category = "Pole Assist")	
	bool bEnablePoleTransferAssist = true;

	// Maximum transfer assist distance
	UPROPERTY(EditAnywhere, Category = "Pole Assist", Meta = (EditCondition = "bEnablePoleTransferAssist", EditConditionHides))	
	float MaxTransferAssistDistance = 1000.0;

	// Maximum transfer assist angle
	UPROPERTY(EditAnywhere, Category = "Pole Assist", Meta = (EditCondition = "bEnablePoleTransferAssist", EditConditionHides))	
	float MaxTransferAssistAngle = 45.0;

	// Whether to assist aim when air jumping or dashing nearby towards this pole
	UPROPERTY(EditAnywhere, Category = "Pole Assist")	
	bool bEnablePoleAirMoveAssist = true;

	// Maximum air jump or dash assist distance
	UPROPERTY(EditAnywhere, Category = "Pole Assist", Meta = (EditCondition = "bEnablePoleAirJumpToAssist", EditConditionHides))	
	float MaxAirMoveAssistDistance = 500.0;

	// Maximum air jump or dash assist angle
	UPROPERTY(EditAnywhere, Category = "Pole Assist", Meta = (EditCondition = "bEnablePoleAirJumpToAssist", EditConditionHides))	
	float MaxAirMoveAssistAngle = 45.0;

	// Whether to nudge the camera so the pole isn't in the center of the screen
	UPROPERTY(EditAnywhere, Category = "Camera Nudge")	
	bool bNudgeCameraAwayFromPoleTransfer = true;

	// How far off-center to nudge the other pole
	UPROPERTY(EditAnywhere, Category = "Camera Nudge", Meta = (EditCondition = "bNudgeCameraAwayFromPoleTransfer", EditConditionHides))	
	float NudgeCameraAngle = 10.0;

	default EnterZone.Shape.CapsuleRadius = 50;

	UPROPERTY()
	StartPoleClimb OnStartPoleClimb;
	UPROPERTY()
	StartPoleClimb OnEnterFinished;
	UPROPERTY()
	StartPoleClimb OnEnteredFromPerch;
	UPROPERTY()
	StopPoleClimb OnStopPoleClimb;
	UPROPERTY()
	PoleDirectionExitEvent OnJumpOff;
	UPROPERTY()
	PoleDirectionExitEvent OnCancel;
	UPROPERTY()
	PoleDirectionExitEvent OnPoleTurnaround;
	UPROPERTY()
	StopPoleClimb OnExitToPerch;

	UPROPERTY(EditAnywhere, Category = "Audio")
	UAudioPlayerHandTraceSettings AudioTraceSlideSettings;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "false"))
	bool bHasDecidedMobility = false;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorPlacedInEditor()
	{
		RootComp.Mobility = EComponentMobility::Static;
		Pole.Mobility = EComponentMobility::Static;
		bHasDecidedMobility = true;
	}
#endif

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		// Make the pole static if it's not attached to anything
		if (!bHasDecidedMobility)
		{
			if (RootComp.AttachParent == nullptr)
			{
				RootComp.Mobility = EComponentMobility::Static;
				Pole.Mobility = EComponentMobility::Static;
			}
			bHasDecidedMobility = true;
		}

		//Component and Location Setup
		EnterZone.Shape = FHazeShapeSettings::MakeCapsule(EnterZone.Shape.CapsuleRadius, (Height * 0.5) - 20.0);
		EnterZone.RelativeLocation = FVector(0.0, 0.0, Height * 0.5);
		Pole.RelativeScale3D = FVector(0.25, 0.25, (Height) / 100);
		PerchPointComp.SetRelativeLocation(FVector(0.0, 0.0, Height));

		PerchPointComp.bAllowPerch = bAllowPerchOnTop;

		if (bEnablePoleTransferAssist || bEnablePoleAirMoveAssist)
		{
			TransferAssistTrigger.Shape = FHazeShapeSettings::MakeSphere(
				Height + Math::Max(MaxTransferAssistDistance, MaxAirMoveAssistDistance) + 200.0
			);
		}
		else
		{
			TransferAssistTrigger.Shape = FHazeShapeSettings();
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(!bEnabled)
			DisablePoleActor(bAllowPerchOnTop);
		else if(!bAllowPerchOnTop)
		{
			DisablePerchPointsOnly();
		}

		if (bEnablePoleTransferAssist)
		{
			TransferAssistTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerNearbyEnter");
			TransferAssistTrigger.OnPlayerLeave.AddUFunction(this, n"OnPlayerNearbyLeave");
		}
		else
		{
			TransferAssistTrigger.DisableTrigger(this);
		}
	}

	UFUNCTION()
	private void OnPlayerNearbyEnter(AHazePlayerCharacter Player)
	{
		auto PoleClimbComp = UPlayerPoleClimbComponent::Get(Player);
		if (PoleClimbComp != nullptr)
			PoleClimbComp.AddNearbyPole(this);
	}

	UFUNCTION()
	private void OnPlayerNearbyLeave(AHazePlayerCharacter Player)
	{
		auto PoleClimbComp = UPlayerPoleClimbComponent::Get(Player);
		if (PoleClimbComp != nullptr)
			PoleClimbComp.RemoveNearbyPole(this);
	}

	UFUNCTION()
	void EnablePoleActor(bool bShouldEnablePerchPoints = true)
	{
		EnterZone.EnableTrigger(this);
		bEnabled = true;

		if(bShouldEnablePerchPoints)
		{
			PerchPointComp.Enable(this);
			PerchEnterZone.EnableTrigger(this);
			bAllowPerchOnTop = true;
		}
	}

	UFUNCTION()
	void DisablePoleActor(bool bShouldDisablePerchPoints = true)
	{
		EnterZone.DisableTrigger(this);
		bEnabled = false;
	
		if(bShouldDisablePerchPoints)
		{
			PerchPointComp.Disable(this);
			PerchEnterZone.DisableTrigger(this);
			bAllowPerchOnTop = false;
		}
	}

	UFUNCTION()
	bool IsPoleDisabled()
	{
		return !bEnabled;
	}

	UFUNCTION()
	void EnablePerchPointsOnly()
	{
		PerchPointComp.Enable(this);
		PerchEnterZone.EnableTrigger(this);
		bAllowPerchOnTop = true;
	}

	UFUNCTION()
	void DisablePerchPointsOnly()
	{
		PerchPointComp.Disable(this);
		PerchEnterZone.DisableTrigger(this);
		bAllowPerchOnTop = false;
	}

	//Modify height of pole, updating mesh / Enterzone
	UFUNCTION()
	void SetNewHeight(float NewHeight)
	{
		Height = NewHeight;
		Pole.RelativeScale3D = FVector(0.25, 0.25, (NewHeight) / 100);
		PerchPointComp.SetRelativeLocation(FVector(0.0, 0.0, NewHeight));

		FHazeShapeSettings Shape;
		Shape.Type = EHazeShapeType::Capsule;
		Shape.CapsuleHalfHeight = (NewHeight * 0.5) - 20.0;
		Shape.CapsuleRadius = EnterZone.Shape.CapsuleRadius;
		EnterZone.ChangeShape(Shape);
		EnterZone.RelativeLocation = FVector(0.0, 0.0, Height * 0.5);
	}

	bool IsValidForPlayer(AHazePlayerCharacter Player) const
	{
		if(!Player.IsSelectedBy(UsableByPlayers))
			return false;

		return true;
	}

	TArray<FVector> GetAllowedPlayerDirections() const
	{
		TArray<FVector> Directions;
		if(bClimbInFourCardinalAngles)
		{
			Directions.Add(ActorForwardVector.RotateAngleAxis(CardinalAngleOffset, ActorUpVector));
			Directions.Add(-ActorForwardVector.RotateAngleAxis(CardinalAngleOffset, ActorUpVector));
			Directions.Add(ActorRightVector.RotateAngleAxis(CardinalAngleOffset, ActorUpVector));
			Directions.Add(-ActorRightVector.RotateAngleAxis(CardinalAngleOffset, ActorUpVector));
			return Directions;
		}

		if (ForwardClimbAngleRotation != 0.0)
			Directions.Add(ActorForwardVector.RotateAngleAxis(ForwardClimbAngleRotation, ActorUpVector));
		else
			Directions.Add(ActorForwardVector);

		if (BackwardClimbAngleRotation != 0.0)
			Directions.Add(-ActorForwardVector.RotateAngleAxis(BackwardClimbAngleRotation, ActorUpVector));
		else
			Directions.Add(-ActorForwardVector);

		return Directions;
	}
}

class UPoleClimbEnterZone : UHazeMovablePlayerTriggerComponent
{
	default Shape = FHazeShapeSettings::MakeCapsule(100.0, 25.0);

	APoleClimbActor Pole;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Pole = Cast<APoleClimbActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnPlayerEnteredTrigger(AHazePlayerCharacter OtherActor)
	{
		auto PoleClimbComp = UPlayerPoleClimbComponent::Get(OtherActor);
		if(PoleClimbComp == nullptr)
			return;

		if(!Pole.bEnabled)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(PoleClimbComp.Owner);

		if(!Player.IsSelectedBy(Pole.UsableByPlayers))
			return;

		if(Pole.bShouldValidatePlayerPoleWorldUp && !ValidatePlayerPoleAlignment(Player))
			return;

		PoleClimbComp.OverlappingPoles.AddUnique(Pole);
	}

	UFUNCTION(BlueprintOverride)
	void OnPlayerLeftTrigger(AHazePlayerCharacter OtherActor)
	{
		auto PoleClimbComp = UPlayerPoleClimbComponent::Get(OtherActor);
		if(PoleClimbComp == nullptr)
			return;

		if(PoleClimbComp.OverlappingPoles.Contains(Pole))
			PoleClimbComp.OverlappingPoles.RemoveSwap(Pole);
	}

	//Check if player world up matchers relative up vector of Pole
	bool ValidatePlayerPoleAlignment(AHazePlayerCharacter Player) const
	{
		float Angle = Owner.ActorUpVector.GetAngleDegreesTo(Player.MovementWorldUp);
		float PlayerPoleUpDot = Pole.ActorUpVector.DotProduct(Player.MovementWorldUp);

		if(PlayerPoleUpDot >= 0.0)
		{
			if(Angle > Pole.UpVectorCutOffAngle)
				return false;
			else
				return true;
		}
		else
		{
			FVector PoleDownVector = -Owner.ActorUpVector;
			float AngleNegative = PoleDownVector.GetAngleDegreesTo(Player.MovementWorldUp);

			if(AngleNegative > Pole.UpVectorCutOffAngle)
				return false;
			else
				return true;
		}
	}
}

class UPoleClimbActorDetailCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = APoleClimbActor;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		EditCategory(n"Settings | PoleClimb", CategoryType = EScriptDetailCategoryType::Important);
		EditCategory(n"Settings | PerchPoint", CategoryType = EScriptDetailCategoryType::Important);
		EditCategory(n"Targetable | PoleClimb", CategoryType = EScriptDetailCategoryType::Important);
		EditCategory(n"Targetable | PerchPoint", CategoryType = EScriptDetailCategoryType::Important);
		EditCategory(n"Zone", CategoryType = EScriptDetailCategoryType::Important);
		EditCategory(n"Visuals",CategoryType = EScriptDetailCategoryType::Important);
		AddDefaultPropertiesFromOtherCategory(n"Settings | PoleClimb", n"Settings | PoleClimbDefaults");
		AddDefaultPropertiesFromOtherCategory(n"Settings | PerchPoint", n"Settings");
		AddDefaultPropertiesFromOtherCategory(n"Targetable | PoleClimb", n"Targetable | PoleClimbDefaults");
		AddDefaultPropertiesFromOtherCategory(n"Targetable | PerchPoint", n"Targetable");

		HideCategory(n"Physics");
		HideCategory(n"Collision");
		HideCategory(n"Activation");
	}
}

enum EPoleType
{
	Default,
	Slippery
}

enum EPoleTypeOverride
{
	None,
	Default,
	Slippery
}