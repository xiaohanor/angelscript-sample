asset TeenDragonRollHomingAttackGravitySettings of UMovementGravitySettings
{
	GravityAmount = 2000.0;
}

class UTeenDragonRollHomingAttackCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonRoll);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 10;

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonRollComponent RollComp;
	UPlayerTargetablesComponent PlayerTargetablesComp;
	UCameraUserComponent CameraUserComp;

	UPlayerMovementComponent MoveComp;
	UTeenDragonRollMovementData Movement;

	UTeenDragonRollSettings RollSettings;

	FVector GravityVelocity;

	FHazeAcceleratedRotator AccCameraDesiredRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = Cast<UTeenDragonRollMovementData>(MoveComp.SetupMovementData(UTeenDragonRollMovementData));

		RollSettings = UTeenDragonRollSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTeenDragonRollHomingAttackActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		auto PrimaryTarget = PlayerTargetablesComp.GetPrimaryTarget(UTeenDragonRollAutoAimComponent);
		if(PrimaryTarget == nullptr)
			return false;

		auto AttackTarget = Cast<UTeenDragonRollAutoAimComponent>(PrimaryTarget);
		if(!RollComp.ShouldStartHoming(AttackTarget.bHomingRequireJump))
			return false;
		
		if(!AttackTarget.bAllowHoming)
			return false;

		if(RollComp.IsRolling()
		|| WasActionStarted(ActionNames::PrimaryLevelAbility))
		{
			Params.AttackTarget = AttackTarget;
			Params.bWasRolling = RollComp.IsRolling();
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTeenDragonRollHomingAttackDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
		{
			Params.bShouldKeepRolling = true;
			return true;
		}
		
		// Target is destroyed
		if(RollComp.AttackTarget.IsDisabled())
		{
			Params.bShouldKeepRolling = true;
			return true;
		}

		// if(!IsActioning(ActionNames::PrimaryLevelAbility))
		// {
		// 	Params.bShouldKeepRolling = false;
		// 	return true;
		// }

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTeenDragonRollHomingAttackActivationParams Params)
	{
		RollComp.AttackTarget = Params.AttackTarget;
		if(!Params.bWasRolling)
			UTeenDragonRollEventHandler::Trigger_RollWindupStarted(Player);

		// To not redirect with grounds, we want everything to appear as walls
		auto MovementStandardSettings = UMovementStandardSettings::GetSettings(Player);
		MovementStandardSettings.bOverride_WalkableSlopeAngle = true;
		MovementStandardSettings.WalkableSlopeAngle = 20.0;
		MovementStandardSettings.bOverride_CeilingAngle = true;
		MovementStandardSettings.CeilingAngle = 20.0;

		Player.SetActorVelocity(FVector::ZeroVector);
		GravityVelocity = FVector::ZeroVector;

		RollComp.bHasLandedBetweenHomingAttacks = false;
		RollComp.bIsHomingTowardsTarget = true;
		RollComp.RollingInstigators.Add(this);

		AccCameraDesiredRotation.SnapTo(CameraUserComp.GetDesiredRotation());

		RollComp.TimeLastStartedRoll = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTeenDragonRollHomingAttackDeactivationParams Params)
	{
		UMovementStandardSettings::ClearWalkableSlopeAngle(Player, this);
		UMovementStandardSettings::ClearCeilingAngle(Player, this);

		if(!Params.bShouldKeepRolling)
			UTeenDragonRollEventHandler::Trigger_RollEnded(Player);
		else
			RollComp.bRollIsStarted = true;

		Player.ClearSettingsByInstigator(this);

		RollComp.bIsHomingTowardsTarget = false;
		RollComp.RollingInstigators.RemoveSingleSwap(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(RollComp.bHasLandedBetweenHomingAttacks)
			return;

		if(MoveComp.IsOnWalkableGround())
			RollComp.bHasLandedBetweenHomingAttacks = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector VelocityToTarget = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(Player.ActorLocation, RollComp.AttackTarget.WorldLocation
					, MoveComp.GravityForce, RollSettings.HomingAttackForwardLaunchImpulse, MoveComp.WorldUp);
				Movement.AddVelocity(VelocityToTarget);

				TEMPORAL_LOG(DragonComp)
					.DirectionalArrow("Roll Homing Attack launch velocity to target", Player.ActorLocation, VelocityToTarget, 5, 40 , FLinearColor::Red)
				;

				GravityVelocity += MoveComp.Gravity * DeltaTime;
				Movement.AddVelocity(GravityVelocity);
				Movement.ApplyTerminalVelocityThisFrame();
				Movement.BlockWallRedirectsThisFrame();

				FQuat Rotation = GetInterpedRotationTowardsTarget(DeltaTime);
				Movement.SetRotation(Rotation);

				if(RollComp.AttackTarget.bAllowHomingCameraRotation)
					MoveDesiredRotationTowardsTarget(DeltaTime);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::RollMovement);
		}
	}

	FQuat GetInterpedRotationTowardsTarget(float DeltaTime) const 
	{
		FVector TowardsCenter = (RollComp.AttackTarget.WorldLocation - Player.ActorLocation).VectorPlaneProject(Player.MovementWorldUp);
		FQuat RotToCenter = FQuat::MakeFromXZ(TowardsCenter, FVector::UpVector);

		FQuat CurrentRotation = Player.ActorRotation.Quaternion();

		return Math::QInterpTo(CurrentRotation, RotToCenter, DeltaTime, RollSettings.HomingAttackRotationInterpSpeed);
	}

	void MoveDesiredRotationTowardsTarget(float DeltaTime)
	{
		FRotator TargetRotation = FRotator::MakeFromX(RollComp.AttackTarget.WorldLocation - Player.ActorLocation);
		AccCameraDesiredRotation.AccelerateTo(TargetRotation, RollSettings.HomingAttackCameraRotationDuration, DeltaTime);	
		
		CameraUserComp.SetDesiredRotation(AccCameraDesiredRotation.Value, this);
	}
};


struct FTeenDragonRollHomingAttackActivationParams
{
	UTeenDragonRollAutoAimComponent AttackTarget;
	bool bWasRolling;
}

struct FTeenDragonRollHomingAttackDeactivationParams
{
	bool bShouldKeepRolling;
}