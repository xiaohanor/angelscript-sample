struct FSkylineDroneBossAttachmentData
{
	UPROPERTY(NotVisible, BlueprintReadOnly)
	ASkylineDroneBossAttachment Actor;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	float SpawnTimestamp = 0.0;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	float AttachTimestamp = 0.0;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	float DestroyTimestamp = 0.0;

	bool IsValid() const
	{
		if (Actor == nullptr)
			return false;
		if (Actor.IsActorBeingDestroyed())
			return false;

		return true;
	}
}

class ASkylineDroneBoss : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent BodyPivot;

	UPROPERTY(DefaultComponent, Attach = BodyPivot)
	UStaticMeshComponent BodyMesh;
	default BodyMesh.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceEnemy, ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = BodyPivot)
	USceneComponent LeftPivot;
	default LeftPivot.RelativeLocation = -FVector::RightVector * 870.0;
	default LeftPivot.RelativeRotation = FRotator::MakeFromXZ(FVector::ForwardVector, -FVector::RightVector);

	UPROPERTY(DefaultComponent, Attach = BodyPivot)
	USceneComponent RightPivot;
	default RightPivot.RelativeLocation = FVector::RightVector * 870.0;
	default RightPivot.RelativeRotation = FRotator::MakeFromXZ(FVector::ForwardVector, FVector::RightVector);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineDroneBossCompoundCapability");

	UPROPERTY(DefaultComponent)
	UGravityBladeGravityShiftComponent GravityShiftComponent;
	default GravityShiftComponent.Type = EGravityBladeGravityShiftType::Spherical;
	default GravityShiftComponent.bForceSticky = true;

	UPROPERTY(DefaultComponent)
	UGravityBladeGrappleComponent GrappleComponent;

	UPROPERTY(DefaultComponent)
	UPlayerInheritMovementComponent InheritMovementComponent;

	UPROPERTY(DefaultComponent)
	USkylineDroneBossHealthComponent HealthComponent;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Drone")
	USkylineDroneBossSettings DefaultSettings;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Drone")
	TArray<USkylineDroneBossPhase> Phases;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Drone")
	FSkylineDroneBossAttachmentData LeftAttachment;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Drone")
	FSkylineDroneBossAttachmentData RightAttachment;

	int PhaseIndex = -1;
	float PhaseStartTimestamp = 0.0;
	float PhaseEndTimestamp = 0.0;

	int PhaseLeftAttachmentsSpawned = 0;
	int PhaseRightAttachmentsSpawned = 0;

	TInstigated<AHazePlayerCharacter> TargetPlayer;
	USkylineDroneBossPhase CurrentPhase;

	private TMap<TSubclassOf<USkylineDroneBossPhase>, USkylineDroneBossPhase> PhaseMap;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (DefaultSettings != nullptr)
		{
			ApplyDefaultSettings(DefaultSettings);
		}

		TargetPlayer.SetDefaultValue(Game::Zoe);

		if (TargetPlayer.Get() != nullptr)
		{
			FVector ToTargetPlayer = (TargetPlayer.Get().ActorCenterLocation - BodyPivot.WorldLocation).GetSafeNormal();
			FQuat TargetRotation = FQuat::MakeFromXZ(ToTargetPlayer, FVector::UpVector);
			BodyPivot.SetWorldRotation(TargetRotation);
		}
	}

	USkylineDroneBossPhase GetNextPhase() const
	{
		int NextPhaseIndex = PhaseIndex + 1;
		if (NextPhaseIndex > Phases.Num() - 1)
			return nullptr;

		return Phases[NextPhaseIndex];
	}

	bool HasAnyAttachments() const
	{
		if (LeftAttachment.IsValid())
			return true;

		if (RightAttachment.IsValid())
			return true;

		return false;
	}

	int GetPhaseIndexForHealthSegment() const
	{
		float HealthFraction = (HealthComponent.Health / HealthComponent.MaxHealth);
		return Math::FloorToInt(Phases.Num() * (1.0 - HealthFraction));
	}

	UFUNCTION(DevFunction)
	void DestroyAttachments()
	{
		if (LeftAttachment.IsValid())
			LeftAttachment.Actor.DestroyActor();

		if (RightAttachment.IsValid())
			RightAttachment.Actor.DestroyActor();
	}

	UFUNCTION(DevFunction)
	void KillAttachments()
	{
		if (LeftAttachment.IsValid())
		{
			auto AttachmentHealthComponent = UBasicAIHealthComponent::Get(LeftAttachment.Actor);
			if (AttachmentHealthComponent != nullptr)
				AttachmentHealthComponent.TakeDamage(100.0, EDamageType::Default, this);
		}

		if (RightAttachment.IsValid())
		{
			auto AttachmentHealthComponent = UBasicAIHealthComponent::Get(RightAttachment.Actor);
			if (AttachmentHealthComponent != nullptr)
				AttachmentHealthComponent.TakeDamage(100.0, EDamageType::Default, this);
		}
	}

	UFUNCTION(DevFunction)
	void SmolDamage()
	{
		HealthComponent.TakeDamage(0.1);
	}
}