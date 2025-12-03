class USkylinePowerPlugVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USkylinePowerPlugVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto PowerPlug = Cast<ASkylinePowerPlug>(InComponent.Owner);

		DrawWireSphere(PowerPlug.ActorLocation, PowerPlug.CableLength, FLinearColor::Yellow, 5.0, 24);
	}
}

class USkylinePowerPlugVisualizerComponent : UActorComponent
{

}

class USkylinePowerPlugEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGrabbed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlugged() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnUnplugged() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartReturnToSpool() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinishReturnToSpool() {}
}

class ASkylinePowerPlug : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USkylinePowerPlugVisualizerComponent VisualizerComp;

	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Collision;
	default Collision.SphereRadius = 25.0;
	default Collision.SetCollisionProfileName(n"BlockAllDynamic");

	UPROPERTY(DefaultComponent, Attach = Collision)
	UGravityWhipTargetComponent GravityWhipTargetComp;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComp)
	UTargetableOutlineComponent TargetableOutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComp;
	default GravityWhipResponseComp.GrabMode = EGravityWhipGrabMode::Sling;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.bResolveMovementLocally.Apply(true, this);

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TemporalLocation;
#endif

	USimpleMovementData Movement;

	UPROPERTY(DefaultComponent)
	UCableComponent CableComp;
	default CableComp.EndLocation = FVector::ZeroVector;

	FVector GravityDirection = FVector::UpVector;
	float Gravity = -2500.0;
	float FreeDrag = 0.0;

	float SlingForce = 20.0;
	float SlingDrag = 6.0;

	float ReturnForce = 40.0;
	float ReturnDrag = 10.0;

	float ThrowDrag = 0.0;

	UPROPERTY(EditAnywhere)
	float ThrowSpeed = 3000.0;

	UPROPERTY(EditAnywhere)
	float CableLength = 1300.0;

	bool bSocketed = false;
	bool bThrown = false;
	const float MIN_IMPACT_VELOCITY_THRESHOLD = 475.0;
	bool bHadImpact = false;

	UPROPERTY(EditAnywhere)
	float ReturnDelay = 3.0;
	float ReturnTime = 0.0;

	bool bLerpingIn = false;
	bool bIsSpooled = false;
	float LerpDuration = 1.0;
	FHazeAcceleratedTransform AcceleratedTransform;

	float TimeSinceControlGrab = 0.0;

	ASkylineAllySocketHatch TargetedHatch;
	ASkylinePowerPlugSocket CurrentSocket;
	bool bPlugged = false;

	FRotator OGRotation;
	USceneComponent Origin;
	USceneComponent CableAttach;

	const float MINIMUM_REQUIRED_AUDIO_IMPACT_FORCE = 2900;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OGRotation = ActorRotation;
		SetActorControlSide(Game::Zoe);
		Movement = MoveComp.SetupSimpleMovementData();

		GravityWhipResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		GravityWhipResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");
		GravityWhipResponseComp.OnThrown.AddUFunction(this, n"HandleThrown");
	
		CableComp.SetAttachEndToComponent(CableAttach);
		CableComp.CableLength = CableLength;
		
		// VO lives on Zoe
		EffectEvent::LinkActorToReceiveEffectEventsFrom(Game::Zoe, this);

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (DevTogglesSkyline::AllyAutoSocketHatch.IsEnabled())
			Debug::DrawDebugSphere(Origin.WorldLocation, CableLength, 64, ColorDebug::White);

		TemporalLog();

		// Give the cable a proportional slack
		FVector ToOrigin = Origin.WorldLocation - ActorLocation;
		CableComp.CableLength = Math::Min(CableLength - CableLength * 0.2, ToOrigin.Size() * 1.04);
		if (bSocketed)
		{
			CableComp.CableLength = ToOrigin.Size() * 0.95;
			return;
		}

		if (GravityWhipResponseComp.IsGrabbed() && HasControl())
		{
			UpdateControlGrabbed(DeltaSeconds);
			return;
		}

		if (bThrown)
			ActorRotation = ActorVelocity.Rotation();
		else
		{
			if (ToOrigin.Size() < 1.0)
				ActorRotation = OGRotation;
			else
				ActorRotation = (-ToOrigin).Rotation();
		}

		// Reeling it in
		bool bTargetingHatch = TargetedHatch != nullptr;
		if (!bTargetingHatch && !GravityWhipResponseComp.IsGrabbed() && Time::GameTimeSeconds > ReturnTime)
		{
			UpdateReelIn(DeltaSeconds);
			return;
		}

		// Update movement for Thrown (both sides) and Grabbed remote

		FVector Force = FVector::ZeroVector;
		float Drag = FreeDrag;
		FVector Velocity = ActorVelocity;
		FVector Acceleration = Force + GravityDirection * Gravity * (GravityWhipResponseComp.IsGrabbed() ? 0.0 : 1.0) - Velocity * Drag;
		Velocity += Acceleration * DeltaSeconds;

		// find out local movement
		FVector DeltaMove = Velocity * DeltaSeconds;
		FVector NewLocation = ActorLocation + DeltaMove;
		FVector OriginToNewLocation = NewLocation - Origin.WorldLocation;

		if (!GravityWhipResponseComp.IsGrabbed() && Time::GameTimeSeconds > ReturnTime)
		{
			AcceleratedTransform.AccelerateTo(Origin.WorldTransform, 1.0, DeltaSeconds);
			NewLocation = AcceleratedTransform.GetLocation();
			ActorRotation = Acceleration.Rotation();
		}

		// Hitting contraint and calculating new delta
		if (OriginToNewLocation.Size() > CableLength)
		{
			if (bThrown)
				ReturnTime = Time::GameTimeSeconds + 1.0;
			bThrown = false;
			NewLocation = Origin.WorldLocation + OriginToNewLocation.GetSafeNormal() * CableLength;
			DeltaMove = NewLocation - ActorLocation;
		}

		if (MoveComp.PrepareMove(Movement))
		{
			Movement.AddDelta(DeltaMove);
			MoveComp.ApplyMove(Movement);
		}

		FHitResult HitResult;
		if (GetImpact(HitResult))
		{
			ActorVelocity = GetVelocityFromBounce(Velocity, 0.2, HitResult.ImpactNormal);			

			if (HasControl())
			{
				auto Socket = Cast<ASkylinePowerPlugSocket>(HitResult.Actor);
				CrumbHitTarget(Socket);
			}

			bHadImpact = true;
		}	
		else
		{
			bHadImpact = false;
		}

	}

	private void TemporalLog()
	{
#if EDITOR
		TEMPORAL_LOG(this, "State Bools").Value("Thrown", bThrown);
		TEMPORAL_LOG(this, "State Bools").Value("Plugged", bPlugged);
		TEMPORAL_LOG(this, "State Bools").Value("Grabbed", GravityWhipResponseComp.IsGrabbed());
#endif
	}

	private void UpdateControlGrabbed(float DeltaSeconds)
	{
		TimeSinceControlGrab += DeltaSeconds;
		bool bTargetingHatch = TargetedHatch != nullptr;
		bool bStretchedTooFar = (ActorLocation - Origin.WorldLocation).Size() > CableLength;
		bool bIsInDontReleaseInstantlyWindow = TimeSinceControlGrab < 1.0;
		if (!bTargetingHatch && !bIsInDontReleaseInstantlyWindow && bStretchedTooFar)
		{
			GravityWhipTargetComp.Disable(n"StretchedTooFar");
			CrumbReleaseFromStretchedTooFar();
		}
	}

	private void UpdateReelIn(float DeltaSeconds)
	{
		FVector Force;
		float Drag = FreeDrag;
		FVector ToOrigin = Origin.WorldLocation - ActorLocation;
		CableComp.CableLength = ToOrigin.Size() * 0.5;
		Force += ToOrigin * ReturnForce;
		Drag = ReturnDrag;

		if (!bLerpingIn)
		{
			AcceleratedTransform.SnapTo(ActorTransform, ActorVelocity);
			USkylinePowerPlugEventHandler::Trigger_OnStartReturnToSpool(this);
		}

		bLerpingIn = true;

		AcceleratedTransform.AccelerateTo(Origin.WorldTransform, LerpDuration, DeltaSeconds);
		ActorTransform = AcceleratedTransform.Value;

		if(!bIsSpooled && ActorTransform.Equals(Origin.WorldTransform, 100.0))
		{
			bIsSpooled = true;
			GravityWhipTargetComp.Enable(n"Thrown");
			GravityWhipTargetComp.Enable(n"StretchedTooFar");
			USkylinePowerPlugEventHandler::Trigger_OnFinishReturnToSpool(this);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbReleaseFromStretchedTooFar()
	{
		bThrown = true;
		ReturnTime = Time::GameTimeSeconds + ReturnDelay;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbHitTarget(ASkylinePowerPlugSocket Socket)
	{
		bThrown = false;
		GravityWhipTargetComp.Enable(n"Thrown");

		if (Socket != nullptr)
		{
			SetActorLocationAndRotation(Socket.ActorLocation, Socket.ActorRotation);
			Plug(Socket);
		}
		else if(!bHadImpact && ActorVelocity.Size() >= MIN_IMPACT_VELOCITY_THRESHOLD)
		{
			USkylinePowerPlugEventHandler::Trigger_OnImpact(this);
		}

		if (TargetedHatch != nullptr)
			TargetedHatch.bTargetedDontCloseHatch = false;
		TargetedHatch = nullptr;
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{	
		TimeSinceControlGrab = 0.0;
		bThrown = false;
		bLerpingIn = false;
		bIsSpooled = false;

		Unplug();

		USkylinePowerPlugEventHandler::Trigger_OnGrabbed(this);
	}

	UFUNCTION()
	private void HandleReleased(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		ReturnTime = Time::GameTimeSeconds + ReturnDelay;	
	}

	UFUNCTION()
	private void HandleThrown(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FHitResult HitResult, FVector Impulse)
	{
		bThrown = true;	
		ReturnTime = Time::GameTimeSeconds + ReturnDelay;
		MoveComp.RemoveMovementIgnoresActor(this);
		GravityWhipTargetComp.Disable(n"Thrown");

		FVector Direction = GetLaunchDirection(ActorLocation, GravityWhipResponseComp.AimLocation, ThrowSpeed);
		SetActorVelocity(Direction * ThrowSpeed);

		FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::WorldGeometry);
		Trace.UseLine();
		Trace.IgnoreActor(this);
		FVector TraceVector = GravityWhipResponseComp.AimLocation - ActorLocation;
		FHitResult EnvHit = Trace.QueryTraceSingle(ActorLocation, ActorLocation + TraceVector * 1.5);
		if (EnvHit.Actor != nullptr)
		{
			ASkylineAllySocketHatch SocketHatch = Cast<ASkylineAllySocketHatch>(EnvHit.Actor);
			if (SocketHatch != nullptr && SocketHatch.bHatchOpen)
			{
				if (SocketHatch.ActorLocation.Distance(Origin.WorldLocation) < CableLength)
				{
					TargetedHatch = SocketHatch;
					TargetedHatch.bTargetedDontCloseHatch = true;
				}
			}
		}

//		Debug::DrawDebugSphere(GravityWhipResponseComp.AimLocation, 100.0, Duration = 2.0);
//		Debug::DrawDebugLine(ActorLocation, ActorLocation + Direction.SafeNormal * 500.0, FLinearColor::Green, 10.0, 0.5);

		USkylinePowerPlugEventHandler::Trigger_OnThrown(this);
	}

	bool GetImpact(FHitResult& OutHitResult)
	{
		if (MoveComp.HasGroundContact())
			OutHitResult = MoveComp.GroundContact.ConvertToHitResult();

		if (MoveComp.HasWallContact())
			OutHitResult = MoveComp.WallContact.ConvertToHitResult();

		if (MoveComp.HasCeilingContact())
			OutHitResult = MoveComp.CeilingContact.ConvertToHitResult();

		return OutHitResult.bBlockingHit;
	}

	FVector GetVelocityFromBounce(FVector Velocity, float Restitution, FVector Normal)
	{
		float d = Velocity.DotProduct(Normal);
		float j = Math::Max(-(1 + Restitution) * d, 0.0);

		return Velocity + Normal * j;
	}

	UFUNCTION()
	void Plug(ASkylinePowerPlugSocket Socket, bool bWasInitialPlug = false)
	{
		if (Socket.bSocketed)
			return;

		bPlugged = true;
		GravityWhipTargetComp.Enable(n"Thrown");

		CurrentSocket = Socket;
		CurrentSocket.bSocketed = true;
		CurrentSocket.Activate();
		AttachToComponent(CurrentSocket.SocketPivot);
		MoveComp.AddMovementIgnoresActor(this, CurrentSocket);
		bSocketed = true;

		Socket.OnForceUnplug.AddUFunction(this, n"Unplug");

		if(!bWasInitialPlug)
			USkylinePowerPlugEventHandler::Trigger_OnPlugged(this);

		BP_OnPlugged();
	}

	UFUNCTION()
	void Unplug()
	{
		if (!bPlugged)
			return;

		bPlugged = false;
		ReturnTime = Time::GameTimeSeconds + ReturnDelay;	
		
		if (CurrentSocket != nullptr)
		{
			CurrentSocket.bSocketed = false;
			CurrentSocket.Deactivate();
			CurrentSocket.OnForceUnplug.Unbind(this, n"Unplug");
			USkylinePowerPlugEventHandler::Trigger_OnUnplugged(this);
		}

		DetachFromActor();
		bSocketed = false;

//		ActorVelocity = FVector::ZeroVector;

		ReturnTime = 0.0;
		BP_OnUnplugged();
		CurrentSocket = nullptr;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnPlugged() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnUnplugged() {}

	FVector GetLaunchDirection(FVector LaunchLocation, FVector TargetLocation, float LaunchSpeed)
	{
		FVector Direction;

		FVector ToTarget = TargetLocation - LaunchLocation;
		float LaunchSpeedSquared = LaunchSpeed * LaunchSpeed;
		float DistanceSquared = ToTarget.SizeSquared();

		float Root = LaunchSpeedSquared * LaunchSpeedSquared - Gravity * (Gravity * DistanceSquared + (2.0 * ToTarget.Z * LaunchSpeedSquared));

		float Angle = 15.0;

		if (Root >= 0.0)
			Angle = Math::RadiansToDegrees(-Math::Atan2(Gravity * Math::Sqrt(DistanceSquared), LaunchSpeedSquared + Math::Sqrt(Root)));

		FVector PitchAxis = ToTarget.CrossProduct(FVector::UpVector).SafeNormal;

		Direction = ToTarget.RotateAngleAxis(Angle, PitchAxis).SafeNormal;

		return Direction;
	}
};