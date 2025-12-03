class UGravityBladeCombatRushCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(GravityBladeTags::GravityBlade);
	
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeCombatCamera);
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeCombat);
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeRush);
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeDashRush);

	default DebugCategory = GravityBlade::DebugCategory;

	default TickGroup = EHazeTickGroup::Movement;

	UGravityBladeCombatUserComponent CombatComp;
	UCameraUserComponent CameraUserComp;
	UGravityBladeUserComponent BladeComp;
	UPlayerMovementComponent MoveComp;

	uint RushStartFrame;
	FVector StartLocation;

	float TargetRotationOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CombatComp = UGravityBladeCombatUserComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);
		BladeComp = UGravityBladeUserComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(!CombatComp.HasActiveAttack())
			return false;

		if(!CombatComp.ActiveAttackData.IsRushAttack())
			return false;

		// If we have deactivated during a rush we don't want to activate again on the same rush, only a new rush
		if(CombatComp.AnimData.RushStartFrame == RushStartFrame)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CombatComp.HasActiveAttack())
			return true;

		if(!CombatComp.ActiveAttackData.IsRushAttack())
			return true;

		if (CombatComp.bInsideHitWindow)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CameraTags::CameraControl, this);
		RushStartFrame = CombatComp.AnimData.RushStartFrame;

		StartLocation = Player.ActorLocation;

		FVector TargetLocation;
		FRotator TargetRotation;

		GravityBladeCombatRush::CalculateTargetLocationAndRotation(
			false,
			Player,
			CombatComp.ActiveAttackData.Target,
			StartLocation,
			TargetLocation,
			TargetRotation
		);

		FQuat TargetCameraRotation = FQuat::MakeFromXZ((TargetLocation - StartLocation).GetSafeNormal(), MoveComp.WorldUp);
		FQuat CurrentCameraRotation = Player.ViewRotation.Quaternion();

		// Rotate either left or right depending on whether the enemy is to the left or right
		TargetRotationOffset = Math::DegreesToRadians(GravityBladeCombat::RushCameraSidewaysAngle);

		FQuat DeltaRotation = TargetCameraRotation * CurrentCameraRotation.Inverse();
		if (DeltaRotation.GetTwistAngle(MoveComp.WorldUp) > 0)
			TargetRotationOffset *= -1.0;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraControl, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TargetLocation;
		FRotator TargetRotation;
		GravityBladeCombatRush::CalculateTargetLocationAndRotation(
			false,
			Player,
			CombatComp.ActiveAttackData.Target,
			StartLocation,
			TargetLocation,
			TargetRotation
		);

		// If we start a new rush attack we don't want to stop camera rotation
		if (CombatComp.HasActiveAttack() && CombatComp.ActiveAttackData.IsRushAttack() && CombatComp.AnimData.RushStartFrame != RushStartFrame)
			RushStartFrame = CombatComp.AnimData.RushStartFrame;

		float AnticipationDelay;
		if (CombatComp.ActiveAttackData.MovementType == EGravityBladeAttackMovementType::AirRush)
			AnticipationDelay = CombatComp.AnimFeature.AnimData.AirRushAnticipationDelay;
		else
			AnticipationDelay = CombatComp.AnimFeature.AnimData.GroundRushAnticipationDelay;

		bool bInAnticipationDelay = ActiveDuration < AnticipationDelay;
		float RotationSpeed = bInAnticipationDelay ? GravityBladeCombat::RushCameraRotationSpeedWhenInAnticipationDelay : GravityBladeCombat::RushCameraRotationSpeed;

		FQuat TargetCameraRotation = FQuat::MakeFromZX(CameraUserComp.GetDesiredRotation().UpVector, (TargetLocation - StartLocation).GetSafeNormal());
		TargetCameraRotation = TargetCameraRotation * FQuat(FVector::UpVector, TargetRotationOffset);

		// Having an interp speed of 0.0 will make it snap, we don't want this
		FRotator NewRotation = Math::RInterpConstantShortestPathTo(CameraUserComp.GetDesiredRotation(), TargetCameraRotation.Rotator(), DeltaTime, RotationSpeed);
		CameraUserComp.SetDesiredRotation(NewRotation, this);
	}
}