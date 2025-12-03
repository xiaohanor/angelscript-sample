event void FSwarmDronePossessed();
event void FSwarmTransitionStartEvent(bool bSwarmifying);
event void FSwarmTransitionCompleteEvent(bool bSwarmActive);

class UPlayerSwarmDroneComponent : UDroneComponent
{
	access SwarmMoveCapability = private, ADroneSwarmMoveZone, UDroneSwarmHoverCapability, UDroneSwarmMovementCapability, UDroneSwarmFloatCapability, UPlayerSwarmDroneHoverEventHandler, USwarmBoatMovementCapability;


	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASwarmBot> SwarmBotClass;

	UPROPERTY(NotEditable, BlueprintHidden, Transient)
	TArray<ASwarmBot> SwarmBots;


	UPROPERTY(EditDefaultsOnly, Category = "GroupMesh")
	TSubclassOf<UAnimInstanceSwarmBotGroup> SwarmGroupABP;

	UPROPERTY(EditDefaultsOnly, Category = "GroupMesh")
	private USkeletalMesh SwarmGroupMesh;
	UHazeSkeletalMeshComponentBase SwarmGroupMeshComponent;


	UPROPERTY(Category = "Movement")
	UPrisonSwarmMovementSettings SwarmMovementSettings;

	UPROPERTY()
	UMaterialInterface LightMaterial;

	UPROPERTY()
	FSwarmDronePointLightSettings LightSettings;


	UPROPERTY(Category = "Parachute")
	FSwarmDroneParachuteInfo ParachuteInfo;


	UPROPERTY()
	FSwarmDronePossessed OnSwarmDronePossessed;

	UPROPERTY()
	FSwarmTransitionStartEvent OnSwarmTransitionStartEvent;

	UPROPERTY()
	FSwarmTransitionCompleteEvent OnSwarmTransitionCompleteEvent;


	UPlayerMovementComponent MovementComponent;

	// access : SwarmMoveCapability
	TArray<ADroneSwarmMoveZone> ActiveSwarmMoveZones;

	private TInstigated<bool> SwarmTransitionBlocks;
	default SwarmTransitionBlocks.SetDefaultValue(false);

	private TInstigated<bool> SwarmBotMovementBlocks;
	default SwarmBotMovementBlocks.SetDefaultValue(false);

	float DroneMeshRadius;

	bool bSwarmTransitionActive;
	bool bSwarmModeActive;
	bool bDeswarmifying;

	bool bHovering;
	bool bHoverDashing;

	bool bSwarmDashing;

	bool bFloating;

	bool bJumping;

	bool bShouldDeactivateSwarmMode;

	UPROPERTY()
	UStaticMesh DroneMeshClass;
	UStaticMeshComponent DroneMesh;

	UPROPERTY(Category = "Movement")
	protected UDroneMovementSettings SwarmDroneMovementSettings;

	float CurrentSpeedFraction;

	bool bShouldLerpJump;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		MovementComponent = UPlayerMovementComponent::Get(Owner);

		if(SwarmDroneMovementSettings != nullptr)
			Player.ApplySettings(SwarmDroneMovementSettings, this, EHazeSettingsPriority::Gameplay);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CurrentSpeedFraction = Math::Saturate(Player.ActorVelocity.Size() / MovementSettings.GroundMaxHorizontalSpeed);
	}

	void PossessDrone() override
	{
		Super::PossessDrone();

		DroneMesh.SetHiddenInGame(true);
		DroneMeshRadius = CollisionComponent.SphereRadius;
		check(Math::IsNearlyEqual(DroneMeshRadius, SwarmDrone::Radius, 0.01));

		CreateSwarm();

		OnSwarmDronePossessed.Broadcast();
	}

	private void CreateSwarm()
	{
		// Create swarm bot actors
		for (int i = 0; i < SwarmDrone::TotalBotCount; i++)
		{
			ASwarmBot Bot = SpawnActor(SwarmBotClass, Player.ActorLocation, Player.ActorRotation, bDeferredSpawn = true);
			Bot.Initialize(this, DroneMeshRadius, i);
			SwarmBots.Add(Bot);
			FinishSpawningActor(Bot);

			Bot.ResetRelativeTransform();
		}

		// Create group mesh component
		SwarmGroupMeshComponent = UHazeSkeletalMeshComponentBase::GetOrCreate(Owner, n"SwarmGroupMeshComponent");
		SwarmGroupMeshComponent.SetSkeletalMeshAsset(SwarmGroupMesh);
		SwarmGroupMeshComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		SwarmGroupMeshComponent.SetShadowPriorityRuntime(EShadowPriority::Player);
		SwarmGroupMeshComponent.SetAnimClass(SwarmGroupABP);
		SwarmGroupMeshComponent.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;

#if !RELEASE
	UHazeMeshPoseDebugComponent MeshPoseDebugComponent = UHazeMeshPoseDebugComponent::Get(Player);
	if (MeshPoseDebugComponent != nullptr)
		MeshPoseDebugComponent.AddSkelMeshComponent(SwarmGroupMeshComponent);
#endif
	}

	private void CreateDroneMeshComponent() override
	{
		DroneMesh = UStaticMeshComponent::Create(Player, n"DroneMesh");
		DroneMesh.SetStaticMesh(DroneMeshClass);
		DroneMesh.SetReceivesDecals(false);

		// Set drone collision AND player capsule size
		const float ShapeRadius = DroneMesh.GetBoundsRadius();
		CollisionComponent.SetSphereRadius(ShapeRadius);

		// [Eman] 'Twas attached to CollisionComponent beforefor some reason...test and see what fucks
		DroneMesh.AttachToComponent(Player.MeshOffsetComponent);
		DroneMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UMeshComponent GetDroneMeshComponent() const override
	{
		return DroneMesh;
	}

	void ApplyOutline() override
	{
		TArray<UPrimitiveComponent> OutlinedComponents;
		OutlinedComponents.Add(GetDroneMeshComponent());
		OutlinedComponents.Add(SwarmGroupMeshComponent);

		Outline::ApplyOutlineOnComponents(OutlinedComponents, Game::Zoe, Outline::GetZoeOutlineAsset(), this, EInstigatePriority::High);
	}

	void ClearOutline() override
	{
		TArray<UPrimitiveComponent> OutlinedComponents;
		OutlinedComponents.Add(GetDroneMeshComponent());
		OutlinedComponents.Add(SwarmGroupMeshComponent);

		Outline::ClearOutlineOnComponents(OutlinedComponents, Game::Zoe, this);
	}

	UFUNCTION()
	void ApplySwarmTransitionBlock(FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		SwarmTransitionBlocks.Apply(true, Instigator, Priority);
	}

	UFUNCTION()
	void ClearSwarmTransitionBlock(FInstigator Instigator)
	{
		SwarmTransitionBlocks.Clear(Instigator);
	}

	UFUNCTION(BlueprintPure)
	bool IsSwarmTransitionBlocked() const
	{
		return SwarmTransitionBlocks.Get();
	}

	void ApplySwarmBotMovementBlock(FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		SwarmBotMovementBlocks.Apply(true, Instigator, Priority);
	}

	void ClearSwarmBotMovementBlock(FInstigator Instigator)
	{
		SwarmBotMovementBlocks.Clear(Instigator);
	}

	bool IsSwarmBotMovementBlocked() const
	{
		return SwarmBotMovementBlocks.Get();
	}

	// Used as override for deactivating swarm in special cases (surprise surprise)
	UFUNCTION()
	void ConsumeSwarmMode()
	{
		if (bSwarmModeActive)
		{
			// Deactivation gets handled by transition capability
			bShouldDeactivateSwarmMode = true;

			// Also consume input
			Player.ConsumeButtonInputsRelatedTo(ActionNames::PrimaryLevelAbility);
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsInsideFloatZone()
	{
		for (auto ActiveSwarmZone : ActiveSwarmMoveZones)
		{
			if (ActiveSwarmZone.IsA(ADroneSwarmFloatZone))
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintPure)
	bool IsInsideHoverZone() const
	{
		for (auto ActiveSwarmZone : ActiveSwarmMoveZones)
		{
			if (ActiveSwarmZone.IsA(ADroneSwarmHoverZone))
				return true;
		}

		return false;
	}

	UFUNCTION()
	bool IsInsideAnySpecialMovementZone() const
	{
		return ActiveSwarmMoveZones.Num() > 0;
	}

	UFUNCTION(BlueprintPure)
	bool IsHovering() const
	{
		return bHovering;
	}

	UFUNCTION(BlueprintPure)
	bool IsSwarmTransitionActive() const
	{
		return bSwarmTransitionActive;
	}

	bool IsPlayerGrounded() const
	{
		return MovementComponent.IsOnAnyGround();
	}

#if !RELEASE
	void DebugDrawSwarmBots()
	{
		for (ASwarmBot SwarmBot : SwarmBots)
			Debug::DrawDebugSphere(SwarmBot.ActorLocation, SwarmBot.Collider.SphereRadius * 0.5, 6, FLinearColor::DPink, 0.5);
	}
#endif
}