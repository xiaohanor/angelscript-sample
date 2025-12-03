namespace Dentist
{
	const FHazeDevToggleCategory ToggleCategory(n"Dentist");
	const FHazeDevToggleBoolPerPlayer PrintAnimationValues(ToggleCategory, n"Print Animation Values");
}

UCLASS(Abstract)
class UDentistToothPlayerComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	private TPerPlayer<TSubclassOf<ADentistTooth>> ToothClass;

	UPROPERTY(EditDefaultsOnly)
	UPlayerBlobShadowSettings BlobShadowSettings;

	private AHazePlayerCharacter Player;
	private ADentistTooth Tooth;

	private uint LastSetRotationFrame = 0;
	private FInstigator LastRotationInstigator;

	FHazeAcceleratedQuat AccRotation;
	FHazeAcceleratedVector AccTiltAmount;

	private FHazeAcceleratedFloat AccVerticalOffset;

	UPROPERTY(EditDefaultsOnly)
	FSoundDefReference MioToothSoundDef;

	UPROPERTY(EditDefaultsOnly)
	FSoundDefReference ZoeToothSoundDef;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> GroundPoundShake;
	UPROPERTY()
	UForceFeedbackEffect ForceFeedbackGroundPound;

	// Restrained by dentist scraper tool
	bool bHooked;

	// Restrained by dentist scraper tool
	uint StruckByHammerFrame;

	// Restrained by the dentist drill tool
	bool bDrilled;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		// auto MovementResponseComp = UDentistToothMovementResponseComponent::GetOrCreate(Player);
		// MovementResponseComp.OnDashedInto.AddUFunction(this, n"OnDashedInto");

		Dentist::PrintAnimationValues.MakeVisible();

		if(Player.IsMio())
		{
			MioToothSoundDef.SpawnSoundDefAttached(Player,Owner);
		}
		else
		{
			ZoeToothSoundDef.SpawnSoundDefAttached(Player,Owner);
		}
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TEMPORAL_LOG(this, Owner, "Rotation").Section("Component")
			.Value("LastSetRotationFrame", LastSetRotationFrame)
			.Value("HasSetMeshRotationThisFrame()", HasSetMeshRotationThisFrame())
			.Value("LastRotationInstigator", LastRotationInstigator)
			.Rotation("AccRotation.Value", AccRotation.Value, Player.Mesh.WorldLocation)
		;
	}
#endif

	void SpawnAndAttachTooth()
	{
		Player.CapsuleComponent.OverrideCapsuleSize(Dentist::CollisionRadius, Dentist::CollisionHeight, this);
		
		// Place the mesh offset component in the middle of the capsule, allowing us to rotate the mesh around that point
		Player.MeshOffsetComponent.SnapToRelativeLocation(FInstigator(this, n"Location"), Player.CapsuleComponent, FVector::ZeroVector, EInstigatePriority::Low);
		
		// Move the mesh origin down so that the center of the mesh is at the mesh offset component
		Player.Mesh.SetRelativeLocation(FVector(0, 0, -Dentist::CollisionHeight));

		Tooth = SpawnActor(ToothClass[Player], Player.ActorLocation, Player.ActorRotation);
		Tooth.AttachToComponent(Player.MeshOffsetComponent);
		Tooth.OnAttached(Player);

		SetMeshWorldRotation(Player.ActorQuat, this);

		UTeleportResponseComponent::GetOrCreate(Player).OnTeleported.AddUFunction(this, n"OnTeleported");

		UMovementGravitySettings::SetGravityScale(Player, 1.5, this);
		UMovementGravitySettings::SetTerminalVelocity(Player, 3000.0, this);

		UMovementSteppingSettings::SetStepUpSize(Player, FMovementSettingsValue::MakePercentage(1), this);
		UMovementSteppingSettings::SetStepDownSize(Player, FMovementSettingsValue::MakePercentage(1), this);

		Player.ApplySettings(BlobShadowSettings, this);
	}

	UFUNCTION()
	private void OnTeleported()
	{
		if(!HasSetMeshRotationThisFrame())
			SetMeshWorldRotation(Player.ActorQuat, this);

		Tooth.LeftEyeSpawner.GooglyEye.Reset();
		Tooth.RightEyeSpawner.GooglyEye.Reset();
	}

	FQuat GetMeshWorldRotation() const
	{
		return Player.MeshOffsetComponent.ComponentQuat;
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

		Player.MeshOffsetComponent.SnapToRotation(FInstigator(this, n"Rotation"), AccRotation.Value);
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

	ADentistTooth GetToothActor() const
	{
		return Tooth;
	}

	UFUNCTION()
	private void OnDashedInto(AHazePlayerCharacter DashingPlayer, FVector Impulse, FHitResult Impact)
	{
		auto ResponseComp = UDentistToothImpulseResponseComponent::Get(Player);
		if(ResponseComp == nullptr)
			return;

		auto RagdollSettings = UDentistToothDashSettings::GetSettings(Player).RagdollSettings;

		ResponseComp.OnImpulseFromObstacle.Broadcast(DashingPlayer, Impulse, RagdollSettings);
	}
};