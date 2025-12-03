class UGravityBladeCombatAttackRecoilCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default CapabilityTags.Add(GravityBladeTags::GravityBlade);
	
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeCombat);
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeAttackRecoil);

	default DebugCategory = GravityBlade::DebugCategory;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 50;

	UGravityBladeUserComponent BladeComp;
	UGravityBladeCombatUserComponent CombatComp;
	
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BladeComp = UGravityBladeUserComponent::Get(Owner);
		CombatComp = UGravityBladeCombatUserComponent::Get(Owner);

		MoveComp = UPlayerMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (CombatComp.ActiveRecoil.EndTimestamp < Time::GameTimeSeconds)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (CombatComp.ActiveRecoil.EndTimestamp < Time::GameTimeSeconds)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		CombatComp.AnimData.LastRecoilFrame = Time::FrameNumber;
		CombatComp.AnimData.RecoilDuration = (CombatComp.ActiveRecoil.EndTimestamp - Time::GameTimeSeconds);
		CombatComp.AnimData.RecoilDirection = CombatComp.ActiveRecoil.Direction;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		CombatComp.ActiveRecoil = FGravityBladeRecoilData();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				Movement.StopMovementWhenLeavingEdgeThisFrame();
				Movement.AddGravityAcceleration();
				Movement.AddOwnerVerticalVelocity();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, GravityBladeCombat::Feature);
		}
	}
}