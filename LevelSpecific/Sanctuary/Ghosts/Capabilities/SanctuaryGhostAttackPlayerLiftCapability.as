class USanctuaryGhostAttackPlayerLiftCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	USanctuaryGhostAttackResponseComponent AttackResponseComp;
	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	bool bIsLifted = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttackResponseComp = USanctuaryGhostAttackResponseComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AttackResponseComp.bIsLifted.Get())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!AttackResponseComp.bIsLifted.Get())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FHazeSlotAnimSettings SlotAnimSettings;
		SlotAnimSettings.bLoop = true;
		Player.PlaySlotAnimation(AttackResponseComp.LiftAnim, SlotAnimSettings);

		FHazePointOfInterestFocusTargetInfo POITarget;
		POITarget.SetFocusToActor(AttackResponseComp.Ghosts.Get());
		FApplyPointOfInterestSettings POISettings;
		Player.ApplyPointOfInterest(this, POITarget, POISettings, 4.0);

		Player.ApplyCameraSettings(AttackResponseComp.CameraSettings, 6.0, this);

		USanctuaryGhostEventHandler::Trigger_StartLiftingPlayer(AttackResponseComp.Ghosts.Get());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopSlotAnimationByAsset(AttackResponseComp.LiftAnim);
		Player.ClearPointOfInterestByInstigator(this);

		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!AttackResponseComp.Ghosts.IsDefaultValue())
		{
			FVector ToGhost = AttackResponseComp.Ghosts.Get().ActorLocation - Player.ActorLocation;
			Player.SetMovementFacingDirection(ToGhost.ToOrientationQuat());
		}

		if(MoveComp.PrepareMove(Movement))
		{
		if (!AttackResponseComp.Ghosts.IsDefaultValue())
		{
			FVector ToGhost = AttackResponseComp.Ghosts.Get().ActorLocation - Player.ActorLocation;
//			Player.SetMovementFacingDirection(ToGhost.ToOrientationQuat());
			Movement.InterpRotationTo(ToGhost.ToOrientationQuat(), 4.0);
		}

			Movement.AddDelta(FVector::UpVector * 50.0 * DeltaTime);
			MoveComp.ApplyMove(Movement);
		}
	}
};