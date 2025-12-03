
enum ESlideType
{
	// Slide in any direction along the slope of the floor
	Freeform,
	// Always slide forward in a specific direction, preventing backtracking
	StaticDirection,
	// Always slide forward along a spline, preventing backtracking
	SplineSlide,
};

struct FSlideParameters
{
	// What kind of slide is being done
	UPROPERTY()
	ESlideType SlideType = ESlideType::Freeform;

	// Direction to slide forward in
	UPROPERTY(Meta = (EditCondition = "SlideType == ESlideType::StaticDirection", EditConditionHides))
	FVector SlideWorldDirection;

	// Spline to slide along
	UPROPERTY(Meta = (EditCondition = "SlideType == ESlideType::SplineSlide", EditConditionHides))
	UHazeSplineComponent SplineComp;

	// Whether to lock the player to be near the spline based on its scale
	UPROPERTY(Meta = (EditCondition = "SlideType == ESlideType::SplineSlide", EditConditionHides))
	bool bConstrainToSplineWidth = false; 

	// If we should skip the slide enter anim (if we came from a cutscene / etc)
	UPROPERTY()
	bool bSkipEnterAnim = false; 
};

struct FActiveSlideInstance
{
	FSlideParameters Parameters;
	FInstigator Instigator;
	bool bIsTemporarySlide = false;
	float TemporarySlideMinimumDuration = 0.0;
	float TemporarySlideMinimumDistance = 0.0;
	float TemporarySlideMaximumDuration = 0.0;
	float GameTimeSlideStarted = 0.0;
}

struct FSlideSlopeData
{
	FVector SlopeNormal;
	FVector SlopeForward;
	FVector SlopeRight;

	FVector FacingForward;
	FVector FacingRight;

	FVector ConstrainRight;

	bool bConstrainToSlopeWidth = false;
	FVector SlopeWidthOrigin;
	float SlopeWidth = 0.0;

	float RubberBandMultiplier = 1.0;
};

class UPlayerSlideComponent : UActorComponent
{
	UPROPERTY()
	UPlayerSlideSettings Settings;

	UPROPERTY()
	float Speed = 0.0;

	//How much is the angle difference between our input and the actor forward angle clamped within -90 / 90 for animation
	UPROPERTY()
	float TurnAngle = 0;

	bool bIsSliding = false;
	bool bHasSlidOnGround = false;

	FHazeAcceleratedRotator AcceleratedDesiredRotation;
	FHazeAcceleratedFloat AcceleratedLowerPitchClamp;

	TInstigated<FActiveSlideInstance> ActiveSlide;
	TArray<FInstigator> TemporarySlides;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset SlideCameraSetting;
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> SlideShake;

	UPROPERTY()
	FPlayerSlideAnimData AnimData;

	//Cam setting instigators set to be cleared on slide stop via SlideCameraCapability
	TArray<FInstigator> CamOverrideInstigators;

	AHazePlayerCharacter Player;
	UPlayerMovementComponent MoveComp;
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_PostPhysics;

	UCameraUserComponent CameraUserComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerSlideSettings::GetSettings(Cast<AHazeActor>(Owner));

		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);

		CameraUserComp = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// If we have temporary slide starts, but we didn't actually start a slide, remove them
		if (!bIsSliding)
			StopTemporarySlides();
	}

	void StartSlide(FInstigator Instigator, FSlideParameters Params)
	{
		FActiveSlideInstance SlideInstance;
		SlideInstance.Parameters = Params;
		SlideInstance.Instigator = Instigator;
		SlideInstance.GameTimeSlideStarted = Time::GameTimeSeconds;

		ActiveSlide.Apply(SlideInstance, Instigator);
	}

	void StartTemporarySlide(FInstigator Instigator, FSlideParameters Params, float MinimumDuration = 0.4, float MaximumDuration = -1.0, float MinimumDistance = 0.0)
	{
		FActiveSlideInstance SlideInstance;
		SlideInstance.Parameters = Params;
		SlideInstance.Instigator = Instigator;
		SlideInstance.bIsTemporarySlide = true;
		SlideInstance.TemporarySlideMinimumDistance = MinimumDistance;
		SlideInstance.TemporarySlideMinimumDuration = MinimumDuration;
		SlideInstance.TemporarySlideMaximumDuration = MaximumDuration;
		SlideInstance.GameTimeSlideStarted = Time::GameTimeSeconds;

		ActiveSlide.Apply(SlideInstance, Instigator);
		TemporarySlides.Add(Instigator);
	}

	void StopTemporarySlides()
	{
		for (auto TempInstigator : TemporarySlides)
			ActiveSlide.Clear(TempInstigator);
		TemporarySlides.Reset();

		if (!IsSlideActive())
			bHasSlidOnGround = false;
	}

	void StopSlide(FInstigator Instigator)
	{
		ActiveSlide.Clear(Instigator);
		if (!IsSlideActive())
			bHasSlidOnGround = false;
	}

	bool IsSlideActive() const
	{
		return !ActiveSlide.IsDefaultValue();
	}

	bool IsTemporarySlide() const
	{
		return ActiveSlide.Get().bIsTemporarySlide;
	}

	bool IsFreeformSlide() const
	{
		return ActiveSlide.Get().Parameters.SlideType == ESlideType::Freeform;
	}

	float GetTemporarySlideMinimumDuration() const
	{
		return ActiveSlide.Get().TemporarySlideMinimumDuration;
	}

	const FActiveSlideInstance& GetSlideInstance() const
	{
		return ActiveSlide.Get();
	}

	const FSlideParameters& GetSlideParameters() const
	{
		return ActiveSlide.Get().Parameters;
	}

	FSlideSlopeData GetSlideSlopeData() const
	{
		FSlideSlopeData Slope;
		Slope.SlopeNormal = FVector::UpVector;
		Slope.SlopeForward = FVector::ForwardVector;
		Slope.SlopeRight = FVector::RightVector;

		FVector WorldUp = MoveComp.GetWorldUp();

		auto GroundImpact = MoveComp.GetGroundContact();
		if (GroundImpact.bBlockingHit)
			Slope.SlopeNormal = MoveComp.GetGroundContact().Normal;
		else
			Slope.SlopeNormal = WorldUp;

		float NearestSplineDistance = 0.0;
		FSlideParameters Params = ActiveSlide.Get().Parameters;
		if (Params.SlideType == ESlideType::Freeform)
		{
			if (Math::Abs(Slope.SlopeNormal.DotProduct(WorldUp)) >= 0.99)
			{
				// Our normal is pointing fully upward, we don't actually have a proper forward vector
				Slope.SlopeForward = MoveComp.GetHorizontalVelocity().GetSafeNormal();
				if (Slope.SlopeForward.IsNearlyZero())
					Slope.SlopeForward = Player.ActorForwardVector;

				Slope.SlopeRight = Slope.SlopeForward.CrossProduct(WorldUp);
			}
			else
			{
				Slope.SlopeRight = WorldUp.CrossProduct(Slope.SlopeNormal).GetSafeNormal();
				Slope.SlopeForward = Slope.SlopeRight.CrossProduct(Slope.SlopeNormal).GetSafeNormal();
			}

			Slope.FacingForward = Slope.SlopeForward.ConstrainToPlane(WorldUp).GetSafeNormal();
			Slope.FacingRight = Slope.SlopeRight.ConstrainToPlane(WorldUp).GetSafeNormal();
		}
		else
		{
			FVector WantedForward;
			if (Params.SlideType == ESlideType::StaticDirection)
			{
				WantedForward = Params.SlideWorldDirection;
			}
			else if (Params.SlideType == ESlideType::SplineSlide && Params.SplineComp != nullptr)
			{
				NearestSplineDistance = Params.SplineComp.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
				WantedForward = Params.SplineComp.GetWorldForwardVectorAtSplineDistance(NearestSplineDistance);

				if (Params.bConstrainToSplineWidth)
				{
					FTransform SplineTransform = Params.SplineComp.GetWorldTransformAtSplineDistance(NearestSplineDistance);

					Slope.bConstrainToSlopeWidth = true;
					Slope.SlopeWidth = SplineTransform.Scale3D.Y * 30.0;
					Slope.SlopeWidthOrigin = SplineTransform.Location;
					Slope.ConstrainRight = SplineTransform.Rotation.RightVector;
				}
			}
			else
			{
				// Should not happen. Maybe the spline got destroyed?
				WantedForward = MoveComp.GetHorizontalVelocity().GetSafeNormal();
				if (WantedForward.IsNearlyZero())
					WantedForward = Player.ActorForwardVector;
			}

			Slope.SlopeRight = Slope.SlopeNormal.CrossProduct(WantedForward).GetSafeNormal();
			Slope.SlopeForward = Slope.SlopeRight.CrossProduct(Slope.SlopeNormal).GetSafeNormal();

			Slope.FacingForward = Slope.SlopeForward.ConstrainToPlane(WorldUp).GetSafeNormal();
			Slope.FacingRight = Slope.SlopeRight.ConstrainToPlane(WorldUp).GetSafeNormal();
		}

		if (Settings.bEnableRubberBanding && !Player.OtherPlayer.IsPlayerDead())
		{
			float RubberBandDistance = 0.0;
			if (Params.SlideType == ESlideType::SplineSlide)
			{
				if (Params.SplineComp != nullptr)
				{
					float OtherPlayerSplineDistance = Params.SplineComp.GetClosestSplineDistanceToWorldLocation(Player.OtherPlayer.ActorLocation);
					if (Settings.RubberBandOffset == EPlayerSlideRubberBandOffsetType::MioInFrontOfZoe)
					{
						if (Player.IsMio())
							OtherPlayerSplineDistance += Settings.RubberBandOffsetDistance;
						else
							OtherPlayerSplineDistance -= Settings.RubberBandOffsetDistance;
					}
					else if (Settings.RubberBandOffset == EPlayerSlideRubberBandOffsetType::ZoeInFrontOfMio)
					{
						if (Player.IsMio())
							OtherPlayerSplineDistance -= Settings.RubberBandOffsetDistance;
						else
							OtherPlayerSplineDistance += Settings.RubberBandOffsetDistance;
					}

					RubberBandDistance = NearestSplineDistance - OtherPlayerSplineDistance;
				}
			}
			else if (Params.SlideType == ESlideType::StaticDirection)
			{
				FVector RubberBandTargetLocation = Player.OtherPlayer.ActorLocation;
				if (Settings.RubberBandOffset == EPlayerSlideRubberBandOffsetType::MioInFrontOfZoe)
				{
					if (Player.IsMio())
						RubberBandTargetLocation += Params.SlideWorldDirection * Settings.RubberBandOffsetDistance;
					else
						RubberBandTargetLocation -= Params.SlideWorldDirection * Settings.RubberBandOffsetDistance;
				}
				else if (Settings.RubberBandOffset == EPlayerSlideRubberBandOffsetType::ZoeInFrontOfMio)
				{
					if (Player.IsMio())
						RubberBandTargetLocation -= Params.SlideWorldDirection * Settings.RubberBandOffsetDistance;
					else
						RubberBandTargetLocation += Params.SlideWorldDirection * Settings.RubberBandOffsetDistance;
				}

				RubberBandDistance = (Player.ActorLocation - RubberBandTargetLocation).DotProduct(Params.SlideWorldDirection);
			}

			float MinimumDistance = Settings.RubberBandMinDistance;
			float MaximumDistance = Settings.RubberBandMaxDistance;
			if (Settings.bRubberBandRemovePingFromDistance && Network::IsGameNetworked())
			{
				float PredictedPingDelay = Time::OtherSideCrumbTrailSendTimePrediction - Time::GetPlayerCrumbTrailTime(Game::FirstLocalPlayer.OtherPlayer);
				float PredictedPingDistance = PredictedPingDelay * 1.25 * Math::Max(Player.OtherPlayer.ActorVelocity.Size(), Settings.SlideTargetSpeed);
				MinimumDistance += PredictedPingDistance;
				MaximumDistance += PredictedPingDistance;
			}

			if (RubberBandDistance > MinimumDistance)
			{
				Slope.RubberBandMultiplier = Math::GetMappedRangeValueClamped(
					FVector2D(MinimumDistance, MaximumDistance),
					FVector2D(1.0, Settings.RubberBandMaxSlowdown),
					RubberBandDistance
				);
			}
			else if (RubberBandDistance < -MinimumDistance)
			{
				Slope.RubberBandMultiplier = Math::GetMappedRangeValueClamped(
					FVector2D(-MinimumDistance, -MaximumDistance),
					FVector2D(1.0, Settings.RubberBandMaxSpeedUp),
					RubberBandDistance
				);
			}
		}

		return Slope;
	}

	void CalculateAndClampPitch(float DeltaTime)
	{
		CalculatePitchClamp(DeltaTime);
		ClampPitch();
	}

	void CalculatePitchClamp(float DeltaTime)
	{
		float PitchUpTarget;
		PitchUpTarget = GetSlideSlopeData().SlopeForward.GetAngleDegreesTo(MoveComp.WorldUp) - (90 - Settings.AdditionalCameraPitchClampAngle);
		AcceleratedLowerPitchClamp.AccelerateTo(-PitchUpTarget, 3, DeltaTime);
	}

	void SnapPitchClamp(float Velocity = 0)
	{
		float PitchUpTarget;
		PitchUpTarget = GetSlideSlopeData().SlopeForward.GetAngleDegreesTo(MoveComp.WorldUp) - (90 - Settings.AdditionalCameraPitchClampAngle);
		AcceleratedLowerPitchClamp.SnapTo(-PitchUpTarget, Velocity);
	}

	void ClampPitch()
	{
		FHazeCameraClampSettings ClampSettings = FHazeCameraClampSettings(SlideCameraSetting.ClampSettings.GetSettings(CameraUserComp).YawLeft.Value,
																				SlideCameraSetting.ClampSettings.GetSettings(CameraUserComp).YawRight.Value,
																					AcceleratedLowerPitchClamp.Value,
																						SlideCameraSetting.ClampSettings.GetSettings(CameraUserComp).PitchDown.Value);

		UCameraSettings::GetSettings(Player).Clamps.Apply(ClampSettings, FInstigator(this, n"SlideClampConstraint"), SubPriority = 40);
	}

	FRotator CalculateVelocityBasedSlopeDesiredRotation()
	{
		FVector SlopeVelocityDirection = MoveComp.Velocity;

		FRotator SlopeAlignedRotation = FRotator::MakeFromX(SlopeVelocityDirection);
		SlopeAlignedRotation.Roll = 0;
		SlopeAlignedRotation.Pitch -= Settings.AdditionalCameraPitchAssist * (Math::Clamp(MoveComp.Velocity.Size() / Settings.SlideMaximumSpeed, 0, 1));

		return SlopeAlignedRotation;
	}

	FRotator CalculateSlopDesiredRotation()
	{
		FRotator SlopeAlignedRotation = FRotator::MakeFromX(GetSlideSlopeData().SlopeForward);
		SlopeAlignedRotation.Roll = 0;
		SlopeAlignedRotation.Pitch -= Settings.AdditionalCameraPitchAssist;

		return SlopeAlignedRotation;
	}

	void SnapDesiredRotationAndPitch()
	{
		AcceleratedDesiredRotation.SnapTo(CalculateSlopDesiredRotation(), FRotator::ZeroRotator);
		CameraUserComp.SnapCamera(AcceleratedDesiredRotation.Value.ForwardVector);

		if(!Player.IsCapabilityTagBlocked(PlayerSlideTags::SlideCameraPitchConstraint))
		{
			SnapPitchClamp();
			ClampPitch();
		}
	}
}

struct FPlayerSlideAnimData
{
	UPROPERTY()
	bool bSlideJumpActive = false;

	void Reset()
	{
		bSlideJumpActive = false;
	}
}

// Force the player to be in sliding movement until cleared
UFUNCTION()
mixin void ForcePlayerSlide(AHazePlayerCharacter Player, FInstigator Instigator, FSlideParameters Parameters) 
{
	if (Player == nullptr)
		return;

	UPlayerSlideComponent SlideComp = UPlayerSlideComponent::GetOrCreate(Player);

	SlideComp.StopTemporarySlides();
	SlideComp.StartSlide(Instigator, Parameters);
}

// Clear the player's previous forced sliding movement
UFUNCTION()
mixin void ClearForcePlayerSlide(AHazePlayerCharacter Player, FInstigator Instigator) 
{
	if (Player == nullptr)
		return;

	UPlayerSlideComponent SlideComp = UPlayerSlideComponent::GetOrCreate(Player);
	SlideComp.StopSlide(Instigator);
}

// Put the player into a slide until they hit a wall or slow down enough to exit the slide
UFUNCTION()
mixin void StartTemporaryPlayerSlide(AHazePlayerCharacter Player, FInstigator Instigator, FSlideParameters Parameters, float MinimumDuration = 0.4, float MaximumDuration = -1.0, float MinimumDistance = 0.0) 
{
	if (Player == nullptr)
		return;

	UPlayerSlideComponent SlideComp = UPlayerSlideComponent::GetOrCreate(Player);

	if(SlideComp.IsSlideActive() && !SlideComp.IsTemporarySlide())
		return;

	SlideComp.StartTemporarySlide(Instigator, Parameters, MinimumDuration, MaximumDuration, MinimumDistance);
}

