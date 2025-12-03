enum EDentistSplitToothAIState
{
	Inactive,

	// From launch until we land
	Splitting,

	// Jump around randomly
	Idle,

	// Turning around to face the player, and jump into the air before turning around
	Startled,

	// Frantically trying to run away
	Scared,

	// The player has caught us
	Recombining,
};

UCLASS(Abstract)
class ADentistSplitToothAI : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCapsuleCollisionComponent CollisionComp;
	default CollisionComp.CollisionProfileName = n"PlayerCharacter";
	default CollisionComp.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;
	default MeshRoot.bAbsoluteRotation = true;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeCharacterSkeletalMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent ToothTip;

	UPROPERTY(DefaultComponent)
	UDentistSplitToothComponent SplitToothComp;
	default SplitToothComp.bIsAI = true;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.FollowEnablement.DefaultValue = EMovementFollowEnabledStatus::FollowEnabled;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPositionComp;
	default SyncedActorPositionComp.SyncRate = EHazeCrumbSyncRate::High;
	default SyncedActorPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedTiltAmount;
	default SyncedTiltAmount.SyncRate = EHazeCrumbSyncRate::Standard;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;

	UPROPERTY(DefaultComponent)
	UHazeMeshPoseDebugComponent MeshPoseDebugComp;
#endif

	AHazePlayerCharacter OwningPlayer;

	EDentistSplitToothAIState State = EDentistSplitToothAIState::Splitting;

	// Rotation
	FHazeAcceleratedVector AccTiltAmount;
	FHazeAcceleratedQuat AccRotation;
	FInstigator LastRotationInstigator;
	uint LastSetRotationFrame = 0;

	UDentistSplitToothAISettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp.SetupShapeComponent(CollisionComp);
		
		Settings = UDentistSplitToothAISettings::GetSettings(this);
		ApplyDefaultSettings(DentistSplitToothAISettings);

		auto PlayerGravitySettings = UMovementGravitySettings::GetSettings(OwningPlayer);
		
		UMovementStandardSettings::SetAutoFollowGround(this, EMovementAutoFollowGroundType::FollowWalkable, this, EHazeSettingsPriority::Defaults);
		UMovementGravitySettings::SetGravityAmount(this, PlayerGravitySettings.GravityAmount, this);
		UMovementGravitySettings::SetGravityScale(this, PlayerGravitySettings.GravityScale, this);
		UMovementGravitySettings::SetTerminalVelocity(this, PlayerGravitySettings.TerminalVelocity, this);

		const auto CircleConstraint = TListedActors<ADentistSplitToothAICircleConstraint>().Single;
		if(CircleConstraint != nullptr)
			MoveComp.ApplyCircleConstraint(CircleConstraint, this);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TEMPORAL_LOG(this)
			.Status(f"{State:n}", GetStateColor())
		;
	}

	FLinearColor GetStateColor() const
	{
		switch(State)
		{
			case EDentistSplitToothAIState::Inactive:
				return FLinearColor::Black;
				
			case EDentistSplitToothAIState::Splitting:
				return FLinearColor::DPink;

			case EDentistSplitToothAIState::Idle:
				return FLinearColor::LucBlue;

			case EDentistSplitToothAIState::Startled:
				return FLinearColor::Yellow;

			case EDentistSplitToothAIState::Scared:
				return FLinearColor::Red;

			case EDentistSplitToothAIState::Recombining:
				return FLinearColor::Green;
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, true, true);

		for(auto AttachedActor : AttachedActors)
		{
			AttachedActor.RemoveActorDisable(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, true, true);

		for(auto AttachedActor : AttachedActors)
		{
			AttachedActor.AddActorDisable(this);
		}
	}

	FQuat GetMeshWorldRotation() const
	{
		return MeshRoot.ComponentQuat;
	}

	FVector GetMeshAngularVelocity() const
	{
		return AccRotation.VelocityAxisAngle;
	}

	void SetMeshWorldRotation(FQuat WorldRotation, FInstigator Instigator, float ResetOffsetDuration = -1, float DeltaTime = -1)
	{
		if(!ensure(!HasSetMeshRotationThisFrame()))
			return;

		if(ResetOffsetDuration > 0)
		{
			AccRotation.AccelerateTo(WorldRotation, ResetOffsetDuration, DeltaTime);
		}
		else
		{
			if(Instigator != LastRotationInstigator)
			{
				AccRotation.SnapTo(WorldRotation);
			}
			else
			{
				FQuat DeltaRotation = WorldRotation * AccRotation.Value.Inverse();

				FVector Axis = FVector::UpVector;
				float Angle = 0;
				DeltaRotation.ToAxisAndAngle(Axis, Angle);

				const FVector AngularVelocity = Axis * (Angle / DeltaTime);
				AccRotation.SnapTo(WorldRotation, AngularVelocity.GetSafeNormal(), Math::RadiansToDegrees(AngularVelocity.Size()));
			}
		}

		MeshRoot.SetWorldRotation(AccRotation.Value);
		LastSetRotationFrame = Time::FrameNumber;
		LastRotationInstigator = Instigator;
	}

	void AddMeshWorldRotation(FQuat Rotation, FInstigator Instigator, float ResetOffsetDuration = -1, float DeltaTime = -1)
	{
		SetMeshWorldRotation(Rotation * GetMeshWorldRotation(), Instigator, ResetOffsetDuration, DeltaTime);
	}

	bool HasSetMeshRotationThisFrame() const
	{
		return LastSetRotationFrame == Time::FrameNumber;
	}

	UFUNCTION(BlueprintOverride)
	FVector GetActorCenterLocation() const
	{
		return CollisionComp.WorldLocation;
	}
};