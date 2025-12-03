UCLASS(Abstract)
class APrisonDronesCoolingSpinnerArm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent ExtendRoot;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(EditDefaultsOnly, Category = "Spinner Arm")
	FHazeRange ExtensionRange = FHazeRange(-550.0, 500);

	UPROPERTY(EditDefaultsOnly, Category = "Spinner Arm")
	float RetractExponent = 2;

	UPROPERTY(EditDefaultsOnly, Category = "Spinner Arm")
	float ExtendExponent = 2;

	UPROPERTY(EditDefaultsOnly, Category = "Spinner Arm", Meta = (ClampMin = "0.0", ClampMax = "360.0"))
	float StartRetractAngle = 275;

	UPROPERTY(EditDefaultsOnly, Category = "Spinner Arm", Meta = (ClampMin = "0.0", ClampMax = "360.0"))
	float EndRetractAngle = 290;

	UPROPERTY(EditDefaultsOnly, Category = "Spinner Arm", Meta = (ClampMin = "0.0", ClampMax = "360.0"))
	float StartExtendAngle = 335;

	UPROPERTY(EditDefaultsOnly, Category = "Spinner Arm", Meta = (ClampMin = "0.0", ClampMax = "360.0"))
	float EndExtendAngle = 355;

	UPROPERTY(EditDefaultsOnly, Category = "Spinner Arm")
	bool bReverse = false;

	AKineticRotatingActor ParentRotatingActor;
	float PreviousCurrentYaw = 0;
	bool bHasTriggeredStartRetract;
	bool bHasTriggeredEndRetract;
	bool bHasTriggeredStartExtend;
	bool bHasTriggeredEndExtend;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		ParentRotatingActor = Cast<AKineticRotatingActor>(AttachParentActor);
		if(ParentRotatingActor == nullptr)
			return;

		UpdatePosition();
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ParentRotatingActor = Cast<AKineticRotatingActor>(AttachParentActor);
		check(ParentRotatingActor != nullptr);

		// Disable together with parent
		ParentRotatingActor.DisableComp.LateAddAutoDisableLinkedActor(this);

		UpdateEvents(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdatePosition();
		UpdateEvents();
	}

	float GetCurrentYaw() const
	{
		float CurrentYaw = ActorRotation.Yaw;
		CurrentYaw = Math::Wrap(CurrentYaw, 0, 360);

		if(bReverse)
			CurrentYaw = 360 - CurrentYaw;

		return CurrentYaw;
	}

	void UpdatePosition()
	{
		const float ExtensionAlpha = GetExtensionAlpha();
		const float CurrentExtension = ExtensionRange.Lerp(ExtensionAlpha);
		ExtendRoot.SetRelativeLocation(FVector(
			CurrentExtension,
			ExtendRoot.RelativeLocation.Y,
			ExtendRoot.RelativeLocation.Z
		));
	}

	float GetExtensionAlpha() const
	{
		const float CurrentYaw = GetCurrentYaw();

		if(CurrentYaw < StartRetractAngle)
		{
			return 1;
		}
		else if(CurrentYaw < EndRetractAngle)
		{
			const float Alpha = Math::GetPercentageBetween(StartRetractAngle, EndRetractAngle, CurrentYaw);
			return 1.0 - Math::EaseIn(0, 1, Alpha, RetractExponent);
		}
		else if(CurrentYaw < StartExtendAngle)
		{
			return 0;
		}
		else if(CurrentYaw < EndExtendAngle)
		{
			const float Alpha = Math::GetPercentageBetween(StartExtendAngle, EndExtendAngle, CurrentYaw);
			return Math::EaseIn(0, 1, Alpha, ExtendExponent);
		}
		else
		{
			return 1;
		}
	}

	void UpdateEvents(bool bSilent = false)
	{
		const float CurrentYaw = GetCurrentYaw();

		const bool bIsNewCycle = CurrentYaw < PreviousCurrentYaw;
		if(bIsNewCycle)
		{
			bHasTriggeredStartRetract = false;
			bHasTriggeredEndRetract = false;
			bHasTriggeredStartExtend = false;
			bHasTriggeredEndExtend = false;
		}

		if(!bHasTriggeredStartRetract && CurrentYaw > StartRetractAngle)
		{
			bHasTriggeredStartRetract = true;
			if(!bSilent)
				UPrisonDronesCoolingSpinnerArmEventHandler::Trigger_StartRetract(this);
		}

		if(!bHasTriggeredEndRetract && CurrentYaw > EndRetractAngle)
		{
			bHasTriggeredEndRetract = true;
			if(!bSilent)
				UPrisonDronesCoolingSpinnerArmEventHandler::Trigger_EndRetract(this);
		}


		if(!bHasTriggeredStartExtend && CurrentYaw > StartExtendAngle)
		{
			bHasTriggeredStartExtend = true;
			if(!bSilent)
				UPrisonDronesCoolingSpinnerArmEventHandler::Trigger_StartExtend(this);
		}

		if(!bHasTriggeredEndExtend && CurrentYaw > EndExtendAngle)
		{
			bHasTriggeredEndExtend = true;
			if(!bSilent)
				UPrisonDronesCoolingSpinnerArmEventHandler::Trigger_EndExtend(this);
		}

		PreviousCurrentYaw = CurrentYaw;
	}
};