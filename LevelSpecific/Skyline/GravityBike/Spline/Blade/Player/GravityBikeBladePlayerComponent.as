enum EGravityBikeBladeState
{
	None,
	Throwing,
	Thrown,
	Grappling,
	Barrel,
};

struct FGravityBikeBladeAnimationData
{
    bool bEquippedGravityBlade;
    bool bThrowGravityBlade;
    float BladeThrowSide = 0;
    bool bIsChangingGravity;
    float GravityChangeAlpha;
    float GravityChangeDuration;
	FVector PreviousGravityDirection;
	FVector NewGravityDirection;
	float RotateDirection;
	uint LandedFrame;
};

UCLASS(Abstract)
class UGravityBikeBladePlayerComponent : UActorComponent
{
	access Triggers = private, AGravityBikeBladeGravityTrigger, UGravityBikeBladeTriggerCapability;

	default PrimaryComponentTick.bStartWithTickEnabled = false;

	AHazePlayerCharacter Player;
	UGravityBikeSplinePlayerComponent DriverComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UGravityBikeBladeTargetWidget> TargetWidgetClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AGravityBikeBlade> BladeActorClass;

	access:Triggers
	TArray<AGravityBikeBladeGravityTrigger> GravityTriggers;
	private AGravityBikeBladeGravityTrigger PrimaryGravityTrigger_Internal;

	AGravityBikeBlade BladeActor = nullptr;

	EGravityBikeBladeState State = EGravityBikeBladeState::None;
	bool bThrowAnimFinished = false;

	private AGravityBikeBladeGravityTrigger Trigger = nullptr;
	UGravityBikeBladeTargetComponent TargetComp = nullptr;
	AGravityBikeBladeSurface Surface = nullptr;
	AGravityBikeBladeBarrel Barrel = nullptr;

	float GravityChangeAlpha = 0;
	float GravityChangeDuration = 0;
	FVector PreviousGravityDirection;
	FVector NewGravityDirection;
	float RotateDirection = 0;

	FGravityBikeBladeAnimationData AnimationData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		DriverComp = UGravityBikeSplineDriverComponent::Get(Player);

		BladeActor = GetOrCreateBladeActor();
	}

	AGravityBikeBlade GetOrCreateBladeActor()
	{
		if(BladeActor == nullptr)
		{
			BladeActor = SpawnActor(BladeActorClass);

			// Audio lives on blade actor
			EffectEvent::LinkActorToReceiveEffectEventsFrom(BladeActor, Player);
		}

		return BladeActor;
	}

	void SetPrimaryGravityTrigger(AGravityBikeBladeGravityTrigger InPrimaryGravityTrigger)
	{
		if(PrimaryGravityTrigger_Internal != nullptr)
			PrimaryGravityTrigger_Internal.OnStopPrimary.Broadcast();

		PrimaryGravityTrigger_Internal = InPrimaryGravityTrigger;

		if(InPrimaryGravityTrigger != nullptr)
		{
			InPrimaryGravityTrigger.OnStartPrimary.Broadcast();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetPrimaryGravityTrigger(AGravityBikeBladeGravityTrigger InPrimaryGravityTrigger)
	{
		SetPrimaryGravityTrigger(InPrimaryGravityTrigger);
	}

	AGravityBikeBladeGravityTrigger GetPrimaryGravityTrigger() const
	{
		return PrimaryGravityTrigger_Internal;
	}

	bool HasThrowTarget() const
	{
		if(PrimaryGravityTrigger_Internal == nullptr)
			return false;

		if(PrimaryGravityTrigger_Internal.IsCurrentGravitySpline())
			return false;

		return true;
	}

	void OnThrowingAnimationStarted(AGravityBikeBladeGravityTrigger InTrigger)
	{
		Trigger = InTrigger;
		TargetComp = Trigger.TargetComp;

		switch(TargetComp.Type)
		{
			case EGravityBikeBladeTargetType::Surface:
				Surface = Cast<AGravityBikeBladeSurface>(TargetComp.Owner);
				check(Surface != nullptr);
				break;

			case EGravityBikeBladeTargetType::Barrel:
				Barrel = Cast<AGravityBikeBladeBarrel>(TargetComp.Owner);
				check(Barrel != nullptr);
				break;
		}

		State = EGravityBikeBladeState::Throwing;

		bThrowAnimFinished = false;
		
		Trigger.OnStartThrow.Broadcast();
	}

	void OnThrowingAnimationFinished()
	{
		bThrowAnimFinished = true;

		// FVector LineStart = Player.ActorLocation;
		// FVector LineEnd = Player.ActorLocation + Player.ViewRotation.ForwardVector * GravityBikeBlade::ThrowTargetLineLength; 		
		// BladeComp.TargetLocation = BladeComp.Trigger.GravitySurface.GetClosestPointToLine(LineStart, LineEnd);
	}

	/**
	 * Actually let go of the blade and start moving it towards the target
	 */
	void OnStartThrow()
	{
		State = EGravityBikeBladeState::Thrown;
		bThrowAnimFinished = false;
	}

	UFUNCTION(BlueprintPure)
	FTransform GetThrowTargetTransform() const
	{
		if(!ensure(TargetComp != nullptr))
			return FTransform::Identity;

		return FTransform(
			TargetComp.ComponentQuat,
			TargetComp.WorldLocation
		);
	}

	void FinishThrow()
	{
		State = EGravityBikeBladeState::Grappling;
		Trigger.OnStopThrow.Broadcast();

		const FTransform ThrowTargetTransform = GetThrowTargetTransform();
		const FVector BladeEndLocation = ThrowTargetTransform.Location + BladeActor.ActorUpVector * -50;

		BladeActor.SetActorLocation(BladeEndLocation);
	}

	void StartGrapple(AGravityBikeSpline GravityBike)
	{
		switch(TargetComp.Type)
		{
			case EGravityBikeBladeTargetType::Surface:
			{
				GravityBike.SetSpline(TargetComp.SurfaceSpline);

				if(Surface.GrappleCameraActor != nullptr)
				{
					GravityBike.GetDriver().ActivateCamera(Surface.GrappleCameraActor, 1, this);
				}
				break;
			}

			case EGravityBikeBladeTargetType::Barrel:
			{
				break;
			}
		}

		GravityBike.BlockCapabilities(GravityBikeSpline::AlignmentTags::GravityBikeSplineAlignment, this);
		GravityBike.BlockCapabilities(GravityBikeSpline::MovementTags::GravityBikeSplineMovement, this);

		Trigger.OnStartGravityChange.Broadcast();
		
		UGravityBikeBladeEventHandler::Trigger_OnGravityChangeStarted(GravityBikeBlade::GetPlayer());
		UGravityBikeSplineEventHandler::Trigger_OnGravityChangeStarted(DriverComp.GravityBike);

#if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(GravityBike);
		TemporalLog.Event("Start Grapple");
#endif
	}

	void FinishGrapple(AGravityBikeSpline GravityBike)
	{
		switch(TargetComp.Type)
		{
			case EGravityBikeBladeTargetType::Surface:
			{
				if(Surface.GrappleCameraActor != nullptr)
				{
					GravityBike.GetDriver().DeactivateCameraByInstigator(this, 1);
				}

				State = EGravityBikeBladeState::None;
				break;
			}

			case EGravityBikeBladeTargetType::Barrel:
			{
				State = EGravityBikeBladeState::Barrel;
				break;
			}
		}

		GravityBike.UnblockCapabilities(GravityBikeSpline::AlignmentTags::GravityBikeSplineAlignment, this);
		GravityBike.UnblockCapabilities(GravityBikeSpline::MovementTags::GravityBikeSplineMovement, this);
		Trigger.OnStopGravityChange.Broadcast();
		UGravityBikeBladeEventHandler::Trigger_OnGravityChangeStopped(GravityBikeBlade::GetPlayer());

		if(State == EGravityBikeBladeState::None)
			Reset();

#if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(GravityBike);
		TemporalLog.Event("Finish Grapple");
#endif
	}

	void Reset()
	{
		State = EGravityBikeBladeState::None;
		Trigger = nullptr;
		TargetComp = nullptr;
		Surface = nullptr;
		Barrel = nullptr;
	}

	UFUNCTION(BlueprintPure)
	bool IsThrowingOrThrown() const
	{
		return State == EGravityBikeBladeState::Throwing || State == EGravityBikeBladeState::Thrown;
	}

	UFUNCTION(BlueprintPure)
	bool IsGrappling() const
	{
		return State == EGravityBikeBladeState::Grappling;
	}
}