struct FDarkPortalAttachedParams
{
	USceneComponent Component;
	FName Socket;
	FVector WorldLocation;
}

class USanctuaryDarkPortalCompanionAtPortalCapability : UHazeCapability
{
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortalLaunch);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryDarkPortalCompanionComponent CompanionComp;
	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIAnimationComponent AnimComp;
	UHazeSkeletalMeshComponentBase Mesh;
	USanctuaryDarkPortalCompanionSettings Settings;

	FHazeAcceleratedRotator AccRotation;
	FHazeAcceleratedVector AccRelativeLocation;
	FVector RelativeTargetLoc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryDarkPortalCompanionComponent::GetOrCreate(Owner); 
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner); 
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		Settings = USanctuaryDarkPortalCompanionSettings::GetSettings(Owner); 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDarkPortalAttachedParams& OutParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false; // Wait one tick after movement before activating this
		if (CompanionComp.State != EDarkPortalCompanionState::AtPortal)
			return false;
		OutParams.Component = CompanionComp.Portal.TargetData.SceneComponent;
		OutParams.Socket = CompanionComp.Portal.TargetData.SocketName;
		OutParams.WorldLocation = CompanionComp.Portal.TargetData.WorldLocation;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (CompanionComp.State != EDarkPortalCompanionState::AtPortal)
			return true;
		if (!CompanionComp.Portal.IsSettled())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDarkPortalAttachedParams Params)
	{
		CompanionComp.State = EDarkPortalCompanionState::AtPortal;
		CompanionComp.PortalOpeners.Add(this);
		
		UDarkPortalEventHandler::Trigger_CompanionReachPortal(Owner);
		UDarkPortalEventHandler::Trigger_CompanionReachPortal(CompanionComp.Player);

		UDarkPortalPlayerEventHandler::Trigger_DarkPortalAttach(CompanionComp.Player); 

		Mesh.AddComponentVisualsBlocker(this);

		if (!IsValid(Params.Component))
		{
			// Attach target has become invalid after end of launch but before this was activated. 
			// Revert to follow state, then deactivate
			CompanionComp.State = EDarkPortalCompanionState::Follow;
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

		// Network safety fix
		CompanionComp.LastPortalTransform = CompanionComp.Portal.ActorTransform;
		CompanionComp.LastPortalTime = Time::GameTimeSeconds;

		// Align mesh with portal in vector
		CompanionComp.TargetMeshPitch.Apply(-CompanionComp.LastPortalTransform.Rotator().Pitch, this, EInstigatePriority::Normal);

		//AnimComp.RequestFeature(DarkPortalCompanionAnimTags::LaunchAttached, EBasicBehaviourPriority::Medium, this);	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (CompanionComp.State == EDarkPortalCompanionState::AtPortal)
			CompanionComp.State = EDarkPortalCompanionState::PortalExit;
		CompanionComp.PortalOpeners.RemoveSingleSwap(this);

		Mesh.RemoveComponentVisualsBlocker(this);

		CompanionComp.Detach();

		AnimComp.ClearFeature(this);
		CompanionComp.TargetMeshPitch.Clear(this);

		UDarkPortalEventHandler::Trigger_CompanionLeavePortal(Owner);
		UDarkPortalEventHandler::Trigger_CompanionLeavePortal(CompanionComp.Player);

		// Snap rotation fix properly if we should be visible in Portal
		Owner.ActorRotation = CompanionComp.LastPortalTransform.Rotator();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CompanionComp.LastPortalTransform = CompanionComp.Portal.ActorTransform;
		CompanionComp.LastPortalTime = Time::GameTimeSeconds;

		Owner.SetActorVelocity(FVector::ZeroVector);
		if (!IsValid(Owner.AttachParentActor))
			return;

		AccRelativeLocation.AccelerateTo(RelativeTargetLoc, 1.0, DeltaTime);
		Owner.SetActorRelativeLocation(AccRelativeLocation.Value);
		FRotator PortalRot = CompanionComp.Portal.ActorRotation;
		if (FRotator::NormalizeAxis(PortalRot.Yaw - Owner.ActorRotation.Yaw) > Settings.AtPortalYawThreshold)
			AccRotation.AccelerateTo(PortalRot, 0.1, DeltaTime);
		Owner.ActorRotation = AccRotation.Value;
#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + Owner.ActorForwardVector * 500.0, FLinearColor::Blue, 5);
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + CompanionComp.Portal.ActorForwardVector * 800.0, FLinearColor::DPink, 1);
		}
#endif		
	}
};