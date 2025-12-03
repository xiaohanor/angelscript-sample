asset DentistCannonSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UDentistCannonAimingCapability);
	Capabilities.Add(UDentistCannonLaunchingCapability);
	Capabilities.Add(UDentistCannonLockPlayerCapability);
	Capabilities.Add(UDentistCannonResettingCapability);
};

enum EDentistCannonState
{
	Inactive,
	Aiming,
	Launching,
	Resetting,
};

UCLASS(Abstract)
class ADentistCannon : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent YawPivotComp;

	UPROPERTY(DefaultComponent, Attach = YawPivotComp)
	UStaticMeshComponent HingeMeshComp;

	UPROPERTY(DefaultComponent, Attach = YawPivotComp)
	USceneComponent PitchPivotComp;

	UPROPERTY(DefaultComponent, Attach = PitchPivotComp)
	USceneComponent SpringTopComp;

	UPROPERTY(DefaultComponent, Attach = SpringTopComp)
	UFauxPhysicsTranslateComponent SpringTranslateComp;

	UPROPERTY(DefaultComponent, Attach = SpringTranslateComp)
	UStaticMeshComponent SpringTopMeshComp;

	UPROPERTY(DefaultComponent, Attach = SpringTranslateComp)
	USceneComponent ToothAttachmentComp;

	UPROPERTY(DefaultComponent, Attach = PitchPivotComp)
	USceneComponent BarrelRootComp;

	UPROPERTY(DefaultComponent, Attach = BarrelRootComp)
	UStaticMeshComponent BarrelMeshComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(DentistCannonSheet);

	UPROPERTY(DefaultComponent)
	UDentistToothMovementResponseComponent MovementResponseComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;
	default MovementImpactCallbackComp.bTriggerLocally = true;
	default MovementImpactCallbackComp.bUseSpecifiedComponentsForImpacts = true;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;

	UPROPERTY(EditAnywhere, Category = "Aiming")
	float AimRotateDuration = 2;

	UPROPERTY(EditInstanceOnly, Category = "Aiming|Initial", Meta = (ClampMin = "-180.0", ClampMax = "180.0"))
	float InitialYaw;

	UPROPERTY(EditInstanceOnly, Category = "Aiming|Initial", Meta = (ClampMin = "-180.0", ClampMax = "180.0"))
	float InitialPitch;

	UPROPERTY(EditInstanceOnly, Category = "Aiming|Target", Meta = (ClampMin = "0", ClampMax = "1000"))
	ADentistCannonTarget AimAtTarget = nullptr;

	UPROPERTY(EditInstanceOnly, Category = "Aiming|Target", Meta = (EditCondition = "AimAtTarget != nullptr", EditConditionHides, ClampMin = "0.1", ClampMax = "20.0"))
	float FlyToAimAtTargetDuration = 5;

	UPROPERTY(EditInstanceOnly, Category = "Aiming|Target", Meta = (ClampMin = "0", ClampMax = "1000"))
	float TargetCannonHeight = 200;

	UPROPERTY(EditInstanceOnly, Category = "Aiming|Target", Meta = (EditCondition = "AimAtTarget == nullptr", EditConditionHides, ClampMin = "-180.0", ClampMax = "180.0"))
	float TargetYaw = 90;

	UPROPERTY(EditInstanceOnly, Category = "Aiming|Target", Meta = (EditCondition = "AimAtTarget == nullptr", EditConditionHides, ClampMin = "-180.0", ClampMax = "180.0"))
	float TargetPitch = 45;

#if EDITOR
	UPROPERTY(EditInstanceOnly, Transient, Category = "Aiming|Preview", Meta = (ClampMin = "0.0", ClampMax = "1.0"))
	float PreviewAlpha = 0.0;

	UPROPERTY(EditInstanceOnly, Transient, Category = "Aiming|Preview", Meta = (ClampMin = "0.0", ClampMax = "30.0"))
	float PreviewDuration = 10.0;
#endif

	UPROPERTY(EditAnywhere, Category = "Aiming|Camera")
	AHazeCameraActor CameraToActivateWhileAiming = nullptr;

	UPROPERTY(EditAnywhere, Category = "Aiming|Camera", Meta = (EditCondition = "CameraToActivateWhileAiming != nullptr", EditConditionHides))
	float CameraBlendInTime = 2.0;
	
	UPROPERTY(EditAnywhere, Category = "Aiming|Camera", Meta = (EditCondition = "CameraToActivateWhileAiming != nullptr", EditConditionHides))
	float CameraBlendOutTime = 3.0;

	UPROPERTY(EditAnywhere, Category = "Launch", Meta = (EditCondition = "AimAtTarget == nullptr"))
	float LaunchSpeed = 1000;

	UPROPERTY(EditAnywhere, Category = "Launch")
	float Gravity = 3000;

	// How long to wait after aiming is finished before we launch the player
	UPROPERTY(EditAnywhere, Category = "Launch")
	float LaunchDelay = 0.5;

	// How fast to play back the trajectory
	UPROPERTY(EditAnywhere, Category = "Launch")
	float LaunchPlayRate = 1;

	// How long it takes after a launch to start resetting
	UPROPERTY(EditAnywhere, Category = "Reset")
	float ResetDelay = 1.0;

	// How long it takes to reset back to the initial rotation, and allow another enter
	UPROPERTY(EditAnywhere, Category = "Reset")
	float ResetDuration = 1.0;

	private AHazePlayerCharacter PlayerInCannon;
	private EDentistCannonState State = EDentistCannonState::Inactive;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		FRotator AimAtRotation = FRotator::MakeFromXZ(GetLaunchDirection(), FVector::UpVector);
		FRotator RelativeRotation = ActorTransform.InverseTransformRotation(AimAtRotation);
		TargetPitch = -(90 - RelativeRotation.Pitch);
		TargetYaw = RelativeRotation.Yaw;

		SetCannonAlpha(PreviewAlpha);
	}

	void UpdateAiming()
	{
		FRotator AimAtRotation = FRotator::MakeFromXZ(GetLaunchDirection(), FVector::UpVector);
		FRotator RelativeRotation = ActorTransform.InverseTransformRotation(AimAtRotation);
		TargetPitch = -(90 - RelativeRotation.Pitch);
		TargetYaw = RelativeRotation.Yaw;

		SetCannonAlpha(PreviewAlpha);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetCannonAlpha(0);

		MovementResponseComp.OnGroundPoundedOn.AddUFunction(this, n"OnGroundPoundedOn");
		MovementImpactCallbackComp.AddComponentUsedForImpacts(SpringTopMeshComp);
	}

	UFUNCTION()
	private void OnGroundPoundedOn(AHazePlayerCharacter GroundPoundPlayer, FHitResult Impact)
	{
		if(!CanEnterCannon())
			return;
		
		OnPlayerEnteredCannon(GroundPoundPlayer);
	}

	bool CanEnterCannon() const
	{
		if(IsOccupied())
			return false;

		if(State == EDentistCannonState::Resetting)
			return false;

		return true;
	}

	void OnPlayerEnteredCannon(AHazePlayerCharacter Player)
	{
		PlayerInCannon = Player;

		State = EDentistCannonState::Aiming;
	}

	AHazePlayerCharacter GetPlayerInCannon() const
	{
		return PlayerInCannon;
	}

	void StartAiming()
	{
		State = EDentistCannonState::Aiming;
	}

	void Launch()
	{
		State = EDentistCannonState::Launching;
	}

	void OnPlayerLaunched()
	{
		SpringTranslateComp.ApplyImpulse(SpringTranslateComp.WorldLocation, SpringTranslateComp.UpVector * 500);
		PlayerInCannon = nullptr;
	}

	void StartResetting()
	{
		State = EDentistCannonState::Resetting;
		PlayerInCannon = nullptr;
	}

	void Reset()
	{
		State = EDentistCannonState::Inactive;
		PlayerInCannon = nullptr;
	}

	bool IsOccupied() const
	{
		if(PlayerInCannon != nullptr)
			return true;

		return false;
	}

	bool IsOccupiedBy(AHazePlayerCharacter Player) const
	{
		return PlayerInCannon == Player;
	}

	bool IsStateActive(EDentistCannonState InState) const
	{
		return State == InState;
	}

	void SetCannonAlpha(float Alpha)
	{
		FRotator InitialRotation = FRotator(InitialPitch, InitialYaw, 0);
		FRotator TargetRotation = FRotator(TargetPitch, TargetYaw, 0);
		FRotator Rotation = Math::LerpShortestPath(InitialRotation, TargetRotation, Alpha);

		YawPivotComp.SetRelativeRotation(FRotator(0, Rotation.Yaw, 0));
		PitchPivotComp.SetRelativeRotation(FRotator(Rotation.Pitch, 0, 0));

		float CannonHeight = Math::Lerp(0, TargetCannonHeight, Alpha);
		YawPivotComp.SetRelativeLocation(FVector(0, 0, CannonHeight));
	}

	private FVector GetLaunchLocation() const
	{
		return SpringTopComp.WorldLocation;
	}

	private FVector GetLaunchVelocity() const
	{
		if(AimAtTarget != nullptr)
		{
			FVector Distance = AimAtTarget.ActorLocation - GetLaunchLocation();

			FVector HorizontalDistance = Distance.ConstrainToPlane(FVector::UpVector);
			float VerticalDistance = Distance.DotProduct(FVector::UpVector);

			FVector LaunchVelocity = HorizontalDistance / FlyToAimAtTargetDuration;
			LaunchVelocity += FVector::UpVector * Trajectory::GetSpeedToReachTarget(VerticalDistance, FlyToAimAtTargetDuration, -Gravity);
			return LaunchVelocity;
		}
		else
		{
			return SpringTopComp.UpVector * LaunchSpeed;
		}
	}

	private FVector GetLaunchDirection() const
	{
		return GetLaunchVelocity().GetSafeNormal();
	}

	FTraversalTrajectory GetLaunchTrajectory() const
	{
		FVector InitialLocation = GetLaunchLocation();
		FVector InitialVelocity = GetLaunchVelocity();

		FTraversalTrajectory Trajectory;
		Trajectory.LaunchLocation = InitialLocation;
		Trajectory.LaunchVelocity = InitialVelocity;
		Trajectory.Gravity = FVector::DownVector * Gravity;

		return Trajectory;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Dentist::Cannon::VisualizeCannon(this);
	}
#endif
};

namespace Dentist::Cannon
{
#if EDITOR
	void VisualizeCannon(const ADentistCannon Cannon)
	{
		float Time = 0;
		const float TimeStep = 1.0 / 10;
		float Duration = Cannon.PreviewDuration;

		const FTraversalTrajectory Trajectory = Cannon.GetLaunchTrajectory();

		while(Time < Duration)
		{
			FVector PreviousLocation = Trajectory.GetLocation(Time);
			Time += TimeStep;
			FVector NewLocation = Trajectory.GetLocation(Time);

			//Debug::DrawDebugLine(PreviousLocation, NewLocation, FLinearColor::Black, 1);

			FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			TraceSettings.IgnorePlayers();
			TraceSettings.IgnoreActor(Cannon);
			TraceSettings.UseSphereShape(Dentist::CollisionRadius);
			FHitResult Hit = TraceSettings.QueryTraceSingle(PreviousLocation, NewLocation);

			if(Hit.IsValidBlockingHit())
				NewLocation = Hit.Location;

			Debug::DrawDebugLine(PreviousLocation, NewLocation, FLinearColor::Red, 10);

			if(Hit.IsValidBlockingHit())
			{
				Debug::DrawDebugSphere(Hit.Location, Dentist::CollisionRadius, 12, FLinearColor::Green);
				Time -= TimeStep * (1.0 - Hit.Time);
				Duration = Time;
				break;
			}
		}

		float PointTime = (Time::GameTimeSeconds * Cannon.LaunchPlayRate) % Duration;
		const FVector PointLocation = Trajectory.GetLocation(PointTime);
		Debug::DrawDebugSphere(PointLocation, Dentist::CollisionRadius, 12, FLinearColor::Green);
		
		const FVector PointVelocity = Trajectory.GetVelocity(PointTime);
		Debug::DrawDebugDirectionArrow(PointLocation, PointVelocity, PointVelocity.Size(), 5, FLinearColor::Green);
	}
#endif
}