struct FTeenDragonRollBounceOffWallActivationParams
{
	FVector PreReflectForward;
	FVector PostReflectForward;
	FVector WallNormal;
	FVector HitLocation;
	float SpeedIntoWall;

	float ReflectMeshRotateDuration;
	float ReflectHorizontalImpulsePerSpeed;
	float ReflectVerticalImpulsePerSpeed;

	FHazeCameraImpulse CameraImpulse;
}

class UTeenDragonRollBounceOffWallCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonRoll);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 95;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonRollComponent RollComp;	

	UHazeMovementComponent MoveComp;
	UTeenDragonRollMovementData Movement;

	FVector ImpulseToAddOnDeactivate;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupMovementData(UTeenDragonRollMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTeenDragonRollBounceOffWallActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!RollComp.ReflectOffWallData.IsSet())
			return false;

		if (DeactiveDuration < 0.25)
			return false;

		auto ReflectData = RollComp.ReflectOffWallData.Value;
		Params.HitLocation = ReflectData.HitLocation;
		Params.PostReflectForward = ReflectData.PostReflectForward;
		Params.PreReflectForward = ReflectData.PreReflectForward;
		Params.SpeedIntoWall = ReflectData.SpeedIntoWall;
		Params.WallNormal = ReflectData.WallNormal;

		Params.ReflectHorizontalImpulsePerSpeed = ReflectData.KnockbackSettings.ReflectHorizontalImpulsePerSpeed;
		Params.ReflectVerticalImpulsePerSpeed = ReflectData.KnockbackSettings.ReflectVerticalImpulsePerSpeed;
		Params.ReflectMeshRotateDuration = ReflectData.KnockbackSettings.ReflectMeshRotateDuration;

		Params.CameraImpulse = ReflectData.CameraImpulse;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTeenDragonRollBounceOffWallActivationParams Params)
	{
		Player.PlayCameraShake(RollComp.RollReflectOffWallCameraShake, this);
		Player.PlayForceFeedback(RollComp.RollReflectOffWallRumble, false, false, this);

		RollComp.RollingInstigators.Add(this);

		FVector ReflectedForward = Params.PostReflectForward;

		DragonComp.DragonMeshOffsetComponent.FreezeRotationAndLerpBackToParent(this, Params.ReflectMeshRotateDuration);
		Player.SetActorRotation(FRotator::MakeFromXZ(ReflectedForward, MoveComp.WorldUp));

		FVector Impulse 
			= Params.WallNormal * Params.SpeedIntoWall * Params.ReflectHorizontalImpulsePerSpeed
			+ MoveComp.WorldUp * Params.SpeedIntoWall * Params.ReflectVerticalImpulsePerSpeed;

		FVector ImpulseTowardsForward = Impulse.ConstrainToDirection(ReflectedForward);
		Impulse -= ImpulseTowardsForward;
		
		ImpulseToAddOnDeactivate = Impulse;

		Player.ApplyCameraImpulse(Params.CameraImpulse, this);

		if(Params.SpeedIntoWall > 750
		&& Time::GetGameTimeSince(RollComp.TimeLastReflectedOffWall) > 0.3)
		{
			FTeenDragonRollOnReflectedOffWallParams EffectParams;
			EffectParams.ForwardGoingIntoWall = Params.PreReflectForward;
			EffectParams.ForwardLeavingWall = Params.PostReflectForward;
			EffectParams.SpeedIntoWall = Params.SpeedIntoWall;
			EffectParams.WallHitLocation = Params.HitLocation;
			EffectParams.WallNormal = Params.WallNormal;
			UTeenDragonRollVFX::Trigger_OnReflectedOffWall(Player, EffectParams);
		}

		RollComp.TimeLastReflectedOffWall = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		RollComp.RollingInstigators.RemoveSingleSwap(this);
		RollComp.ReflectOffWallData.Reset();

		Player.AddMovementImpulse(ImpulseToAddOnDeactivate);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				Movement.AddOwnerVelocity();
				Movement.AddGravityAcceleration();
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::RollMovement);
		}
	}
};