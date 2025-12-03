class UMeltdownRopeHangMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;
	UMeltdownRopeHangPlayerComponent RopeHangComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();
		RopeHangComp = UMeltdownRopeHangPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.FollowComponentMovement(RopeHangComp.ActiveAttachment, this, EMovementFollowComponentType::ResolveCollision);
		Player.BlockCapabilities(n"Collision", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.UnFollowComponentMovement(this);
		Player.UnblockCapabilities(n"Collision", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			FTransform AttachTransform = RopeHangComp.ActiveAttachment.WorldTransform;
			if (Player.IsMio())
				AttachTransform.AddToTranslation(FVector(200000.0, 200000.0, 0.0));

			FVector TargetRelativePos;
			TargetRelativePos.X = -MeltdownRopeHang::PlayerBehindPosition;
			TargetRelativePos.Y = Player.IsMio() ? -MeltdownRopeHang::PlayerSpacing : MeltdownRopeHang::PlayerSpacing;
			TargetRelativePos.Z = -Math::Sqrt(Math::Square(MeltdownRopeHang::RopeLength) - Math::Square(MeltdownRopeHang::PlayerBehindPosition));

			float Multiplier = Player.IsMio() ? 0.991 : 1.081;

			TargetRelativePos.X += Math::Sin(ActiveDuration * 4.1 * Multiplier) * 20.0;
			TargetRelativePos.X += Math::Sin(ActiveDuration * 2.7 * Multiplier) * 11.0;

			TargetRelativePos.Z += Math::Sin(ActiveDuration * 2.881 / Multiplier) * 20.0;
			TargetRelativePos.Z += Math::Sin(ActiveDuration * 1.171 / Multiplier) * 20.0;

			FVector LocalWantedMovement = AttachTransform.InverseTransformVector(MoveComp.MovementInput);

			FVector RelativePos = AttachTransform.InverseTransformPosition(Player.ActorLocation);
			RelativePos.X = TargetRelativePos.X;
			RelativePos.Y = TargetRelativePos.Y + (RelativePos.Y - TargetRelativePos.Y) * Math::Pow(0.1, DeltaTime);
			RelativePos.Y += LocalWantedMovement.Y * DeltaTime * MeltdownRopeHang::HorizontalMovementSpeed;
			RelativePos.Z = TargetRelativePos.Z;

			FVector TargetWorldPos = AttachTransform.TransformPosition(RelativePos);

			if (HasControl())
			{
				Movement.AddDelta(TargetWorldPos - Player.ActorLocation);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"SwingAir");

			Debug::DrawDebugLine(
				Player.Mesh.GetSocketLocation(n"LeftAttach"),
				AttachTransform.Location,
				FLinearColor::Black, 4.0
			);

			FVector OtherWorldOffset(200000.0, 200000.0, 0.0);
			if (Player.IsMio())
				OtherWorldOffset *= -1;
			
			Debug::DrawDebugLine(
				Player.Mesh.GetSocketLocation(n"LeftAttach") + OtherWorldOffset,
				AttachTransform.Location + OtherWorldOffset,
				FLinearColor::Black, 4.0
			);

		}
	}
};