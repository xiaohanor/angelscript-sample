class ARemoteHackableTetheredActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsSplineTranslateComponent TranslateComp;
	default TranslateComp.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromMioControl;
	default TranslateComp.bConstrainZ = true;
	default TranslateComp.bClockwise = false;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsConeRotateComponent RotateComp;
	default RotateComp.NetworkMode = EFauxPhysicsConeRotateNetworkMode::SyncedFromMioControl;
	default RotateComp.SpringStrength = 0.015;
	default RotateComp.ConeAngle = 20.0;
	default RotateComp.ConstrainBounce = 0.0;

	default TranslateComp.bConstrainZ = true;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	USceneComponent HoverRoot;

	UPROPERTY(DefaultComponent, Attach = HoverRoot)
	UCableComponent CableComp;
	default CableComp.RelativeLocation = FVector(0.0, 0.0, 50.);
	default CableComp.EndLocation = FVector(0.0, 0.0, 1000.0);
	default CableComp.CableLength = 600.0;
	default CableComp.NumSegments = 15;

	UPROPERTY(DefaultComponent, Attach = HoverRoot)
	URemoteHackingResponseComponent HackingComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableTetheredActorCapability");

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 8000;

	UPROPERTY(EditAnywhere)
	float MoveForce = 1800.0;

	UPROPERTY(EditAnywhere)
	bool bVertical = false;

	UPROPERTY(EditAnywhere)
	bool bSideScroller = false;

	UPROPERTY(EditAnywhere)
	bool bDisabled = false;

	float DefaultSpringStrenth;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);
		
		DefaultSpringStrenth = TranslateComp.SpringStrength;

		if (!bDisabled)
			Timer::SetTimer(this, n"AddRandomRotationImpulse", 2.0, false);
		else
			TranslateComp.AddDisabler(this);
	}

	UFUNCTION(BlueprintCallable)
	void Enable()
	{
		TranslateComp.RemoveDisabler(this);
		Timer::SetTimer(this, n"AddRandomRotationImpulse", 2.0, false);
		bDisabled = false;
		TranslateComp.ApplyImpulse(TranslateComp.WorldLocation, FVector(0.0, 0.0, 500.0));
		HackingComp.SetHackingAllowed(true);

		BP_Enabled();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Enabled() {}

	UFUNCTION(NotBlueprintCallable)
	void AddRandomRotationImpulse()
	{
		FVector Dir = ActorForwardVector;
		float RandomAngle = Math::RandRange(0.0, 360.0);
		Dir = ActorForwardVector.RotateAngleAxis(RandomAngle, FVector::UpVector);
		RotateComp.ApplyImpulse((RotateComp.UpVector * 100.0), Dir * 75.0);

		float RandomDelay = Math::RandRange(1.25, 2.5);
		Timer::SetTimer(this, n"AddRandomRotationImpulse", RandomDelay, false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bDisabled)
			return;

		float HoverOffset = Math::Sin(Time::GameTimeSeconds * 1.5) * 14.0;

		float XOffset = Math::Sin(Time::GameTimeSeconds * 1.3) * 20.0;
		float YOffset = Math::Sin(Time::GameTimeSeconds * 2.2) * 8.0;
		HoverRoot.SetRelativeLocation(FVector(XOffset, YOffset, HoverOffset));
	}
}

class URemoteHackableTetheredActorCapability : URemoteHackableBaseCapability
{
	ARemoteHackableTetheredActor TetheredActor;

	FHazeAcceleratedFloat AccFloat;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		TetheredActor = Cast<ARemoteHackableTetheredActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		TetheredActor.TranslateComp.SpringStrength = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TetheredActor.TranslateComp.SpringStrength = TetheredActor.DefaultSpringStrenth;
		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		if (HasControl())
		{
			if (TetheredActor.TranslateComp.GetVelocity().Size() > 100.0)
			{
				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Sin(ActiveDuration * 30) * 0.2;
				FF.RightMotor = Math::Sin(-ActiveDuration * 30) * 0.2;
				Player.SetFrameForceFeedback(FF);
			}

			if (TetheredActor.bSideScroller)
			{
				FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
				FVector ForceDir = FVector(0.0, Input.Y, Input.X);
				TetheredActor.TranslateComp.ApplyForce(TetheredActor.TranslateComp.WorldLocation, ForceDir * TetheredActor.MoveForce);

				FVector WorldInput = PlayerMoveComp.MovementInput;
				FRotator TargetRot = WorldInput.IsZero() ? TetheredActor.HoverRoot.WorldRotation : WorldInput.Rotation();
				FRotator Rot = Math::RInterpTo(TetheredActor.HoverRoot.WorldRotation, TargetRot, DeltaTime, 2.0);
				TetheredActor.HoverRoot.SetWorldRotation(Rot);
				return;
			}

			if (TetheredActor.bVertical)
			{
				FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
				FVector ForceDir = FVector(0.0, 0.0, Input.X);
				TetheredActor.TranslateComp.ApplyForce(TetheredActor.TranslateComp.WorldLocation, ForceDir * TetheredActor.MoveForce);
			}
			else
			{
				FVector Input = PlayerMoveComp.MovementInput;
				TetheredActor.TranslateComp.ApplyForce(TetheredActor.TranslateComp.WorldLocation, Input * TetheredActor.MoveForce);
				TetheredActor.RotateComp.ApplyForce(TetheredActor.RotateComp.WorldLocation + (TetheredActor.RotateComp.UpVector * 100.0), -Input * 2000.0);

				FRotator TargetRot = Input.IsZero() ? TetheredActor.HoverRoot.WorldRotation : Input.Rotation();
				FRotator Rot = Math::RInterpTo(TetheredActor.HoverRoot.WorldRotation, TargetRot, DeltaTime, 2.0);
				TetheredActor.HoverRoot.SetWorldRotation(Rot);
			}
		}
	}
}