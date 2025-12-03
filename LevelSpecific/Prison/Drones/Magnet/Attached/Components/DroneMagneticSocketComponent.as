/**
 * Component used for locking the player in a magnetic socket
 */
class UDroneMagneticSocketComponent : UMagnetDroneAutoAimComponent
{
	default TargetShape.Type = EHazeShapeType::None;
	default TargetShape.BoxExtents = FVector::ZeroVector;

	UPROPERTY(EditAnywhere, Category = "Attraction")
	bool bRelativeAttraction = false;

	UPROPERTY(EditAnywhere, Category = "Magnet Jump")
	float MagnetJumpAimConeAngle = 30;

	UPROPERTY(EditAnywhere, Category = "Magnet Jump")
	float MagnetJumpSocketConeAngle = 55;

	// Angle can give a very small tolerance when close to the player, so we also use a "cylinder"
	UPROPERTY(EditAnywhere, Category = "Magnet Jump")
	float MagnetJumpCylinderRadius = 100;

	UPROPERTY(EditAnywhere, Category = "Magnet Jump")
	float MagnetJumpDistance = 700;

#if EDITOR
	UPROPERTY(EditAnywhere, Category = "Magnet Jump")
	bool bVisualizeMagnetJumpAim = true;
#endif

	/**
	 * When attaching, in addition to collision, also check if we are within this radius.
	 * Visualized as a green circle.
	 */
	UPROPERTY(EditAnywhere, Category = "Attached")
	float AttachRadius = 80;

	UPROPERTY(EditAnywhere, Category = "Attached|Camera")
	bool bUseAutomaticWallCamera = true;

	// FB TODO: Activate camera support is a hack on this. Rewrite the handling of this and SurfaceComponent camera when we are allowed to break stuff in the level
	UPROPERTY(EditInstanceOnly, Category = "Attached|Camera", Meta = (EditCondition = "!bUseAutomaticWallCamera"))
	AHazeCameraActor CameraActor;

	UPROPERTY(EditInstanceOnly, Category = "Attached|Camera", Meta = (EditCondition = "!bUseAutomaticWallCamera && CameraActor != nullptr", EditConditionHides))
	float ActivateCameraBlendInTime = 1;

	UPROPERTY(EditInstanceOnly, Category = "Attached|Camera", Meta = (EditCondition = "!bUseAutomaticWallCamera && CameraActor != nullptr", EditConditionHides))
	float ActivateCameraBlendOutTime = 1;

	UPROPERTY(EditInstanceOnly, Category = "Attached|Camera", Meta = (EditCondition = "!bUseAutomaticWallCamera && CameraActor != nullptr", EditConditionHides))
	float ActivateCameraWaitUntilDeactivateDuration = 1;

	UPROPERTY(EditInstanceOnly, Category = "Attached|Camera", Meta = (EditCondition = "!bUseAutomaticWallCamera && CameraActor != nullptr", EditConditionHides))
	EHazeCameraPriority ActivateCameraPriority = EHazeCameraPriority::Low;

	/**
	 * When attached in a socket, we sweep for any obstacles.
	 * This can be bad if we go into a socket where we intersect some
	 * geometry. Assign those actors here to ignore them while in the socket.
	 */
	UPROPERTY(EditInstanceOnly, Category = "Movement")
	protected TArray<TSoftObjectPtr<AActor>> MovementIgnoreActors;
	
	UPROPERTY(EditAnywhere, Category = "Detach")
	bool bAllowDeattaching = true;

	UPROPERTY(EditAnywhere, Category = "Detach", Meta = (EditCondition = "bAllowDeattaching"))
	bool bDetachByToggle = false;

	/**
	 * If true, we can still attract, but will immediately detach. Use for when we just want to smash into something.
	 */
	UPROPERTY(EditAnywhere, Category = "Detach")
	bool bImmediatelyDetach = false;

	UPROPERTY(EditAnywhere, Category = "Detach")
	bool bJumpOnDetach = true;

	UPROPERTY(EditAnywhere, Category = "Detach", Meta = (EditCondition = "bJumpOnDetach", ClampMin = "0.0", ClampMax = "1.0"))
	float JumpOnDetachImpulseMultiplier = 1.0;

	UPROPERTY(EditInstanceOnly, Category = "Detach", Meta = (EditCondition = "bJumpOnDetach"))
	bool bIgnoreOverlappingComponentsOnDetach = false;

	UPROPERTY(EditAnywhere, Category = "Detach", Meta = (EditCondition = "bJumpOnDetach"))
	bool bOnlyJumpOnPlayerDetach = false;

	UPROPERTY()
	FOnMagnetDroneStartAttraction OnMagnetDroneStartAttraction;

	UPROPERTY()
	FOnMagnetDroneEndAttraction OnMagnetDroneEndAttraction;

	UPROPERTY()
    FOnMagnetDroneAttached OnMagnetDroneAttached;

	UPROPERTY()
    FOnMagnetDroneDetached OnMagnetDroneDetached;

	TArray<AActor> IgnoredActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnMagnetDroneAttached.AddUFunction(this, n"OnAttached");
	}

	bool ThirdPersonTargeting(FTargetableQuery& Query) const override
	{
		bool bIsAttachedToUs = false;
		if(IsAttractJumpAim(Query.Player, bIsAttachedToUs))
		{
			// When attached, we perform a special attract jump aim instead
			if(bIsAttachedToUs)
				return false;

			if(!IsWithinJumpAimCone(Query))
				return false;

			Targetable::ApplyTargetableRange(Query, MagnetJumpDistance);
		}
		else
		{
			return Super::ThirdPersonTargeting(Query);
		}

		return true;
	}

	bool TopDownTargeting(FTargetableQuery& Query) const override
	{
		bool bIsAttachedToUs = false;
		if(IsAttractJumpAim(Query.Player, bIsAttachedToUs))
		{
			if(bIsAttachedToUs)
				return false;

			if(!IsWithinJumpAimCone(Query))
				return false;

			Targetable::ApplyTargetableRange(Query, MagnetJumpDistance);
		}
		else
		{
			return Super::TopDownTargeting(Query);
		}

		return true;
	}

	bool IsAttractJumpAim(AHazePlayerCharacter Player, bool&out bOutIsAttachedToUs) const
	{
		auto AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
		if(AttachedComp == nullptr)
			return false;

		if(!AttachedComp.IsAttached())
			return false;

		bOutIsAttachedToUs = AttachedComp.AttachedData.GetSocketComp() == this;
		return true;
	}

	bool IsWithinJumpAimCone(FTargetableQuery& Query) const
	{
		auto AttractJumpComp = UMagnetDroneAttractJumpComponent::Get(Query.Player);
		if(AttractJumpComp == nullptr)
			return true;

		const FVector PlayerCenterLocation = Query.Player.ActorCenterLocation;

		const FVector SweepDirection = AttractJumpComp.GetJumpDirection();
		FVector ToTarget = WorldLocation - PlayerCenterLocation;

		const float AimAngle = ToTarget.GetAngleDegreesTo(SweepDirection);
		const bool bWithinAimAngle = AimAngle < MagnetJumpAimConeAngle;

		const float DistanceToJumpRay = ToTarget.VectorPlaneProject(SweepDirection).Size();
		const bool bWithinRadius = DistanceToJumpRay < MagnetJumpCylinderRadius;

		if(!bWithinAimAngle && !bWithinRadius)
			return false;

		const float SocketAngle = ForwardVector.GetAngleDegreesTo(-SweepDirection);
		if(SocketAngle > MagnetJumpSocketConeAngle)
			return false;

		return true;
	}

	UFUNCTION()
	private void OnAttached(FOnMagnetDroneAttachedParams Params)
	{
		if(!MovementIgnoreActors.IsEmpty() && IgnoredActors.IsEmpty())
		{
			for(auto IgnoredActor : MovementIgnoreActors)
			{
				auto Actor = IgnoredActor.Get();
				if(Actor == nullptr)
					continue;

				IgnoredActors.Add(Actor);
			}
		}
	}

	float DistanceFromPoint(FVector Point, bool bProjectToPlane) const override
	{
		if(bProjectToPlane)
			return WorldLocation.Distance(Point.PointPlaneProject(WorldLocation, ForwardVector));
		else
			return WorldLocation.Distance(Point);
	}

	UFUNCTION(BlueprintCallable)
	void ForceDetachJumpMagnetDrone()
	{
		auto AttachedComp = UMagnetDroneAttachedComponent::Get(Drone::GetMagnetDronePlayer());

		if(!AttachedComp.IsAttachedToSocket())
			return;

		if(AttachedComp.AttachedData.GetSocketComp() != this)
			return;

		AttachedComp.Detach(n"Socket_ForceDetachJumpMagnetDrone");
	}

#if EDITOR
	protected void DebugDraw() override
	{
		Debug::DrawDebugSphere(GetWorldLocation(), 40.0, 12, FLinearColor::Red);
	}
#endif
}

#if EDITOR
class UDroneMagneticSocketComponentVisualizer : UAutoAimTargetVisualizer
{
	default VisualizedClass = UDroneMagneticSocketComponent;

    UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component) override
	{
		Super::VisualizeComponent(Component);

		const auto SocketComp = Cast<UDroneMagneticSocketComponent>(Component);
		if(SocketComp == nullptr)
			return;

		SetRenderForeground(false);

		const FVector Location = SocketComp.GetWorldLocation();
		DrawWireSphere(Location, MagnetDrone::Radius, FLinearColor::Red);
		DrawCircle(Location, SocketComp.AttachRadius, FLinearColor::Green, 3, SocketComp.ForwardVector);

		if(SocketComp.bVisualizeMagnetJumpAim)
		{
			const float CylinderHalfHeight = SocketComp.MagnetJumpDistance * 0.5;
			DrawCone(Location, SocketComp.ForwardVector, SocketComp.MagnetJumpAimConeAngle, CylinderHalfHeight * 2, FLinearColor::LucBlue);
			DrawCone(Location, SocketComp.ForwardVector, SocketComp.MagnetJumpSocketConeAngle, CylinderHalfHeight * 2, FLinearColor::DPink);
			DrawWireCylinder(Location + (SocketComp.ForwardVector * CylinderHalfHeight), FRotator::MakeFromZ(SocketComp.ForwardVector), FLinearColor::LucBlue, SocketComp.MagnetJumpCylinderRadius, CylinderHalfHeight, 16);
		}
	}
}
#endif