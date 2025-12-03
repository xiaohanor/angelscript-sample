struct FBattlefieldHoverboardCollisionActivationParams
{
	FMovementHitResult WallHitResult;
	FVector ReflectionNormal;
	FVector PlayerForward;
	float ReflectionAngle;
}

class UBattlefieldHoverboardCollisionCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(BlockedWhileIn::WallRun);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);

	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 50;

	UPlayerMovementComponent MoveComp;
	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardLoopComponent HoverboardLoopComp;

	USteppingMovementData Movement;
	UBattlefieldHoverboardGroundMovementSettings GroundMovementSettings;

	/** If you collide with a wall, and the angle between the negated impact normal and the player forward is less than this value, then we kill the player */
	const float KillAngle = 25.0;
	/** If your reflection angle is more than this, don't reflect */
	const float MaxReflectionAngle = 85;
	/** How much greater the vector angle should be after reflected
	 * (Increase if you want to reflect more shallowly along the surface impacted)*/
	const float ReflectionAngleMultiplier = 1.35;
	/** At which speed towards the impact the camera impulse and blend is at full effect */
	const float MaxCameraEffectSpeed = 750.0;
	const float MaxCameraImpulseSize = 500.0; 
	const float MaxCameraBlendTime = 1.0;

	/** How much of the original velocity is lost after going into the wall 
	 * (Also modified by how much the velocity is going into the wall)
	*/
	const float CollisionVelocityFraction = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		HoverboardLoopComp = UBattlefieldHoverboardLoopComponent::Get(Player);

		GroundMovementSettings = UBattlefieldHoverboardGroundMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBattlefieldHoverboardCollisionActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!MoveComp.HasWallContact())
			return false;

		auto WallImpact = MoveComp.WallContact;
		if(WallImpact.bIsStepUp)
			return false;

		auto GrindSplineComp = UBattlefieldHoverboardGrindSplineComponent::Get(WallImpact.Actor);
		if(GrindSplineComp != nullptr)
		{
			return false;
			// if(GrindSplineComp.PlayerIsJumpingToGrind(Player))
			// 	return false;
			// else if(GrindSplineComp.PlayerIsGrapplingToGrind(Player))
			// 	return false;
		}

		if(HoverboardLoopComp.bIsInLoop)
			return false;

		FVector ReflectionNormal = WallImpact.Normal.ConstrainToPlane(FVector::UpVector);
		FVector PlayerForward = Player.ActorForwardVector.ConstrainToPlane(FVector::UpVector);

		const float ReflectionAngle = PlayerForward.GetAngleDegreesTo(-ReflectionNormal);

		if(ReflectionAngle > MaxReflectionAngle)
			return false;

		Params.WallHitResult = WallImpact;
		Params.PlayerForward = PlayerForward;
		Params.ReflectionAngle = ReflectionAngle;
		Params.ReflectionNormal = ReflectionNormal;	

		TEMPORAL_LOG(Player, "Hoverboard Collision")
			.DirectionalArrow("Reflection Normal", Params.WallHitResult.ImpactPoint, Params.ReflectionNormal * 500, 5, 40, FLinearColor::Purple)
			.Arrow("Before Reflection Vector", Params.WallHitResult.ImpactPoint + -(Params.PlayerForward * 500), Params.WallHitResult.ImpactPoint, 5, 40, FLinearColor::DPink)
			.Value("Angle", Params.ReflectionAngle)
		;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBattlefieldHoverboardCollisionActivationParams Params)
	{
		ApplyImpactRumble(Params);
		ApplyImpactCameraEffects(Params);

		if(Params.ReflectionAngle <= KillAngle)
		{
			Player.KillPlayer(FPlayerDeathDamageParams(Player.ActorForwardVector, 20.0), HoverboardComp.DeathEffect);
		}
		// Reflect Player
		else
		{
			float RotationAngle = Math::Clamp(Params.ReflectionAngle * ReflectionAngleMultiplier, 0, MaxReflectionAngle);
			float ReflectionNormalDotPlayerRight = Player.ActorRightVector.DotProduct(Params.ReflectionNormal);
			FVector ReflectedVector = Params.ReflectionNormal.RotateAngleAxis(Math::Sign(-ReflectionNormalDotPlayerRight) *  RotationAngle, FVector::UpVector);

			FVector PlayerHorizontalVelocityDir = MoveComp.PreviousHorizontalVelocity.GetSafeNormal();
			float VelocityDotWall = PlayerHorizontalVelocityDir.DotProduct(-Params.ReflectionNormal);
			float Speed = MoveComp.PreviousHorizontalVelocity.Size();
			float SpeedPostReflection = Speed - (Speed * VelocityDotWall * CollisionVelocityFraction);
			SpeedPostReflection = Math::Clamp(SpeedPostReflection,0,  SpeedPostReflection);
			FVector HorizontalVelocity = ReflectedVector * SpeedPostReflection;
			FVector VerticalVelocity = Player.ActorVerticalVelocity;
			Player.SetActorVelocity(HorizontalVelocity + VerticalVelocity);
			FRotator NewRotation = FRotator::MakeFromXZ(ReflectedVector, Player.ActorUpVector);

			Player.MeshOffsetComponent.FreezeRotationAndLerpBackToParent(this, 0.1);
			Player.SetActorRotation(NewRotation);
			HoverboardComp.AccRotation.SnapTo(NewRotation);
			HoverboardComp.WantedRotation = NewRotation;

			TEMPORAL_LOG(Player, "Hoverboard Collision")
				.DirectionalArrow("Reflected Vector", Params.WallHitResult.ImpactPoint, ReflectedVector * 500, 5, 40, FLinearColor::Red)
				.DirectionalArrow("Player Horizontal Velocity Dir", Player.ActorLocation, PlayerHorizontalVelocityDir * 500, 5, 40, FLinearColor::Red)
				.Value("Rotation Angle", RotationAngle)
			;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
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
				if(MoveComp.IsOnWalkableGround())
					Movement.ApplyCrumbSyncedGroundMovement();
				else
					Movement.ApplyCrumbSyncedAirMovement();
			}
			
			Player.SetAnimBoolParam(BattlefieldHoverboardAnimParams::HoverboardReflectedOffWall, true);
			FName AnimTag;
			if(MoveComp.IsOnAnyGround())
			{	
				if(MoveComp.WasInAir())
					AnimTag = BattlefieldHoverboardLocomotionTags::HoverboardLanding;
				else if(MoveComp.IsOnWalkableGround())
					AnimTag = BattlefieldHoverboardLocomotionTags::Hoverboard;
			}
			else
				AnimTag = BattlefieldHoverboardLocomotionTags::HoverboardAirMovement;
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimTag);
		}
	}

	private void ApplyImpactCameraEffects(FBattlefieldHoverboardCollisionActivationParams Params)
	{
		float SpeedAlignedWithWall = MoveComp.PreviousVelocity.DotProduct(-Params.ReflectionNormal);
		float SpeedAlpha = Math::GetPercentageBetweenClamped(0, MaxCameraEffectSpeed, SpeedAlignedWithWall);

		Player.ApplyBlendToCurrentView(MaxCameraBlendTime * SpeedAlpha);
		
		FHazeCameraImpulse CamImpulse;
		CamImpulse.WorldSpaceImpulse = -Params.ReflectionNormal * MaxCameraImpulseSize * SpeedAlpha;
		CamImpulse.ExpirationForce = 10.5;
		CamImpulse.Dampening = 1.0;
		Player.ApplyCameraImpulse(CamImpulse, this);
	}

	private void ApplyImpactRumble(FBattlefieldHoverboardCollisionActivationParams Params)
	{
		float SpeedAlignedWithWall = MoveComp.PreviousVelocity.DotProduct(-Params.WallHitResult.ImpactNormal);
		float RumbleAlpha = Math::GetPercentageBetweenClamped(0, GroundMovementSettings.WallSpeedForFullRumble, SpeedAlignedWithWall);
		float RumbleMultiplier = GroundMovementSettings.WallRumbleCurve.GetFloatValue(RumbleAlpha);
		Player.PlayForceFeedback(GroundMovementSettings.WallRumble, false, false, this, RumbleMultiplier);
	}
};