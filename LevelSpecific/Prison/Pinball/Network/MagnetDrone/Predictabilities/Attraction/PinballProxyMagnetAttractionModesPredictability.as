struct FPinballProxyMagnetAttractionModesActivateParams
{
	TSubclassOf<UMagnetDroneAttractionMode> AttractionModeClass;
}

struct FPinballProxyMagnetAttractionModesDeactivateParams
{
	bool bFinished = false;
}

class UPinballProxyMagnetAttractionModesPredictability : UPinballMagnetDronePredictability
{
	default TickGroup = MagnetDrone::AttractionTickGroup;
	default TickGroupOrder = MagnetDrone::AttractionTickGroupOrder;

	UPinballProxyMagnetAttractionComponent AttractionComp;
	UPinballProxyMagnetAttachedComponent AttachedComp;

	UPinballProxyMovementComponent MoveComp;
	UPinballMagnetAttractionMovementData MoveData;

	UMagnetDroneAttractionMode ActiveAttractionMode;

	FPinballProxyMagnetAttractionModesActivateParams ActivateParams;
	FPinballProxyMagnetAttractionModesDeactivateParams DeactivateParams;

	void Setup(APinballProxy InProxy) override
	{
		Super::Setup(InProxy);

		AttractionComp = UPinballProxyMagnetAttractionComponent::Get(Proxy);
		AttachedComp = UPinballProxyMagnetAttachedComponent::Get(Proxy);

		MoveComp = UPinballProxyMovementComponent::Get(Proxy);
		MoveData = MoveComp.SetupMovementData(UPinballMagnetAttractionMovementData);
	}

	bool ShouldActivate(bool bInit) override
	{
		if(MoveComp.ProxyHasMovedThisFrame())
			return false;

		if(AttachedComp.IsAttached())
			return false;

		if(!AttractionComp.HasAttractionTarget())
			return false;

		auto ShouldActivateParams = FMagnetDroneAttractionModeShouldActivateParams(
			Proxy.ActorLocation,
			Proxy.ActorVelocity,
			AttachedComp.IsAttached(),
			AttractionComp.GetAttractionTarget(),
			AttractionComp.GetAttractionTargetInstigator(),
			false
		);

		for(UMagnetDroneAttractionMode AttractionMode : AttractionComp.AttractionModes)
		{
			if(!AttractionMode.ShouldActivate(ShouldActivateParams))
				continue;

			ActivateParams.AttractionModeClass = AttractionMode.Class;
			return true;
		}

		return false;
	}

	bool ShouldDeactivate() override
	{
		if(AttachedComp.IsAttached())
		{
			DeactivateParams.bFinished = true;
			return true;
		}

		if(MoveComp.ProxyHasMovedThisFrame())
		{
			DeactivateParams.bFinished = AttachedComp.AttachedThisFrame();
			return true;
		}

		if(!AttractionComp.HasAttractionTarget())
			return true;

		// While attracting, check if we have finished
		FMovementHitResult AnyValidContact;
		if(MoveComp.GetAnyValidContact(AnyValidContact))
		{
			FMagnetDroneTargetData PendingTargetData = AttractionComp.GetAttractionTarget();
			EMagnetDroneIntendedTargetResult Result = MagnetDrone::WasImpactIntendedTarget(
				AnyValidContact.ConvertToHitResult(),
				Proxy.ActorLocation,
				MoveComp.PreviousVelocity,
				PendingTargetData
			);

			switch(Result)
			{
				case EMagnetDroneIntendedTargetResult::Finish:
				{
					DeactivateParams.bFinished = true;
					return true;
				}

				case EMagnetDroneIntendedTargetResult::Continue:
					break;

				case EMagnetDroneIntendedTargetResult::Invalidate:
					return true;
			}
		}

		if(AttractionComp.GetAttractionMightBeStuckThisFrame())
		{
			DeactivateParams.bFinished = AttachedComp.AttachedThisFrame();
			return true;
		}

		if(!AttractionComp.HasAttractionTarget())
		{
			DeactivateParams.bFinished = false;
			return true;
		}

		return false;
	}

	void OnActivated(bool bInit) override
	{
		AttractionComp.bIsAttracting = true;
		
		FMovementHitResult AnyValidContact;
		if(MoveComp.GetAnyValidContact(AnyValidContact))
			AttractionComp.AttractionStartContact = AnyValidContact.ConvertToHitResult();
		else
			AttractionComp.AttractionStartContact = FHitResult();

		ActiveAttractionMode = AttractionComp.GetAttractionMode(ActivateParams.AttractionModeClass);
		
		FMagnetDroneAttractionModePrepareAttractionParams SetupAttractionParams(
			Proxy,
			MagnetDrone,
			AttractionComp.GetAttractionTarget(),
		);

		float TimeUntilArrival = 0;
		ActiveAttractionMode.RunPrepareAttraction(SetupAttractionParams, TimeUntilArrival, this);

		// The attraction mode might have modified our initial state
		SetupAttractionParams.ApplyOnProxy(Proxy);
	
		UMovementStandardSettings::SetWalkableSlopeAngle(Proxy, 90, this);
		UDroneMovementSettings::SetRollMaxSpeed(Proxy, 15, this);
	}

	void OnDeactivated() override
	{
		if(ActiveAttractionMode != nullptr)
		{
			ActiveAttractionMode.Reset();
			ActiveAttractionMode = nullptr;
		}
		
		if(DeactivateParams.bFinished)
		{
			AttractionComp.AttractionAlpha = 1.0;
		}
		else
		{
			AttractionComp.AttractionAlpha = 0;
			AttractionComp.AttractionTarget.Invalidate(n"AttractionTarget FinishAttraction", this);
		}

		AttractionComp.bIsAttracting = false;

		MoveComp.RemoveMovementIgnoresActor(this);

		UMovementStandardSettings::ClearWalkableSlopeAngle(Proxy, this);
		UDroneMovementSettings::ClearRollMaxSpeed(Proxy, this);
	}

	void PostPrediction() override
	{
		Super::PostPrediction();
		
		if(ActiveAttractionMode != nullptr)
		{
			ActiveAttractionMode.Reset();
			ActiveAttractionMode = nullptr;
		}

		if(bIsActive)
		{
			MoveComp.RemoveMovementIgnoresActor(this);
			UMovementStandardSettings::ClearWalkableSlopeAngle(Proxy, this);
			UDroneMovementSettings::ClearRollMaxSpeed(Proxy, this);
		}
	}

	void TickActive(float DeltaTime) override
	{	
		Super::TickActive(DeltaTime);

		if(!MoveComp.ProxyPrepareMove(MoveData, DeltaTime, FVector::BackwardVector))
			return;

		CalculateDeltaMove(DeltaTime);

		MoveData.IgnoreSplineLockConstraint();

		MoveComp.ApplyMove(MoveData);

#if !RELEASE
		ActiveAttractionMode.GetTemporalLog(false).Status(f"Running {Class.Name.PlainNameString}", ActiveAttractionMode.DebugColor);
		FTemporalLog TemporalLog = ActiveAttractionMode.GetTemporalLog();
		TemporalLog.Value("Attraction Alpha", AttractionComp.GetAttractionAlpha());
		ActiveAttractionMode.LogToTemporalLog(
			TemporalLog,
			FMagnetDroneAttractionModeLogParams(
				AttractionComp.GetAttractionAlpha(),
				GetAttractionActiveDuration(),
				Proxy.ActorLocation
			)
		);
#endif
	}

	void CalculateDeltaMove(float DeltaTime)
	{
		auto TickAttractionParams = FMagnetDroneAttractionModeTickAttractionParams(
			Proxy.ActorLocation,
			Proxy.ActorVelocity,
			Math::Max(GetAttractionActiveDuration(), KINDA_SMALL_NUMBER),
			Proxy.TickGameTime,
		);

		float AttractionAlpha = AttractionComp.GetAttractionAlpha();
		FVector DesiredLocation = ActiveAttractionMode.RunTickAttraction(TickAttractionParams, DeltaTime, AttractionAlpha);
		AttractionComp.SetAttractionAlpha(AttractionAlpha);

		const FVector DeltaMove = (DesiredLocation - Proxy.ActorLocation);

		MoveData.AddDelta(DeltaMove);
	}

	float GetAttractionActiveDuration() const
	{
		return Proxy.TickGameTime - AttractionComp.StartAttractTime;
	}
}