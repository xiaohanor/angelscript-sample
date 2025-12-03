UCLASS(Abstract)
class UInnerCityWaterSlideEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartSliding()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopSliding()
	{
	}

};	

UCLASS(Abstract)
class AInnerCityWaterSlide : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerCapabilityClasses.Add(UInnerCityWaterSlidePlayerCapability);

	UPROPERTY(EditAnywhere)
	ASplineActor SlideSpline;

	FSlideParameters SlideParams;

	UPROPERTY(EditAnywhere)
	ASplineFollowCameraActor Camera;

	UPROPERTY(EditDefaultsOnly)
	UPlayerSlideSettings SlideSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SlideParams.SlideType = ESlideType::SplineSlide;
		SlideParams.SplineComp = SlideSpline.Spline;
		
	}
};

struct FInnerCityWaterSlideActivateParams
{
	AInnerCityWaterSlide WaterSlide;
};

class UInnerCityWaterSlidePlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(BlockedWhileIn::AirJump);
	default CapabilityTags.Add(BlockedWhileIn::Jump);
	default CapabilityTags.Add(BlockedWhileIn::Dash);

	UPlayerMovementComponent MoveComp;

	AInnerCityWaterSlide WaterSlide;
	float LastOnWaterSlideTime = 0;
	const float DetachDelay = 0.2;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FInnerCityWaterSlideActivateParams& Params) const
	{
		if(!MoveComp.IsOnAnyGround())
			return false;

		if(!MoveComp.GroundContact.Actor.IsA(AInnerCityWaterSlide))
			return false;

		Params.WaterSlide = Cast<AInnerCityWaterSlide>(MoveComp.GroundContact.Actor);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Time::GetGameTimeSince(LastOnWaterSlideTime) > DetachDelay)
		{
			if(MoveComp.IsOnAnyGround())
			{
				if(MoveComp.GroundContact.Actor != WaterSlide)
					return true;
			}
			else
			{
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInnerCityWaterSlideActivateParams Params)
	{
		WaterSlide = Params.WaterSlide;
		LastOnWaterSlideTime = Time::GameTimeSeconds;

		Player.ApplySettings(WaterSlide.SlideSettings, this);
		Player.ActivateCamera(WaterSlide.Camera, 2.0, this);
		Player.ForcePlayerSlide(this, WaterSlide.SlideParams);
		UInnerCityWaterSlideEventHandler::Trigger_OnStartSliding(WaterSlide);

		UMovementFloatingSettings::SetFloatingDirection(Player, EFloatingMovementFloatingDirection::Explicit, this);

		// Audio
		UInnerCityWaterSlideEventHandler::Trigger_OnStartSliding(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearSettingsByInstigator(this);
		Player.ClearForcePlayerSlide(this);
		Player.DeactivateCamera(WaterSlide.Camera, 2.0);
		UInnerCityWaterSlideEventHandler::Trigger_OnStopSliding(WaterSlide);
//
		UMovementFloatingSettings::ClearFloatingDirection(Player, this);
		UMovementFloatingSettings::ClearExplicitFloatingDirection(Player, this);

		// Audio
		UInnerCityWaterSlideEventHandler::Trigger_OnStopSliding(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.HasGroundContact() && MoveComp.GroundContact.Actor == WaterSlide)
		{
			LastOnWaterSlideTime = Time::GameTimeSeconds;

			FTransform ClosestSplinePoint = WaterSlide.SlideSpline.Spline.GetClosestSplineWorldTransformToWorldLocation(Player.ActorCenterLocation);
			FVector FloatingDirection = ClosestSplinePoint.Location - Player.ActorCenterLocation;
			FloatingDirection = FloatingDirection.VectorPlaneProject(ClosestSplinePoint.Rotation.ForwardVector).GetSafeNormal();

			//FF
			FHazeFrameForceFeedback FF;
			FF.LeftMotor = Math::Sin(ActiveDuration * 30.0) * 0.4;
			FF.RightMotor = Math::Sin(-ActiveDuration * 30.0) * 0.4;
			Player.SetFrameForceFeedback(FF);

			UMovementFloatingSettings::SetExplicitFloatingDirection(Player, FloatingDirection, this);
		}
	}
};