UCLASS(Abstract)
class UFeatureAnimInstanceJetski : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureJetski Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureJetskiAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsInAir;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float SolidGroundShakeAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bUnderWater;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasJumpedFromUnderwater;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsActioningDive;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bReflectedOffWall;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bReflectedOffWallRight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EJetskiMovementState MovementState;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector HipsBump;

	FHazeAcceleratedFloat Spring;
	float AirTime;

	AJetski Jetski;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureJetski NewFeature = GetFeatureAsClass(ULocomotionFeatureJetski);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		if (Player.AttachParentActor != nullptr)
			Jetski = Cast<AJetski>(Player.AttachParentActor);

#if !RELEASE
		DevTogglesJetski::PrintAnimationValues.MakeVisible();
#endif
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Jetski == nullptr)
			return;

		const float Speed = Jetski.ActorRotation.UnrotateVector(Jetski.ActorVelocity).Size2D();
		const float TurnSpeed = Jetski.AngularSpeed;

		BlendspaceValues = FVector2D(Math::Clamp(-TurnSpeed / 60, -1.0, 1.0),
									 Math::Clamp((Speed - 50) / 1500, 0.0, 1.0));

		float SpringTarget = Math::Clamp(Jetski.ActorVerticalVelocity.Z / 100, -1.0, 1.0);
		Spring.SpringTo(SpringTarget / 4, 30, 0.4, DeltaTime);

		HipsBump.Z = Math::Clamp((Spring.Value * 40), -40.0, 0.0);
		HipsBump.X = Math::Clamp((Spring.Value * 20), -20.0, 0.0);
		HipsBump *= BlendspaceValues.Y;

		bUnderWater = Jetski.GetMovementState() == EJetskiMovementState::Underwater;
		bHasJumpedFromUnderwater = Jetski.bHasJumpedFromUnderwater;
		bIsActioningDive = Jetski.Input.IsActioningDive();

		SolidGroundShakeAlpha = Jetski.GetMovementState() == EJetskiMovementState::Ground ? BlendspaceValues.Y : 0;

		if (Jetski.GetMovementState() == EJetskiMovementState::Air)
		{
			AirTime += DeltaTime;
			if (AirTime > 0.5 || bHasJumpedFromUnderwater)
			{
				bIsInAir = true;
			}
		}
		else
		{
			AirTime = 0;
			bIsInAir = false;
		}

		bReflectedOffWall = ReflectedThisFrame();

		if(bReflectedOffWall)
		{
			const FVector ReflectionImpulseCS = HazeOwningActor.ActorRotation.UnrotateVector(Jetski.ReflectedImpulse);
			bReflectedOffWallRight = ReflectionImpulseCS.Y > 0;
		}

#if !RELEASE
		if(DevTogglesJetski::PrintAnimationValues.IsEnabled())
		{
			PrintToScreen(f"{BlendspaceValues=}", 0, Player.GetPlayerDebugColor());
			PrintToScreen(f"{bIsInAir=}", 0, Player.GetPlayerDebugColor());
			PrintToScreen(f"{bUnderWater=}", 0, Player.GetPlayerDebugColor());
			PrintToScreen(f"{bHasJumpedFromUnderwater=}", 0, Player.GetPlayerDebugColor());
			PrintToScreen(f"{bIsActioningDive=}", 0, Player.GetPlayerDebugColor());
			PrintToScreen(f"{bReflectedOffWall=}", 0, Player.GetPlayerDebugColor());
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}

	bool ReflectedThisFrame() const
	{
		return Jetski.ReflectedFrame == Time::FrameNumber;
	}
}
