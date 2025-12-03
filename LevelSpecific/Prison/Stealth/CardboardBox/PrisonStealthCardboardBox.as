enum EPrisonStealthCardboardBoxState
{
	Default,
	Attached,
	Simulating,
	Respawn,
};

asset PrisonStealthCardboardBoxSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UPrisonStealthCardboardAttachedCapability);
	Capabilities.Add(UPrisonStealthCardboardSimulatedCapability);
	Capabilities.Add(UPrisonStealthCardboardRespawnCapability);
};

asset PrisonStealthCardboardBoxPlayerSheet of UHazeCapabilitySheet
{
	Components.Add(UPrisonStealthCardboardBoxPlayerComponent);
};

UCLASS(Abstract)
class APrisonStealthCardboardBox : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent TipRoot;

	UPROPERTY(DefaultComponent, Attach = TipRoot)
	USceneComponent BoxRoot;

	UPROPERTY(DefaultComponent, Attach = BoxRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = BoxRoot)
	UHazeMovablePlayerTriggerComponent TriggerComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(PrisonStealthCardboardBoxSheet);

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(PrisonStealthCardboardBoxPlayerSheet);

	UPROPERTY(DefaultComponent)
	UHackableSniperTurretResponseComponent ResponseComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(EditDefaultsOnly)
	bool bAllowRespawning = false;

	// State
	EPrisonStealthCardboardBoxState CurrentState = EPrisonStealthCardboardBoxState::Default;
	EPrisonStealthCardboardBoxState DesiredState = EPrisonStealthCardboardBoxState::Default;

	// Default
	private FTransform InitialActorTransform;
	private FTransform InitialTipRootRelativeTransform;
	private FTransform InitialMeshRelativeTransform;

	// Attached
	AHazePlayerCharacter Player;

	// Simulated
	FVector InitialImpulse = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Drone::GetMagnetDronePlayer());

		if(HasControl())
		{
			TriggerComp.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
			ResponseComp.OnHackableSniperTurretHit.AddUFunction(this, n"OnHit");
			PrisonStealth::GetStealthManager().OnStealthPlayerDetected.AddUFunction(this, n"OnStealthPlayerDetected");
		}

		InitialActorTransform = ActorTransform;
		InitialTipRootRelativeTransform = TipRoot.RelativeTransform;
		InitialMeshRelativeTransform = MeshComp.RelativeTransform;
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter InPlayer)
	{
		if(!InPlayer.HasControl())
			return;

		if(CurrentState != EPrisonStealthCardboardBoxState::Default)
			return;

		auto PlayerComp = UPrisonStealthCardboardBoxPlayerComponent::Get(InPlayer);
		if(PlayerComp != nullptr)
		{
			// We can't have two boxes on one player! That would be silly
			if(PlayerComp.HasCardboardBox())
				return;
		}

		Player = InPlayer;
		DesiredState = EPrisonStealthCardboardBoxState::Attached;
	}

	UFUNCTION()
	private void OnHit(FHackableSniperTurretHitEventData EventData)
	{
		if(CurrentState == EPrisonStealthCardboardBoxState::Attached)
		{
			const FVector ImpulseDirection = FVector::UpVector + EventData.TraceDirection.VectorPlaneProject(FVector::UpVector);
			const FVector Impulse = ImpulseDirection * 500;
			StartSimulating(Impulse);

			NetUnlockAchievement();
		}

		UPrisonStealthCardboardBoxEventHandler::Trigger_OnCardboardHit(this);
	}

	UFUNCTION(NetFunction)
	void NetUnlockAchievement()
	{
		Online::UnlockAchievement(n"ShootCardboardBox");
	}

	UFUNCTION()
	private void OnStealthPlayerDetected(APrisonStealthEnemy DetectedBy, AHazePlayerCharacter DetectedPlayer)
	{
		if(Player != DetectedPlayer)
			return;

		if(CurrentState != EPrisonStealthCardboardBoxState::Attached)
			return;

		FVector Direction = (ActorLocation - DetectedBy.ActorLocation).GetSafeNormal2D(FVector::UpVector);
		const FVector ImpulseDirection = FVector::UpVector + Direction;
		const FVector Impulse = ImpulseDirection * 500;
		StartSimulating(Impulse);
	}

	void StartSimulating(FVector Impulse)
	{
		check(CurrentState == EPrisonStealthCardboardBoxState::Attached);
		DesiredState = EPrisonStealthCardboardBoxState::Simulating;
		InitialImpulse = Impulse;
	}

	void ApplyState(EPrisonStealthCardboardBoxState InState)
	{
		if(CurrentState == InState)
			return;

		CurrentState = InState;

		RemoveActorCollisionBlock(this);
		RemoveActorVisualsBlock(this);

		switch(CurrentState)
		{
			case EPrisonStealthCardboardBoxState::Default:
			{
				MeshComp.SetSimulatePhysics(false);
				MeshComp.SetCollisionProfileName(n"BlockAllDynamic");
				break;
			}

			case EPrisonStealthCardboardBoxState::Attached:
			{
				MeshComp.SetSimulatePhysics(false);
				MeshComp.SetCollisionProfileName(n"NoCollision");
				MeshComp.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
				MeshComp.SetCollisionResponseToChannel(ECollisionChannel::ECC_Visibility, ECollisionResponse::ECR_Block);
				break;
			}

			case EPrisonStealthCardboardBoxState::Simulating:
			{
				MeshComp.SetCollisionProfileName(n"IgnorePlayerCharacter");
				MeshComp.SetSimulatePhysics(true);
				break;
			}

			case EPrisonStealthCardboardBoxState::Respawn:
			{
				MeshComp.SetSimulatePhysics(false);
				AddActorCollisionBlock(this);
				AddActorVisualsBlock(this);
				break;
			}
		}
	}

	void Reset()
	{
		ApplyState(EPrisonStealthCardboardBoxState::Default);

		MeshComp.AttachToComponent(BoxRoot);
		TipRoot.SetRelativeTransform(InitialTipRootRelativeTransform);
		MeshComp.SetRelativeTransform(InitialMeshRelativeTransform);

		DesiredState = EPrisonStealthCardboardBoxState::Default;
		Player = nullptr;
		InitialImpulse = FVector::ZeroVector;

		TeleportActor(
			InitialActorTransform.Location,
			InitialActorTransform.Rotator(),
			this
		);
	}
};