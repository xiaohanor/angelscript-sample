struct FGravityBladeGrappleEjectJumpDeactivateParams
{
	bool bDurationElapsed = false;
}

class UGravityBladeGrappleEjectJumpCapability : UHazeChildCapability
{
	default CapabilityTags.Add(GravityBladeTags::GravityBlade);

	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrapple);
	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrappleEject);
	default BlockExclusionTags.Add(GravityBladeGrappleTags::GravityBladeGrappleEject);

	default DebugCategory = GravityBlade::DebugCategory;

	AHazePlayerCharacter Player;
	UGravityBladeGrappleUserComponent GrappleComp;
	UGravityBladeGrappleEjectComponent EjectComp;

	UPlayerMovementComponent MoveComp;
	USweepingMovementData MoveData;

	FVector StartGravityDirection;
	FVector StartVelocity;
	FQuat StartGravityRotation;
	FQuat TargetGravityRotation;

	FQuat StartRotation;
	FQuat TargetRotation;

	float ActivateTime;
	const FVector TARGET_GRAVITY_DIRECTION = -FVector::UpVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		GrappleComp = UGravityBladeGrappleUserComponent::Get(Owner);
		EjectComp = UGravityBladeGrappleEjectComponent::GetOrCreate(Owner);

		MoveComp = UPlayerMovementComponent::Get(Owner);
		MoveData = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBladeGrappleEjectJumpDeactivateParams& Params) const
	{
		if(ActualActiveDuration > EjectComp.EjectData.JumpDuration)
		{
			Params.bDurationElapsed = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartGravityDirection = Player.GetGravityDirection();
		StartVelocity = -StartGravityDirection * EjectComp.EjectData.Impulse;
		MoveComp.Reset(true);
	
		StartGravityRotation = FQuat::MakeFromZ(StartGravityDirection);
		TargetGravityRotation = FQuat::MakeFromZ(-FVector::UpVector);

		StartRotation = Player.ActorQuat;
		TargetRotation = FQuat::MakeFromZX(FVector::UpVector, StartVelocity.VectorPlaneProject(FVector::UpVector));

		Player.PlaySlotAnimation(Animation = GrappleComp.GrappleEjectAnimation, bLoop = true);


		Player.ApplyCameraSettings(GrappleComp.GrappleEjectCameraSettings, 1, GravityBladeGrapple::Eject::Instigator, EHazeCameraPriority::High);
	
		ActivateTime = Time::GameTimeSeconds;

		Player.BlockCapabilitiesExcluding(GravityBladeGrappleTags::GravityBladeGrapple, GravityBladeGrappleTags::GravityBladeGrappleEject, this);
		Player.BlockCapabilities(PlayerMovementTags::AirMotion, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBladeGrappleEjectJumpDeactivateParams Params)
	{
		if(Params.bDurationElapsed)
		{
			Player.SetActorTimeDilation(EjectComp.EjectData.TimeDilation, GravityBladeGrapple::Eject::Instigator);
		}

		Player.UnblockCapabilities(GravityBladeGrappleTags::GravityBladeGrapple, this);
		Player.UnblockCapabilities(PlayerMovementTags::AirMotion, this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Saturate(ActualActiveDuration / EjectComp.EjectData.JumpDuration);
		FVector GravityDirection = FQuat::Slerp(StartGravityRotation, TargetGravityRotation, Alpha).UpVector;
		Player.OverrideGravityDirection(GravityDirection, Skyline::GravityProxy);

		if(MoveComp.PrepareMove(MoveData, -GravityDirection))
		{
			FVector Velocity = Math::Lerp(StartVelocity, FVector::ZeroVector, Alpha);
			MoveData.AddVelocity(Velocity);

			FQuat Rotation = FQuat::Slerp(StartRotation, TargetRotation, Alpha);
			MoveData.SetRotation(Rotation);

			MoveComp.ApplyMove(MoveData);
		}

		const float TimeDilation = Math::Lerp(1, EjectComp.EjectData.TimeDilation, Alpha);
		Player.SetActorTimeDilation(TimeDilation, GravityBladeGrapple::Eject::Instigator);
	}

	float GetActualActiveDuration() const property
	{
		return Time::GameTimeSeconds - ActivateTime;
	}
}