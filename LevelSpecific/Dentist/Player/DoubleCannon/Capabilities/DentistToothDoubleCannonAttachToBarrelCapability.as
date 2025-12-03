class UDentistToothDoubleCannonAttachToBarrelCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default BlockExclusionTags.Add(Dentist::DoubleCannon::DentistDoubleCannonBlockExclusionTag);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 51;

	UDentistToothPlayerComponent PlayerComp;
	UDentistToothDoubleCannonComponent CannonComp;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData MoveData;

	USceneComponent AttachmentComp;
	FVector HorizontalOffsetFromLaunchedRoot;
	float VerticalOffsetFromLaunchedRoot;

	FQuat RotationOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
		CannonComp = UDentistToothDoubleCannonComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		MoveData = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!CannonComp.IsInCannon())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!CannonComp.IsInCannon())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UDentistToothDoubleCannonEventHandler::Trigger_OnEnterCannon(Player);

		AttachmentComp = CannonComp.GetCannon().SpringTranslateComp;
		FVector OffsetFromLaunchedRoot = AttachmentComp.WorldTransform.InverseTransformPositionNoScale(Player.ActorLocation);
		HorizontalOffsetFromLaunchedRoot = OffsetFromLaunchedRoot.VectorPlaneProject(FVector::UpVector);
		VerticalOffsetFromLaunchedRoot = OffsetFromLaunchedRoot.Z;

		RotationOffset = PlayerComp.GetMeshWorldRotation() * AttachmentComp.ComponentQuat.Inverse();

		MoveComp.AddMovementIgnoresActor(this, CannonComp.GetCannon());
		MoveComp.FollowComponentMovement(AttachmentComp, this, EMovementFollowComponentType::Teleport);

		Player.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		Player.BlockCapabilities(CapabilityTags::Outline, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.RemoveMovementIgnoresActor(this);
		MoveComp.UnFollowComponentMovement(this);

		Player.UnblockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		Player.UnblockCapabilities(CapabilityTags::Outline, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				HorizontalOffsetFromLaunchedRoot = Math::VInterpConstantTo(HorizontalOffsetFromLaunchedRoot, GetTargetHorizontalOffset(), DeltaTime, 500);
				VerticalOffsetFromLaunchedRoot = Math::FInterpConstantTo(VerticalOffsetFromLaunchedRoot, 0, DeltaTime, 500);

				FVector OffsetFromLaunchedRoot = HorizontalOffsetFromLaunchedRoot + FVector(0, 0, VerticalOffsetFromLaunchedRoot);
				FVector Target = AttachmentComp.WorldTransform.TransformPositionNoScale(OffsetFromLaunchedRoot);

				MoveData.AddDeltaFromMoveTo(Target);
				MoveData.SetRotation(AttachmentComp.WorldRotation);
			}
			else
			{
				MoveData.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(MoveData, Dentist::Feature);
		}

		TickMeshRotation(DeltaTime);
	}

	void TickMeshRotation(float DeltaTime)
	{
		if(PlayerComp.HasSetMeshRotationThisFrame())
			return;

		RotationOffset = Math::QInterpConstantTo(RotationOffset, FQuat::Identity, DeltaTime, 5);
		FQuat Rotation = AttachmentComp.WorldTransform.TransformRotation(RotationOffset);

		if(Dentist::DoubleCannon::bApplyRotation)
			PlayerComp.SetMeshWorldRotation(Rotation, this, -1, DeltaTime);
	}

	FVector GetTargetHorizontalOffset() const
	{
		if(Player.IsMio())
			return FVector(0, -75, 0);
		else
			return FVector(0, 75, 0);
	}
};