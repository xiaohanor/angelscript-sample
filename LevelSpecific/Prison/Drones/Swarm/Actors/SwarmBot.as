event void FSwarmBotRespawnEvent();

class ASwarmBot : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.SetbAbsoluteScale(true);

	UPROPERTY(DefaultComponent, EditAnywhere)
	USphereComponent Collider;
	default Collider.SetbAbsoluteRotation(true);
	default Collider.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	// Expensive as all balls with shadows on
	// UPROPERTY(DefaultComponent, EditAnywhere)
	// UPointLightComponent PointLight;
	// default PointLight.SetRelativeLocation(ActorUpVector * 5.0);
	// default PointLight.SetCastShadows(false);

	UPROPERTY(DefaultComponent)
	USwarmBotMovementComponent MovementComponent;

	// We will change the swarmbot's mesh transform through this struct
	FHazeSwarmBotAnimData GroupSkelMeshAnimData;

	UPlayerSwarmDroneComponent PlayerSwarmDroneComponent;

	UPROPERTY()
	FSwarmBotRespawnEvent OnSwarmBotRespawnEvent;

	USwarmBotLerp CurrentLerp = nullptr;

	// Transform relative to the attached mesh
	FTransform InitialTransformOnMesh;

	private TInstigated<bool> RespawnBlocked;
	default RespawnBlocked.DefaultValue = false;

	float RetractedScale;
	float OGPointLightIntensity;
	float OGColliderRadius;

	bool bSwarmActive;
	bool bSwarmTransitioning;

	access SwarmBoat = private, UPlayerSwarmBoatComponent, USwarmBoatMovementCapability;
	access : SwarmBoat bool bBoatPropeller;

	private bool bMeshRetracted;

	int Id;

	const float RespawnDelay = 1.0;
	float LastRespawnTimeStamp;
	bool bRespawning;

	void Initialize(UPlayerSwarmDroneComponent SwarmDroneComponent, float DroneRadius, int BotId)
	{
		Id = BotId;
		PlayerSwarmDroneComponent = SwarmDroneComponent;
		OGPointLightIntensity = 0.0; // PointLight.Intensity;
		OGColliderRadius = Collider.SphereRadius;
		RetractedScale = IsRetractedInnerLayer() ? 1.8 : SwarmDrone::SwarmBotScale;

		GroupSkelMeshAnimData.BotIndex = BotId;
		GroupSkelMeshAnimData.Transform.SetScale3D(FVector(RetractedScale));

		SetActorTickEnabled(true);

		// Setup initial transform on mesh
		AttachToComponent(PlayerSwarmDroneComponent.DroneMesh);
		InitialTransformOnMesh.SetLocation(GetSwarmBotRelativeLocationOnDroneMesh(DroneRadius));
		InitialTransformOnMesh.SetRotation(FQuat::MakeFromZ(InitialTransformOnMesh.Location));

		ResetRelativeTransform();

		PlayerSwarmDroneComponent.OnSwarmTransitionStartEvent.AddUFunction(this, n"OnSwarmTransitionStart");
		PlayerSwarmDroneComponent.OnSwarmTransitionCompleteEvent.AddUFunction(this, n"OnSwarmTransitionComplete");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (ShouldRespawnOffCamera())
		{
			bRespawning = true;
			OnSwarmBotRespawnEvent.Broadcast();
			LastRespawnTimeStamp = Time::GameTimeSeconds;
		}

		UpdateSkelMeshAnimData();

		// UpdatePointLightPulse(DeltaTime);

		UpdateLerp(DeltaTime);
	}

	void UpdateSkelMeshAnimData()
	{
		GroupSkelMeshAnimData.Transform.SetLocation(ActorTransform.Location);
		GroupSkelMeshAnimData.Transform.SetRotation(ActorTransform.Rotation);

		if (bMeshRetracted)
		{
			GroupSkelMeshAnimData.AnimState = EHazeSwarmBotAnimState::Retracted;
			return;
		}

		// Update state
		if (bSwarmActive)
		{
			if (PlayerSwarmDroneComponent.Player.IsAnyCapabilityActive(SwarmDroneTags::SwarmDroneCongaLineCapability))
			{
				GroupSkelMeshAnimData.AnimState = EHazeSwarmBotAnimState::Push;
				GroupSkelMeshAnimData.PlayRate = Math::Clamp(MovementComponent.ActualVelocity.Size() / 200.0, 1.0, 3.0);
			} else if (PlayerSwarmDroneComponent.IsHovering())
			{
				GroupSkelMeshAnimData.AnimState = Id == 0 ? EHazeSwarmBotAnimState::HoverDive : EHazeSwarmBotAnimState::HoverParachute;
			}
			else if (PlayerSwarmDroneComponent.Player.IsAnyCapabilityActive(SwarmDroneTags::SwarmGliderCapability))
			{
				GroupSkelMeshAnimData.AnimState = EHazeSwarmBotAnimState::HoverDive;
			}
			else if (PlayerSwarmDroneComponent.Player.IsAnyCapabilityActive(SwarmDroneTags::SwarmAirMovementCapability))
			{
				// GroupSkelMeshAnimData.AnimState = EHazeSwarmBotAnimState::BoatPropeller;
				GroupSkelMeshAnimData.AnimState = EHazeSwarmBotAnimState::Retracted;
			}
			// else if (PlayerSwarmDroneHijackComponent.IsHijackActive())
			// {
			// 	GroupSkelMeshAnimData.AnimState = EHazeSwarmBotAnimState::Walk;
			// 	GroupSkelMeshAnimData.PlayRate = 0.2;
			// }
			else if (MovementComponent.ActualVelocity.Size() > 10.0)
			{
				GroupSkelMeshAnimData.AnimState = EHazeSwarmBotAnimState::Walk;
				GroupSkelMeshAnimData.PlayRate = Math::Clamp(MovementComponent.ActualVelocity.Size() / 200.0, 1.0, 3.0);
			}
			else
			{
				GroupSkelMeshAnimData.AnimState = EHazeSwarmBotAnimState::Idle;
			}
		}
		else
		{
			if (PlayerSwarmDroneComponent.bFloating && bBoatPropeller)
			{
				GroupSkelMeshAnimData.AnimState = EHazeSwarmBotAnimState::BoatPropeller;
			}
			else
			{
				GroupSkelMeshAnimData.AnimState = EHazeSwarmBotAnimState::Retracted;
			}
		}
	}

	// void UpdatePointLightPulse(float DeltaTime)
	// {
	// 	if (PointLight.GetbVisible() && !bSwarmActive)
	// 	{
	// 		float Intensity = Math::Max(OGPointLightIntensity * 0.5, Math::Abs(Math::Sin(Time::GameTimeSeconds) * 0.8) * OGPointLightIntensity);
	// 		PointLight.SetIntensity(Intensity);
	// 	}
	// }

	void UpdateLerp(float DeltaTime)
	{
		if (CurrentLerp == nullptr)
			return;

		FTransform LerpTransform = CurrentLerp.Tick(DeltaTime);
		if (CurrentLerp.LerpType == ESwarmBotLerpType::Relative)
		{
			Root.SetRelativeLocation(LerpTransform.Location);
			Root.SetRelativeRotation(LerpTransform.Rotation);
		}
		else
		{
			SetActorLocation(LerpTransform.Location);
			SetActorRotation(LerpTransform.Rotation);
		}

		if (CurrentLerp.IsDone())
			CurrentLerp = nullptr;
	}

	// Switch to absolute/relative location depending on status
	void SetSwarmActive(bool bValue)
	{
		bSwarmActive = bValue;

		Collider.SetCollisionEnabled(bValue ? ECollisionEnabled::QueryOnly : ECollisionEnabled::NoCollision);

		RootComponent.SetbAbsoluteLocation(bValue);
		RootComponent.SetbAbsoluteRotation(bValue);

		// Make sure to reset transform if we are back to sphere
		if (!bValue)
		{
			ResetRelativeTransform();
			ResetScale();
		}
	}

	void RelativeLerpOverTime(FVector RelativeLocation, FQuat RelativeRotation, float Duration = 0.2, float Exp = 1.0)
	{
		FVector StartLocation = PlayerSwarmDroneComponent.DroneMesh.WorldTransform.InverseTransformPositionNoScale(ActorLocation);
		CurrentLerp = USwarmBotLerp(StartLocation, RelativeLocation, Root.RelativeRotation.Quaternion(), RelativeRotation, Duration, Exp);
		CurrentLerp.LerpType = ESwarmBotLerpType::Relative;
	}

	void ResetRelativeTransform()
	{
		SetActorRelativeTransform(InitialTransformOnMesh);
	}

	void ResetWorldTransform()
	{
		SetActorTransform(GetInitialWorldTransformOnMesh());
	}

	FTransform GetInitialWorldTransformOnMesh() const
	{
		return InitialTransformOnMesh * AttachmentRoot.WorldTransform;
	}

	void TickResetRelativeTransform(float LerpFraction)
	{
		// Lerp back to origin
		FVector RelativeLocation = InitialTransformOnMesh.Location;
		FVector UnscaledWorldLocation = PlayerSwarmDroneComponent.DroneMesh.WorldTransform.TransformPositionNoScale(RelativeLocation);
		FVector WorldLocationLerp = Math::Lerp(ActorLocation, UnscaledWorldLocation, Math::Pow(LerpFraction, 1.2));

		SetActorLocation(WorldLocationLerp);

		FVector WorldBotUp = PlayerSwarmDroneComponent.DroneMesh.WorldTransform.TransformVector(RelativeLocation);
		FQuat WorldRotationLerp = FQuat::FastLerp(ActorRotation.Quaternion(), FQuat::MakeFromZ(WorldBotUp), Math::Pow(LerpFraction, 1.2));

		SetActorRotation(WorldRotationLerp);
	}

	private FVector GetSwarmBotRelativeLocationOnDroneMesh(float DroneRadius) const
	{
		float DistributionCount;
		float Radius;
		float LayerId;
		float Factor;

		if (IsRetractedInnerLayer())
		{
			DistributionCount = SwarmDrone::RetractedInnerLayerBotCount;
			Radius = DroneRadius * 0.73;
			LayerId = Id - SwarmDrone::TotalBotCount + SwarmDrone::RetractedInnerLayerBotCount;
			Factor = 5.1;
		}
		else
		{
			DistributionCount = SwarmDrone::TotalBotCount - SwarmDrone::RetractedInnerLayerBotCount;
			Radius = DroneRadius;
			LayerId = Id;
			Factor = 5.0;
		}

		// Fibonacci lattice
		float P = PI * (1.0 - Math::Sqrt(Factor));
		float T = P * LayerId;

		// Map from -1 to 1
		float Y = 1.0 - (LayerId / (DistributionCount - 1.0)) * 2.0;
		float R = Math::Sqrt(1.0 - Y * Y);
		float X = Math::Cos(T) * R;
		float Z = Math::Sin(T) * R;

		return FVector(X, Y, Z) * Radius;
	}

	FVector GetSwarmBotRelativeLocationOnDroneMeshWithFraction(float Alpha) const
	{
		float DistributionCount;
		float Radius;
		float LayerId;
		float Factor;

		float Fraction = Math::Saturate(Alpha);

		if (IsRetractedInnerLayer())
		{
			DistributionCount = SwarmDrone::RetractedInnerLayerBotCount;
			Radius = PlayerSwarmDroneComponent.DroneMeshRadius * 0.73;
			LayerId = Id - SwarmDrone::TotalBotCount + SwarmDrone::RetractedInnerLayerBotCount;
			Factor = 4.1;
		}
		else
		{
			DistributionCount = SwarmDrone::TotalBotCount - SwarmDrone::RetractedInnerLayerBotCount;
			Radius = PlayerSwarmDroneComponent.DroneMeshRadius;
			LayerId = Id;
			Factor = 4.0;
		}

		Factor += Fraction;

		// Fibonacci lattice
		float P = PI * (1.0 - Math::Sqrt(Factor));
		float T = P * LayerId;

		// Map from -1 to 1
		float Y = 1.0 - (LayerId / (DistributionCount - 1.0)) * 2.0;
		float R = Math::Sqrt(1.0 - Y * Y);
		float X = Math::Cos(T) * R;
		float Z = Math::Sin(T) * R;

		Radius *= (2.0 - Fraction);
		return FVector(X, Y, Z) * Radius;
	}

	bool ShouldRespawnOffCamera() const
	{
		if (!bSwarmActive)
			return false;

		if (RespawnBlocked.Get())
			return false;

		if (bSwarmTransitioning)
			return false;

		if (bRespawning)
			return false;

		if (PlayerSwarmDroneComponent.bHovering)
			return false;

		if (PlayerSwarmDroneComponent.Player.IsAnyCapabilityActive(SwarmDroneTags::SwarmAirductCapability))
			return false;

		float TimeSinceLastRespawn = Time::GameTimeSeconds - LastRespawnTimeStamp;
		if (TimeSinceLastRespawn < RespawnDelay)
			return false;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			// Eman TODO: Add extra check for occlusion
			if (SceneView::IsInView(Player, ActorLocation))
			{
				return false;
			}
		}

		return true;
	}

	bool IsRetractedInnerLayer() const
	{
		return Id >= SwarmDrone::TotalBotCount - SwarmDrone::RetractedInnerLayerBotCount;
	}

	void ApplyRespawnBlock(FInstigator Instigator)
	{
		RespawnBlocked.Apply(true, Instigator);
	}

	void ClearRespawnBlock(FInstigator Instigator)
	{
		RespawnBlocked.Clear(Instigator);
	}

	void SetColliderRadius(float ColliderRadius)
	{
		Collider.SetSphereRadius(ColliderRadius);

		// Adjust collider offset to compensate for radius
		FVector ColliderOffset = FVector::UpVector * ColliderRadius;
		Collider.SetRelativeLocation(ColliderOffset);
	}

	void ResetScale()
	{
		GroupSkelMeshAnimData.Transform.SetScale3D(FVector(RetractedScale));
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnSwarmTransitionStart(bool bSwarmifying)
	{
		bSwarmTransitioning = true;
		bMeshRetracted = !bSwarmifying;

		// Go about your day as usual
		if (Id < SwarmDrone::DeployedBotCount)
		{
			if (bSwarmifying)
				SetSwarmActive(bSwarmifying);

			return;
		}

		// If these are extra bots, hide if swarming, or show if sphere mode
		if (bSwarmifying)
		{
			GroupSkelMeshAnimData.Transform.SetScale3D(FVector::ZeroVector);
			// PointLight.SetVisibility(false);
		}
		else
		{
			GroupSkelMeshAnimData.Transform.SetScale3D(FVector(RetractedScale));
			// PointLight.SetVisibility(true);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnSwarmTransitionComplete(bool _bSwarmActive)
	{
		bSwarmTransitioning = false;

		if (!_bSwarmActive)
			SetSwarmActive(_bSwarmActive);
	}
}