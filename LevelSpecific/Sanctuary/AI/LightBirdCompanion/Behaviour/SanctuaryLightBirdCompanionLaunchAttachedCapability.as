struct FLightBirdAttachedParams
{
	USceneComponent Component;
	FName Socket;
	FVector WorldLocation;
}

class USanctuaryLightBirdCompanionLaunchAttachedCapability : UHazeCapability
{
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(LightBird::Tags::LightBird);
	default CapabilityTags.Add(LightBird::Tags::LightBirdLaunch);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryLightBirdCompanionComponent CompanionComp;
	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIAnimationComponent AnimComp;
	USanctuaryLightBirdCompanionSettings Settings;

	FHazeAcceleratedRotator AccRotation;
	FHazeAcceleratedVector AccRelativeLocation;
	FVector RelativeTargetLoc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryLightBirdCompanionComponent::GetOrCreate(Owner); 
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner); 
		Settings = USanctuaryLightBirdCompanionSettings::GetSettings(Owner); 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FLightBirdAttachedParams& OutParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false; // Wait one tick after movement before activating this
		if (CompanionComp.State != ELightBirdCompanionState::LaunchAttached)
			return false;
		OutParams.Component = CompanionComp.UserComp.AttachedTargetData.SceneComponent;
		OutParams.Socket = CompanionComp.UserComp.AttachedTargetData.SocketName;
		OutParams.WorldLocation = CompanionComp.UserComp.AttachedTargetData.WorldLocation;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (CompanionComp.State != ELightBirdCompanionState::LaunchAttached)
			return true;
		if (CompanionComp.UserComp.State != ELightBirdState::Attached)
			return true;
		if (!IsValid(Owner.AttachParentActor))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FLightBirdAttachedParams Params)
	{
		CompanionComp.State = ELightBirdCompanionState::LaunchAttached;
		CompanionComp.Illuminators.Add(this);

		if (!IsValid(Params.Component))
		{
			// Attach target has become invalid after end of launch but before this was activated. 
			// Revert to follow state, then deactivate
			CompanionComp.State = ELightBirdCompanionState::Follow;
			return;
		}

		CompanionComp.Attach(Params.Component, Params.Socket);
		AccRelativeLocation.SnapTo(Owner.ActorRelativeLocation);
		AccRotation.SnapTo(Owner.ActorRotation);
		
		FTransform ParentTransform = Params.Component.WorldTransform;
		if (!Params.Socket.IsNone())	
		{
			UMeshComponent ParentMesh = Cast<UMeshComponent>(Params.Component);
			if (ParentMesh != nullptr)
				ParentTransform = ParentMesh.GetSocketTransform(Params.Socket);			
		}
		RelativeTargetLoc = ParentTransform.InverseTransformPosition(Params.WorldLocation);

		AnimComp.RequestFeature(LightBirdCompanionAnimTags::LaunchAttached, EBasicBehaviourPriority::Medium, this);

		ULightBirdEventHandler::Trigger_AttachedTarget(Owner);
		ULightBirdEventHandler::Trigger_AttachedTarget(CompanionComp.Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (CompanionComp.State == ELightBirdCompanionState::LaunchAttached)
			CompanionComp.State = ELightBirdCompanionState::LaunchExit;
		CompanionComp.Illuminators.RemoveSingleSwap(this);

		CompanionComp.Detach();

		AnimComp.ClearFeature(this);

		ULightBirdEventHandler::Trigger_AttachedTargetStopped(Owner);
		ULightBirdEventHandler::Trigger_AttachedTargetStopped(CompanionComp.Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Owner.SetActorVelocity(FVector::ZeroVector);
		if (!IsValid(Owner.AttachParentActor))
			return;

		AccRelativeLocation.AccelerateTo(RelativeTargetLoc, 1.0, DeltaTime);
		Owner.SetActorRelativeLocation(AccRelativeLocation.Value);
		FRotator ToPlayerRot = (CompanionComp.Player.FocusLocation - Owner.ActorLocation).Rotation();
		if (FRotator::NormalizeAxis(ToPlayerRot.Yaw - Owner.ActorRotation.Yaw) > Settings.LaunchAttachedYawThreshold)
			AccRotation.AccelerateTo(ToPlayerRot, 2.0, DeltaTime);
		Owner.ActorRotation = AccRotation.Value;
	}
};